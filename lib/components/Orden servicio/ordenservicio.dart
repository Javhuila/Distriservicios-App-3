import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:distriservicios_app_3/components/Orden%20servicio/fecha_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'list_view_pdf_orden.dart';

class OrdenServicio extends StatefulWidget {
  const OrdenServicio({super.key});

  @override
  State<OrdenServicio> createState() => _OrdenServicioState();
}

class _OrdenServicioState extends State<OrdenServicio> {
  final _formKey = GlobalKey<FormState>();
  User? user;
  String userId = '';
  String? accessToken;

  int _contador = 0;
  String? _selectedTipoIden;
  String? _selectedTipoVivienda;
  String? _otherTipoVivienda;
  int? _selectedTipoEstrato;
  String? _selectedActuaCalidad;
  String? _selectedTipoInstalacion;
  String? _otherActuaCalidad;
  String? _otherTipoInstalacion;
  String? _selectedConcepto;
  String? _selectedTipoPago;
  String? _selectedPago;
  String? _otherTipoPago;
  String? _subsidioSeleccionado;
  String? _confirmRespuesta;
  String? _estadoContrato;
  String _sumaTextPago = "";
  int? _sumaNumberPago = 0;
  String _personNameAuth = "";
  int? _personCedulaAuth = 0;
  String _personLugarAuth = "";
  int? _personPriceAuth = 0;
  int? _personCuotaAuth = 0;
  String? _diaTextCons;
  int? _diaCons;
  String? _mesCons;
  int? _yearCons;

  Uint8List? signature1;
  Uint8List? signature2;

  final _firmaUsuarioController = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 4,
    exportPenColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final _firmaAsesorController = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 4,
    exportPenColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final List<String> _identifications = ['CC', 'NIT', 'CE'];
  final List<String> _viviendas = ['Casa', 'Apartamento', 'Otro'];
  final List<int> _estratos = [1, 2, 3, 4, 5, 6];
  final List<String> _actuaCalidads = [
    'Propietario',
    'Poseedor',
    'Arrendatario',
    'Otro',
  ];
  final List<String> _tipoInstalations = [
    'Residencial',
    'Comercial',
    'Industrial',
    'Oficial',
    'Oficial Asistencial',
    'Oficial Educativo',
    'Otro'
  ];

  final List<String> _conceptos = [
    'Cargo por conexion',
    'Interna',
    'Mts adicionales de la interna',
    'Punto adicional',
    'Subsidio',
  ];

  final List<String> _tipoPago = [
    'Credicontado con subsidio',
    'Credito sin subsidio',
  ];

  final List<String> _formaPago = [
    'Cuota inicial',
    'Valor a Financiar',
    'N° de cuota mensual',
    'Valor cuota mensual',
    'Longitud de la instalacion(metros)',
    'Subsidio',
    'Otros'
  ];

  final List<Map<String, dynamic>> _conceptosList = [];

  List<String> _opcionesPago = [];
  final List<Map<String, String?>> _resultados = [];

  @override
  void initState() {
    user = FirebaseAuth.instance.currentUser;
    userId = user?.uid ?? '';
    _getAccessToken();

    _cargarContador();
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

  Future<void> _cargarContador() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _contador = prefs.getInt('contador') ?? 0;
    });
  }

  @override
  void dispose() {
    _fechaGeneralController.dispose();
    _nombreController.dispose();
    _fristApellidoController.dispose();
    _secondApellidoController.dispose();
    _direccionController.dispose();
    _departamentoController.dispose();
    _ciudadController.dispose();
    _nIdentificacionController.dispose();
    _lugarExpedicionController.dispose();
    _barrioVeredaController.dispose();
    _matriculaInmobiliariaController.dispose();
    _codigoCastralController.dispose();
    _telefonoController.dispose();
    _movilController.dispose();
    _emailController.dispose();
    _cantidadController.dispose();
    _valorUnitarioController.dispose();
    _nombreSPUController.dispose();
    _numeroIdentificacionController.dispose();
    _nombreFamiliarController.dispose();
    _telefonoFamiliarController.dispose();
    _parentUsuarioController.dispose();
    _nombrePersonalController.dispose();
    _telefonoPersonalController.dispose();
    _parentPersonalController.dispose();
    _nombreAsesorController.dispose();
    _viviendaCoor1Controller.dispose();
    _viviendaCoor2Controller.dispose();
    _medicionCoor1Controller.dispose();
    _medicionCoor2Controller.dispose();
    _observacionAsesorController.dispose();
    _firmaUsuarioController.dispose();
    _firmaAsesorController.dispose();
    super.dispose();
  }

  final TextEditingController _fechaGeneralController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _fristApellidoController =
      TextEditingController();
  final TextEditingController _secondApellidoController =
      TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _nIdentificacionController =
      TextEditingController();
  final TextEditingController _lugarExpedicionController =
      TextEditingController();
  final TextEditingController _barrioVeredaController = TextEditingController();
  final TextEditingController _matriculaInmobiliariaController =
      TextEditingController();
  final TextEditingController _codigoCastralController =
      TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _movilController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _valorUnitarioController =
      TextEditingController();
  final TextEditingController _nombreSPUController = TextEditingController();
  final TextEditingController _numeroIdentificacionController =
      TextEditingController();
  final TextEditingController _nombreFamiliarController =
      TextEditingController();
  final TextEditingController _telefonoFamiliarController =
      TextEditingController();
  final TextEditingController _parentUsuarioController =
      TextEditingController();
  final TextEditingController _nombrePersonalController =
      TextEditingController();
  final TextEditingController _telefonoPersonalController =
      TextEditingController();
  final TextEditingController _parentPersonalController =
      TextEditingController();
  final TextEditingController _nombreAsesorController = TextEditingController();
  final TextEditingController _viviendaCoor1Controller =
      TextEditingController();
  final TextEditingController _viviendaCoor2Controller =
      TextEditingController();
  final TextEditingController _medicionCoor1Controller =
      TextEditingController();
  final TextEditingController _medicionCoor2Controller =
      TextEditingController();
  final TextEditingController _observacionAsesorController =
      TextEditingController();

  void _agregarConcepto() {
    String concepto = _selectedConcepto!;

    if (_conceptosList.any((item) => item['concepto'] == concepto)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este concepto ya ha sido agregado')),
      );
      return;
    }

    int cantidadConcepto = int.tryParse(_cantidadController.text) ?? 0;
    double valorUnitario =
        double.tryParse(_valorUnitarioController.text) ?? 0.0;
    double totalPorConcepto = cantidadConcepto * valorUnitario;

    _conceptosList.add({
      'concepto': concepto,
      'cantidad': cantidadConcepto,
      'valor_unitario': valorUnitario,
      'total_concepto': totalPorConcepto,
    });
    setState(() {
      _selectedConcepto = null;
      _cantidadController.clear();
      _valorUnitarioController.clear();
    });
  }

  double _calcularTotalServicio() {
    double total = 0.0;
    double totalSubsidio = 0.0;

    for (var item in _conceptosList) {
      if (item['concepto'] == 'Subsidio') {
        totalSubsidio += item['total_concepto'];
      } else {
        total += item['total_concepto'];
      }
    }
    return total - totalSubsidio;
  }

  void eliminarConcepto(int index) {
    setState(() {
      _conceptosList.removeAt(index);
    });
  }

  void _actualizarOpcionesPago() {
    if (_selectedTipoPago == 'Credicontado con subsidio') {
      _opcionesPago = List.from(_formaPago);
    } else if (_selectedTipoPago == 'Credito sin subsidio') {
      _opcionesPago =
          _formaPago.where((opcion) => opcion != 'Subsidio').toList();
    } else {
      _opcionesPago = [];
    }
  }

  void _realizarPago() {
    if (_resultados.any((resultado) => resultado['Pago'] == _selectedPago)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta opción ya ha sido agregada')),
      );
      return;
    }

    _resultados.add({
      'Tipo de Pago': _selectedTipoPago!,
      'Pago': _selectedPago!,
      'Subsidio': _subsidioSeleccionado ?? 'Indefinido',
      'Otros_Pago': _otherTipoPago ?? 'Indefinido',
    });
    setState(() {
      _selectedPago = null;
      _subsidioSeleccionado = null;
      _otherTipoPago = null;
    });
  }

  void eliminarPago(int index) {
    setState(() {
      _resultados.removeAt(index);
    });
  }

  bool _isTipoPagoBloqueado() {
    return _resultados.isNotEmpty;
  }

  bool _isBotonAgregarBloqueado() {
    return _selectedPago == null || _selectedTipoPago == null;
  }

  String _getDayInWords(int day) {
    if (day >= 1 && day <= daysInWords.length) {
      return daysInWords[day - 1];
    }
    return '';
  }

  String _getMonthName(int month) {
    return monthsInWords[month] ?? '';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _diaTextCons = _getDayInWords(picked.day);
        _diaCons = picked.day;
        _mesCons = _getMonthName(picked.month);
        _yearCons = picked.year;
      });
    }
  }

  Future<void> _showInputDialog(
      String title, Function(dynamic) onSubmit) async {
    String inputValue = '';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ingrese $title'),
          content: TextField(
            keyboardType: (title == 'valor en letras' ||
                    title == "nombres y apellidos completos" ||
                    title == "la ciudad")
                ? TextInputType.text
                : TextInputType.number,
            onChanged: (value) {
              inputValue = value;
            },
            decoration: InputDecoration(hintText: 'Ingrese $title'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                if (title == 'valor en letras' ||
                    title == "nombres y apellidos completos" ||
                    title == "la ciudad") {
                  onSubmit(inputValue);
                } else {
                  int? numericValue = int.tryParse(inputValue);
                  if (numericValue != null) {
                    onSubmit(numericValue);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Por favor ingrese un número válido')),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void guardarInformacion() async {
    if (signature1 == null || signature2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltan campos y/o firmas por rellenar!')),
      );
      return;
    }

    if (_sumaTextPago.isEmpty ||
        _sumaNumberPago == null ||
        _personNameAuth.isEmpty ||
        _personCedulaAuth == null ||
        _personLugarAuth.isEmpty ||
        _personPriceAuth == null ||
        _personCuotaAuth == null ||
        _diaTextCons == null ||
        _diaCons == null ||
        _mesCons == null ||
        _yearCons == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Por favor, complete todos los campos miniatura guiados con el icono!')),
      );
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
        Uint8List? signatureBytes1 = await _firmaUsuarioController.toPngBytes();
        Uint8List? signatureBytes2 = await _firmaAsesorController.toPngBytes();

        String fecha = _fechaGeneralController.text;
        String nombre = _nombreController.text;
        String primerApellido = _fristApellidoController.text;
        String segundoApellido = _secondApellidoController.text;
        String direccion = _direccionController.text;
        String departamento = _departamentoController.text;
        String ciudad = _ciudadController.text;
        String nIdentificacion = _nIdentificacionController.text;
        String lugarExpe = _lugarExpedicionController.text;
        String barrioVereda = _barrioVeredaController.text;
        String matriculaInmo = _matriculaInmobiliariaController.text;
        String codigoCastral = _codigoCastralController.text;
        String telef = _telefonoController.text;
        String movil = _movilController.text;
        String email = _emailController.text;
        String nombrSPU = _nombreSPUController.text;
        String numeroIden = _numeroIdentificacionController.text;
        String nombreF = _nombreFamiliarController.text;
        String telefF = _telefonoFamiliarController.text;
        String parentF = _parentUsuarioController.text;
        String nombrePer = _nombrePersonalController.text;
        String telefPer = _telefonoPersonalController.text;
        String parentPer = _parentPersonalController.text;
        String nombreAse = _nombreAsesorController.text;
        String viviendaCoor1 = _viviendaCoor1Controller.text;
        String viviendaCoor2 = _viviendaCoor2Controller.text;
        String medicionCoor1 = _medicionCoor1Controller.text;
        String medicionCoor2 = _medicionCoor2Controller.text;
        String observacion = _observacionAsesorController.text;
        String? tipoIden = _selectedTipoIden ?? 'No seleccionada';
        String? vivienda = _selectedTipoVivienda == 'Otro'
            ? 'Otro. ¿Cuál?: ${_otherTipoVivienda ?? ''}'
            : _selectedTipoVivienda;
        String? estrato = _selectedTipoEstrato.toString();
        String? actualidad = _selectedActuaCalidad == 'Otro'
            ? 'Otro. ¿Cuál?: ${_otherActuaCalidad ?? ''}'
            : _selectedActuaCalidad;
        String? instalacion = _selectedTipoInstalacion == 'Otro'
            ? 'Otro. ¿Cuál?: ${_otherTipoInstalacion ?? ''}'
            : _selectedTipoInstalacion;
        String? confirmarRes = _confirmRespuesta ?? 'Idenfinido';
        String? estadoCont = _estadoContrato ?? 'Idenfinido';
        String? totalService =
            '\$${_calcularTotalServicio().toStringAsFixed(2)}';

        // Crear PDF
        final pdf = pw.Document();
        final logoDistri = pw.MemoryImage(
          (await rootBundle.load('images/distri002.png')).buffer.asUint8List(),
        );
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
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
              pw.SizedBox(height: 10),
              pw.Text('1. SUSCRIPTOR'),
              pw.SizedBox(height: 10),
              pw.Text('Fecha: $fecha'),
              pw.SizedBox(height: 10),
              pw.Text('Nombres: $nombre'),
              pw.SizedBox(height: 10),
              pw.Text('Primer Apellido: $primerApellido'),
              pw.SizedBox(height: 10),
              pw.Text('Segundo Apellido: $segundoApellido'),
              pw.SizedBox(height: 10),
              pw.Text('Direccion: $direccion'),
              pw.SizedBox(height: 10),
              pw.Text('Departamento: $departamento'),
              pw.SizedBox(height: 10),
              pw.Text('Ciudad: $ciudad'),
              pw.SizedBox(height: 10),
              pw.Text('Tipo de Identificacion: $tipoIden'),
              pw.SizedBox(height: 10),
              pw.Text('No. Identificacion: $nIdentificacion'),
              pw.SizedBox(height: 10),
              pw.Text('Expedida en: $lugarExpe'),
              pw.SizedBox(height: 10),
              pw.Text('Tipo de vivienda: $vivienda'),
              pw.SizedBox(height: 10),
              pw.Text('Barrio/Vereda: $barrioVereda'),
              pw.SizedBox(height: 10),
              pw.Text('Estrato: $estrato'),
              pw.SizedBox(height: 10),
              pw.Text('Actua en calidad de: $actualidad'),
              pw.SizedBox(height: 10),
              pw.Text('Tipo de instalación: $instalacion'),
              pw.SizedBox(height: 10),
              pw.Text('Matricula Inmobiliaria: $matriculaInmo'),
              pw.SizedBox(height: 10),
              pw.Text('Codigo Castral: $codigoCastral'),
              pw.SizedBox(height: 10),
              pw.Text('Telefono: $telef'),
              pw.SizedBox(height: 10),
              pw.Text('Movil: $movil'),
              pw.SizedBox(height: 10),
              pw.Text('E-mail: $email'),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Text(
                  'El suscriptor o usuario que la certificacion previa a la puesta del servicio, sea realizada por DISTRISERVICIOES S.A.S ESP a traves de un organismo de certificacion o inspeccion acreditado.'),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 20),
              // Inicio de la tabla de conceptos
              pw.Text('2. DESCRIPCION DEL SERVICIO Y PRECIO'),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Concepto',
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
                        child: pw.Text('Valor unitario',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ..._conceptosList.map((concepto) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(concepto['concepto'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(concepto['cantidad'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(concepto['valor_unitario'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(concepto['total_concepto'].toString()),
                        ),
                        pw.SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('El total del servicio es de: $totalService'),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Text('3. FORMA DE PAGO'),
              pw.SizedBox(height: 10),
              // Inicio de la tabla de Pago
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Forma de pago',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Opcion de la forma de pago',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Subsidio',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Descripcion',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ..._resultados.map((resultt) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(resultt['Tipo de Pago'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(resultt['Pago'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(resultt['Subsidio'].toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(resultt['Otros_Pago'].toString()),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(children: [
                  pw.Text(
                    "4. Para efectos del presente documento, en adelante se denominará como SUSCRIPTOR a la persona relacionada en el numeral 1 y DISTRISERVICOS S.A.S E.S.P se denominará como la EMPRESA. 5. El valor de las instalaciones de uso comercial, industrial o usuario especial, corresponden al presupuesto previamente presentado y que el SUSCRIPTOR deberá conocer y aceptar. 6. Por los servicios el SUSCRIPTOR se obliga a pagar a favor de la empresa el precio en dinero pactado y definido en el numeral 25 (cinco) de la presente solicitud del servicio. 7. En caso de financiamiento de los conceptos aquí descritos, se cobrarán intereses mensuales a la tasa máxima fijada por la superintendencia financiera, vigente al momento de facturar cada mensualidad. 8. En caso de mora el SUSCRIPTOR deberá pagar a LA EMPRESA un interés liquidado sobre la suma de dinero insoluto, correspondiente a la tasa de interés moratoria máxima permitida por la Superintendencia Financiera de Colombia. 9. E SUSCRIPTOR autoriza de manera irrevocable a la EMPRESA para que en la factura del servicio de gas combustible le facture mensualmente el valor de las cuotas y demás sumas a financiar de que trata este documento. 10. En las operaciones de crédito en las que la empresa defina el cobro de la tasa fija o variable, el plazo final de la obligación será estimado ya que el vencimiento final se dará solo en la fecha en que se termine de cancelar totalmente el mismo por todo concepto, pudiendo en consecuencia la empresa modificar el plazo inicialmente estimado y determinar el vencimiento final de la obligación para la cual tendrá en cuenta la modalidad de la tasa de interés remuneratoria o variable acordado y la imputación hecha de las cuotas pautadas. 11. - La EMPRESA puede declarar el plazo vencido de la obligación a que se refiere el presente contrato y exigir su pago total si se incumple en cualquier forma el pago de la misma o cuando el SUSCRIPTOR sea perseguido judicialmente. 12. En caso de incumplimiento total o parcial en el pago de las cuotas mensuales, la EMPRESA podrá elegir entre el cumplimiento del contrato o pedir su resolución, caso en el cual la totalidad de la suma que hasta tanto se hubiese pagado o cualquier titulo pueden ser retenidos por la EMPRESA o título de indemnización de perjuicios. 13. Se cobrará el IVA, sobre el margen de utilidad del valor de la interna y se cobrará IVA por la revisión previa. Para tal fin se fija un margen de utilidad de diez por ciento, equivalente a la suma de $_sumaTextPago (\$$_sumaNumberPago) pesos M.L.C 14. Se entiende pactada la facultad de retroacción en favor de cualquiera de las partes, dentro de los cinco (5) días hábiles siguientes a la fecha de suscripción del siguiente documento. Sin embargo, cuando se haya dado inicio a la obra, el SUSCRIPTOR deberá pagar los valores correspondientes a lo instalado conforme a los precios aquí escritos. Pasados 5 días de la entrega de los bienes relacionados en el presente contrato, no se aceptan reclamos. 15. EI SUSCRIPTOR autoriza a la empresa de manera irrevocable o a quien represente sus derechos para que obtenga de cualquier fuente información reciente a su comportamiento como cliente de la empresa, como usuario de cualquier operación activa de crédito futura o pasada y a su vez faculta a esas entidades para que divulguen a terceros la información restringida. 16. - EL SUSCRIPTOR con la firma del presente documento autoriza a la EMPRES A para que en caso de mora realice los reportes de la información a las centrales de riesgo. Además, autoriza a la EMPRESA a usar con fines comerciales y/o publicitarios su información personal contenida en el presente documento y a recibir información publicitaria. 17. EL SUSCRIPTOR se obliga a mantener los bienes adquiridos en el lugar mencionado en el presente documento y no trasladarles a otro lugar sin notificación y autorización de la EMPRESA, la violación a lo aquí dispuesto dará el derecho a las acciones que haya lugar. 18. EL SUSCRIPTOR de forma libre, consciente, expresa o informada autoriza a la empresa y a sus empresas vinculadas para realizar el almacenamiento, uso, circulación, transferencia, transmisión de la información, tratamiento de los datos personales recolectados en el desarrollo del contrato de presentación de servicio público, en los términos establecidos en la ley 1581 de 2012, decretos reglamentarios y normas que la complementen, modifiquen y/o sustituyan en la política de privacidad y tratamiento de datos personales de DISTRISERVICIOS S.A.S E.S.P 19. En caso de detectarse falsedad en cualquiera de los documentos presentados por el SUSCRIPTOR, para obtener los beneficios que se lleguen a otorgar dará derecho a la empresa a descontar y/o no aplicar dichos beneficios y por consiguiente cobrarse el valor total por concepto del bien o servicio. 20. La suma aquí descrita se empezará a facturar dentro del mes siguiente a la construcción de la instalación interna, la acometida, e instalado el medidor. 21.El trazado definitivo de la instalación será precisado por el técnico autorizado por la empresa. 22. Los gasodomésticos deben estar disponibles para la fecha programada por la construcción de la instalación y puesta en servicio de lo contrario el usuario deberá programar la nueva visita y cancelar los valores a los que haya lugar. 23. El presente documento presta merito ejecutivo para hacer exigibles las obligaciones y prestaciones mutuas contenidas en él. En consecuencia, las partes acuerdan en forma expresa, que la copia original autógrafa del mismo, así como las facturas enviadas al suscriptor constituyen título ejecutivo suficiente para que la empresa exija por vía judicial el cumplimiento de las obligaciones dinerarias a cargo del SUSCRIPTOR. En consecuencia, el suscriptor acepta que se asimila en sus efectos a un título valor para exigir judicialmente la cancelación de las cuotas adeudadas sin necesidad de requerimiento alguno. EI SUSCRIPTOR autoriza a la empresa a destruir el presente formato, así como todos los documentos en caso de que la solicitud de crédito no sea aprobada. Las partes acuerdan que los bienes y/o servicios que se adquieren a través de la presente solicitud serán cobrados y facturados a partir del mes siguiente de la fecha de construcción de la instalación o entrega del producto adquirido. EL SUSCRIPTOR declara que los datos aquí consignados son ciertos, así como haber leído y por lo tanto conocer y aceptar las condiciones aquí dispuestas.",
                    style: const pw.TextStyle(
                      fontSize: 8,
                    ),
                  ),
                ]),
              ),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                  "Yo $_personNameAuth, identificado(a) con cedula de ciudadania, No. $_personCedulaAuth de $_personLugarAuth autorizo a la empresa DISTRISERVICIOS S.A.S E.S.P. para que financie y descuente a través de la factura de servicios públicos de gas domiciliario el gas doméstico cuya referencia es manejada por DISTRISERVICIOS S.A.S E.S.P., por un valor de \$$_personPriceAuth en $_personCuotaAuth cuotas mensuales."),
              pw.SizedBox(height: 5),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  "Por expresa instrucción de la Superintendencia de la Industria y Comercio, se informa a la parte deudora que durante el periodo de financiación la tasa de interés no podrá ser superior a 1,5 veces el interés bancario corriente que certifica la Superintendencia Financiera. Cuando el interés cobrado supere dicho limite, el acreedor perderá todos los intereses. En tales casos el consumidor podrá solicitar la inmediata devolución de las sumas que haya cancelado por concepto de los respectivos intereses. Se reputarán también como intereses las sumas que el acreedor reciba del deudor sin contraprestación distinta al crédito otorgado, aun cuando las mismas se justifiquen por conceptos de honorarios, comisiones u otros semejantes. También se incluirán dentro de los intereses las sumas de administración, estudio del crédito, papelería, cutas de afiliación, etc. Los contratos de prestación de servicios mediante sistemas de financiación se encuentras reglamentadas por la Superintendencia de Industria y Comercio, en capítulo tercero. Titulo II de la Circular Única, la cual puede ser consultada en la pagina web de esta entidad www.sic.gov.co. En caso de tener alguna queja relacionada con su crédito puede dirigirla a esta Superintendencia.",
                  style: const pw.TextStyle(
                    fontSize: 8,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                  "25.  NOTIFICACION ELECTRONICA: acepto recibir notificaciones por medio electrónico a la dirección descrita en el numeral 2, en conformidad con el artículo 56 de las ley 1437 de 2011 (CPACA) y de más que la adicionen, modifiquen, sustituyan o revoquen. Respuesta:$confirmarRes"),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                  "En consecuencia, de lo anterior y en señal de aceptación se firma el día $_diaTextCons ($_diaCons) del mes de $_mesCons del año $_yearCons."),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("EL SUSCRIPTOR/PROPIETARIO Y/O USUARIO"),
              pw.SizedBox(height: 10),
              if (signatureBytes1 != null)
                pw.Image(
                  pw.MemoryImage(signatureBytes1),
                  width: 200,
                  height: 100,
                ),
              pw.SizedBox(height: 10),
              pw.Text("FIRMA DEL PROPIETARIO"),
              pw.SizedBox(height: 10),
              pw.Text('Nombre: $nombrSPU'),
              pw.SizedBox(height: 10),
              pw.Text('C.C No. O Nit: $numeroIden'),
              pw.SizedBox(height: 10),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Text('Referencia Familiar'),
              pw.SizedBox(height: 10),
              pw.Text('Nombre: $nombreF'),
              pw.SizedBox(height: 10),
              pw.Text('Telefono: $telefF'),
              pw.SizedBox(height: 10),
              pw.Text('Parentesco: $parentF'),
              pw.SizedBox(height: 10),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Text('Referencia Personal'),
              pw.SizedBox(height: 10),
              pw.Text('Nombre: $nombrePer'),
              pw.SizedBox(height: 10),
              pw.Text('Telefono: $telefPer'),
              pw.SizedBox(height: 10),
              pw.Text('Parentesco: $parentPer'),
              pw.SizedBox(height: 5),
              pw.Divider(),

              pw.SizedBox(height: 20),
              pw.Text('PARA USO EXCLUSIVO DE DISTRISERVICIOS S.A.S ESP'),
              pw.SizedBox(height: 10),
              pw.Text('Nombre del Asesor: $nombreAse'),
              pw.SizedBox(height: 10),
              pw.Text('Vivienda: Coordenada = $viviendaCoor1'),
              pw.SizedBox(height: 10),
              pw.Text('Vivienda: Coordenada =  $viviendaCoor2'),
              pw.SizedBox(height: 10),
              pw.Text('Centro de medicion: Coordenada =  $medicionCoor1'),
              pw.SizedBox(height: 10),
              pw.Text('Centro de medicion: Coordenada =  $medicionCoor2'),
              pw.SizedBox(height: 10),
              pw.Text('Observación: $observacion'),
              pw.SizedBox(height: 10),
              if (signatureBytes2 != null)
                pw.Image(
                  pw.MemoryImage(signatureBytes2),
                  width: 200,
                  height: 100,
                ),
              pw.SizedBox(height: 10),
              pw.Text("FIRMA DEL ASESOR"),
              pw.SizedBox(height: 10),

              pw.Divider(),
              pw.SizedBox(height: 5),
              pw.Text(
                  "¿Se hace entrega del contrato en condiciones uniformes?: $estadoCont"),
              pw.SizedBox(height: 10),
            ],
          ),
        );
        // Generar el nombre del archivo PDF
        String fechaActual =
            DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        String nombreArchivo = 'Contrato_$fechaActual.pdf';

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
            'categoria': 'Orden_Servicio_Contrato',
            'userId': userId,
          });
        });
        _fechaGeneralController.clear();
        _nombreController.clear();
        _fristApellidoController.clear();
        _secondApellidoController.clear();
        _direccionController.clear();
        _departamentoController.clear();
        _ciudadController.clear();
        _nIdentificacionController.clear();
        _lugarExpedicionController.clear();
        _barrioVeredaController.clear();
        _matriculaInmobiliariaController.clear();
        _codigoCastralController.clear();
        _telefonoController.clear();
        _movilController.clear();
        _emailController.clear();
        _cantidadController.clear();
        _valorUnitarioController.clear();
        _nombreSPUController.clear();
        _numeroIdentificacionController.clear();
        _nombreFamiliarController.clear();
        _telefonoFamiliarController.clear();
        _parentUsuarioController.clear();
        _nombrePersonalController.clear();
        _telefonoPersonalController.clear();
        _parentPersonalController.clear();
        _nombreAsesorController.clear();
        _viviendaCoor1Controller.clear();
        _viviendaCoor2Controller.clear();
        _medicionCoor1Controller.clear();
        _medicionCoor2Controller.clear();
        _observacionAsesorController.clear();
        _firmaUsuarioController.clear();
        _firmaAsesorController.clear();

        _selectedTipoIden = null;
        _selectedTipoVivienda = null;
        _selectedTipoEstrato = null;
        _selectedActuaCalidad = null;
        _selectedTipoInstalacion = null;
        _otherActuaCalidad = null;
        _otherTipoInstalacion = null;
        _selectedConcepto = null;
        //
        _sumaNumberPago = 0;
        _personCedulaAuth = 0;
        _personPriceAuth = 0;
        _personCuotaAuth = 0;
        _diaCons = 0;
        _yearCons = 0;
        _confirmRespuesta = null;
        _estadoContrato = null;
        _sumaTextPago = "";
        _personNameAuth = "";
        _personLugarAuth = "";
        _diaTextCons = null;
        _mesCons = null;
        signature1 = null;
        signature2 = null;
        setState(() {
          _contador++;
          _conceptosList.clear();
          _resultados.clear();
        });

        // Guardar el contador en la libreria de SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('contador', _contador);
      } catch (e) {
        // print("Error: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(242, 56, 56, 1),
          foregroundColor: Colors.white,
          title: Text(
            'Orden de Servicios N° $_contador',
          ),
          actions: [
            IconButton(
              onPressed: () {
                if (accessToken != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListViewPdfOrden(
                        userId: userId,
                        accessToken: accessToken!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Cargando información de la sesión iniciada...')),
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              iconSize: 35,
            ),
          ],
        ),
        body: SingleChildScrollView(
            child: Column(children: [
          const SizedBox(
            width: 500,
            height: 150,
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
                      Text("DS-P-F-005"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text("Fecha"),
                      Text("20-05-2024"),
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
                      child: Column(children: [
                        const Text(
                          "1. Suscriptor",
                          style: TextStyle(fontSize: 30),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _fechaGeneralController,
                          hintText: 'Escriba una fecha',
                          labelText: 'Fecha de Orden',
                          keyboardType: TextInputType.none,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo, es obligatorio!!!';
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
                              _fechaGeneralController.text = formattedDate;
                            }
                          },
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _nombreController,
                          hintText: 'Escriba el nombre',
                          labelText: 'Nombre',
                          suffixIcon: const Icon(Icons.edit_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo, es obligatorio!!!';
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
                          controller: _fristApellidoController,
                          hintText: 'Escriba el primer apellido',
                          labelText: 'Primer Apellido',
                          suffixIcon: const Icon(Icons.edit_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo, es obligatorio!!!';
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
                          controller: _secondApellidoController,
                          hintText: 'Escriba el segundo apellido',
                          labelText: 'Segundo Apellido',
                          suffixIcon: const Icon(Icons.edit_outlined),
                          validCharacter: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]')),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _direccionController,
                          hintText: 'Escriba la direccion',
                          labelText: 'Direccion',
                          suffixIcon: const Icon(Icons.edit_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo, es obligatorio!!!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _departamentoController,
                          hintText: 'Escriba el departamento',
                          labelText: 'Departamento',
                          suffixIcon: const Icon(Icons.edit_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo, es obligatorio!!!';
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
                          controller: _ciudadController,
                          hintText: 'Escriba la ciudad',
                          labelText: 'Ciudad',
                          suffixIcon: const Icon(Icons.edit_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo, es obligatorio!!!';
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
                          value: _selectedTipoIden,
                          decoration: InputDecoration(
                            labelText: 'Identificación',
                            hintText: 'Seleccione una opción',
                            suffixIcon:
                                const Icon(Icons.contact_emergency_rounded),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 42, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          items: _identifications.map((String id) {
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(id),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTipoIden = newValue;
                            });
                          },
                          validator: (value) => value == null
                              ? 'Por favor seleccione una opción'
                              : null,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _nIdentificacionController,
                          hintText: 'Escriba el n° identificacion',
                          labelText: 'N° identificacion',
                          keyboardType: TextInputType.number,
                          suffixIcon: const Icon(
                            Icons.contact_emergency_rounded,
                          ),
                          validCharacter: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo, es obligatorio!!!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _lugarExpedicionController,
                          hintText: 'Lugar de Expedicion',
                          labelText: 'Expedicion',
                          suffixIcon: const Icon(
                            Icons.business_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo, es obligatorio!!!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedTipoVivienda,
                          decoration: InputDecoration(
                            labelText: 'Vivienda',
                            hintText: 'Seleccione una opción',
                            suffixIcon: const Icon(Icons.house),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 42, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          items: _viviendas.map((String id) {
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(id),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTipoVivienda = newValue;
                              if (newValue != 'Otro') {
                                _otherTipoVivienda = null;
                              }
                            });
                          },
                          validator: (value) => value == null
                              ? 'Por favor seleccione una opción'
                              : null,
                        ),
                        if (_selectedTipoVivienda == 'Otro')
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              TextInputForm(
                                labelText: '¿Cual?',
                                hintText: 'Ingrese el tipo de vivienda',
                                onChanged: (value) {
                                  _otherTipoVivienda = value;
                                },
                                validator: (value) => value?.isEmpty == true
                                    ? 'Este campo no puede estar vacío.'
                                    : null,
                              ),
                            ],
                          ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _barrioVeredaController,
                          hintText: 'Escriba el barrio/vereda',
                          labelText: 'Barrio/Vereda',
                          suffixIcon: const Icon(
                            Icons.house,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo, es obligatorio!!!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        DropdownButtonFormField<int>(
                          value: _selectedTipoEstrato,
                          decoration: InputDecoration(
                            labelText: 'Estrato',
                            hintText: 'Seleccione una opción',
                            suffixIcon:
                                const Icon(Icons.featured_play_list_rounded),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 42, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          items: _estratos.map((int id) {
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(id.toString()),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedTipoEstrato = newValue;
                            });
                          },
                          validator: (value) => value == null
                              ? 'Por favor seleccione una opción'
                              : null,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedActuaCalidad,
                          decoration: InputDecoration(
                            labelText: 'Actua en Calidad',
                            hintText: 'Seleccione una opción',
                            suffixIcon: const Icon(Icons.business_outlined),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 42, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          items: _actuaCalidads.map((String id) {
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(id),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedActuaCalidad = newValue;
                              if (newValue != 'Otro') {
                                _otherActuaCalidad = null;
                              }
                            });
                          },
                          validator: (value) => value == null
                              ? 'Por favor seleccione una opción'
                              : null,
                        ),
                        if (_selectedActuaCalidad == 'Otro')
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: '¿Cual?',
                                  hintText: 'Escriba su opción',
                                  suffixIcon:
                                      const Icon(Icons.question_mark_sharp),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 42, vertical: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                onChanged: (value) {
                                  _otherActuaCalidad = value;
                                },
                                validator: (value) => value?.isEmpty == true
                                    ? 'Este campo no puede estar vacío.'
                                    : null,
                              ),
                            ],
                          ),
                        const SizedBox(
                          height: 20,
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedTipoInstalacion,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Instalación',
                            hintText: 'Seleccione una opción',
                            suffixIcon: const Icon(Icons.insights_sharp),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 42, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          items: _tipoInstalations.map((String id) {
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(id),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTipoInstalacion = newValue;
                              if (newValue != 'Otro') {
                                _otherTipoInstalacion = null;
                              }
                            });
                          },
                          validator: (value) => value == null
                              ? 'Por favor seleccione una opción'
                              : null,
                        ),
                        if (_selectedTipoInstalacion == 'Otro')
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: '¿Cual?',
                                  hintText: 'Escriba su opción',
                                  suffixIcon:
                                      const Icon(Icons.question_mark_outlined),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 42, vertical: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                onChanged: (value) {
                                  _otherTipoInstalacion = value;
                                },
                                validator: (value) => value?.isEmpty == true
                                    ? 'Este campo no puede estar vacío.'
                                    : null,
                              ),
                            ],
                          ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _matriculaInmobiliariaController,
                          hintText: 'Inmobiliaria y/o escritura',
                          labelText: 'Matricula Inmobiliaria',
                          suffixIcon: const Icon(
                            Icons.table_view_outlined,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _codigoCastralController,
                          hintText: 'Escribe el codigo catastral',
                          labelText: 'Codigo Catastral',
                          suffixIcon: const Icon(
                            Icons.table_view_outlined,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _telefonoController,
                          hintText: 'Escriba el telefono',
                          labelText: 'Telefono',
                          suffixIcon: const Icon(
                            Icons.phone,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _movilController,
                          hintText: 'Escriba el movil',
                          labelText: 'Movil',
                          suffixIcon: const Icon(
                            Icons.phone_android_outlined,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _emailController,
                          hintText: 'Escriba el email',
                          labelText: 'Email',
                          suffixIcon: const Icon(
                            Icons.alternate_email_outlined,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                            "El suscriptor o usuario que la certificacion previa a la puesta del servicio, sea realizada por DISTRISERVICIOES S.A.S ESP a traves de un organismo de certificacion o inspeccion acreditado."),
                        const SizedBox(
                          height: 20,
                        ),
                        const Divider(),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                          "2. Descripcion del servicio y precio",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 30),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        DropdownButtonFormField<String>(
                          menuMaxHeight: 500,
                          itemHeight: 50,
                          value: _selectedConcepto,
                          decoration: InputDecoration(
                            labelText: 'Concepto',
                            hintText: 'Seleccione un concepto',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 42, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          items: _conceptos.map((String id) {
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Container(
                                  margin: EdgeInsets.zero,
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: Text(
                                    id,
                                    textAlign: TextAlign.start,
                                    maxLines: 2,
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                  )),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedConcepto = newValue;
                            });
                          },
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _cantidadController,
                          hintText: 'Escriba una cantidad',
                          labelText: 'Cantidad',
                          keyboardType: TextInputType.number,
                          validCharacter: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _valorUnitarioController,
                          hintText: 'Escriba un valor unitario',
                          labelText: 'Valor unitario',
                          keyboardType: TextInputType.number,
                          validCharacter: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        ElevatedButton(
                          onPressed: _agregarConcepto,
                          child: const Text('Agregar Concepto'),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            border: TableBorder.all(),
                            columns: const [
                              DataColumn(label: Text('Concepto')),
                              DataColumn(label: Text('Cantidad')),
                              DataColumn(label: Text('Valor Unitario')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Eliminar')),
                            ],
                            rows: _conceptosList.asMap().entries.map((concept) {
                              int index = concept.key;
                              var concepto = concept.value;
                              return DataRow(cells: [
                                DataCell(Text(concepto['concepto'])),
                                DataCell(Text(concepto['cantidad'].toString())),
                                DataCell(Text(
                                    concepto['valor_unitario'].toString())),
                                DataCell(Text(
                                    concepto['total_concepto'].toString())),
                                DataCell(
                                  SizedBox(
                                    width: 50,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => eliminarConcepto(index),
                                    ),
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Column(
                          children: [
                            Text(
                                'El total del Servicio es de: \$${_calcularTotalServicio().toStringAsFixed(2)}'),
                            const SizedBox(
                              height: 8,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                double totalServicio = _calcularTotalServicio();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Total del Servicio: \$${totalServicio.toStringAsFixed(2)}')),
                                );
                              },
                              child: const Text("Mostrar total del servicio"),
                            ),
                            const SizedBox(
                              width: 10,
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
                        const Text(
                          "3. Forma de Pago",
                          style: TextStyle(fontSize: 30),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        DropdownButtonFormField<String>(
                          value: _isTipoPagoBloqueado()
                              ? _selectedTipoPago
                              : _selectedTipoPago,
                          decoration: InputDecoration(
                            labelText: 'Forma de Pago',
                            hintText: 'Seleccione una opción',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 42, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          items: _tipoPago.map((tipo) {
                            return DropdownMenuItem<String>(
                              value: tipo,
                              child: Text(tipo),
                            );
                          }).toList(),
                          onChanged: _isTipoPagoBloqueado()
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedTipoPago = value;
                                    _actualizarOpcionesPago();
                                    _selectedPago = null;
                                  });
                                },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          itemHeight: 50,
                          value: _selectedPago,
                          decoration: InputDecoration(
                            labelText: 'Opciones',
                            hintText: 'Seleccione una opción',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 42, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          items: _opcionesPago.map((pago) {
                            return DropdownMenuItem<String>(
                              value: pago,
                              child: Container(
                                  margin: EdgeInsets.zero,
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: Text(
                                    pago,
                                    textAlign: TextAlign.start,
                                    maxLines: 2,
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                  )),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPago = value;
                              if (value == 'Subsidio') {
                                _subsidioSeleccionado = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        if (_selectedPago == 'Subsidio')
                          DropdownButtonFormField<String>(
                            value: _subsidioSeleccionado,
                            decoration: InputDecoration(
                              labelText: '¿Subsidio?',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 42, vertical: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            items: ['Sí', 'No'].map((opcion) {
                              return DropdownMenuItem<String>(
                                value: opcion,
                                child: Text(opcion),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _subsidioSeleccionado = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Seleccione una opción' : null,
                          ),
                        const SizedBox(height: 20),
                        if (_selectedTipoPago != null &&
                            _selectedPago != null &&
                            _selectedPago != 'Subsidio')
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Descripción',
                              hintText: 'Escriba una descripción',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 42, vertical: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onChanged: (value) {
                              _otherTipoPago = value;
                            },
                            validator: (value) => value?.isEmpty == true
                                ? 'Por favor ingrese un valor'
                                : null,
                          ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed:
                              _isBotonAgregarBloqueado() ? null : _realizarPago,
                          child: const Text('Agregar'),
                        ),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 20,
                            dataRowMinHeight: 50,
                            dataRowMaxHeight: 110,
                            border: TableBorder.all(),
                            columns: const [
                              DataColumn(label: Text('Tipo de Pago')),
                              DataColumn(label: Text('Pago')),
                              DataColumn(label: Text('Subsidio')),
                              DataColumn(label: Text('Descripción')),
                              DataColumn(label: Text('Eliminar')),
                            ],
                            rows: _resultados.asMap().entries.map((resultar) {
                              int index = resultar.key;
                              var resultado = resultar.value;
                              return DataRow(cells: [
                                DataCell(Text(resultado['Tipo de Pago']!)),
                                DataCell(Text(resultado['Pago']!)),
                                DataCell(Text(resultado['Subsidio']!)),
                                DataCell(Text(resultado['Otros_Pago']!)),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      eliminarPago(index);
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Divider(),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black),
                                      children: [
                                    const TextSpan(
                                      text:
                                          "4. Para efectos del presente documento, en adelante se denominará como SUSCRIPTOR a la persona relacionada en el numeral 1 y DISTRISERVICOS S.A.S E.S.P se denominará como la EMPRESA. 5. El valor de las instalaciones de uso comercial, industrial o usuario especial, corresponden al presupuesto previamente presentado y que el SUSCRIPTOR deberá conocer y aceptar. 6. Por los servicios el SUSCRIPTOR se obliga a pagar a favor de la empresa el precio en dinero pactado y definido en el numeral 25 (cinco) de la presente solicitud del servicio. 7. En caso de financiamiento de los conceptos aquí descritos, se cobrarán intereses mensuales a la tasa máxima fijada por la superintendencia financiera, vigente al momento de facturar cada mensualidad. 8. En caso de mora el SUSCRIPTOR deberá pagar a LA EMPRESA un interés liquidado sobre la suma de dinero insoluto, correspondiente a la tasa de interés moratoria máxima permitida por la Superintendencia Financiera de Colombia. 9. E SUSCRIPTOR autoriza de manera irrevocable a la EMPRESA para que en la factura del servicio de gas combustible le facture mensualmente el valor de las cuotas y demás sumas a financiar de que trata este documento. 10. En las operaciones de crédito en las que la empresa defina el cobro de la tasa fija o variable, el plazo final de la obligación será estimado ya que el vencimiento final se dará solo en la fecha en que se termine de cancelar totalmente el mismo por todo concepto, pudiendo en consecuencia la empresa modificar el plazo inicialmente estimado y determinar el vencimiento final de la obligación para la cual tendrá en cuenta la modalidad de la tasa de interés remuneratoria o variable acordado y la imputación hecha de las cuotas pautadas. 11. - La EMPRESA puede declarar el plazo vencido de la obligación a que se refiere el presente contrato y exigir su pago total si se incumple en cualquier forma el pago de la misma o cuando el SUSCRIPTOR sea perseguido judicialmente. 12. En caso de incumplimiento total o parcial en el pago de las cuotas mensuales, la EMPRESA podrá elegir entre el cumplimiento del contrato o pedir su resolución, caso en el cual la totalidad de la suma que hasta tanto se hubiese pagado o cualquier titulo pueden ser retenidos por la EMPRESA o título de indemnización de perjuicios. 13. Se cobrará el IVA, sobre el margen de utilidad del valor de la interna y se cobrará IVA por la revisión previa. Para tal fin se fija un margen de utilidad de diez por ciento, equivalente a la suma de",
                                    ),
                                    TextSpan(
                                        text: " $_sumaTextPago",
                                        style:
                                            const TextStyle(color: Colors.red)),
                                    TextSpan(
                                        text: " (\$$_sumaNumberPago)",
                                        style:
                                            const TextStyle(color: Colors.red)),
                                    const TextSpan(
                                        text:
                                            " pesos M.L.C 14. Se entiende pactada la facultad de retroacción en favor de cualquiera de las partes, dentro de los cinco (5) días hábiles siguientes a la fecha de suscripción del siguiente documento. Sin embargo, cuando se haya dado inicio a la obra, el SUSCRIPTOR deberá pagar los valores correspondientes a lo instalado conforme a los precios aquí escritos. Pasados 5 días de la entrega de los bienes relacionados en el presente contrato, no se aceptan reclamos. 15. EI SUSCRIPTOR autoriza a la empresa de manera irrevocable o a quien represente sus derechos para que obtenga de cualquier fuente información reciente a su comportamiento como cliente de la empresa, como usuario de cualquier operación activa de crédito futura o pasada y a su vez faculta a esas entidades para que divulguen a terceros la información restringida. 16. - EL SUSCRIPTOR con la firma del presente documento autoriza a la EMPRES A para que en caso de mora realice los reportes de la información a las centrales de riesgo. Además, autoriza a la EMPRESA a usar con fines comerciales y/o publicitarios su información personal contenida en el presente documento y a recibir información publicitaria. 17. EL SUSCRIPTOR se obliga a mantener los bienes adquiridos en el lugar mencionado en el presente documento y no trasladarles a otro lugar sin notificación y autorización de la EMPRESA, la violación a lo aquí dispuesto dará el derecho a las acciones que haya lugar. 18. EL SUSCRIPTOR de forma libre, consciente, expresa o informada autoriza a la empresa y a sus empresas vinculadas para realizar el almacenamiento, uso, circulación, transferencia, transmisión de la información, tratamiento de los datos personales recolectados en el desarrollo del contrato de presentación de servicio público, en los términos establecidos en la ley 1581 de 2012, decretos reglamentarios y normas que la complementen, modifiquen y/o sustituyan en la política de privacidad y tratamiento de datos personales de DISTRISERVICIOS S.A.S E.S.P 19. En caso de detectarse falsedad en cualquiera de los documentos presentados por el SUSCRIPTOR, para obtener los beneficios que se lleguen a otorgar dará derecho a la empresa a descontar y/o no aplicar dichos beneficios y por consiguiente cobrarse el valor total por concepto del bien o servicio. 20. La suma aquí descrita se empezará a facturar dentro del mes siguiente a la construcción de la instalación interna, la acometida, e instalado el medidor. 21.El trazado definitivo de la instalación será precisado por el técnico autorizado por la empresa. 22. Los gasodomésticos deben estar disponibles para la fecha programada por la construcción de la instalación y puesta en servicio de lo contrario el usuario deberá programar la nueva visita y cancelar los valores a los que haya lugar. 23. El presente documento presta merito ejecutivo para hacer exigibles las obligaciones y prestaciones mutuas contenidas en él. En consecuencia, las partes acuerdan en forma expresa, que la copia original autógrafa del mismo, así como las facturas enviadas al suscriptor constituyen título ejecutivo suficiente para que la empresa exija por vía judicial el cumplimiento de las obligaciones dinerarias a cargo del SUSCRIPTOR. En consecuencia, el suscriptor acepta que se asimila en sus efectos a un título valor para exigir judicialmente la cancelación de las cuotas adeudadas sin necesidad de requerimiento alguno. EI SUSCRIPTOR autoriza a la empresa a destruir el presente formato, así como todos los documentos en caso de que la solicitud de crédito no sea aprobada. Las partes acuerdan que los bienes y/o servicios que se adquieren a través de la presente solicitud serán cobrados y facturados a partir del mes siguiente de la fecha de construcción de la instalación o entrega del producto adquirido. EL SUSCRIPTOR declara que los datos aquí consignados son ciertos, así como haber leído y por lo tanto conocer y aceptar las condiciones aquí dispuestas."),
                                  ])),
                              const SizedBox(
                                height: 20,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                      "Ingrese el valor en letras y numeros"),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  GestureDetector(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(_sumaTextPago.isEmpty
                                            ? 'abc'
                                            : _sumaTextPago),
                                        const Icon(
                                          Icons.edit,
                                          size: 20,
                                        )
                                      ],
                                    ),
                                    onTap: () => _showInputDialog(
                                        'valor en letras', (value) {
                                      setState(() {
                                        _sumaTextPago = value.toString();
                                      });
                                    }),
                                  ),
                                  const SizedBox(height: 15),
                                  GestureDetector(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(_sumaNumberPago.toString()),
                                        const Icon(
                                          Icons.edit,
                                          size: 20,
                                        )
                                      ],
                                    ),
                                    onTap: () => _showInputDialog(
                                        'valor en numeros', (value) {
                                      setState(() {
                                        _sumaNumberPago = value;
                                      });
                                    }),
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      children: [
                                    const TextSpan(text: "Yo"),
                                    TextSpan(
                                        text: " $_personNameAuth",
                                        style:
                                            const TextStyle(color: Colors.red)),
                                    const TextSpan(
                                        text:
                                            ", identificado(a) con cedula de ciudadania, "),
                                    TextSpan(
                                        text: "No. $_personCedulaAuth",
                                        style:
                                            const TextStyle(color: Colors.red)),
                                    const TextSpan(text: " de "),
                                    TextSpan(
                                        text: "$_personLugarAuth ",
                                        style:
                                            const TextStyle(color: Colors.red)),
                                    const TextSpan(
                                        text:
                                            "autorizo a la empresa DISTRISERVICIOS S.A.S E.S.P. para que financie y descuente a través de la factura de servicios públicos de gas domiciliario el gas doméstico cuya referencia es manejada por DISTRISERVICIOS S.A.S E.S.P. "),
                                    const TextSpan(text: "por un valor de "),
                                    TextSpan(
                                        text: "\$$_personPriceAuth ",
                                        style:
                                            const TextStyle(color: Colors.red)),
                                    const TextSpan(text: "en "),
                                    TextSpan(
                                        text: "$_personCuotaAuth ",
                                        style:
                                            const TextStyle(color: Colors.red)),
                                    const TextSpan(text: "cuotas mensuales."),
                                  ])),
                              const SizedBox(
                                height: 15,
                              ),
                              Column(
                                children: [
                                  const Text(
                                      "Ingrese los nombre/s y apellidos"),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        child: Row(
                                          children: [
                                            Text(_personNameAuth.isEmpty
                                                ? 'abc'
                                                : _personNameAuth),
                                            const Icon(
                                              Icons.edit,
                                              size: 20,
                                            )
                                          ],
                                        ),
                                        onTap: () => _showInputDialog(
                                            'nombres y apellidos completos',
                                            (value) {
                                          setState(() {
                                            _personNameAuth = value.toString();
                                          });
                                        }),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              Column(
                                children: [
                                  const Text("Ingrese numero de cedula"),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  GestureDetector(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(_personCedulaAuth.toString()),
                                        const Icon(
                                          Icons.edit,
                                          size: 20,
                                        )
                                      ],
                                    ),
                                    onTap: () => _showInputDialog(
                                        'numero de cedula', (value) {
                                      setState(() {
                                        _personCedulaAuth = value;
                                      });
                                    }),
                                  ),
                                  const SizedBox(width: 20),
                                ],
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              Column(
                                children: [
                                  const Text("Ingrese la ciudad"),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  GestureDetector(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(_personLugarAuth.isEmpty
                                            ? 'abc'
                                            : _personLugarAuth),
                                        const Icon(
                                          Icons.edit,
                                          size: 20,
                                        )
                                      ],
                                    ),
                                    onTap: () =>
                                        _showInputDialog('la ciudad', (value) {
                                      setState(() {
                                        _personLugarAuth = value.toString();
                                      });
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              Column(
                                children: [
                                  const Text("Ingrese el valor en numeros"),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  GestureDetector(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(_personPriceAuth.toString()),
                                        const Icon(
                                          Icons.edit,
                                          size: 20,
                                        )
                                      ],
                                    ),
                                    onTap: () =>
                                        _showInputDialog('un valor', (value) {
                                      setState(() {
                                        _personPriceAuth = value;
                                      });
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              Column(
                                children: [
                                  const Text("Ingrese el numero de cuotas"),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  GestureDetector(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(_personCuotaAuth.toString()),
                                        const Icon(
                                          Icons.edit,
                                          size: 20,
                                        )
                                      ],
                                    ),
                                    onTap: () =>
                                        _showInputDialog('la cuota', (value) {
                                      setState(() {
                                        _personCuotaAuth = value;
                                      });
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text(
                            "Por expresa instrucción de la Superintendencia de la Industria y Comercio, se informa a la parte deudora que durante el periodo de financiación la tasa de interés no podrá ser superior a 1,5 veces el interés bancario corriente que certifica la Superintendencia Financiera. Cuando el interés cobrado supere dicho limite, el acreedor perderá todos los intereses. En tales casos el consumidor podrá solicitar la inmediata devolución de las sumas que haya cancelado por concepto de los respectivos intereses. Se reputarán también como intereses las sumas que el acreedor reciba del deudor sin contraprestación distinta al crédito otorgado, aun cuando las mismas se justifiquen por conceptos de honorarios, comisiones u otros semejantes. También se incluirán dentro de los intereses las sumas de administración, estudio del crédito, papelería, cutas de afiliación, etc. Los contratos de prestación de servicios mediante sistemas de financiación se encuentras reglamentadas por la Superintendencia de Industria y Comercio, en capítulo tercero. Titulo II de la Circular Única, la cual puede ser consultada en la pagina web de esta entidad www.sic.gov.co. En caso de tener alguna queja relacionada con su crédito puede dirigirla a esta Superintendencia. "),
                        const SizedBox(
                          height: 10,
                        ),
                        const Divider(),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                            "25.  NOTIFICACION ELECTRONICA: acepto recibir notificaciones por medio electrónico a la dirección descrita en el numeral 2, en conformidad con el artículo 56 de las ley 1437 de 2011 (CPACA) y de más que la adicionen, modifiquen, sustituyan o revoquen."),
                        const SizedBox(
                          height: 20,
                        ),
                        DropdownButtonFormField<String>(
                          value: _confirmRespuesta,
                          decoration: InputDecoration(
                            labelText: 'Confirmar',
                            hintText: 'Seleccione una opción',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 42, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          items: ['Sí', 'No'].map((opcion) {
                            return DropdownMenuItem<String>(
                              value: opcion,
                              child: Text(opcion),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _confirmRespuesta = value;
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black),
                                  children: [
                                    const TextSpan(
                                        text:
                                            'En consecuencia, de lo anterior y en señal de aceptación se firma el día'),
                                    TextSpan(
                                      text: _diaTextCons != null &&
                                              _diaCons != null
                                          ? ' $_diaTextCons ($_diaCons) '
                                          : ' dia ',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                    const TextSpan(text: 'del mes de '),
                                    TextSpan(
                                      text: _mesCons != null
                                          ? '$_mesCons '
                                          : 'mes ',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                    const TextSpan(text: 'del año '),
                                    TextSpan(
                                      text: _yearCons != null
                                          ? '$_yearCons.'
                                          : 'año.',
                                      style: const TextStyle(color: Colors.red),
                                    )
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Column(
                                children: [
                                  const Text("Ingrese una fecha"),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        child: Row(
                                          children: [
                                            Text(_diaCons != null &&
                                                    _mesCons != null &&
                                                    _yearCons != null
                                                ? '$_diaTextCons $_diaCons $_mesCons $_yearCons'
                                                : 'Selecciona la fecha'),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            const Icon(
                                                Icons.calendar_today_sharp,
                                                size: 30,
                                                color: Colors.red),
                                          ],
                                        ),
                                        onTap: () => _selectDate(context),
                                      ),
                                    ],
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
                        const Text("El suscriptor/propietario y/o usuario"),
                        const SizedBox(
                          height: 20,
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                const SizedBox(
                                  width: 200,
                                  child: Text(
                                    "Firma del suscriptor, propietario y/o usuario",
                                    maxLines: 2,
                                  ),
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
                                                                _firmaUsuarioController,
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
                                                                      _firmaUsuarioController
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
                                                                      _firmaUsuarioController
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
                                                                      _firmaUsuarioController
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
                                                                    signature1 =
                                                                        await _firmaUsuarioController
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
                        TextInputForm(
                          controller: _nombreSPUController,
                          hintText: "Nombre del usuario",
                          labelText: "Nombre",
                          keyboardType: TextInputType.text,
                          validCharacter: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]')),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _numeroIdentificacionController,
                          hintText: "Numero de identificacion",
                          labelText: "C.C/Nit",
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        const Text("Referencia Familiar"),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _nombreFamiliarController,
                          hintText: "Nombre del familiar",
                          labelText: "Nombre",
                          keyboardType: TextInputType.text,
                          validCharacter: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]')),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _telefonoFamiliarController,
                          hintText: "Telefono del familiar",
                          labelText: "Telefono",
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _parentUsuarioController,
                          hintText: "Parentesco del usuario",
                          labelText: "Parentesco",
                          keyboardType: TextInputType.text,
                          validCharacter: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]')),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text("Referencia Personal"),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _nombrePersonalController,
                          hintText: "Nombre del usuario",
                          labelText: "Nombre",
                          keyboardType: TextInputType.text,
                          validCharacter: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]')),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _telefonoPersonalController,
                          hintText: "Telefono del usuario",
                          labelText: "Telefono",
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _parentPersonalController,
                          hintText: "Parentesco del usuario",
                          labelText: "Parentesco",
                          keyboardType: TextInputType.text,
                          validCharacter: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]')),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Divider(),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                          "Para uso exclusivo de DISTRISERVICIOS S.A.S ESP",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 60,
                                color: Colors.red,
                              ),
                              Expanded(
                                child: Text(
                                  "Ningun funcionario esta autorizado para recibir dinero en efectivo",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _nombreAsesorController,
                          hintText: "Nombre del asesor",
                          labelText: "Nombre Asesor",
                          keyboardType: TextInputType.text,
                          validCharacter: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s]')),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Column(
                          children: [
                            const Text("Coordenadas de Vivienda"),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: TextInputForm(
                                      controller: _viviendaCoor1Controller,
                                      hintText: "Este",
                                      labelText: "Coordenada"),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: TextInputForm(
                                      controller: _viviendaCoor2Controller,
                                      hintText: "Norte",
                                      labelText: "Coordenada"),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Column(
                          children: [
                            const Text("Coordenadas de Centro de Medición"),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: TextInputForm(
                                      controller: _medicionCoor1Controller,
                                      hintText: "Este",
                                      labelText: "Coordenada"),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: TextInputForm(
                                      controller: _medicionCoor2Controller,
                                      hintText: "Norte",
                                      labelText: "Coordenada"),
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextInputForm(
                          controller: _observacionAsesorController,
                          hintText: "Escriba las observaciones",
                          labelText: "Observaciones",
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                const Text("Firma del Asesor"),
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
                                                                _firmaAsesorController,
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
                                                                      _firmaAsesorController
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
                                                                      _firmaAsesorController
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
                                                                      _firmaAsesorController
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
                                                                        await _firmaAsesorController
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
                        const Text(
                            "Se hace entrega del contrato en condiciones uniformes"),
                        const SizedBox(
                          height: 20,
                        ),
                        DropdownButtonFormField<String>(
                          value: _estadoContrato,
                          decoration: InputDecoration(
                            labelText: 'Confirmar',
                            hintText: 'Seleccione una opción',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 42, vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          items: ['Sí', 'No'].map((opcion) {
                            return DropdownMenuItem<String>(
                              value: opcion,
                              child: Text(opcion),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _estadoContrato = value;
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
                                  "Guardar Contrato",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 25),
                                ),
                              )),
                        ),
                      ]))))
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
