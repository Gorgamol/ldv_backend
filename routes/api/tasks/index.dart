import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../utils/db.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _get(),
    HttpMethod.post => await _post(request: context.request),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
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

Future<Response> _post({required Request request}) async {
  Map<String, dynamic>? body;

  try {
    body = (await request.json()) as Map<String, dynamic>;
  } on FormatException catch (e) {
    return Response.json(
      statusCode: 400,
      body: {
        'error': 'Invalid JSON body',
        'details': e.message,
        'headers': request.headers,
        'body': await request.body(),
      },
    );
  }

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
