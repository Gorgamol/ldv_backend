import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../utils/db.dart';

Future<Response> onRequest(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;

    return switch (context.request.method) {
      HttpMethod.get => await _get(),
      HttpMethod.post => await _post(body: body),
      _ => Response(statusCode: HttpStatus.methodNotAllowed),
    };
  } on FormatException catch (e) {
    return Response.json(
      statusCode: 400,
      body: {
        'error': 'Invalid JSON body',
        'details': e.message,
        'headers': context.request.headers,
        'body': await context.request.body(),
      },
    );
  }
}

Future<Response> _get() async {
  final db = await openDatabase();

  final tasks = await db.execute(
    '''
      SELECT * FROM tasks WHERE deleted_at IS NULL
    ''',
  );

  return Response.json(
    body: tasks.map((row) => row.toColumnMap()).toList(),
  );
}

Future<Response> _post({required Map<String, dynamic> body}) async {
  final db = await openDatabase();

  final result = await db.execute(
    '''
      INSERT INTO tasks (title, description, author, priority, status)
      VALUES (@title, @description, @author, @priority, @status)
      RETURNING *
      ''',
    parameters: {
      'title': body['title'],
      'description': body['description'],
      'author': body['author'],
      'priority': body['priority'],
      'status': body['status'],
    },
  );

  return Response.json(
    statusCode: 201,
    body: result.first.toColumnMap(),
  );
}
