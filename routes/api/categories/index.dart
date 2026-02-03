import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../utils/db.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _get(
      request: context.request,
    ),
    HttpMethod.post => await _post(
      request: context.request,
    ),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get({
  required Request request,
}) async {
  final branch = request.uri.queryParameters['branch'];

  if (branch == null) {
    return Response(statusCode: 400, body: 'Missing branch parameter');
  }

  final db = await openDatabase();

  final result = await db.execute(
    Sql.named(
      'SELECT * FROM categories WHERE branch = @branch',
    ),
    parameters: {
      'branch': branch,
    },
  );

  await db.close();

  final categories = result
      .map(
        (row) => row.toColumnMap().map(
          (key, value) {
            if (value is DateTime) {
              return MapEntry(key, value.toIso8601String());
            }
            return MapEntry(key, value);
          },
        ),
      )
      .toList();

  return Response.json(body: categories);
}

Future<Response> _post({
  required Request request,
}) async {
  final data = await request.json() as Map<String, dynamic>;
  final name = data['name'];
  final branch = data['branch'];

  if (name == null || branch == null) {
    return Response(statusCode: 400, body: 'Missing name or branch.');
  }

  final db = await openDatabase();

  await db.execute(
    Sql.named(
      'INSERT INTO categories (name, branch) VALUES (@name, @branch)',
    ),
    parameters: {
      'name': name,
      'branch': branch,
    },
  );

  final result = await db.execute(
    Sql.named(
      'SELECT * FROM categories WHERE branch = @branch',
    ),
    parameters: {
      'branch': branch,
    },
  );

  await db.close();

  final categories = result
      .map(
        (row) => row.toColumnMap().map(
          (key, value) {
            if (value is DateTime) {
              return MapEntry(key, value.toIso8601String());
            }
            return MapEntry(key, value);
          },
        ),
      )
      .toList();

  return Response.json(body: categories);
}
