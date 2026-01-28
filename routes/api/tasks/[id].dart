import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../utils/db.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.delete => await _delete(id: id),
    HttpMethod.patch => await _patch(
      id: id,
      request: context.request,
    ),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
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
          'title = @title '
          'description = @description, '
          'priority = @priority, '
          'status = @status, '
          'author = @author, '
          'branch = @branch '
          'WHERE id = @id',
        ),
        parameters: {
          'id': taskId,
          'title': body['title'],
          'description': body['description'],
          'author': body['author'],
          'priority': body['priority'],
          'status': body['status'],
          'branch': body['branch'],
        },
      );
    },
  );

  return Response();
}
