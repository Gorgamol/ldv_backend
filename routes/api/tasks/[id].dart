import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../utils/db.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => await _get(id: id),
    HttpMethod.delete => await _delete(id: id),
    HttpMethod.patch => await _patch(
      id: id,
      request: context.request,
    ),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get({required String id}) async {
  final taskId = int.tryParse(id);

  if (taskId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Invalid task ID'},
    );
  }

  late final Result result;

  await doDatabaseOperation(
    (db) async {
      result = await db.execute(
        Sql.named('SELECT * FROM tasks WHERE deleted_at IS NULL AND id = @id'),
        parameters: {'id': taskId},
      );
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

  return Response.json(
    body: task,
  );
}

Future<Response> _delete({required String id}) async {
  final taskId = int.tryParse(id);
  if (taskId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Invalid task ID'},
    );
  }

  await doDatabaseOperation(
    (db) async {
      await db.execute(
        Sql.named(' UPDATE tasks SET deleted_at = NOW() WHERE id = @id'),
        parameters: {'id': taskId},
      );
    },
  );

  return Response();
}

Future<Response> _patch({
  required Request request,
  required String id,
}) async {
  final taskId = int.tryParse(id);
  final body = (await request.json()) as Map<String, dynamic>;

  if (taskId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Invalid task ID'},
    );
  }

  await doDatabaseOperation(
    (db) async {
      await db.execute(
        Sql.named(
          'UPDATE tasks '
          'SET updated_at = NOW(), '
          'title = @title, '
          'description = @description, '
          'priority = @priority, '
          'status = @status, '
          'author = @author, '
          'WHERE id = @id',
        ),
        parameters: {
          'id': taskId,
          'title': body['title'],
          'description': body['description'],
          'author': body['author'],
          'priority': body['priority'],
          'status': body['status'],
        },
      );
    },
  );

  return Response();
}
