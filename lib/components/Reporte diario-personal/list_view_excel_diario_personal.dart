import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ListViewExcelDiarioPersonal extends StatefulWidget {
  final String userId;
  final String accessToken;

  const ListViewExcelDiarioPersonal(
      {Key? key, required this.userId, required this.accessToken})
      : super(key: key);

  @override
  State<ListViewExcelDiarioPersonal> createState() =>
      _ListViewExcelDiarioPersonalState();
}

class _ListViewExcelDiarioPersonalState
    extends State<ListViewExcelDiarioPersonal> {
  bool isSelectionMode = false;
  List<bool> selectedFiles = [];
  QuerySnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _deleteExcelFile(BuildContext context, String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ArchiveFile')
          .doc(documentId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo Excel eliminado con éxito.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el archivo Excel.')),
        );
      }
      // print('Error al eliminar el archivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Archivos Excel'),
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
            .where('categoria', isEqualTo: 'Reporte_Diario_Personal')
            .where('tipo', isEqualTo: 'excel')
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
                    'No hay archivos Excel creados.',
                    textAlign: TextAlign.center,
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
                  leading: const Icon(Icons.file_copy),
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
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteExcelFile(context, files[index].id);
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
                // print("Token de acceso dentro de FloatingActionButton: ${widget.accessToken}");
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
                    await _uploadExcelToGoogleDrive(
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

  Future<void> _uploadExcelToGoogleDrive(
      File file, String fileName, String accessToken) async {
    final uri = Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');

    // Metadata en formato JSON con el tipo MIME para archivos Excel
    final metadata = jsonEncode({
      'name': fileName,
      'mimeType':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'multipart/related; boundary=foo_bar_baz',
    };

    final List<int> requestBody = [];

    requestBody.addAll(utf8.encode('''
--foo_bar_baz
Content-Type: application/json; charset=UTF-8

$metadata
--foo_bar_baz
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet

'''));

    requestBody.addAll(await file.readAsBytes());

    requestBody.addAll(utf8.encode('\n--foo_bar_baz--'));

    final request = http.Request("POST", uri)
      ..headers.addAll(headers)
      ..bodyBytes = Uint8List.fromList(requestBody);

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        // print("Archivo de Excel subido correctamente");
      } else {
        // print(
        // "Error al subir el archivo. Código de estado: ${response.statusCode}");
        // print("Detalles del error: ${await response.stream.bytesToString()}");
      }
    } catch (e) {
      // print("Error al realizar la solicitud: $e");
    }
  }

  Future<List<File>> getExcelFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);
    final files = dir.listSync();

    List<File> excelFiles = [];
    for (var file in files) {
      if (file is File && file.path.endsWith('.xlsx')) {
        excelFiles.add(file);
      }
    }
    return excelFiles;
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
                // Implementar la funcionalidad de descargar el archivo!!!
                _moveFileToDownloads(widget.fileUrl, context);
              },
              icon: const Icon(Icons.download_rounded),
              iconSize: 35,
            ),
          ],
        ),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 100,
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.warning_amber_outlined,
                  size: 120,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'No se puede visualizar el archivo excel.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30),
              ),
              const Text(
                'Por favor, guarde el archivo y ábrelo con la app de Excel u otra',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30),
              ),
              const SizedBox(
                height: 20,
              ),
              TextButton(
                onPressed: () {
                  // Implementar la funcionalidad de descargar el archivo!!!
                  _moveFileToDownloads(widget.fileUrl, context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Guardar excel",
                        style: TextStyle(
                          fontSize: 25,
                        )),
                    SizedBox(
                      width: 8,
                    ),
                    Icon(
                      Icons.download_rounded,
                      size: 35,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )));
  }

  Future<void> _moveFileToDownloads(String url, BuildContext context) async {
    try {
      // Verificar si la URL es una ruta local (almacenamiento interno de la app)
      if (url.startsWith('/data/user/')) {
        // Ruta de archivo local en almacenamiento interno de la app
        final filePath = url;
        final file = File(filePath);

        if (await file.exists()) {
          // Obtener la ruta de la carpeta de Descargas o Documentos
          final downloadsDirectory =
              await ExternalPath.getExternalStoragePublicDirectory(
                  ExternalPath.DIRECTORY_DOWNLOADS);
          // final documentsDirectory =
          //     await ExternalPath.getExternalStoragePublicDirectory(
          //         ExternalPath.DIRECTORY_DOCUMENTS);

          // Obtener el nombre del archivo
          final fileName = basename(
              filePath); // Usando basename para obtener solo el nombre del archivo

          // Definir el path para guardar el archivo en Descargas o Documentos
          final savePath =
              '$downloadsDirectory/$fileName'; // o $documentsDirectory/$fileName

          // Copiar el archivo desde la ubicación interna a la ubicación de Descargas
          await file.copy(savePath);

          // Asegúrate de que `context` es un BuildContext válido
          if (mounted) {
            // Asegúrate de usar `context` correctamente dentro de la función `setState` o cuando realmente necesites el BuildContext
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
