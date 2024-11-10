import 'dart:convert';
import 'dart:typed_data';

import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class ListViewPdfMaterial extends StatefulWidget {
  final String userId;
  final String accessToken;

  const ListViewPdfMaterial(
      {super.key, required this.userId, required this.accessToken});

  @override
  State<ListViewPdfMaterial> createState() => _ListViewPdfMaterialState();
}

class _ListViewPdfMaterialState extends State<ListViewPdfMaterial> {
  List<bool> selectedFiles = [];
  bool isSelectionMode = false;
  QuerySnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    selectedFiles = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Archivos'),
        backgroundColor: const Color.fromRGBO(242, 56, 56, 1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isSelectionMode ? Icons.check : Icons.send),
            onPressed: () {
              setState(() {
                isSelectionMode = !isSelectionMode;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ArchiveFile')
            .where('userId', isEqualTo: widget.userId)
            .where('categoria', isEqualTo: 'Recibo_Obra_Material')
            .where('tipo', isEqualTo: 'pdf')
            .snapshots(),
        builder: (context, snapshot) {
          _snapshot = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Column(
              children: [
                const Text("Se ha presentado el siguiente error:"),
                const SizedBox(
                  height: 8,
                ),
                Text('Error: ${snapshot.error}'),
              ],
            ));
          } else {
            final files = snapshot.data?.docs ?? [];
            if (selectedFiles.length != files.length) {
              selectedFiles = List.generate(files.length, (_) => false);
            }
            if (files.isEmpty) {
              return const Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 100,
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.warning_amber_outlined,
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    'No hay archivos creados.',
                    style: TextStyle(fontSize: 30),
                  ),
                ],
              ));
            }
            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final fileData = files[index].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(fileData['nombre']),
                  leading: const Icon(Icons.description_sharp),
                  onTap: () {
                    if (!isSelectionMode) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PDFViewerScreen(fileUrl: fileData['url']),
                        ),
                      );
                    } else {
                      setState(() {
                        selectedFiles[index] = !selectedFiles[index];
                      });
                    }
                  },
                  trailing: isSelectionMode
                      ? Checkbox(
                          value: selectedFiles[index],
                          onChanged: (bool? value) {
                            setState(() {
                              selectedFiles[index] = value!;
                            });
                          },
                          activeColor: Colors.red.shade500,
                          checkColor: Colors.red.shade900,
                          fillColor: MaterialStateProperty.resolveWith<Color>(
                              (states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.red.shade100;
                            }
                            return Colors.transparent;
                          }),
                          side: BorderSide(color: Colors.red.shade900),
                          // shape: Border(),
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deletePdf(context, files[index].id);
                          },
                        ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: isSelectionMode
          ? FloatingActionButton(
              onPressed: () async {
                // print( "Token de acceso dentro de FloatingActionButton: ${widget.accessToken}");
                final selectedDocs = _snapshot!.docs
                    .asMap()
                    .entries
                    .where((entry) => selectedFiles[entry.key])
                    .map((entry) => entry.value)
                    .toList();

                if (selectedDocs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No se ha seleccionado ningún archivo')),
                  );
                  return;
                }

                // Obtener el token de acceso de Google Sign-In
                final googleSignIn = GoogleSignIn.standard(
                  scopes: ['https://www.googleapis.com/auth/drive.file'],
                );
                final account = await googleSignIn.signIn();
                final googleAuth = await account?.authentication;
                final accessToken = googleAuth?.accessToken;

                if (accessToken == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Token de acceso no disponible. Por favor, inicie sesión.'),
                      ),
                    );
                  }
                  return;
                }

                // Subir los archivos a Google Drive
                for (var doc in selectedDocs) {
                  final fileData = doc.data() as Map<String, dynamic>;
                  final localFile = File(fileData['url']);

                  if (await localFile.exists()) {
                    await _uploadFileToGoogleDrive(
                        localFile, fileData['nombre'], widget.accessToken);
                  }
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Archivos subidos a Google Drive con éxito')),
                  );
                  setState(() {
                    selectedFiles =
                        List.generate(_snapshot!.docs.length, (_) => false);
                    isSelectionMode = false;
                  });
                }
              },
              child: const Icon(Icons.send),
            )
          : null,
    );
  }

  void _deletePdf(BuildContext context, String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ArchiveFile')
          .doc(documentId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo eliminado con éxito.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el archivo.')),
        );
      }
      // print('Error al eliminar el archivo: $e');
    }
  }
}

Future<void> _uploadFileToGoogleDrive(
    File file, String fileName, String accessToken) async {
  // print("Entrando a _uploadFileToGoogleDrive");
  final uri = Uri.parse(
      'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');
  // print("URI de la solicitud: $uri");

  // Metadata en formato JSON
  final metadata = jsonEncode({
    'name': fileName,
    'mimeType': 'application/pdf',
  });

  // Configurar los encabezados para la solicitud multipart/related
  final headers = {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'multipart/related; boundary=foo_bar_baz',
  };

  final List<int> requestBody = [];

  // Añadir la metadata al cuerpo
  requestBody.addAll(utf8.encode('''
--foo_bar_baz
Content-Type: application/json; charset=UTF-8

$metadata
--foo_bar_baz
Content-Type: application/pdf

'''));

  // Añadir el archivo PDF en formato binario
  requestBody.addAll(await file.readAsBytes());

  // Añadir el cierre del boundary
  requestBody.addAll(utf8.encode('\n--foo_bar_baz--'));

  // Crear la solicitud y asignar el cuerpo de bytes
  final request = http.Request("POST", uri)
    ..headers.addAll(headers)
    ..bodyBytes = Uint8List.fromList(requestBody);

  try {
    final response = await request.send();
    if (response.statusCode == 200) {
      // print("Archivo subido correctamente");
    } else {
      // print(
      // "Error al subir el archivo. Código de estado: ${response.statusCode}");
      // print("Detalles del error: ${await response.stream.bytesToString()}");
    }
  } catch (e) {
    // print("Error al realizar la solicitud: $e");
  }
}

class PDFViewerScreen extends StatefulWidget {
  final String fileUrl;

  const PDFViewerScreen({Key? key, required this.fileUrl}) : super(key: key);

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int currentPage = 0;
  int totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileUrl.split('/').last),
        backgroundColor: const Color.fromRGBO(242, 56, 56, 1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              _moveFileToDownloads(widget.fileUrl, context);
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            iconSize: 35,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PDFView(
              filePath: widget.fileUrl,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: true,
              pageFling: true,
              onPageChanged: (int? page, int? total) {
                setState(() {
                  currentPage = page ?? 0;
                  totalPages = total ?? 0;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Página ${currentPage + 1} de $totalPages',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveFileToDownloads(String url, BuildContext context) async {
    try {
      if (url.startsWith('/data/user/')) {
        final filePath = url;
        final file = File(filePath);

        if (await file.exists()) {
          final downloadsDirectory =
              await ExternalPath.getExternalStoragePublicDirectory(
                  ExternalPath.DIRECTORY_DOWNLOADS);
          final fileName = basename(filePath);

          final savePath = '$downloadsDirectory/$fileName';

          await file.copy(savePath);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Archivo movido a: $savePath')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('El archivo no existe en la ruta local')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('URL no válida: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al mover el archivo: $e')),
        );
      }
    }
  }
}
