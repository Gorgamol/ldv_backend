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
        Sql.named('''
        SELECT t.id, t.created_at, t.updated_at, t.deleted_at, t.title, t.description, t.status, t.priority, t.author, t.branch,
        COALESCE(json_agg(json_build_object('id', c.id, 'name', c.name)) FILTER (WHERE c.id IS NOT NULL), []) AS categories
        FROM tasks t
        LEFT JOIN task_categories tc ON tc.task_id = t.id
        LEFT JOIN categories c ON c.id = tc.category_id
        WHERE t.id=@id AND t.deleted_at IS NULL
        GROUP BY t.id, t.created_at, t.updated_at, t.deleted_at, t.title, t.description, t.status, t.priority, t.author, t.branch
        '''),
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
        Sql.named('UPDATE tasks SET deleted_at = NOW() WHERE id = @id'),
        parameters: {'id': taskId},
      );

      await db.execute(
        Sql.named(
          'UPDATE task_categories SET deleted_at = NOW() WHERE task_id=@id',
        ),
        parameters: {
          'id': taskId,
        },
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
  final categoryIds = (body['categories'] as List?)?.cast<int>() ?? [];

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
          'author = @author '
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

      await db.execute(
        Sql.named('DELETE FROM task_categories WHERE task_id=@id'),
        parameters: {
          'id': taskId,
        },
      );

      for (final id in categoryIds) {
        await db.execute(
          Sql.named(
            'INSERT INTO task_categories (task_id, category_id) '
            'VALUES (@task, @category)',
          ),
          parameters: {
            'task': taskId,
            'category': id,
          },
        );
      }
    },
  );

  return Response();
}
