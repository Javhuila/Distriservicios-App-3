import 'package:cloud_firestore/cloud_firestore.dart';

class ArchiveFile {
  final String id;
  final String url;
  final String nombre;
  final DateTime fechaCreacion;
  final String tipo; // 'pdf', 'excel'
  final String userId;

  ArchiveFile({
    required this.id,
    required this.url,
    required this.nombre,
    required this.fechaCreacion,
    required this.tipo,
    required this.userId,
  });

  factory ArchiveFile.fromMap(Map<String, dynamic> data) {
    return ArchiveFile(
      id: data['id'],
      url: data['url'],
      nombre: data['nombre'],
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      tipo: data['tipo'],
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'nombre': nombre,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'tipo': tipo,
      'userId': userId,
    };
  }
}
