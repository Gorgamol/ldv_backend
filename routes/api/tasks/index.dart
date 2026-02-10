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
  final db = await openDatabase();

  final tasks = await db.execute(
    Sql.named(
      '''
      SELECT
    t.id,
    t.created_at,
    t.updated_at,
    t.deleted_at,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.author,
    t.branch,
    COALESCE(
        json_agg(
            json_build_object(
                'id', c.id,
                'name', c.name,
                'branch', c.branch
            )
        ) FILTER (WHERE c.id IS NOT NULL),
        '[]'
    ) AS categories
FROM tasks t
LEFT JOIN task_categories tc ON tc.task_id = t.id
LEFT JOIN categories c ON c.id = tc.category_id
WHERE t.deleted_at IS NULL AND branch = @branch
GROUP BY t.id
ORDER BY t.created_at DESC;
    ''',
    ),
    parameters: {
      'branch': request.uri.queryParameters['branch'],
    },
  );

  await db.close();

  final jsonTasks = tasks.map((row) {
    final map = row.toColumnMap();
    return map.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      }
      return MapEntry(key, value);
    });
  }).toList();

  return Response.json(body: jsonTasks);
}

Future<Response> _post({
  required Request request,
}) async {
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
      },
    );
  }

  final db = await openDatabase();

  final result = await db.execute(
    Sql.named('''
      INSERT INTO tasks (title, description, author, priority, status, branch)
      VALUES (@title, @description, @author, @priority, @status, @branch)
      RETURNING *;
      '''),
    parameters: {
      'title': body['title'],
      'description': body['description'],
      'author': body['author'],
      'priority': body['priority'],
      'status': body['status'],
      'branch': request.uri.queryParameters['branch'],
    },
  );

  final task = result.first.toColumnMap().map(
    (key, value) {
      if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      }
      return MapEntry(key, value);
    },
  );

  await db.close();

  return Response.json(
    statusCode: 201,
    body: task,
  );
}
