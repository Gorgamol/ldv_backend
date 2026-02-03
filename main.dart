// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'migrations/migration.dart';
import 'utils/db.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  final connection = await openDatabase();

  await runMigrations(connection);

  await connection.close();

  return serve(handler, ip, port);
}
