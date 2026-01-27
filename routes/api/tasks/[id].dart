import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../utils/db.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.delete => await _delete(id: id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _delete({required String id}) async {
  final db = await openDatabase();

  // Optional: parse id as integer
  final taskId = int.tryParse(id);
  if (taskId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Invalid task ID'},
    );
  }

  // Soft delete by setting deleted_at
  final result = await db.execute(
    Sql.named('''
    UPDATE tasks
    SET deleted_at = NOW()
    WHERE id = @id
    RETURNING *
    '''),
    parameters: {'id': taskId},
  );

  if (result.isEmpty) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Task not found'},
    );
  }

  // Return the deleted task
  final deletedTask = result.first.toColumnMap().map((key, value) {
    if (value is DateTime) return MapEntry(key, value.toIso8601String());
    return MapEntry(key, value);
  });

  return Response.json(body: deletedTask);
}
