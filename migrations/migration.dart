import 'dart:io';

import 'package:postgres/postgres.dart';

Future<void> runMigrations(Connection connection) async {
  await connection.execute('''
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version TEXT PRIMARY KEY,
      applied_at TIMESTAMP DEFAULT now()
    );
  ''');

  final appliedRows = await connection.execute(
    'SELECT version FROM schema_migrations',
  );

  final applied = appliedRows.map((r) => r[0]! as String).toSet();

  final migrationFiles =
      Directory('/app/migrations')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  stdout.writeln('Migrations: ${migrationFiles.length}');

  for (final file in migrationFiles) {
    final version = file.uri.pathSegments.last;

    if (applied.contains(version)) continue;

    final sql = await file.readAsString();

    stdout.writeln('Applying migration: $version');

    await connection.runTx(
      (ctx) async {
        await ctx.execute(sql);
        await ctx.execute(
          'INSERT INTO schema_migrations (version) VALUES (@v)',
          parameters: {'v': version},
        );
      },
    );
  }
}
