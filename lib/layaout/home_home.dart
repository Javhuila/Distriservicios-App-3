import 'package:flutter/material.dart';

import '../components/Informe diario-obra/informediarioobra.dart';
import '../components/Orden servicio/ordenservicio.dart';
import '../components/Recibo obra-material/reciboobramaterial.dart';
import '../components/Recibo obra-soldador/reciboobrasoldador.dart';
import '../components/Reporte diario-personal/reportediariopersonal.dart';
import '../services/auth/profile.dart';

class HomeHome extends StatefulWidget {
  const HomeHome({super.key});

  @override
  State<HomeHome> createState() => _HomeHomeState();
}

class _HomeHomeState extends State<HomeHome> {
  void _navigateToProfile(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pop(context);
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Profile()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DistriServicios ESP',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromRGBO(242, 56, 56, 1),
        actions: [
          IconButton(
            onPressed: () => _navigateToProfile(context),
            icon: const Icon(Icons.person_outline_outlined),
            color: Colors.white,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 50),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.end,
                // crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 50),
                  Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 2.0),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ReciboObraMaterial()),
                          );
                        },
                        child: const Text(
                          "Recibo de obra y de material",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      )),
                  const SizedBox(height: 50),
                  Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 2.0),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ReciboObraSoldador()),
                          );
                        },
                        child: const Text(
                          "Recibo de obra. Soldador de polietileno",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      )),
                  const SizedBox(height: 50),
                  SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const InformeDiarioObra()),
                          );
                        },
                        child: const Text(
                          "Informe diario de Obra",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      )),
                  const SizedBox(height: 50),
                  SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ReporteDiarioPersonal()),
                          );
                        },
                        child: const Text(
                          "Reporte diario del Personal",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      )),
                  const SizedBox(height: 50),
                  SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const OrdenServicio()),
                          );
                        },
                        child: const Text(
                          "Orden de Servicio",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      )),
                  const SizedBox(height: 50),
                ],
              )),
        ),
      ),
    );
  }
}
