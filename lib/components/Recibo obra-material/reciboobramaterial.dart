import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:distriservicios_app_3/model/internas.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';

import '../../model/materiales.dart';
import '../../model/mediciones.dart';
import 'list_view_excel_material.dart';
import 'list_view_pdf_material.dart';

class ReciboObraMaterial extends StatefulWidget {
  const ReciboObraMaterial({super.key});

  @override
  State<ReciboObraMaterial> createState() => _ReciboObraMaterialState();
}

class _ReciboObraMaterialState extends State<ReciboObraMaterial>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  User? user;
  String userId = '';
  String? accessToken;

  // Items para agregar materiales de la tabla "redes"
  List<Materiales> materialesss = [];
  Materiales? seleccionarMaterial;
  String cantidad = '';
  List<Map<String, dynamic>> addedMaterials = [];

  // Items para agregar materiales de la tabla "centro de mediciones"
  List<Mediciones> medicionesss = [];
  Mediciones? seleccionarMediciones;
  String cantidadMediciones = '';
  List<Map<String, dynamic>> addedMediciones = [];

  // Items para agregar materiales de la tabla "internas"
  List<Internas> internasss = [];
  Internas? seleccionarInternas;
  String cantidadInternas = '';
  List<Map<String, dynamic>> addedInternas = [];

  final TextEditingController _nombreTecnicoController =
      TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _codigoUsuarioController =
      TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _fechaConstruccionController =
      TextEditingController();
  final TextEditingController _fechaServicioController =
      TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _cantidadMedicionesController =
      TextEditingController();
  final TextEditingController _cantidadInternasController =
      TextEditingController();
  final TextEditingController _observacionController = TextEditingController();

  Uint8List? signature;
  Uint8List? signature2;

  final _firmaController = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 4,
    exportPenColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final _firmaInstaladorController = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 4,
    exportPenColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    user = FirebaseAuth.instance.currentUser;
    userId = user?.uid ?? '';
    _getAccessToken();

    axiosMaterials().then((value) {
      setState(() {
        materialesss = value;
      });
    });

    axiosMediciones().then((value) {
      setState(() {
        medicionesss = value;
      });
    });

    axiosInternas().then((value) {
      setState(() {
        internasss = value;
      });
    });
    super.initState();
  }

  Future<void> _getAccessToken() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount == null) {
        return;
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      setState(() {
        accessToken = googleSignInAuthentication.accessToken;
      });

      if (accessToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No se pudo obtener el token de acceso')),
          );
        }
      } else {
        // print(
        //     "Access Token obtenido: $accessToken");
      }
    } catch (e) {
      // print("Error al obtener el accessToken: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firmaController.dispose();
    _firmaInstaladorController.dispose();
    super.dispose();
  }

  void agregarMateriales() {
    if (seleccionarMaterial != null) {
      bool exists = addedMaterials
          .any((material) => material['codigo'] == seleccionarMaterial!.codigo);

      if (!exists) {
        setState(() {
          addedMaterials.add({
            'codigo': seleccionarMaterial!.codigo,
            'nombre': seleccionarMaterial!.nombre,
            'cantidad': int.tryParse(cantidad) ?? 1,
          });
          seleccionarMaterial = null;
          _cantidadController.clear();
          cantidad = '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este material ya ha sido agregado.')),
        );
      }
    }
  }

  void eliminarMateriales(int index) {
    setState(() {
      addedMaterials.removeAt(index);
    });
  }

  void agregarMediciones() {
    if (seleccionarMediciones != null) {
      bool exists = addedMediciones.any(
          (medicion) => medicion['codigo'] == seleccionarMediciones!.codigo);

      if (!exists) {
        setState(() {
          addedMediciones.add({
            'codigo': seleccionarMediciones!.codigo,
            'nombre': seleccionarMediciones!.nombre,
            'cantidad': int.tryParse(cantidadMediciones) ?? 1,
          });
          seleccionarMediciones = null;
          _cantidadMedicionesController.clear();
          cantidadMediciones = '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este material ya ha sido agregado.')),
        );
      }
    }
  }

  void eliminarMediciones(int index) {
    setState(() {
      addedMediciones.removeAt(index);
    });
  }

  void agregarInternas() {
    if (seleccionarInternas != null) {
      bool exists = addedInternas
          .any((internas) => internas['codigo'] == seleccionarInternas!.codigo);

      if (!exists) {
        setState(() {
          addedInternas.add({
            'codigo': seleccionarInternas!.codigo,
            'nombre': seleccionarInternas!.nombre,
            'cantidad': int.tryParse(cantidadInternas) ?? 1,
          });
          seleccionarInternas = null;
          _cantidadInternasController.clear();
          cantidadInternas = '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este material ya ha sido agregado.')),
        );
      }
    }
  }

  void eliminarInternas(int index) {
    setState(() {
      addedInternas.removeAt(index);
    });
  }

  void guardarInformacion() async {
    if (signature == null || signature2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltan campos y/o firmas por rellenar!')),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      _showFileTypeDialog();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falta campos por rellenar!!!')),
        );
      }
    }
  }

  void _showFileTypeDialog() async {
    // Uint8List? signatureBytes = await _firmaController.toPngBytes();
    // Uint8List? signatureBytes2 = await _firmaInstaladorController.toPngBytes();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar tipo de archivo'),
          content: const Text('¿Qué tipo de archivo deseas generar?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _generatePdf();
              },
              child: const Text('PDF'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                generateExcel();
              },
              child: const Text('Excel'),
            ),
          ],
        );
      },
    );
  }

  void _generatePdf() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        // Esta propiedad, se usa para inhabilitar el toque
        // en el fondo de pantalla
        barrierDismissible: false,
        builder: (context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Generando PDF..."),
              ],
            ),
          );
        },
      );

      try {
        Uint8List? signatureBytes = await _firmaController.toPngBytes();
        Uint8List? signatureBytes2 =
            await _firmaInstaladorController.toPngBytes();

        String nombreTecnico = _nombreTecnicoController.text;
        String usuario = _usuarioController.text;
        String codigoUsuario = _codigoUsuarioController.text;
        String cedula = _cedulaController.text;
        String fechaConstruccion = _fechaConstruccionController.text;
        String fechaServicio = _fechaServicioController.text;
        String observacion = _observacionController.text;

        // Crear PDF
        final pdf = pw.Document();

        final logoDistri = pw.MemoryImage(
          (await rootBundle.load('images/distri002.png')).buffer.asUint8List(),
        );
        pdf.addPage(
          pw.MultiPage(
            build: (pw.Context context) => [
              pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.only(left: 0),
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text("DISTRISERVICIOS S.A.S",
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 27)),
                        ),
                      ]),
                    ),
                    pw.Expanded(
                        child: pw.Column(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                          pw.Container(
                            alignment: pw.Alignment.topRight,
                            padding:
                                const pw.EdgeInsets.only(bottom: 8, left: 10),
                            height: 110,
                            child: pw.Image(logoDistri),
                          ),
                        ]))
                  ]),
              pw.SizedBox(height: 20),
              pw.Text('Nombre Técnico: $nombreTecnico'),
              pw.SizedBox(height: 20),
              pw.Text('Usuario: $usuario'),
              pw.SizedBox(height: 20),
              pw.Text('Código Usuario: $codigoUsuario'),
              pw.SizedBox(height: 20),
              pw.Text('Cédula: $cedula'),
              pw.SizedBox(height: 20),
              pw.Text('Fecha Construcción: $fechaConstruccion'),
              pw.SizedBox(height: 20),
              pw.Text('Fecha Servicio: $fechaServicio'),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de Internas
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Código',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Nombre',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Cantidad',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...addedInternas.map((internass) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(internass['codigo']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(internass['nombre']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(internass['cantidad'].toString()),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de Mediciones
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Código',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Nombre',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Cantidad',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...addedMediciones.map((medicioness) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(medicioness['codigo']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(medicioness['nombre']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(medicioness['cantidad'].toString()),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de Redes
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Código',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Nombre',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Cantidad',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...addedMaterials.map((materialess) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(materialess['codigo']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(materialess['nombre']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(materialess['cantidad'].toString()),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Observación: $observacion'),
              pw.SizedBox(height: 20),
              if (signatureBytes != null)
                pw.Image(
                  pw.MemoryImage(signatureBytes),
                  width: 200,
                  height: 100,
                ),
              pw.SizedBox(height: 10),
              pw.Text("FIRMA DEL USUARIO"),
              pw.SizedBox(height: 10),
              if (signatureBytes2 != null)
                pw.Image(
                  pw.MemoryImage(signatureBytes2),
                  width: 200,
                  height: 100,
                ),
              pw.SizedBox(height: 10),
              pw.Text("FIRMA DEL INSTALADOR"),
              pw.SizedBox(height: 10),
            ],
          ),
        );

        // Imprimir la información
        // print('Nombre Técnico: $nombreTecnico');
        // print('Usuario: $usuario');
        // print('Código Usuario: $codigoUsuario');
        // print('Cédula: $cedula');
        // print('Fecha Construcción: $fechaConstruccion');
        // print('Fecha Servicio: $fechaServicio');
        // print('Observación: $observacion');

        // if (signature != null) {
        //   print('Firma guardada, longitud: ${signature!.length} bytes');
        // } else {
        //   print('No se ha guardado la firma.');
        // }

        // Generar el nombre del archivo PDF
        String fechaActual =
            DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        String nombreArchivo = 'Recibo_Material_$fechaActual.pdf';

        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$nombreArchivo');

        await file.writeAsBytes(await pdf.save());

        DocumentReference counterDoc = FirebaseFirestore.instance
            .collection('contadores')
            .doc('ArchiveFile');

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(counterDoc);

          int newId = (snapshot.exists ? snapshot['lastId'] : 0) + 1;

          // Actualizar el contador en Firestore
          transaction.set(counterDoc, {'lastId': newId});

          CollectionReference archivosFile =
              FirebaseFirestore.instance.collection('ArchiveFile');

          await archivosFile.add({
            'id': newId,
            'url': file.path,
            'nombre': nombreArchivo,
            'fechaCreacion': DateTime.now(),
            'tipo': 'pdf',
            'categoria': 'Recibo_Obra_Material',
            'userId': userId,
          });
        });
        _nombreTecnicoController.clear();
        _usuarioController.clear();
        _codigoUsuarioController.clear();
        _cedulaController.clear();
        _fechaConstruccionController.clear();
        _fechaServicioController.clear();
        _observacionController.clear();
        _cantidadController.clear();
        _cantidadMedicionesController.clear();
        _cantidadInternasController.clear();
        _firmaController.clear();
        _firmaInstaladorController.clear();
        //
        signatureBytes = null;
        signatureBytes2 = null;
        setState(() {
          addedMaterials.clear();
          addedMediciones.clear();
          addedInternas.clear();
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ha ocurrido un error: $e')),
        );
      } finally {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF creado con exito!!!')),
          );
        }
      }
    }
  }

  Future<void> generateExcel() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        // Esta propiedad, se usa para inhabilitar el pulso
        // en el fondo de pantalla
        barrierDismissible: false,
        builder: (context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Generando Excel..."),
              ],
            ),
          );
        },
      );

      try {
        // Uint8List? signatureBytes1 = await _firmaController.toPngBytes();
        // Uint8List? signatureBytes2 =
        //     await _firmaInstaladorController.toPngBytes();
        // Crear un nuevo libro en Excel
        var excel = Excel.createExcel();
        // if (excel == null) {
        //   throw Exception("No se pudo crear el libro de Excel.");
        // }
        Sheet sheet = excel['Hoja_Material'];
        int row = 3;

        // Organizar
        sheet.merge(
            CellIndex.indexByString("A2"), CellIndex.indexByString("E3"));
        // Insertamos el texto en la celda A1 (ya combinada)
        sheet.cell(CellIndex.indexByString("A2")).value =
            "DISTRISERVICIOS ESP \nINGENERIA, DISEÑO, CONSTRUCCION";

        // Formato de la celda combinada
        sheet.cell(CellIndex.indexByString("A2")).cellStyle?.fontSize = 14;
        sheet.cell(CellIndex.indexByString("A2")).cellStyle?.isBold = true;
        sheet
            .cell(CellIndex.indexByString("A2"))
            .cellStyle
            ?.horizontalAlignment = HorizontalAlign.Center;
        sheet.cell(CellIndex.indexByString("A2")).cellStyle?.verticalAlignment =
            VerticalAlign.Center;
        sheet.cell(CellIndex.indexByString("A2")).cellStyle?.wrap =
            TextWrapping.WrapText;

        row += 2;
        row++;

        sheet.merge(
            CellIndex.indexByString("F2"), CellIndex.indexByString("G3"));
        sheet.cell(CellIndex.indexByString("F2")).value = "RECIBO DE OBRA 6981";
        sheet
            .cell(CellIndex.indexByString("F2"))
            .cellStyle
            ?.horizontalAlignment = HorizontalAlign.Center;
        sheet.cell(CellIndex.indexByString("F2")).cellStyle?.verticalAlignment =
            VerticalAlign.Center;
        sheet.cell(CellIndex.indexByString("F2")).cellStyle?.wrap =
            TextWrapping.WrapText;

        // Agrega encabezados I
        sheet.cell(CellIndex.indexByString("E5")).value = "Nombre Técnico";
        sheet.cell(CellIndex.indexByString("E6")).value = "Usuario";
        sheet.cell(CellIndex.indexByString("E7")).value = "Código Usuario";
        sheet.cell(CellIndex.indexByString("E8")).value = "Cédula";
        sheet.cell(CellIndex.indexByString("E9")).value = "Fecha Construcción";
        sheet.cell(CellIndex.indexByString("E10")).value = "Fecha Servicio";
        sheet.cell(CellIndex.indexByString("E11")).value = "Observación";
        // sheet.cell(CellIndex.indexByString("A12")).value = "Firma Usuario";
        // sheet.cell(CellIndex.indexByString("A13")).value = "Firma Instalador";

        // Agregar datos del formulario I
        sheet.cell(CellIndex.indexByString("F5")).value =
            _nombreTecnicoController.text;
        sheet.cell(CellIndex.indexByString("F6")).value =
            _usuarioController.text;
        sheet.cell(CellIndex.indexByString("F7")).value =
            _codigoUsuarioController.text;
        sheet.cell(CellIndex.indexByString("F8")).value =
            _cedulaController.text;
        sheet.cell(CellIndex.indexByString("F9")).value =
            _fechaConstruccionController.text;
        sheet.cell(CellIndex.indexByString("F10")).value =
            _fechaServicioController.text;
        sheet.cell(CellIndex.indexByString("F11")).value =
            _observacionController.text;

        // Obtener ruta para guardar las firmas
        final directory = await getApplicationDocumentsDirectory();

        // Guardar las firmas como archivos de imagen
        // String firmaUsuarioPath = '${directory.path}/firma_usuario.png';
        // String firmaInstaladorPath = '${directory.path}/firma_instalador.png';

        // await File(firmaUsuarioPath).writeAsBytes(signatureBytes1!);
        // await File(firmaInstaladorPath).writeAsBytes(signatureBytes2!);

        // // Agregar rutas de las firmas al Excel
        // sheet.cell(CellIndex.indexByString("H2")).value = firmaUsuarioPath;
        // sheet.cell(CellIndex.indexByString("H6")).value = firmaInstaladorPath;

        // Agregar datos de las tablas (ejemplo para Redes)

        // Agregar encabezados para "Redes"
        sheet.cell(CellIndex.indexByString("A$row")).value = "Código Redes";
        sheet.cell(CellIndex.indexByString("B$row")).value = "Nombre Redes";
        sheet.cell(CellIndex.indexByString("C$row")).value = "Cantidad Redes";

        row++; // Mover a la siguiente fila para los datos

        // Agregar los datos de "Redes"
        for (var material in addedMaterials) {
          sheet.cell(CellIndex.indexByString("A$row")).value =
              material['codigo'];
          if (material['nombre'].length > 20) {
            sheet.merge(CellIndex.indexByString("B$row"),
                CellIndex.indexByString("C$row"));
            sheet.cell(CellIndex.indexByString("B$row")).value =
                material['nombre'];
          } else {
            sheet.cell(CellIndex.indexByString("B$row")).value =
                material['nombre'];
          }
          sheet.cell(CellIndex.indexByString("C$row")).value =
              material['cantidad'];
          row++; // Mover a la siguiente fila
        }

        // Espacio entre tablas: Dejar una fila en blanco
        row++;

        // Agregar encabezados para "Mediciones"
        sheet.cell(CellIndex.indexByString("A$row")).value =
            "Código Mediciones";
        sheet.cell(CellIndex.indexByString("B$row")).value =
            "Nombre Mediciones";
        sheet.cell(CellIndex.indexByString("C$row")).value =
            "Cantidad Mediciones";
        row++; // Mover a la siguiente fila para los datos

        // Agregar los datos de "Mediciones"
        for (var medicion in addedMediciones) {
          sheet.cell(CellIndex.indexByString("A$row")).value =
              medicion['codigo'];
          sheet.cell(CellIndex.indexByString("B$row")).value =
              medicion['nombre'];
          sheet.cell(CellIndex.indexByString("C$row")).value =
              medicion['cantidad'];
          row++; // Mover a la siguiente fila
        }

        // Espacio entre tablas: Dejar una fila en blanco
        row++;

        // Agregar encabezados para "Internas"
        sheet.cell(CellIndex.indexByString("A$row")).value = "Código Internas";
        sheet.cell(CellIndex.indexByString("B$row")).value = "Nombre Internas";
        sheet.cell(CellIndex.indexByString("C$row")).value =
            "Cantidad Internas";
        row++; // Mover a la siguiente fila para los datos

        // Agregar los datos de "Internas"
        for (var internas in addedInternas) {
          sheet.cell(CellIndex.indexByString("A$row")).value =
              internas['codigo'];
          sheet.cell(CellIndex.indexByString("B$row")).value =
              internas['nombre'];
          sheet.cell(CellIndex.indexByString("C$row")).value =
              internas['cantidad'];
          row++; // Mover a la siguiente fila
        }

        // Obtener ruta para guardar el archivo
        // final directory = await getApplicationDocumentsDirectory();
        String fechaActual =
            DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        String nombreArchivo = 'Recibo_Material_$fechaActual.xlsx';
        final file = File('${directory.path}/$nombreArchivo');

        // Guardar el archivo Excel
        final excelBytes = excel.encode();
        if (excelBytes == null) {
          throw Exception("Error al codificar el archivo Excel.");
        }
        await file.writeAsBytes(excelBytes);
        // print("Archivo Excel guardado en: ${file.path}");
        // Actualizar el contador en Firestore
        DocumentReference counterDoc = FirebaseFirestore.instance
            .collection('contadores')
            .doc('ArchiveFile');
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(counterDoc);
          int newId = (snapshot.exists ? snapshot['lastId'] : 0) + 1;

          // Actualizar el contador en Firestore
          transaction.set(counterDoc, {'lastId': newId});

          CollectionReference archivosFile =
              FirebaseFirestore.instance.collection('ArchiveFile');
          await archivosFile.add({
            'id': newId,
            'url': file.path,
            'nombre': nombreArchivo,
            'fechaCreacion': DateTime.now(),
            'tipo': 'excel',
            'categoria': 'Recibo_Obra_Material',
            'userId': userId,
          });
        });

        _nombreTecnicoController.clear();
        _usuarioController.clear();
        _codigoUsuarioController.clear();
        _cedulaController.clear();
        _fechaConstruccionController.clear();
        _fechaServicioController.clear();
        _observacionController.clear();
        setState(() {
          addedMaterials.clear();
          addedMediciones.clear();
          addedInternas.clear();
        });
      } catch (e) {
        // print("Error al crear el archivo Excel: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ha ocurrido un error: ${e.toString()}'),
            duration: const Duration(seconds: 7),
          ),
        );
      } finally {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel creado con exito!!!')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(242, 56, 56, 1),
          foregroundColor: Colors.white,
          title: const Text(
            'Recibo de Obra N° 6981',
          ),
          actions: [
            PopupMenuButton<int>(
              icon: AnimatedIcon(
                icon: AnimatedIcons.menu_arrow,
                progress: _animationController,
              ),
              iconSize: 35,
              onSelected: (value) {
                if (value == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListViewPdfMaterial(
                        userId: userId,
                        accessToken: accessToken!,
                      ),
                    ),
                  );
                } else if (value == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListViewExcelMaterial(
                        userId: userId,
                        accessToken: accessToken!,
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<int>(
                    value: 1,
                    height: 55,
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.red,
                          size: 40,
                        ),
                        SizedBox(width: 8),
                        Text('PDF', style: TextStyle(fontSize: 25)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<int>(
                    value: 2,
                    height: 55,
                    child: Row(
                      children: [
                        Icon(
                          Icons.drive_file_move_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                        SizedBox(width: 8),
                        Text('Excel', style: TextStyle(fontSize: 25)),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                width: 500,
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text("Codigo:"),
                          Text("COD-REG-008"),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            "Version:",
                            textAlign: TextAlign.left,
                          ),
                          Text("001", textAlign: TextAlign.right),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text("Fecha"),
                          Text("07-10-2022"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              SizedBox(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          TextInputForm(
                            controller: _nombreTecnicoController,
                            hintText: 'Escriba el nombre del Tecnico',
                            labelText: 'Nombre Tecnico',
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '¡¡¡Este campo es obligatorio!!!';
                              }
                              return null;
                            },
                            validCharacter: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z\s]')),
                            ],
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          TextInputForm(
                            controller: _usuarioController,
                            hintText: 'Escriba tu Usuario',
                            labelText: 'Nombre Usuario',
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '¡¡¡Este campo es obligatorio!!!';
                              }
                              return null;
                            },
                            validCharacter: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z\s]')),
                            ],
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          TextInputForm(
                            controller: _codigoUsuarioController,
                            hintText: 'Escriba tu codigo',
                            labelText: 'Codigo Usuario',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '¡¡¡Este campo es obligatorio!!!';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          TextInputForm(
                            controller: _cedulaController,
                            hintText: 'Escriba tu cedula',
                            labelText: 'Cedula',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '¡¡¡Este campo es obligatorio!!!';
                              }
                              return null;
                            },
                            validCharacter: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          TextInputForm(
                            controller: _fechaConstruccionController,
                            hintText: 'Selecciona la fecha de Construccion',
                            labelText: 'Fecha Construccion',
                            keyboardType: TextInputType.none,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '¡¡¡Este campo es obligatorio!!!';
                              }
                              return null;
                            },
                            suffixIcon: const Icon(Icons.date_range_outlined),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                String formattedDate =
                                    "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                _fechaConstruccionController.text =
                                    formattedDate;
                              }
                            },
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          TextInputForm(
                            controller: _fechaServicioController,
                            hintText: 'Selecciona la fecha del Servicio',
                            labelText: 'Fecha Servicio',
                            keyboardType: TextInputType.none,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '¡¡¡Este campo es obligatorio!!!';
                              }
                              return null;
                            },
                            suffixIcon: const Icon(Icons.date_range_outlined),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );

                              if (pickedDate != null) {
                                String formattedDate =
                                    "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                _fechaServicioController.text = formattedDate;
                              }
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Divider(),
                          const Center(
                            child: Text(
                              "Agregar materiales de Internas",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 30),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          DropdownButton<Internas>(
                            menuMaxHeight: 500,
                            itemHeight: 80,
                            hint: const Text("Seleccione un material"),
                            value: seleccionarInternas,
                            onChanged: (Internas? newInterna) {
                              setState(() {
                                seleccionarInternas = newInterna;
                              });
                            },
                            items: internasss.map<DropdownMenuItem<Internas>>(
                                (Internas internas) {
                              return DropdownMenuItem<Internas>(
                                value: internas,
                                child: Container(
                                  // decoration: const BoxDecoration(
                                  //   border: Border(
                                  //     top: BorderSide.none,
                                  //   ),
                                  //   gradient: LinearGradient(colors: [
                                  //     Colors.red,
                                  //     Colors.orange,
                                  //   ]),
                                  // ),
                                  margin: EdgeInsets.zero,
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: Text(
                                    internas.nombre,
                                    maxLines: 3,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          TextInputForm(
                            controller: _cantidadInternasController,
                            hintText: "Ingrese una cantidad",
                            labelText: "Cantidad",
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              cantidadInternas = value!;
                            },
                            validCharacter: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          ElevatedButton(
                              onPressed: agregarInternas,
                              child: const Text("Agregar")),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 30, 20, 20),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 20,
                                  dataRowMinHeight: 50,
                                  dataRowMaxHeight: 110,
                                  border: TableBorder.all(),
                                  columns: const [
                                    DataColumn(
                                      label: SizedBox(
                                          width: 50, child: Text('Codigo')),
                                    ),
                                    DataColumn(
                                        label: SizedBox(
                                            width: 150, child: Text('Nombre'))),
                                    DataColumn(label: Text('Cantidad')),
                                    DataColumn(label: Text('Eliminar')),
                                  ],
                                  rows: addedInternas.map((internass) {
                                    int index =
                                        addedInternas.indexOf(internass);
                                    return DataRow(cells: [
                                      DataCell(Text(internass['codigo'])),
                                      DataCell(Container(
                                        constraints:
                                            const BoxConstraints(maxWidth: 150),
                                        child: Text(
                                          internass['nombre'],
                                          overflow: TextOverflow.fade,
                                          maxLines: 6,
                                        ),
                                      )),
                                      DataCell(Center(
                                        child: Text(
                                          internass['cantidad'].toString(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 25),
                                        ),
                                      )),
                                      DataCell(
                                        SizedBox(
                                          width: 50,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () =>
                                                eliminarInternas(index),
                                          ),
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Divider(),
                          const SizedBox(
                            height: 20,
                          ),
                          const Center(
                            child: Text(
                              "Agregar materiales de centro de mediciones",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 30),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          DropdownButton<Mediciones>(
                            menuMaxHeight: 500,
                            itemHeight: 80,
                            hint: const Text("Seleccione un material"),
                            value: seleccionarMediciones,
                            onChanged: (Mediciones? newMedicion) {
                              setState(() {
                                seleccionarMediciones = newMedicion;
                              });
                            },
                            items: medicionesss
                                .map<DropdownMenuItem<Mediciones>>(
                                    (Mediciones mediciones) {
                              return DropdownMenuItem<Mediciones>(
                                value: mediciones,
                                child: Container(
                                    margin: EdgeInsets.zero,
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: Text(mediciones.nombre)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          TextInputForm(
                            controller: _cantidadMedicionesController,
                            hintText: "Ingrese una cantidad",
                            labelText: "Cantidad",
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              cantidadMediciones = value!;
                            },
                            validCharacter: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          ElevatedButton(
                              onPressed: agregarMediciones,
                              child: const Text("Agregar")),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 30, 20, 20),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 20,
                                  dataRowMinHeight: 50,
                                  dataRowMaxHeight: 110,
                                  border: TableBorder.all(),
                                  columns: const [
                                    DataColumn(
                                      label: SizedBox(
                                          width: 50, child: Text('Codigo')),
                                    ),
                                    DataColumn(
                                        label: SizedBox(
                                            width: 150, child: Text('Nombre'))),
                                    DataColumn(label: Text('Cantidad')),
                                    DataColumn(label: Text('Eliminar')),
                                  ],
                                  rows: addedMediciones.map((medicioness) {
                                    int index =
                                        addedMediciones.indexOf(medicioness);
                                    return DataRow(cells: [
                                      DataCell(Text(medicioness['codigo'])),
                                      DataCell(Container(
                                        constraints:
                                            const BoxConstraints(maxWidth: 150),
                                        child: Text(
                                          medicioness['nombre'],
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 6,
                                        ),
                                      )),
                                      DataCell(Center(
                                        child: Text(
                                          medicioness['cantidad'].toString(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 25),
                                        ),
                                      )),
                                      DataCell(
                                        SizedBox(
                                          width: 50,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () =>
                                                eliminarMediciones(index),
                                          ),
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Divider(),
                          const SizedBox(
                            height: 20,
                          ),
                          const Center(
                            child: Text(
                              "Agregar materiales de Redes",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 30),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          DropdownButton<Materiales>(
                            menuMaxHeight: 500,
                            itemHeight: 80,
                            hint: const Text("Seleccione un material"),
                            value: seleccionarMaterial,
                            onChanged: (Materiales? newMaterial) {
                              setState(() {
                                seleccionarMaterial = newMaterial;
                              });
                            },
                            items: materialesss
                                .map<DropdownMenuItem<Materiales>>(
                                    (Materiales materiales) {
                              return DropdownMenuItem<Materiales>(
                                value: materiales,
                                child: Container(
                                  margin: EdgeInsets.zero,
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: Text(
                                    materiales.nombre,
                                    overflow: TextOverflow.fade,
                                    maxLines: 3,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          TextInputForm(
                            controller: _cantidadController,
                            hintText: "Ingrese una cantidad",
                            labelText: "Cantidad",
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              cantidad = value!;
                            },
                            validCharacter: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          ElevatedButton(
                              onPressed: agregarMateriales,
                              child: const Text("Agregar")),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 30, 20, 20),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 20,
                                  dataRowMinHeight: 50,
                                  dataRowMaxHeight: 110,
                                  border: TableBorder.all(),
                                  columns: const [
                                    DataColumn(
                                      label: SizedBox(
                                          width: 50, child: Text('Codigo')),
                                    ),
                                    DataColumn(
                                        label: SizedBox(
                                            width: 150, child: Text('Nombre'))),
                                    DataColumn(label: Text('Cantidad')),
                                    DataColumn(label: Text('Eliminar')),
                                  ],
                                  rows: addedMaterials.map((materialess) {
                                    int index =
                                        addedMaterials.indexOf(materialess);
                                    return DataRow(cells: [
                                      DataCell(Text(materialess['codigo'])),
                                      DataCell(Container(
                                        constraints:
                                            const BoxConstraints(maxWidth: 150),
                                        child: Text(
                                          materialess['nombre'],
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 6,
                                        ),
                                      )),
                                      DataCell(Center(
                                        child: Text(
                                          materialess['cantidad'].toString(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 25),
                                        ),
                                      )),
                                      DataCell(
                                        SizedBox(
                                          width: 50,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () =>
                                                eliminarMateriales(index),
                                          ),
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          const Divider(),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            "Observaciones",
                            style: TextStyle(fontSize: 30),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          TextInputForm(
                            controller: _observacionController,
                            maxLines: null,
                            hintText: "Observaciones acerca del recibo de obra",
                            labelText: "Observacion",
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '¡¡¡Este campo es obligatorio!!!';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Divider(),
                          const SizedBox(
                            height: 20,
                          ),
                          const Text(
                            "Firmas Digitales",
                            style: TextStyle(fontSize: 30),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  const Text("Firma del Usuario"),
                                  ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Container(
                                              width: 450,
                                              height: 550,
                                              padding: const EdgeInsets.all(16),
                                              child: Stack(
                                                children: [
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const SizedBox(
                                                          height: 60),
                                                      Center(
                                                        child: Column(
                                                          children: [
                                                            Signature(
                                                              controller:
                                                                  _firmaController,
                                                              width: double
                                                                  .infinity,
                                                              height: 300,
                                                              backgroundColor:
                                                                  Colors.white,
                                                            ),
                                                            const SizedBox(
                                                              height: 15,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      ElevatedButton
                                                                          .icon(
                                                                    onPressed: () async =>
                                                                        _firmaController
                                                                            .undo(),
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .undo),
                                                                    label: const Text(
                                                                        "Borrar trazo"),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      ElevatedButton
                                                                          .icon(
                                                                    onPressed: () async =>
                                                                        _firmaController
                                                                            .clear(),
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .clear),
                                                                    label: const Text(
                                                                        "Limpiar"),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 15,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      ElevatedButton
                                                                          .icon(
                                                                    onPressed: () async =>
                                                                        _firmaController
                                                                            .redo(),
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .redo),
                                                                    label: const Text(
                                                                        "Retomar trazo"),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      ElevatedButton
                                                                          .icon(
                                                                    onPressed:
                                                                        () async {
                                                                      signature =
                                                                          await _firmaController
                                                                              .toPngBytes();
                                                                      setState(
                                                                          () {});
                                                                      if (mounted) {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      }
                                                                    },
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .save_sharp),
                                                                    label: const Text(
                                                                        "Guardar"),
                                                                  ),
                                                                ),
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Positioned(
                                                    right: 10,
                                                    top: 10,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.close),
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    top: 10,
                                                    child: Tooltip(
                                                      showDuration:
                                                          const Duration(
                                                              seconds: 20),
                                                      message:
                                                          'El botón Borrar trazo, sirve para volver un trazo atrás.\n'
                                                          'El botón Limpiar, sirve para limpiar el tablero.\n'
                                                          'El botón Retomar trazo, sirve para volver un trazo adelante.',
                                                      child: IconButton(
                                                        icon: const Icon(Icons
                                                            .lightbulb_circle_outlined),
                                                        onPressed: () {},
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: const Text('Firmar'),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  const Text("Firma del Instalador"),
                                  ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Container(
                                              width: 450,
                                              height: 550,
                                              padding: const EdgeInsets.all(16),
                                              child: Stack(
                                                children: [
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const SizedBox(
                                                          height: 60),
                                                      Center(
                                                        child: Column(
                                                          children: [
                                                            Signature(
                                                              controller:
                                                                  _firmaInstaladorController,
                                                              width: double
                                                                  .infinity,
                                                              height: 300,
                                                              backgroundColor:
                                                                  Colors.white,
                                                            ),
                                                            const SizedBox(
                                                              height: 15,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      ElevatedButton
                                                                          .icon(
                                                                    onPressed: () async =>
                                                                        _firmaInstaladorController
                                                                            .undo(),
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .undo),
                                                                    label: const Text(
                                                                        "Borrar trazo"),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      ElevatedButton
                                                                          .icon(
                                                                    onPressed: () async =>
                                                                        _firmaInstaladorController
                                                                            .clear(),
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .clear),
                                                                    label: const Text(
                                                                        "Limpiar"),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 15,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      ElevatedButton
                                                                          .icon(
                                                                    onPressed: () async =>
                                                                        _firmaInstaladorController
                                                                            .redo(),
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .redo),
                                                                    label: const Text(
                                                                        "Retomar trazo"),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      ElevatedButton
                                                                          .icon(
                                                                    onPressed:
                                                                        () async {
                                                                      signature2 =
                                                                          await _firmaInstaladorController
                                                                              .toPngBytes();
                                                                      setState(
                                                                          () {});
                                                                      if (mounted) {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      }
                                                                    },
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .save_sharp),
                                                                    label: const Text(
                                                                        "Guardar"),
                                                                  ),
                                                                ),
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Positioned(
                                                    right: 10,
                                                    top: 10,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.close),
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    top: 10,
                                                    child: Tooltip(
                                                      showDuration:
                                                          const Duration(
                                                              seconds: 20),
                                                      message:
                                                          'El botón Borrar trazo, sirve para volver un trazo atrás.\n'
                                                          'El botón Limpiar, sirve para limpiar el tablero.\n'
                                                          'El botón Retomar trazo, sirve para volver un trazo adelante.',
                                                      child: IconButton(
                                                        icon: const Icon(Icons
                                                            .lightbulb_circle_outlined),
                                                        onPressed: () {},
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: const Text('Firmar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: guardarInformacion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromRGBO(48, 124, 191, 1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(19),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: const Text(
                                    "Guardar",
                                    style: TextStyle(fontSize: 25),
                                  ),
                                )),
                          ),
                        ],
                      )),
                ),
              ),
            ],
          ),
        ));
  }
}

class TextInputForm extends StatelessWidget {
  const TextInputForm({
    super.key,
    required this.hintText,
    required this.labelText,
    this.suffixIcon,
    this.prefixIcon,
    this.onPressed,
    this.onSaved,
    this.onChanged,
    this.controller,
    this.isImageSelected = false,
    this.keyboardType,
    this.maxLines,
    this.validator,
    this.validCharacter,
  });

  final String labelText, hintText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final VoidCallback? onPressed;
  final void Function(String?)? onChanged;
  final void Function(String?)? onSaved;
  final TextEditingController? controller;
  final bool isImageSelected;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? validCharacter;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: validCharacter,
      onTap: onPressed,
      onChanged: onChanged,
      onSaved: onSaved,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        // suffixIcon: Icon(Icons.image_search),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        border: InputBorder.none,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Colors.grey),
            gapPadding: 10),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Colors.grey),
            gapPadding: 10),
        hintText: hintText,
        labelText: labelText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 42, vertical: 20),
        hintStyle: const TextStyle(color: Color(0xFFb2b7bf), fontSize: 18.0),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.deepOrange, width: 2.0),
        ),
      ),
    );
  }
}

Future<List<Materiales>> axiosMaterials() async {
  QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('Materiales').get();
  return snapshot.docs.map((doc) {
    return Materiales(
      id: doc.id,
      codigo: doc['codigo'],
      nombre: doc['nombre'],
    );
  }).toList();
}

Future<List<Mediciones>> axiosMediciones() async {
  QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('Mediciones').get();
  return snapshot.docs.map((doc) {
    return Mediciones(
      id: doc.id,
      codigo: doc['codigo'],
      nombre: doc['nombre'],
    );
  }).toList();
}

Future<List<Internas>> axiosInternas() async {
  QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('Internas').get();
  return snapshot.docs.map((doc) {
    return Internas(
      id: doc.id,
      codigo: doc['codigo'],
      nombre: doc['nombre'],
    );
  }).toList();
}

// TextInputForm(
//                             hintText: 'Firma del Usuario',
//                             labelText: 'Usuario',
//                             prefixIcon: const Icon(
//                                 Icons.drive_file_rename_outline_outlined),
//                             onSaved: (value) {
//                               _textFirmaUsuario = value;
//                               // _image = null;
//                             },
//                             isImageSelected: _image != null,
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ElevatedButton(
//                                   onPressed: _pickImage,
//                                   child: const Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceEvenly,
//                                     children: [
//                                       Text('Cargar Imagen'),
//                                       Icon(Icons.image_search_rounded)
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 16),
//                               if (_image != null)
//                                 Image.file(
//                                   _image!,
//                                   width: 100,
//                                   height: 100,
//                                 ),
//                             ],
//                           ),
//                           const SizedBox(
//                             height: 20,
//                           ),
//                           TextInputForm(
//                             hintText: 'Firma del Instalador',
//                             labelText: 'Instalador',
//                             prefixIcon: const Icon(
//                                 Icons.drive_file_rename_outline_outlined),
//                             onSaved: (value) {
//                               _textFirmaInstalador = value;
//                               // _image = null;
//                             },
//                             isImageSelected: _image != null,
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ElevatedButton(
//                                   onPressed: _pickImage,
//                                   child: const Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceEvenly,
//                                     children: [
//                                       Text('Cargar Imagen'),
//                                       Icon(Icons.image_search_rounded)
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 16),
//                               if (_image != null)
//                                 Image.file(
//                                   _image!,
//                                   width: 100,
//                                   height: 100,
//                                 ),
//                             ],
//                           ),
//                           const SizedBox(
//                             height: 20,
//                           ),
//                           TextInputForm(
//                             hintText: 'Firma del Superior',
//                             labelText: 'Superior',
//                             prefixIcon: const Icon(
//                                 Icons.drive_file_rename_outline_outlined),
//                             onSaved: (value) {
//                               _textFirmaSuperior = value;
//                               // _image = null;
//                             },
//                             isImageSelected: _image != null,
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ElevatedButton(
//                                   onPressed: _pickImage,
//                                   child: const Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceEvenly,
//                                     children: [
//                                       Text('Cargar Imagen'),
//                                       Icon(Icons.image_search_rounded)
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 16),
//                               if (_image != null)
//                                 Image.file(
//                                   _image!,
//                                   width: 100,
//                                   height: 100,
//                                 ),
//                             ],
//                           ),
