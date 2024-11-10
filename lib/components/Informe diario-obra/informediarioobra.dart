import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'list_view_excel_diario.dart';
import 'list_view_pdf_diario_obra.dart';

class InformeDiarioObra extends StatefulWidget {
  const InformeDiarioObra({super.key});

  @override
  State<InformeDiarioObra> createState() => _InformeDiarioObraState();
}

class _InformeDiarioObraState extends State<InformeDiarioObra>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _formKeyTendido = GlobalKey<FormState>();
  final _formKeyExcavacion = GlobalKey<FormState>();
  final _formKeyMecanica = GlobalKey<FormState>();
  final _formKeyMaquinaria = GlobalKey<FormState>();
  final _formKeyHerramienta = GlobalKey<FormState>();
  late AnimationController _animationController;
  User? user;
  String userId = '';
  String? accessToken;
  int _contadorHoja = 0;

  final TextEditingController _proyectoController = TextEditingController();
  final TextEditingController _cargoController = TextEditingController();
  final TextEditingController _nombreApellidoController =
      TextEditingController();
  final TextEditingController _fechadiarioController = TextEditingController();
  final TextEditingController _veredaController = TextEditingController();
  final TextEditingController _ingenieroResidenteController =
      TextEditingController();
  final TextEditingController _estacionAlmaController = TextEditingController();
  final TextEditingController _tramoTendidoController = TextEditingController();
  final TextEditingController _acometidaTendidoController =
      TextEditingController();
  final TextEditingController _cantidadTendidoController =
      TextEditingController();
  final TextEditingController _cintaController = TextEditingController();
  final TextEditingController _tramoExcavacionController =
      TextEditingController();
  final TextEditingController _cantidadExcavacionController =
      TextEditingController();
  final TextEditingController _equipoMecanicaController =
      TextEditingController();
  final TextEditingController _tramoMecanicaController =
      TextEditingController();
  final TextEditingController _cantidadMecanicaController =
      TextEditingController();
  final TextEditingController _propietarioController = TextEditingController();
  final TextEditingController _tramoMaquinariaController =
      TextEditingController();
  final TextEditingController _cantidadMaquinariaController =
      TextEditingController();
  final TextEditingController _rocaController = TextEditingController();
  final TextEditingController _observacionMaquinariaController =
      TextEditingController();
  final TextEditingController _equipoHerramientaController =
      TextEditingController();
  final TextEditingController _tiempoUsoController = TextEditingController();
  final TextEditingController _combustibleController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _cambioAceiteController = TextEditingController();
  final TextEditingController _observacionHerramientaController =
      TextEditingController();
  final TextEditingController _observacionController = TextEditingController();

  String? selectedMedida;
  String? selectedMedidaTwo;
  String? selectedMedidaThree;
  String? selectedMedidaFour;
  String? selectedMedidaOption;
  String? selectedMedidaOptionTwo;
  String? selectedMedidaOptionThree;
  String? cantidadMedida;
  String? cantidadMedidaExca;
  String? cantidadMedidaMeca;
  String? cantidadMedidaMaqui;
  String? _selectedJornada;

  Uint8List? signature;

  List<String> medidaPulgada = [
    '1/2"',
    '3/4"',
    '1"',
    '2"',
  ];

  List<String> medidaextraPulgada = [
    '1/2"',
    '3/4"',
    '1"',
  ];

  List<String> mediaPulgada = [
    'A',
    'RD',
  ];

  List<String> extrasPulgada = [
    'RD',
  ];

  List<Map<String, String>> addedTendido = [];
  List<Map<String, String>> addedExcavacionManual = [];
  List<Map<String, String>> addedMecanica = [];
  List<Map<String, String>> addedMaquinaria = [];
  List<Map<String, String>> addedHerramienta = [];

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

    _cargarContadorHoja();
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

  Future<void> _cargarContadorHoja() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _contadorHoja = prefs.getInt('contador_hoja') ?? 0;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firmaController.dispose();

    _proyectoController.dispose();
    _cargoController.dispose();
    _nombreApellidoController.dispose();
    _fechadiarioController.dispose();
    _veredaController.dispose();
    _ingenieroResidenteController.dispose();
    _estacionAlmaController.dispose();
    _tramoTendidoController.dispose();
    _acometidaTendidoController.dispose();
    _cantidadTendidoController.dispose();
    _cintaController.dispose();
    _tramoExcavacionController.dispose();
    _cantidadExcavacionController.dispose();
    _equipoMecanicaController.dispose();
    _tramoMecanicaController.dispose();
    _cantidadMecanicaController.dispose();
    _propietarioController.dispose();
    _tramoMaquinariaController.dispose();
    _cantidadMaquinariaController.dispose();
    _rocaController.dispose();
    _observacionMaquinariaController.dispose();
    _equipoHerramientaController.dispose();
    _tiempoUsoController.dispose();
    _combustibleController.dispose();
    _estadoController.dispose();
    _cambioAceiteController.dispose();
    _observacionHerramientaController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  void agregarDatos() {
    if (_formKeyTendido.currentState?.validate() ?? false) {
      if (selectedMedida != null &&
          selectedMedidaOption != null &&
          cantidadMedida != null) {
        setState(() {
          addedTendido.add({
            'tramo': _tramoTendidoController.text,
            'acometidas': _acometidaTendidoController.text,
            'medida': selectedMedida!,
            'tipo': selectedMedidaOption!,
            'cantidad_tendido': cantidadMedida!,
            'cinta': _cintaController.text,
          });
          _tramoTendidoController.clear();
          _acometidaTendidoController.clear();
          _cantidadTendidoController.clear();
          _cintaController.clear();
          setState(() {
            selectedMedida = null;
            selectedMedidaOption = null;
            cantidadMedida = null;
          });
        });
      }
    }
  }

  void eliminarTendido(int index) {
    setState(() {
      addedTendido.removeAt(index);
    });
  }

  void agregarDatos1() {
    if (_formKeyExcavacion.currentState?.validate() ?? false) {
      if (selectedMedidaTwo != null &&
          selectedMedidaOptionTwo != null &&
          cantidadMedidaExca != null) {
        setState(() {
          addedExcavacionManual.add({
            'tramo': _tramoExcavacionController.text,
            'medida': selectedMedidaTwo!,
            'tipo': selectedMedidaOptionTwo!,
            'cantidad_excavacion': cantidadMedidaExca!,
          });
          _tramoExcavacionController.clear();
          _cantidadExcavacionController.clear();
          setState(() {
            selectedMedidaTwo = null;
            selectedMedidaOptionTwo = null;
            cantidadMedidaExca = null;
          });
        });
      }
    }
  }

  void eliminarExcavacionManual(int index) {
    setState(() {
      addedExcavacionManual.removeAt(index);
    });
  }

  void agregarDatos2() {
    if (_formKeyMecanica.currentState?.validate() ?? false) {
      if (selectedMedidaThree != null &&
          selectedMedidaOptionThree != null &&
          cantidadMedidaMeca != null) {
        setState(() {
          addedMecanica.add({
            'equipo': _equipoMecanicaController.text,
            'tramo': _tramoMecanicaController.text,
            'medida': selectedMedidaThree!,
            'tipo': selectedMedidaOptionThree!,
            'cantidad_mecanica': cantidadMedidaMeca!,
          });
          _equipoMecanicaController.clear();
          _tramoMecanicaController.clear();
          _cantidadMecanicaController.clear();
          setState(() {
            selectedMedidaThree = null;
            selectedMedidaOptionThree = null;
            cantidadMedidaMeca = null;
          });
        });
      }
    }
  }

  void eliminarMecanica(int index) {
    setState(() {
      addedMecanica.removeAt(index);
    });
  }

  void agregarDatos3() {
    if (_formKeyMaquinaria.currentState?.validate() ?? false) {
      if (selectedMedidaFour != null && cantidadMedidaMaqui != null) {
        setState(() {
          addedMaquinaria.add({
            'propietario': _propietarioController.text,
            'tramo': _tramoMaquinariaController.text,
            'medida': selectedMedidaFour!,
            'cantidad_maquinaria': cantidadMedidaMaqui!,
            'roca': _rocaController.text,
            'observacion_maquinaria': _observacionMaquinariaController.text,
          });
          _propietarioController.clear();
          _tramoMaquinariaController.clear();
          _cantidadMaquinariaController.clear();
          _rocaController.clear();
          _observacionMaquinariaController.clear();
          setState(() {
            selectedMedidaFour = null;
            cantidadMedidaMaqui = null;
          });
        });
      }
    }
  }

  void eliminarMaquinaria(int index) {
    setState(() {
      addedMaquinaria.removeAt(index);
    });
  }

  void agregarDatos4() {
    if (_formKeyHerramienta.currentState?.validate() ?? false) {
      setState(() {
        addedHerramienta.add({
          'equipo': _equipoHerramientaController.text,
          'tiempo_uso': _tiempoUsoController.text,
          'combustible': _combustibleController.text,
          'estado': _estadoController.text,
          'cambio_aceite': _cambioAceiteController.text,
          'observacion_herramienta': _observacionHerramientaController.text,
        });
        _equipoHerramientaController.clear();
        _tiempoUsoController.clear();
        _combustibleController.clear();
        _estadoController.clear();
        _cambioAceiteController.clear();
        _observacionHerramientaController.clear();
      });
    }
  }

  void eliminarHerramienta(int index) {
    setState(() {
      addedHerramienta.removeAt(index);
    });
  }

  void guardarInformacion() async {
    if (signature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltan campos y/o firma por rellenar!')),
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
        String fecha = _fechadiarioController.text;
        String vereda = _veredaController.text;
        String ingenierioResidente = _ingenieroResidenteController.text;
        String estacionAlma = _estacionAlmaController.text;
        String observacion = _observacionController.text;
        String? jornada = _selectedJornada ?? 'No seleccionada';

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
              pw.Text('Imgeniero Residente: $ingenierioResidente'),
              pw.SizedBox(height: 20),
              pw.Text('Estacion de almacenamiento: $estacionAlma'),
              pw.SizedBox(height: 20),
              pw.Text('Jornada: $jornada'),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de Tendido
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tramo',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Acometidas',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Medida',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tipo',
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
                        child: pw.Text('Cinta',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...addedTendido.map((tendido) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(tendido['tramo'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(tendido['acometidas'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(tendido['medida'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(tendido['tipo'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child:
                              pw.Text(tendido['cantidad_tendido'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(tendido['cinta'].toString()),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de ExcavacionManual
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tramo',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Medida',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tipo',
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
                  ...addedExcavacionManual.map((manual) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(manual['tramo'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(manual['medida'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(manual['tipo'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child:
                              pw.Text(manual['cantidad_excavacion'].toString()),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de Mecanica
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Equipo',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tramo',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Medida',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tipo',
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
                  ...addedMecanica.map((mecanica) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(mecanica['equipo'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(mecanica['tramo'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(mecanica['medida'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(mecanica['tipo'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child:
                              pw.Text(mecanica['cantidad_mecanica'].toString()),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de Maquinaria
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Propietario/Maquinaria',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tramo',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Medida',
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
                        child: pw.Text('Roca',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Observación',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...addedMaquinaria.map((maquina) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(maquina['propietario'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(maquina['tramo'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(maquina['medida'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              maquina['cantidad_maquinaria'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(maquina['roca'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              maquina['observacion_maquinaria'].toString()),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de Herramienta
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Equipo',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tiempo de uso',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Combustible',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Estado',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Cambio de aceite',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Observaciones',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...addedHerramienta.map((herramienta) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(herramienta['equipo'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(herramienta['tiempo_uso'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(herramienta['combustible'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(herramienta['estado'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child:
                              pw.Text(herramienta['cambio_aceite'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(herramienta['observacion_herramienta']
                              .toString()),
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
              pw.Text("FIRMA"),
              pw.SizedBox(height: 10),
            ],
          ),
        );

        // Generar el nombre del archivo PDF
        String fechaActual =
            DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        String nombreArchivo = 'Informe_Diario_Obra_$fechaActual.pdf';

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
            'categoria': 'Informe_Diario_Obra',
            'userId': userId,
          });
        });
        _proyectoController.clear();
        _cargoController.clear();
        _nombreApellidoController.clear();
        _fechadiarioController.clear();
        _veredaController.clear();
        _ingenieroResidenteController.clear();
        _estacionAlmaController.clear();
        _observacionController.clear();
        setState(() {
          addedTendido.clear();
          addedExcavacionManual.clear();
          addedMecanica.clear();
          addedMaquinaria.clear();
          addedHerramienta.clear();
          _selectedJornada = null;

          _contadorHoja++;
        });

        // Guardar el contador en la libreria de SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('contador_hoja', _contadorHoja);
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
        Sheet sheet = excel['Hoja_Informe_Diario_Obra'];
        int row = 3;
        // Organizar
        sheet.merge(
            CellIndex.indexByString("A2"), CellIndex.indexByString("F3"));
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
            CellIndex.indexByString("G2"), CellIndex.indexByString("H3"));
        sheet.cell(CellIndex.indexByString("G2")).value =
            "INFORME DIARIO\n OBRA";
        sheet
            .cell(CellIndex.indexByString("G2"))
            .cellStyle
            ?.horizontalAlignment = HorizontalAlign.Center;
        sheet.cell(CellIndex.indexByString("G2")).cellStyle?.verticalAlignment =
            VerticalAlign.Center;
        sheet.cell(CellIndex.indexByString("G2")).cellStyle?.wrap =
            TextWrapping.WrapText;

        // Agrega encabezados I
        sheet.cell(CellIndex.indexByString("I5")).value = "Proyecto";
        sheet.cell(CellIndex.indexByString("I6")).value = "Cargo";
        sheet.cell(CellIndex.indexByString("I7")).value = "Nombres y Apellidos";
        sheet.cell(CellIndex.indexByString("I8")).value = "Fecha";
        sheet.cell(CellIndex.indexByString("I9")).value = "Vereda";
        sheet.cell(CellIndex.indexByString("I10")).value =
            "Ingenierio Residente";
        sheet.cell(CellIndex.indexByString("I11")).value = "Jornada";
        sheet.cell(CellIndex.indexByString("I12")).value = "Observación";

        // Agregar datos del formulario I
        sheet.cell(CellIndex.indexByString("J5")).value =
            _proyectoController.text;
        sheet.cell(CellIndex.indexByString("J6")).value = _cargoController.text;
        sheet.cell(CellIndex.indexByString("J7")).value =
            _nombreApellidoController.text;
        sheet.cell(CellIndex.indexByString("J8")).value =
            _fechadiarioController.text;
        sheet.cell(CellIndex.indexByString("J9")).value =
            _veredaController.text;
        sheet.cell(CellIndex.indexByString("J10")).value =
            _ingenieroResidenteController.text;
        sheet.cell(CellIndex.indexByString("J11")).value = _selectedJornada;
        sheet.cell(CellIndex.indexByString("J12")).value =
            _observacionController.text;

        // Obtener ruta para guardar las firmas
        final directory = await getApplicationDocumentsDirectory();

        // Agregar encabezados para "Tendido"
        sheet.cell(CellIndex.indexByString("A$row")).value = "Tramo - Tuberia";
        sheet.cell(CellIndex.indexByString("B$row")).value =
            "Acometida - Tuberia";
        sheet.cell(CellIndex.indexByString("C$row")).value = "Medida - Tuberia";
        sheet.cell(CellIndex.indexByString("D$row")).value = "Tipo - Tuberia";
        sheet.cell(CellIndex.indexByString("E$row")).value =
            "Cantidad - Tuberia";
        sheet.cell(CellIndex.indexByString("F$row")).value = "Cinta - Tuberia";

        row++;

        // Agregar los datos de "Tendido"
        for (var tendido in addedTendido) {
          sheet.cell(CellIndex.indexByString("A$row")).value = tendido['tramo'];
          sheet.cell(CellIndex.indexByString("B$row")).value =
              tendido['acometidas'];
          sheet.cell(CellIndex.indexByString("C$row")).value =
              tendido['medida'];
          sheet.cell(CellIndex.indexByString("D$row")).value = tendido['tipo'];
          sheet.cell(CellIndex.indexByString("E$row")).value =
              tendido['cantidad_tendido'];
          sheet.cell(CellIndex.indexByString("F$row")).value = tendido['cinta'];
          row++;
        }

        row++;

        // Agregar encabezados para "ExcavacionManual"
        sheet.cell(CellIndex.indexByString("A$row")).value =
            "Tramo - ExcavacionManual";
        sheet.cell(CellIndex.indexByString("B$row")).value =
            "Medida - ExcavacionManual";
        sheet.cell(CellIndex.indexByString("C$row")).value =
            "Tipo - ExcavacionManual";
        sheet.cell(CellIndex.indexByString("D$row")).value =
            "Cantidad - ExcavacionManual";
        row++;

        // Agregar los datos de "ExcavacionManual"
        for (var excavacionManual in addedExcavacionManual) {
          sheet.cell(CellIndex.indexByString("A$row")).value =
              excavacionManual['tramo'];
          sheet.cell(CellIndex.indexByString("B$row")).value =
              excavacionManual['medida'];
          sheet.cell(CellIndex.indexByString("C$row")).value =
              excavacionManual['tipo'];
          sheet.cell(CellIndex.indexByString("D$row")).value =
              excavacionManual['cantidad_excavacion'];
          row++;
        }

        row++;

        // Agregar encabezados para "Mecanica"
        sheet.cell(CellIndex.indexByString("A$row")).value =
            "Equipo - Mecanica";
        sheet.cell(CellIndex.indexByString("B$row")).value = "Tramo - Mecanica";
        sheet.cell(CellIndex.indexByString("C$row")).value =
            "Medida - Mecanica";
        sheet.cell(CellIndex.indexByString("D$row")).value = "Tipo - Mecanica";
        sheet.cell(CellIndex.indexByString("E$row")).value =
            "Cantidad - Mecanica";
        row++;

        // Agregar los datos de "Mecanica"
        for (var mecanica in addedMecanica) {
          sheet.cell(CellIndex.indexByString("A$row")).value =
              mecanica['equipo'];
          sheet.cell(CellIndex.indexByString("B$row")).value =
              mecanica['tramo'];
          sheet.cell(CellIndex.indexByString("C$row")).value =
              mecanica['medida'];
          sheet.cell(CellIndex.indexByString("D$row")).value = mecanica['tipo'];
          sheet.cell(CellIndex.indexByString("E$row")).value =
              mecanica['cantidad_mecanica'];
          row++;
        }
        row++;

// Agregar encabezados para "Maquinaria"
        sheet.cell(CellIndex.indexByString("A$row")).value =
            "Propietario/Maquinaria - Maquinaria";
        sheet.cell(CellIndex.indexByString("B$row")).value =
            "Tramo - Maquinaria";
        sheet.cell(CellIndex.indexByString("C$row")).value =
            "Medida - Maquinaria";
        sheet.cell(CellIndex.indexByString("D$row")).value =
            "Cantidad - Maquinaria";
        sheet.cell(CellIndex.indexByString("E$row")).value =
            "Roca - Maquinaria";
        sheet.cell(CellIndex.indexByString("F$row")).value =
            "Observación - Maquinaria";
        row++;

        // Agregar los datos de "Maquinaria"
        for (var maquina in addedMaquinaria) {
          sheet.cell(CellIndex.indexByString("A$row")).value =
              maquina['propietario'];
          sheet.cell(CellIndex.indexByString("B$row")).value = maquina['tramo'];
          sheet.cell(CellIndex.indexByString("C$row")).value =
              maquina['medida'];
          sheet.cell(CellIndex.indexByString("D$row")).value =
              maquina['cantidad_maquinaria'];
          sheet.cell(CellIndex.indexByString("E$row")).value = maquina['roca'];
          sheet.cell(CellIndex.indexByString("F$row")).value =
              maquina['observacion_maquinaria'];
          row++;
        }
        row++;

        // Agregar encabezados para "Herramienta"
        sheet.cell(CellIndex.indexByString("A$row")).value =
            "Equipo - Herramienta";
        sheet.cell(CellIndex.indexByString("B$row")).value =
            "Tiempo de uso - Herramienta";
        sheet.cell(CellIndex.indexByString("C$row")).value =
            "Combustible - Herramienta";
        sheet.cell(CellIndex.indexByString("D$row")).value =
            "Estado - Herramienta";
        sheet.cell(CellIndex.indexByString("E$row")).value =
            "Cambio de aceite - Herramienta";
        sheet.cell(CellIndex.indexByString("F$row")).value =
            "Observaciones - Herramienta";
        row++;

        // Agregar los datos de "Herramienta"
        for (var herramienta in addedHerramienta) {
          sheet.cell(CellIndex.indexByString("A$row")).value =
              herramienta['equipo'];
          sheet.cell(CellIndex.indexByString("B$row")).value =
              herramienta['tiempo_uso'];
          sheet.cell(CellIndex.indexByString("C$row")).value =
              herramienta['combustible'];
          sheet.cell(CellIndex.indexByString("D$row")).value =
              herramienta['estado'];
          sheet.cell(CellIndex.indexByString("E$row")).value =
              herramienta['cambio_aceite'];
          sheet.cell(CellIndex.indexByString("F$row")).value =
              herramienta['observacion_herramienta'];
          row++;
        }

        // Obtener ruta para guardar el archivo
        // final directory = await getApplicationDocumentsDirectory();
        String fechaActual =
            DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        String nombreArchivo = 'Informe_Diario_Obra_$fechaActual.xlsx';
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
            'categoria': 'Informe_Diario_Obra',
            'userId': userId,
          });
        });

        _proyectoController.clear();
        _cargoController.clear();
        _nombreApellidoController.clear();
        _fechadiarioController.clear();
        _veredaController.clear();
        _ingenieroResidenteController.clear();
        _estacionAlmaController.clear();
        _observacionController.clear();
        setState(() {
          addedTendido.clear();
          addedExcavacionManual.clear();
          addedMecanica.clear();
          addedMaquinaria.clear();
          addedHerramienta.clear();
          _selectedJornada = null;

          _contadorHoja++;
        });

        // Guardar el contador en la libreria de SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('contador_hoja', _contadorHoja);
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
            'Informe Diario de Obra',
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
                      builder: (context) => ListViewPdfDiarioObra(
                        userId: userId,
                        accessToken: accessToken!,
                      ),
                    ),
                  );
                } else if (value == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListViewExcelDiario(
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
          SizedBox(
            width: 500,
            height: 150,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text("Codigo:"),
                      Text("DS-P-F-010"),
                    ],
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        "Fecha:",
                        textAlign: TextAlign.left,
                      ),
                      Text("21/05/2024", textAlign: TextAlign.right),
                    ],
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text("Version"),
                      Text("001"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Text("Hoja No:"),
                      Text("$_contadorHoja"),
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
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _proyectoController,
                          hintText: 'Escriba el nombre del proyecto',
                          labelText: 'Proyecto',
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
                          controller: _cargoController,
                          hintText: 'Escriba el cargo',
                          labelText: 'Cargo',
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
                          controller: _nombreApellidoController,
                          hintText: 'Escriba nombre y apellido',
                          labelText: 'Nombres y Apellidos',
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
                          controller: _fechadiarioController,
                          hintText: 'Selecciona una fecha',
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
                              _fechadiarioController.text = formattedDate;
                            }
                          },
                        ),
                        const SizedBox(
                          height: 40,
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
                          height: 40,
                        ),
                        TextInputForm(
                          controller: _ingenieroResidenteController,
                          hintText: 'Escriba el ingenierio residente',
                          labelText: 'Ingenierio',
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
                          controller: _estacionAlmaController,
                          hintText: 'Escriba la estacion',
                          labelText: 'Estacion Almacenamiento',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '¡¡¡Este campo es obligatorio!!!';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.text,
                          validCharacter: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]')),
                          ],
                        ),
                        const SizedBox(
                          height: 40,
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
                        const Text('Tendido Tuberia De Polietileno (ml)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 26)),
                        const SizedBox(
                          height: 20,
                        ),
                        Form(
                            key: _formKeyTendido,
                            child: Column(
                              children: [
                                TextInputForm(
                                  controller: _tramoTendidoController,
                                  hintText: 'Escriba el tramo',
                                  labelText: 'Tramo',
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
                                TextInputForm(
                                  controller: _acometidaTendidoController,
                                  hintText: 'Escriba la acometidas',
                                  labelText: 'Acometidas',
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
                                Column(
                                  children: [
                                    const Text(
                                      "Selección de medidas",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    DropdownButtonFormField<String>(
                                      value: selectedMedida,
                                      decoration: InputDecoration(
                                        labelText: 'Medida',
                                        hintText: 'Seleccione una medida',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 42, vertical: 20),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                      ),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedMedida = newValue;
                                          if (newValue != '1/2"') {
                                            selectedMedidaOption = null;
                                          }
                                        });
                                      },
                                      items: medidaPulgada
                                          .map<DropdownMenuItem<String>>(
                                              (String medida) {
                                        return DropdownMenuItem<String>(
                                          value: medida,
                                          child: Text(medida),
                                        );
                                      }).toList(),
                                      validator: (value) => value == null
                                          ? 'Seleccione una opción'
                                          : null,
                                    ),
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    if (selectedMedida == '1/2"')
                                      DropdownButtonFormField<String>(
                                        value: selectedMedidaOption,
                                        decoration: InputDecoration(
                                          labelText: 'Medida',
                                          hintText: 'Seleccione una medida',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 42, vertical: 20),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                          ),
                                        ),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedMedidaOption = newValue;
                                          });
                                        },
                                        items: mediaPulgada
                                            .map<DropdownMenuItem<String>>(
                                                (String option) {
                                          return DropdownMenuItem<String>(
                                            value: option,
                                            child: Text(option),
                                          );
                                        }).toList(),
                                        validator: (value) => value == null
                                            ? 'Seleccione una opción'
                                            : null,
                                      ),
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    if (selectedMedida != '1/2"')
                                      DropdownButtonFormField<String>(
                                        value: selectedMedidaOption,
                                        decoration: InputDecoration(
                                          labelText: 'Medida',
                                          hintText: 'Seleccione una medida',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 42, vertical: 20),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                          ),
                                        ),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedMedidaOption = newValue;
                                          });
                                        },
                                        items: extrasPulgada
                                            .map<DropdownMenuItem<String>>(
                                                (String option) {
                                          return DropdownMenuItem<String>(
                                            value: option,
                                            child: Text(option),
                                          );
                                        }).toList(),
                                        validator: (value) => value == null
                                            ? 'Seleccione una opción'
                                            : null,
                                      ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    if (selectedMedida != null &&
                                        selectedMedidaOption != null)
                                      TextInputForm(
                                        controller: _cantidadTendidoController,
                                        hintText: 'Escriba la cantidad',
                                        labelText: 'Cantidad',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '¡¡¡Este campo es obligatorio!!!';
                                          }
                                          return null;
                                        },
                                        keyboardType: TextInputType.number,
                                        validCharacter: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        onChanged: (value) {
                                          cantidadMedida = value;
                                        },
                                      ),
                                    const SizedBox(height: 20),
                                    TextInputForm(
                                      controller: _cintaController,
                                      hintText: 'Escriba la cinta',
                                      labelText: 'Cinta',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '¡¡¡Este campo es obligatorio!!!';
                                        }
                                        return null;
                                      },
                                    ),
                                    ElevatedButton(
                                      onPressed: agregarDatos,
                                      child: const Text("Agregar"),
                                    ),
                                    const SizedBox(height: 20),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        border: TableBorder.all(),
                                        columns: const [
                                          DataColumn(label: Text('Tramo')),
                                          DataColumn(label: Text('Acometidas')),
                                          DataColumn(label: Text('Medida')),
                                          DataColumn(label: Text('Tipo')),
                                          DataColumn(label: Text('Cantidad')),
                                          DataColumn(label: Text('Cinta')),
                                          DataColumn(label: Text('Eliminar')),
                                        ],
                                        rows: addedTendido.map((data) {
                                          int index =
                                              addedTendido.indexOf(data);
                                          return DataRow(cells: [
                                            DataCell(Text(data['tramo']!)),
                                            DataCell(Text(data['acometidas']!)),
                                            DataCell(Text(data['medida']!)),
                                            DataCell(Text(data['tipo']!)),
                                            DataCell(Text(
                                                data['cantidad_tendido']!)),
                                            DataCell(Text(data['cinta']!)),
                                            DataCell(
                                              SizedBox(
                                                width: 50,
                                                child: IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () =>
                                                      eliminarTendido(index),
                                                ),
                                              ),
                                            ),
                                          ]);
                                        }).toList(),
                                      ),
                                    ),
                                  ],
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
                        const Text('Excavacion (ml)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 26)),
                        const SizedBox(
                          height: 20,
                        ),
                        Form(
                            key: _formKeyExcavacion,
                            child: Column(
                              children: [
                                TextInputForm(
                                  controller: _tramoExcavacionController,
                                  hintText: 'Escriba el tramo',
                                  labelText: 'Tramo',
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
                                Column(
                                  children: [
                                    const Text(
                                      "Selección de medidas",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Medida',
                                        hintText: 'Seleccione una medida',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 42, vertical: 20),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                      ),
                                      value: selectedMedidaTwo,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedMedidaTwo = newValue;
                                          if (newValue != '1/2"') {
                                            selectedMedidaOptionTwo = null;
                                          }
                                        });
                                      },
                                      items: medidaPulgada
                                          .map<DropdownMenuItem<String>>(
                                              (String medida) {
                                        return DropdownMenuItem<String>(
                                          value: medida,
                                          child: Text(medida),
                                        );
                                      }).toList(),
                                      validator: (value) => value == null
                                          ? 'Seleccione una opción'
                                          : null,
                                    ),
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    if (selectedMedidaTwo == '1/2"')
                                      DropdownButtonFormField<String>(
                                        value: selectedMedidaOptionTwo,
                                        decoration: InputDecoration(
                                          labelText: 'Medida',
                                          hintText: 'Seleccione una medida',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 42, vertical: 20),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                          ),
                                        ),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedMedidaOptionTwo = newValue;
                                          });
                                        },
                                        items: mediaPulgada
                                            .map<DropdownMenuItem<String>>(
                                                (String option) {
                                          return DropdownMenuItem<String>(
                                            value: option,
                                            child: Text(option),
                                          );
                                        }).toList(),
                                        validator: (value) => value == null
                                            ? 'Seleccione una opción'
                                            : null,
                                      ),
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    if (selectedMedidaTwo != '1/2"')
                                      DropdownButtonFormField<String>(
                                        value: selectedMedidaOptionTwo,
                                        decoration: InputDecoration(
                                          labelText: 'Medida',
                                          hintText: 'Seleccione una medida',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 42, vertical: 20),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                          ),
                                        ),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedMedidaOptionTwo = newValue;
                                          });
                                        },
                                        items: extrasPulgada
                                            .map<DropdownMenuItem<String>>(
                                                (String option) {
                                          return DropdownMenuItem<String>(
                                            value: option,
                                            child: Text(option),
                                          );
                                        }).toList(),
                                        validator: (value) => value == null
                                            ? 'Seleccione una opción'
                                            : null,
                                      ),
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    if (selectedMedidaTwo != null &&
                                        selectedMedidaOptionTwo != null)
                                      TextInputForm(
                                        controller:
                                            _cantidadExcavacionController,
                                        hintText: 'Escriba la cantidad',
                                        labelText: 'Cantidad',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '¡¡¡Este campo es obligatorio!!!';
                                          }
                                          return null;
                                        },
                                        keyboardType: TextInputType.number,
                                        validCharacter: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        onChanged: (value) {
                                          cantidadMedidaExca = value;
                                        },
                                      ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: agregarDatos1,
                                      child: const Text("Agregar"),
                                    ),
                                    const SizedBox(height: 20),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        border: TableBorder.all(),
                                        columns: const [
                                          DataColumn(label: Text('Tramo')),
                                          DataColumn(label: Text('Medida')),
                                          DataColumn(label: Text('Tipo')),
                                          DataColumn(label: Text('Cantidad')),
                                          DataColumn(label: Text('Eliminar')),
                                        ],
                                        rows: addedExcavacionManual.map((data) {
                                          int index = addedExcavacionManual
                                              .indexOf(data);
                                          return DataRow(cells: [
                                            DataCell(Text(data['tramo']!)),
                                            DataCell(Text(data['medida']!)),
                                            DataCell(Text(data['tipo']!)),
                                            DataCell(Text(
                                                data['cantidad_excavacion']!)),
                                            DataCell(
                                              SizedBox(
                                                width: 50,
                                                child: IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () =>
                                                      eliminarExcavacionManual(
                                                          index),
                                                ),
                                              ),
                                            ),
                                          ]);
                                        }).toList(),
                                      ),
                                    ),
                                  ],
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
                        const Text('Mecanica Taladros (ml)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 26)),
                        const SizedBox(
                          height: 20,
                        ),
                        Form(
                          key: _formKeyMecanica,
                          child: Column(
                            children: [
                              TextInputForm(
                                controller: _equipoMecanicaController,
                                hintText: 'Escriba el equipo',
                                labelText: 'Equipo',
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
                              TextInputForm(
                                controller: _tramoMecanicaController,
                                hintText: 'Escriba el tramo',
                                labelText: 'Tramo',
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
                              Column(
                                children: [
                                  const Text(
                                    "Selección de medidas",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  DropdownButtonFormField<String>(
                                    value: selectedMedidaThree,
                                    decoration: InputDecoration(
                                      labelText: 'Medida',
                                      hintText: 'Seleccione una medida',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 42, vertical: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedMedidaThree = newValue;
                                        if (newValue != '1/2"') {
                                          selectedMedidaOptionThree = null;
                                        }
                                      });
                                    },
                                    items: medidaextraPulgada
                                        .map<DropdownMenuItem<String>>(
                                            (String medida) {
                                      return DropdownMenuItem<String>(
                                        value: medida,
                                        child: Text(medida),
                                      );
                                    }).toList(),
                                    validator: (value) => value == null
                                        ? 'Seleccione una opción'
                                        : null,
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  if (selectedMedidaThree == '1/2"')
                                    DropdownButtonFormField<String>(
                                      value: selectedMedidaOptionThree,
                                      decoration: InputDecoration(
                                        labelText: 'Medida',
                                        hintText: 'Seleccione una medida',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 42, vertical: 20),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                      ),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedMedidaOptionThree = newValue;
                                        });
                                      },
                                      items: mediaPulgada
                                          .map<DropdownMenuItem<String>>(
                                              (String option) {
                                        return DropdownMenuItem<String>(
                                          value: option,
                                          child: Text(option),
                                        );
                                      }).toList(),
                                      validator: (value) => value == null
                                          ? 'Seleccione una opción'
                                          : null,
                                    ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  if (selectedMedidaThree != '1/2"')
                                    DropdownButtonFormField<String>(
                                      value: selectedMedidaOptionThree,
                                      decoration: InputDecoration(
                                        labelText: 'Medida',
                                        hintText: 'Seleccione una medida',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 42, vertical: 20),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                      ),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedMedidaOptionThree = newValue;
                                        });
                                      },
                                      items: extrasPulgada
                                          .map<DropdownMenuItem<String>>(
                                              (String option) {
                                        return DropdownMenuItem<String>(
                                          value: option,
                                          child: Text(option),
                                        );
                                      }).toList(),
                                      validator: (value) => value == null
                                          ? 'Seleccione una opción'
                                          : null,
                                    ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  if (selectedMedidaThree != null &&
                                      selectedMedidaOptionThree != null)
                                    TextInputForm(
                                      controller: _cantidadMecanicaController,
                                      hintText: 'Escriba la cantidad',
                                      labelText: 'Cantidad',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '¡¡¡Este campo es obligatorio!!!';
                                        }
                                        return null;
                                      },
                                      keyboardType: TextInputType.number,
                                      validCharacter: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        cantidadMedidaMeca = value;
                                      },
                                    ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: agregarDatos2,
                                    child: const Text("Agregar"),
                                  ),
                                  const SizedBox(height: 20),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      border: TableBorder.all(),
                                      columns: const [
                                        DataColumn(label: Text('Equipo')),
                                        DataColumn(label: Text('Tramo')),
                                        DataColumn(label: Text('Medida')),
                                        DataColumn(label: Text('Tipo')),
                                        DataColumn(label: Text('Cantidad')),
                                        DataColumn(label: Text('Eliminar')),
                                      ],
                                      rows: addedMecanica.map((data) {
                                        int index = addedMecanica.indexOf(data);
                                        return DataRow(cells: [
                                          DataCell(Text(data['equipo']!)),
                                          DataCell(Text(data['tramo']!)),
                                          DataCell(Text(data['medida']!)),
                                          DataCell(Text(data['tipo']!)),
                                          DataCell(
                                              Text(data['cantidad_mecanica']!)),
                                          DataCell(
                                            SizedBox(
                                              width: 50,
                                              child: IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed: () =>
                                                    eliminarMecanica(index),
                                              ),
                                            ),
                                          ),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Divider(),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text('Excavacion con Maquinaria (ml)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 26)),
                        const SizedBox(
                          height: 20,
                        ),
                        Form(
                            key: _formKeyMaquinaria,
                            child: Column(
                              children: [
                                TextInputForm(
                                  controller: _propietarioController,
                                  hintText: 'Escriba el propietario',
                                  labelText: 'Propietario/Maquinaria',
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
                                TextInputForm(
                                  controller: _tramoMaquinariaController,
                                  hintText: 'Escriba el tramo',
                                  labelText: 'Tramo',
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
                                Column(
                                  children: [
                                    const Text(
                                      "Selección de medidas",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    DropdownButtonFormField<String>(
                                      value: selectedMedidaFour,
                                      decoration: InputDecoration(
                                        labelText: 'Medida',
                                        hintText: 'Seleccione una medida',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 42, vertical: 20),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                      ),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedMedidaFour = newValue;
                                        });
                                      },
                                      items: mediaPulgada
                                          .map<DropdownMenuItem<String>>(
                                              (String medida) {
                                        return DropdownMenuItem<String>(
                                          value: medida,
                                          child: Text(medida),
                                        );
                                      }).toList(),
                                      validator: (value) => value == null
                                          ? 'Seleccione una opción'
                                          : null,
                                    ),
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    if (selectedMedidaFour != null)
                                      TextInputForm(
                                        controller:
                                            _cantidadMaquinariaController,
                                        hintText: 'Escriba la cantidad',
                                        labelText: 'Cantidad',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '¡¡¡Este campo es obligatorio!!!';
                                          }
                                          return null;
                                        },
                                        keyboardType: TextInputType.number,
                                        validCharacter: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        onChanged: (value) {
                                          cantidadMedidaMaqui = value;
                                        },
                                      ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    TextInputForm(
                                      controller: _rocaController,
                                      hintText: 'Escriba la roca',
                                      labelText: 'Roca',
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
                                    TextInputForm(
                                      controller:
                                          _observacionMaquinariaController,
                                      hintText: 'Escriba una observacion',
                                      labelText: 'Observaciones',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '¡¡¡Este campo es obligatorio!!!';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: agregarDatos3,
                                      child: const Text("Agregar"),
                                    ),
                                    const SizedBox(height: 20),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        border: TableBorder.all(),
                                        columns: const [
                                          DataColumn(
                                              label: Text('Propietario')),
                                          DataColumn(label: Text('Tramo')),
                                          DataColumn(label: Text('Medida')),
                                          DataColumn(label: Text('Cantidad')),
                                          DataColumn(label: Text('Roca')),
                                          DataColumn(
                                              label: Text('Observaciones')),
                                          DataColumn(label: Text('Eliminar')),
                                        ],
                                        rows: addedMaquinaria.map((data) {
                                          int index =
                                              addedMaquinaria.indexOf(data);
                                          return DataRow(cells: [
                                            DataCell(
                                                Text(data['propietario']!)),
                                            DataCell(Text(data['tramo']!)),
                                            DataCell(Text(data['medida']!)),
                                            DataCell(Text(
                                                data['cantidad_maquinaria']!)),
                                            DataCell(Text(data['roca']!)),
                                            DataCell(Text(data[
                                                'observacion_maquinaria']!)),
                                            DataCell(
                                              SizedBox(
                                                width: 50,
                                                child: IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () =>
                                                      eliminarMaquinaria(index),
                                                ),
                                              ),
                                            ),
                                          ]);
                                        }).toList(),
                                      ),
                                    ),
                                  ],
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
                        const Text('Herramientas y Equipos (horas)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 26)),
                        const SizedBox(
                          height: 20,
                        ),
                        Form(
                            key: _formKeyHerramienta,
                            child: Column(
                              children: [
                                TextInputForm(
                                  controller: _equipoHerramientaController,
                                  hintText: 'Escriba la equipo',
                                  labelText: 'Equipo',
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
                                TextInputForm(
                                  controller: _tiempoUsoController,
                                  hintText: 'Escriba tiempo de uso',
                                  labelText: 'Tiempo Uso',
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
                                TextInputForm(
                                  controller: _combustibleController,
                                  hintText: 'Escria el combustible',
                                  labelText: 'Combustible',
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
                                TextInputForm(
                                  controller: _estadoController,
                                  hintText: 'Escriba el estado',
                                  labelText: 'Estado',
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
                                TextInputForm(
                                  controller: _cambioAceiteController,
                                  hintText: 'Escriba el cambio de aceite',
                                  labelText: 'Cambio Aceite',
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
                                TextInputForm(
                                  controller: _observacionHerramientaController,
                                  hintText: 'Escriba una observacion',
                                  labelText: 'Observaciones',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '¡¡¡Este campo es obligatorio!!!';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: agregarDatos4,
                                  child: const Text("Agregar"),
                                ),
                                const SizedBox(height: 20),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    border: TableBorder.all(),
                                    columns: const [
                                      DataColumn(label: Text('Equipo')),
                                      DataColumn(label: Text('Tiempo Uso')),
                                      DataColumn(label: Text('Combustible')),
                                      DataColumn(label: Text('Estado')),
                                      DataColumn(label: Text('Cambio Aceite')),
                                      DataColumn(label: Text('Observaciones')),
                                      DataColumn(label: Text('Eliminar')),
                                    ],
                                    rows: addedHerramienta.map((data) {
                                      int index =
                                          addedHerramienta.indexOf(data);
                                      return DataRow(cells: [
                                        DataCell(Text(data['equipo']!)),
                                        DataCell(Text(data['tiempo_uso']!)),
                                        DataCell(Text(data['combustible']!)),
                                        DataCell(Text(data['estado']!)),
                                        DataCell(Text(data['cambio_aceite']!)),
                                        DataCell(Text(
                                            data['observacion_herramienta']!)),
                                        DataCell(
                                          SizedBox(
                                            width: 50,
                                            child: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () =>
                                                  eliminarHerramienta(index),
                                            ),
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
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
                          hintText: "Observaciones acerca del recibo de obra",
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
                                const Text("Firma"),
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
                        const Divider(),
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
                    ),
                  )))
        ])));
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
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? validCharacter;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onTap: onPressed,
      onSaved: onSaved,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: validCharacter,
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
