// ignore_for_file: avoid_print

import 'dart:io';

import 'package:postgres/postgres.dart';

Future<Connection> openDatabase() async {
  final dbUrl = Platform.environment['DATABASE_URL'];
  if (dbUrl == null) {
    print('DATABASE_URL not set');
    exit(1);
  }

  return Connection.openFromUrl('$dbUrl?sslmode=disable');
}

Future<void> doDatabaseOperation(
  Future<void> Function(Connection) operation,
) async {
  final dbUrl = Platform.environment['DATABASE_URL'];
  if (dbUrl == null) {
    print('DATABASE_URL not set');
    exit(1);
  }

  final connection = await Connection.openFromUrl('$dbUrl?sslmode=disable');

  await operation.call(connection);

  await connection.close();
}
