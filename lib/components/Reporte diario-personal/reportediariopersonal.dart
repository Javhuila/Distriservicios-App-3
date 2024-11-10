import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:distriservicios_app_3/model/colaboradores.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'list_view_excel_diario_personal.dart';
import 'list_view_pdf_diario_personal.dart';

class ReporteDiarioPersonal extends StatefulWidget {
  const ReporteDiarioPersonal({super.key});

  @override
  State<ReporteDiarioPersonal> createState() => _ReporteDiarioPersonalState();
}

class _ReporteDiarioPersonalState extends State<ReporteDiarioPersonal>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  User? user;
  String userId = '';
  String? accessToken;

  final TextEditingController _proyectoController = TextEditingController();
  final TextEditingController _cargoController = TextEditingController();
  final TextEditingController _nombreApellidoController =
      TextEditingController();
  final TextEditingController _fechaDiarioController = TextEditingController();
  final TextEditingController _veredaController = TextEditingController();
  final TextEditingController _ingenieroResidenteController =
      TextEditingController();
  final TextEditingController _estacionAlmaController = TextEditingController();
  final TextEditingController _rendimientoController = TextEditingController();
  final TextEditingController _observacionController = TextEditingController();

  List<Colaboradores> colaboradoresss = [];
  List<Map<String, dynamic>> addedColaboradores = [];
  String? selectedColaborador;
  int contadorColab = 0;
  String? _selectedJornada;

  Uint8List? signature;

  final _firmaController = SignatureController(
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

    loadColaboradores();
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
    _proyectoController.dispose();
    _cargoController.dispose();
    _nombreApellidoController.dispose();
    _fechaDiarioController.dispose();
    _veredaController.dispose();
    _ingenieroResidenteController.dispose();
    _estacionAlmaController.dispose();
    _rendimientoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> loadColaboradores() async {
    colaboradoresss = await axiosColaboradores();
    setState(() {});
  }

  void agregarColaborador() {
    if (addedColaboradores
        .any((reporte) => reporte['id'] == selectedColaborador)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este colaborador ya ha sido agregado.')),
      );
      return;
    }

    if (selectedColaborador != null && _rendimientoController.text.isNotEmpty) {
      final colaboradorSeleccionado = colaboradoresss.firstWhere(
        (colaborador) => colaborador.id == selectedColaborador,
      );

      setState(() {
        addedColaboradores.add({
          'id': colaboradorSeleccionado.id,
          'colaborador':
              '${colaboradorSeleccionado.nombre} ${colaboradorSeleccionado.primerApellido} ${colaboradorSeleccionado.segundoApellido}',
          'actividad': colaboradorSeleccionado.cargo,
          'rendimiento': _rendimientoController.text,
        });
        selectedColaborador = null;

        _rendimientoController.clear();
      });
    }
  }

  void eliminarReporte(int index) {
    setState(() {
      addedColaboradores.removeAt(index);
    });
  }

  void guardarInformacion() async {
    if (signature == null) {
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

        String proyecto = _proyectoController.text;
        String cargo = _cargoController.text;
        String nombreApellido = _nombreApellidoController.text;
        String fecha = _fechaDiarioController.text;
        String vereda = _veredaController.text;
        String ingenierioResidente = _ingenieroResidenteController.text;
        String estacionAlma = _estacionAlmaController.text;
        String? jornada = _selectedJornada ?? 'No seleccionada';
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
              pw.Text('Proyecto: $proyecto'),
              pw.SizedBox(height: 20),
              pw.Text('Cargo: $cargo'),
              pw.SizedBox(height: 20),
              pw.Text('Nombres y Apellidos: $nombreApellido'),
              pw.SizedBox(height: 20),
              pw.Text('Fecha: $fecha'),
              pw.SizedBox(height: 20),
              pw.Text('Vereda: $vereda'),
              pw.SizedBox(height: 20),
              pw.Text('Ingeniero Residente: $ingenierioResidente'),
              pw.SizedBox(height: 20),
              pw.Text('Estación de almacenamiento: $estacionAlma'),
              pw.SizedBox(height: 20),
              pw.Text('Jornada: $jornada'),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de Colaboradores
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('N°',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Colaborador',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Actividad realizada',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Rendimiento',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...addedColaboradores.asMap().entries.map((entry) {
                    int index = entry.key;
                    var colaboradoress = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text((index + 1).toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(colaboradoress['colaborador']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(colaboradoress['actividad']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(colaboradoress['rendimiento']),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              // pw.Text('Total de colaboradores: ${addedColaboradores.length}',
              //   style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

              pw.Text('Observación: $observacion'),
              pw.SizedBox(height: 20),
              if (signatureBytes != null)
                pw.Image(
                  pw.MemoryImage(signatureBytes),
                  width: 200,
                  height: 100,
                ),
              pw.SizedBox(height: 10),
              pw.Text("FIRMA DILIGENCIADA"),
              pw.SizedBox(height: 10),
            ],
          ),
        );

        String fechaActual =
            DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        String nombreArchivo = 'Reporte_Diario_Personal$fechaActual.pdf';

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
            'categoria': 'Reporte_Diario_Personal',
            'userId': userId,
          });
        });
        _proyectoController.clear();
        _cargoController.clear();
        _nombreApellidoController.clear();
        _fechaDiarioController.clear();
        _veredaController.clear();
        _ingenieroResidenteController.clear();
        _estacionAlmaController.clear();
        _observacionController.clear();
        _firmaController.clear();
        //
        signatureBytes = null;
        setState(() {
          addedColaboradores.clear();
          _selectedJornada = null;
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
        Sheet sheet = excel['Hoja_Diario_Personal'];
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
            CellIndex.indexByString("F2"), CellIndex.indexByString("H3"));
        sheet.cell(CellIndex.indexByString("F2")).value =
            "REPORTE DIARIO \nPERSONAL";
        sheet
            .cell(CellIndex.indexByString("F2"))
            .cellStyle
            ?.horizontalAlignment = HorizontalAlign.Center;
        sheet.cell(CellIndex.indexByString("F2")).cellStyle?.verticalAlignment =
            VerticalAlign.Center;
        sheet.cell(CellIndex.indexByString("F2")).cellStyle?.wrap =
            TextWrapping.WrapText;

        // Agrega encabezados I
        sheet.cell(CellIndex.indexByString("G5")).value = "Proyecto";
        sheet.cell(CellIndex.indexByString("G6")).value = "Cargo";
        sheet.cell(CellIndex.indexByString("G7")).value = "Nombres y Apellidos";
        sheet.cell(CellIndex.indexByString("G8")).value = "Fecha";
        sheet.cell(CellIndex.indexByString("G9")).value = "Vereda";
        sheet.cell(CellIndex.indexByString("G10")).value =
            "Ingeniero Residente";
        sheet.cell(CellIndex.indexByString("G11")).value =
            "Estación de almacenamiento";
        sheet.cell(CellIndex.indexByString("G12")).value = "Jornada";
        sheet.cell(CellIndex.indexByString("G13")).value = "Observaciones";

        // Agregar datos del formulario I
        sheet.cell(CellIndex.indexByString("H5")).value =
            _proyectoController.text;
        sheet.cell(CellIndex.indexByString("H6")).value = _cargoController.text;
        sheet.cell(CellIndex.indexByString("H7")).value =
            _nombreApellidoController.text;
        sheet.cell(CellIndex.indexByString("H8")).value =
            _fechaDiarioController.text;
        sheet.cell(CellIndex.indexByString("H9")).value =
            _veredaController.text;
        sheet.cell(CellIndex.indexByString("H10")).value =
            _ingenieroResidenteController.text;
        sheet.cell(CellIndex.indexByString("H11")).value =
            _estacionAlmaController.text;
        sheet.cell(CellIndex.indexByString("H12")).value = _selectedJornada;
        sheet.cell(CellIndex.indexByString("H13")).value =
            _observacionController.text;

        final directory = await getApplicationDocumentsDirectory();
        // Agregar datos de las tablas (ejemplo para Colaboradores)

        // Agregar encabezados para "Redes"
        sheet.cell(CellIndex.indexByString("A$row")).value = "Colaborador";
        sheet.cell(CellIndex.indexByString("B$row")).value =
            "Actividad realizada";
        sheet.cell(CellIndex.indexByString("C$row")).value = "Rendimiento";

        row++;

        // Agregar los datos de "Colaboradores"
        for (var material in addedColaboradores) {
          sheet.cell(CellIndex.indexByString("A$row")).value =
              material['colaborador'];
          sheet.cell(CellIndex.indexByString("B$row")).value =
              material['actividad'];
          sheet.cell(CellIndex.indexByString("C$row")).value =
              material['rendimiento'];
          row++;
        }

        row++;

        // Obtener ruta para guardar el archivo
        // final directory = await getApplicationDocumentsDirectory();
        String fechaActual =
            DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        String nombreArchivo = 'Reporte_Diario_Personal_$fechaActual.xlsx';
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
            'categoria': 'Reporte_Diario_Personal',
            'userId': userId,
          });
        });

        _proyectoController.clear();
        _cargoController.clear();
        _nombreApellidoController.clear();
        _fechaDiarioController.clear();
        _veredaController.clear();
        _ingenieroResidenteController.clear();
        _estacionAlmaController.clear();
        _observacionController.clear();
        _firmaController.clear();
        //
        setState(() {
          addedColaboradores.clear();
          _selectedJornada = null;
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
          title: const Text('Reporte diario del personal'),
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
                      builder: (context) => ListViewPdfDiarioPersonal(
                        userId: userId,
                        accessToken: accessToken!,
                      ),
                    ),
                  );
                } else if (value == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListViewExcelDiarioPersonal(
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
                        Text("DS-P-F-011"),
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
                        Text("21-05-2024"),
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
                          controller: _proyectoController,
                          hintText: 'Nombre del proyecto',
                          labelText: 'Proyecto',
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, escriba lo nuevamente';
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
                          controller: _cargoController,
                          hintText: 'Nombre del cargo',
                          labelText: 'Cargo',
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, escriba lo nuevamente';
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
                          controller: _nombreApellidoController,
                          hintText: 'Ej: Bryan Flores',
                          labelText: 'Nombres Y Apellidos',
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, escriba lo nuevamente';
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
                          controller: _fechaDiarioController,
                          hintText: 'Seleccione una fecha',
                          labelText: 'Fecha',
                          keyboardType: TextInputType.none,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, escriba lo nuevamente';
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
                              _fechaDiarioController.text = formattedDate;
                            }
                          },
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
                              return 'Por favor, escriba lo nuevamente';
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
                          controller: _ingenieroResidenteController,
                          hintText: 'Ej: Bryan Flores',
                          labelText: 'Ingeniero Residente',
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, escriba lo nuevamente';
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
                          controller: _estacionAlmaController,
                          hintText: 'Almacenamiento',
                          labelText: 'Estación de Almacenamiento',
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, escriba lo nuevamente';
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
                        DropdownButtonFormField<String>(
                          value: _selectedJornada,
                          decoration: InputDecoration(
                            labelText: 'Jornada',
                            hintText: 'Seleccione una jornada',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 42, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          items:
                              ['Jornada Mañana', 'Jornada Tarde'].map((opcion) {
                            return DropdownMenuItem<String>(
                              value: opcion,
                              child: Text(opcion),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedJornada = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Seleccione una opción' : null,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Divider(),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                          "Agregar colaboradores",
                          style: TextStyle(fontSize: 30),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        DropdownButtonFormField<String>(
                          menuMaxHeight: 500,
                          itemHeight: 80,
                          decoration: InputDecoration(
                            labelText: 'Colaborador',
                            hintText: 'Seleccione una opción',
                            contentPadding:
                                const EdgeInsets.fromLTRB(42, 0, 42, 50),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          value: selectedColaborador,
                          items: colaboradoresss.map((colaborador) {
                            return DropdownMenuItem<String>(
                              value: colaborador.id,
                              child: Container(
                                margin: EdgeInsets.zero,
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: Text(
                                  '${colaborador.nombre} ${colaborador.primerApellido} ${colaborador.segundoApellido}',
                                  overflow: TextOverflow.visible,
                                  maxLines: 5,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedColaborador = value;
                            });
                          },
                          // validator: (value) => value == null
                          //     ? 'Por favor seleccione una opción'
                          //     : null,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _rendimientoController,
                          hintText: 'Escribir un rendimiento',
                          labelText: 'Rendimiento',
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        ElevatedButton(
                          onPressed: agregarColaborador,
                          child: const Text('Agregar'),
                        ),
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
                                  DataColumn(label: Text('N°')),
                                  DataColumn(label: Text('Colaborador')),
                                  DataColumn(label: Text('Actividad')),
                                  DataColumn(label: Text('Rendimiento')),
                                  DataColumn(label: Text('Eliminar')),
                                ],
                                rows: addedColaboradores
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int index = entry.key;
                                  var colabo = entry.value;
                                  return DataRow(cells: [
                                    DataCell(Text((index + 1).toString())),
                                    DataCell(Text(colabo['colaborador']!)),
                                    DataCell(Text(colabo['actividad']!)),
                                    DataCell(Text(colabo['rendimiento']!)),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => eliminarReporte(index),
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
                              "Observaciones acerca del reporte diario del personal",
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
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                const Expanded(
                                  child: Text(
                                      "Firma de la persona que diligenció el documento"),
                                ),
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
                                                    const SizedBox(height: 60),
                                                    Center(
                                                      child: Column(
                                                        children: [
                                                          Signature(
                                                            controller:
                                                                _firmaController,
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
                                                    icon:
                                                        const Icon(Icons.close),
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
          ]),
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
  final void Function(String?)? onSaved;
  final void Function(String?)? onChanged;
  final TextEditingController? controller;
  final bool isImageSelected;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? validCharacter;
  final int? maxLines;

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
        // suffixIcon: Icon(Icons.image_search),
        prefixIcon: prefixIcon,
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

Future<List<Colaboradores>> axiosColaboradores() async {
  QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('Colaboradores').get();
  return snapshot.docs.map((doc) {
    return Colaboradores(
      id: doc.id,
      trabajadorId: doc['trabajadorId'],
      primerApellido: doc['primerApellido'],
      segundoApellido: doc['segundoApellido'],
      nombre: doc['nombre'],
      cargo: doc['cargo'],
    );
  }).toList();
}

class TableFillContain extends StatelessWidget {
  const TableFillContain({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(1),
        child: Center(
            child: Column(children: [
          const Text("Tabla de Colaboradores"),
          const SizedBox(
            height: 10,
          ),
          Table(
            border: TableBorder.all(),
            columnWidths: const {
              0: FixedColumnWidth(100), // Ancho fijo para la primera columna
              1: FixedColumnWidth(100),
              2: FixedColumnWidth(100),
              3: FixedColumnWidth(100),
            },
            children: const [
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Categoría',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Columna 1',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Columna 2',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Columna 3',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              // Fila 1
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Fila 1'), // Primera columna independiente
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 1.1'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 1.2'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 1.2'),
                  ),
                ],
              ),
              // Fila 2
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Fila 2'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 2.1'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 2.2'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 2.2'),
                  ),
                ],
              ),
              // Fila 3
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Fila 3'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 3.1'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 3.2'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 3.2'),
                  ),
                ],
              ),
              // Fila 4
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Fila 4'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 4.1'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 4.2'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Dato 4.2'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          const TextInputForm(
            hintText: 'Observaciones',
            labelText: 'Observaciones',
          ),
        ])));
  }
}
