import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../model/tuberias.dart';
import 'list_view_excel_soldador.dart';
import 'list_view_pdf_soldador.dart';

class ReciboObraSoldador extends StatefulWidget {
  const ReciboObraSoldador({super.key});

  @override
  State<ReciboObraSoldador> createState() => _ReciboObraSoldadorState();
}

class _ReciboObraSoldadorState extends State<ReciboObraSoldador>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _formKeyTuberias = GlobalKey<FormState>();
  late AnimationController _animationController;
  User? user;
  String userId = '';
  String? accessToken;

  // Items para agregar tuberias de la tabla "redes"
  List<Tuberias> tuberiasss = [];
  Tuberias? seleccionarTuberias;
  String cantidadTuberias = "";
  String? coorLatitud;
  String? coorLongitud;

  Uint8List? signature;
  Uint8List? signature2;

  String? validateLatitud(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio.';
    }

    // Verifica si es un número y está en el rango
    final latitud = double.tryParse(value);
    if (latitud != null && (latitud < -90 || latitud > 90)) {
      return 'Ingrese una latitud válida (-90 a 90)';
    }

    return null;
  }

  String? validateLongitud(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio.';
    }

    // Verifica si es un número y está en el rango
    final longitud = double.tryParse(value);
    if (longitud != null && (longitud < -180 || longitud > 180)) {
      return 'Ingrese una longitud válida (-180 a 180)';
    }

    return null;
  }

  final _firmaSoldadorController = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 4,
    exportPenColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final _firmaSupervisorController = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 4,
    exportPenColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  void mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  List<Map<String, dynamic>> addedTuberias = [];

  final TextEditingController _nombreApellidoController =
      TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _fechaSoldadorTuberiaController =
      TextEditingController();
  final TextEditingController _municipioController = TextEditingController();
  final TextEditingController _veredaController = TextEditingController();
  final TextEditingController _cantidadTuberiasController =
      TextEditingController();
  final TextEditingController _coorLatitudController = TextEditingController();
  final TextEditingController _coorLongitudController = TextEditingController();
  final TextEditingController _observacionController = TextEditingController();

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    user = FirebaseAuth.instance.currentUser;
    userId = user?.uid ?? '';
    _getAccessToken();

    axiosTuberias().then((value) {
      setState(() {
        tuberiasss = value;
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
    _firmaSoldadorController.dispose();
    _firmaSupervisorController.dispose();
    _nombreApellidoController.dispose();
    _cedulaController.dispose();
    _fechaSoldadorTuberiaController.dispose();
    _municipioController.dispose();
    _veredaController.dispose();
    _cantidadTuberiasController.dispose();
    _coorLatitudController.dispose();
    _coorLongitudController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  void agregarTuberias() {
    if (_formKeyTuberias.currentState?.validate() ?? false) {
      if (seleccionarTuberias != null) {
        bool exists = addedTuberias
            .any((tuberia) => tuberia['codigo'] == seleccionarTuberias!.codigo);

        if (!exists) {
          setState(() {
            addedTuberias.add({
              'codigo': seleccionarTuberias!.codigo,
              'nombre': seleccionarTuberias!.nombre,
              'cantidad': int.tryParse(cantidadTuberias) ?? 1,
              'latitud': coorLatitud,
              'longitud': coorLongitud,
            });
            seleccionarTuberias = null;
            _cantidadTuberiasController.clear();
            cantidadTuberias = "";
            _coorLatitudController.clear();
            coorLatitud = "";
            _coorLongitudController.clear();
            coorLongitud = "";
          });
          // print('Latitud: $coorLatitud, Longitud: $coorLongitud');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este material ya ha sido agregado.')),
          );
        }
      }
    }
  }

  void eliminarTuberias(int index) {
    setState(() {
      addedTuberias.removeAt(index);
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
        Uint8List? signatureBytes = await _firmaSoldadorController.toPngBytes();
        Uint8List? signatureBytes2 =
            await _firmaSupervisorController.toPngBytes();

        String nombreApellido = _nombreApellidoController.text;
        String cedula = _cedulaController.text;
        String fechaSoldadorTuberia = _fechaSoldadorTuberiaController.text;
        String municipio = _municipioController.text;
        String vereda = _veredaController.text;
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
              pw.Text('Nombres y Apellidos: $nombreApellido'),
              pw.SizedBox(height: 20),
              pw.Text('Cedula: $cedula'),
              pw.SizedBox(height: 20),
              pw.Text('Fecha: $fechaSoldadorTuberia'),
              pw.SizedBox(height: 20),
              pw.Text('Municipio: $municipio'),
              pw.SizedBox(height: 20),
              pw.Text('Vereda: $vereda'),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de Tuberias de Redes
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
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Norte',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Este',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...addedTuberias.map((tuberiass) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(tuberiass['codigo']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(tuberiass['nombre']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(tuberiass['cantidad'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(tuberiass['latitud'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(tuberiass['longitud'].toString()),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de Mediciones
              pw.Text('Observación: $observacion'),
              pw.SizedBox(height: 20),
              if (signatureBytes != null)
                pw.Image(
                  pw.MemoryImage(signatureBytes),
                  width: 200,
                  height: 100,
                ),
              pw.SizedBox(height: 10),
              pw.Text("FIRMA DEL SOLDADOR"),
              pw.SizedBox(height: 10),
              if (signatureBytes2 != null)
                pw.Image(
                  pw.MemoryImage(signatureBytes2),
                  width: 200,
                  height: 100,
                ),
              pw.SizedBox(height: 10),
              pw.Text("FIRMA DEL SUPERVISOR"),
              pw.SizedBox(height: 10),
            ],
          ),
        );

        String fechaActual =
            DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        String nombreArchivo = 'Recibo_Soldador_$fechaActual.pdf';

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
            'categoria': 'Recibo_Obra_Soldador',
            'userId': userId,
          });
        });
        _nombreApellidoController.clear();
        _cedulaController.clear();
        _fechaSoldadorTuberiaController.clear();
        _cedulaController.clear();
        _municipioController.clear();
        _veredaController.clear();
        _observacionController.clear();
        _cantidadTuberiasController.clear();
        _coorLatitudController.clear();
        _coorLongitudController.clear();
        _firmaSoldadorController.clear();
        _firmaSupervisorController.clear();
        //
        signatureBytes = null;
        signatureBytes2 = null;
        setState(() {
          addedTuberias.clear();
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
        // Crear un nuevo libro en Excel
        var excel = Excel.createExcel();
        // if (excel == null) {
        //   throw Exception("No se pudo crear el libro de Excel.");
        // }
        Sheet sheet = excel['Hoja_Soldador'];
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

        row++;
        row += 2;

        sheet.merge(
            CellIndex.indexByString("F2"), CellIndex.indexByString("H3"));
        sheet.cell(CellIndex.indexByString("F2")).value =
            "RECIBO DE OBRA DE SOLDADOR \nEN TUBERIA DE TERMOFUSION";
        sheet
            .cell(CellIndex.indexByString("F2"))
            .cellStyle
            ?.horizontalAlignment = HorizontalAlign.Center;
        sheet.cell(CellIndex.indexByString("F2")).cellStyle?.verticalAlignment =
            VerticalAlign.Center;
        sheet.cell(CellIndex.indexByString("F2")).cellStyle?.wrap =
            TextWrapping.WrapText;

        // Agrega encabezados I
        sheet.cell(CellIndex.indexByString("G5")).value = "Nombres y Apellidos";
        sheet.cell(CellIndex.indexByString("G6")).value = "Cedula";
        sheet.cell(CellIndex.indexByString("G7")).value = "Fecha";
        sheet.cell(CellIndex.indexByString("G8")).value = "Cédula";
        sheet.cell(CellIndex.indexByString("G9")).value = "Municipio";
        sheet.cell(CellIndex.indexByString("G10")).value = "Vereda";
        sheet.cell(CellIndex.indexByString("G11")).value = "Observaciones";

        // Agregar datos del formulario I
        sheet.cell(CellIndex.indexByString("H5")).value =
            _nombreApellidoController.text;
        sheet.cell(CellIndex.indexByString("H6")).value =
            _cedulaController.text;
        sheet.cell(CellIndex.indexByString("H7")).value =
            _fechaSoldadorTuberiaController.text;
        sheet.cell(CellIndex.indexByString("H8")).value =
            _cedulaController.text;
        sheet.cell(CellIndex.indexByString("H9")).value =
            _municipioController.text;
        sheet.cell(CellIndex.indexByString("H10")).value =
            _veredaController.text;
        sheet.cell(CellIndex.indexByString("H11")).value =
            _observacionController.text;

        // Obtener ruta para guardar las firmas
        final directory = await getApplicationDocumentsDirectory();
        // Agregar datos de las tablas (ejemplo para Tuberias)

        // Agregar encabezados para "Redes"
        sheet.cell(CellIndex.indexByString("A$row")).value = "Código - Redes";
        sheet.cell(CellIndex.indexByString("B$row")).value = "Nombre - Redes";
        sheet.cell(CellIndex.indexByString("D$row")).value = "Cantidad - Redes";
        sheet.cell(CellIndex.indexByString("E$row")).value = "Norte - Redes";
        sheet.cell(CellIndex.indexByString("F$row")).value = "Este - Redes";

        row++;

        // Agregar los datos de "Redes"
        for (var material in addedTuberias) {
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
          sheet.cell(CellIndex.indexByString("D$row")).value =
              material['cantidad'];
          sheet.cell(CellIndex.indexByString("E$row")).value =
              material['latitud'];
          sheet.cell(CellIndex.indexByString("F$row")).value =
              material['longitud'];
          row++;
        }

        row++;

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
            'categoria': 'Recibo_Obra_Soldador',
            'userId': userId,
          });
        });

        _nombreApellidoController.clear();
        _cedulaController.clear();
        _fechaSoldadorTuberiaController.clear();
        _municipioController.clear();
        _veredaController.clear();
        _cantidadTuberiasController.clear();
        _observacionController.clear();
        setState(() {
          addedTuberias.clear();
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
          title: const Text('Recibo de obra. Soldador de polietileno'),
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
                      builder: (context) => ListViewPdfSoldador(
                        userId: userId,
                        accessToken: accessToken!,
                      ),
                    ),
                  );
                } else if (value == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListViewExcelSoldador(
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
            child: Column(children: [
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
                      Text("DS-P"),
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
                      Text("06-06-2024"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
              child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      TextInputForm(
                        controller: _nombreApellidoController,
                        hintText: 'Ej: Bryan Flores',
                        labelText: 'Nombres Y Apellidos',
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
                        height: 20,
                      ),
                      TextInputForm(
                        controller: _cedulaController,
                        hintText: 'Ej: 10762903123',
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
                        height: 20,
                      ),
                      TextInputForm(
                        controller: _fechaSoldadorTuberiaController,
                        hintText: 'Seleccione una fecha',
                        labelText: 'Fecha',
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
                            _fechaSoldadorTuberiaController.text =
                                formattedDate;
                          }
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextInputForm(
                        controller: _municipioController,
                        hintText: 'Escriba el municipio',
                        labelText: 'Municipio',
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
                        height: 20,
                      ),
                      TextInputForm(
                        controller: _veredaController,
                        hintText: 'Escriba una vereda',
                        labelText: 'Vereda',
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
                        height: 20,
                      ),
                      const Divider(),
                      const Center(
                        child: Text(
                          "Agregar materiales de tuberias de redes",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Form(
                          key: _formKeyTuberias,
                          child: Column(
                            children: [
                              DropdownButtonFormField<Tuberias>(
                                menuMaxHeight: 500,
                                itemHeight: 80,
                                hint: const Text("Seleccione un material"),
                                value: seleccionarTuberias,
                                onChanged: (Tuberias? newTuberias) {
                                  setState(() {
                                    seleccionarTuberias = newTuberias;
                                  });
                                },
                                items: tuberiasss
                                    .map<DropdownMenuItem<Tuberias>>(
                                        (Tuberias tuberias) {
                                  return DropdownMenuItem<Tuberias>(
                                    value: tuberias,
                                    child: Container(
                                        margin: EdgeInsets.zero,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                        child: Text(
                                          tuberias.nombre,
                                          maxLines: 3,
                                        )),
                                  );
                                }).toList(),
                                validator: (value) => value == null
                                    ? 'Seleccione una opción'
                                    : null,
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              TextInputForm(
                                controller: _cantidadTuberiasController,
                                hintText: "Ingrese una cantidad",
                                labelText: "Cantidad",
                                keyboardType: TextInputType.number,
                                validCharacter: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  cantidadTuberias = value!;
                                },
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _coorLatitudController,
                                      validator: validateLatitud,
                                      keyboardType: TextInputType.text,
                                      onChanged: (value) {
                                        coorLatitud = value;
                                      },
                                      decoration: const InputDecoration(
                                          labelText: 'Norte'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _coorLongitudController,
                                      validator: validateLongitud,
                                      keyboardType: TextInputType.text,
                                      onChanged: (value) {
                                        coorLongitud = value;
                                      },
                                      decoration: const InputDecoration(
                                          labelText: 'Este'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                  onPressed: agregarTuberias,
                                  child: const Text("Agregar")),
                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 30, 20, 20),
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
                                              width: 150,
                                              child: Text('Nombre')),
                                        ),
                                        DataColumn(label: Text('Cantidad')),
                                        DataColumn(label: Text('Norte')),
                                        DataColumn(label: Text('Este')),
                                        DataColumn(label: Text('Eliminar')),
                                      ],
                                      rows: addedTuberias.map((medicioness) {
                                        int index =
                                            addedTuberias.indexOf(medicioness);
                                        return DataRow(cells: [
                                          DataCell(Text(medicioness['codigo'])),
                                          DataCell(Container(
                                            constraints: const BoxConstraints(
                                                maxWidth: 150),
                                            child: Text(
                                              medicioness['nombre'],
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 6,
                                            ),
                                          )),
                                          DataCell(Center(
                                            child: Text(
                                              medicioness['cantidad']
                                                  .toString(),
                                              textAlign: TextAlign.center,
                                              style:
                                                  const TextStyle(fontSize: 25),
                                            ),
                                          )),
                                          DataCell(Text(medicioness['latitud']
                                              .toString())),
                                          DataCell(Text(medicioness['longitud']
                                              .toString())),
                                          DataCell(
                                            SizedBox(
                                              width: 50,
                                              child: IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed: () =>
                                                    eliminarTuberias(index),
                                              ),
                                            ),
                                          ),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      const SizedBox(
                        height: 20,
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
                        hintText:
                            "Observaciones acerca del recibo de obra de soldador",
                        labelText: "Observacion",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, escriba lo nuevamente';
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
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              const Text("Firma del Soldador"),
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
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(height: 60),
                                                  Center(
                                                    child: Column(
                                                      children: [
                                                        Signature(
                                                          controller:
                                                              _firmaSoldadorController,
                                                          width:
                                                              double.infinity,
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
                                                                    _firmaSoldadorController
                                                                        .undo(),
                                                                icon: const Icon(
                                                                    Icons.undo),
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
                                                                    _firmaSoldadorController
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
                                                                    _firmaSoldadorController
                                                                        .redo(),
                                                                icon: const Icon(
                                                                    Icons.redo),
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
                                                                      await _firmaSoldadorController
                                                                          .toPngBytes();
                                                                  setState(
                                                                      () {});
                                                                  if (mounted) {
                                                                    Navigator.of(
                                                                            context)
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
                                                  icon: const Icon(Icons.close),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ),
                                              Positioned(
                                                left: 0,
                                                top: 10,
                                                child: Tooltip(
                                                  showDuration: const Duration(
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
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              const Text("Firma del Supervisor"),
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
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(height: 60),
                                                  Center(
                                                    child: Column(
                                                      children: [
                                                        Signature(
                                                          controller:
                                                              _firmaSupervisorController,
                                                          width:
                                                              double.infinity,
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
                                                                    _firmaSupervisorController
                                                                        .undo(),
                                                                icon: const Icon(
                                                                    Icons.undo),
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
                                                                    _firmaSupervisorController
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
                                                                    _firmaSupervisorController
                                                                        .redo(),
                                                                icon: const Icon(
                                                                    Icons.redo),
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
                                                                      await _firmaSupervisorController
                                                                          .toPngBytes();
                                                                  setState(
                                                                      () {});
                                                                  if (mounted) {
                                                                    Navigator.of(
                                                                            context)
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
                                                  icon: const Icon(Icons.close),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ),
                                              Positioned(
                                                left: 0,
                                                top: 10,
                                                child: Tooltip(
                                                  showDuration: const Duration(
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
        ])));
  }
}

class TextInputForm extends StatelessWidget {
  const TextInputForm({
    super.key,
    required this.hintText,
    required this.labelText,
    this.suffixIcon,
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
  final VoidCallback? onPressed;
  final void Function(String?)? onSaved;
  final void Function(String?)? onChanged;
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
      onSaved: onSaved,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        suffixIcon: suffixIcon,
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

Future<List<Tuberias>> axiosTuberias() async {
  QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('Tuberias').get();
  return snapshot.docs.map((doc) {
    return Tuberias(
      id: doc.id,
      codigo: doc['codigo'],
      nombre: doc['nombre'],
    );
  }).toList();
}
