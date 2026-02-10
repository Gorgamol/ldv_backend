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
WHERE t.id = @id AND t.deleted_at IS NULL
GROUP BY t.id;

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
        Sql.named('''
WITH updated_task AS (
    UPDATE tasks
    SET
        title = @title,
        description = @description,
        status = @status,
        priority = @priority,
        author = @author,
        updated_at = NOW()
    WHERE id = @id
    RETURNING id
),
deleted_categories AS (
    DELETE FROM task_categories
    WHERE task_id = @id
      AND category_id NOT IN (SELECT UNNEST(@category_ids::INT[]))
),
inserted_categories AS (
    INSERT INTO task_categories (task_id, category_id)
    SELECT :task_id, UNNEST(@category_ids::INT[])
    ON CONFLICT DO NOTHING
)
SELECT id FROM updated_task;
'''),
        parameters: {
          'id': taskId,
          'title': body['title'],
          'description': body['description'],
          'author': body['author'],
          'priority': body['priority'],
          'status': body['status'],
          'category_ids': (body['category_ids'] as List?)?.cast<int>() ?? [],
        },
      );
    },
  );

  return Response();
}
