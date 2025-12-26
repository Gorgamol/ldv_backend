import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(id: id),
    _ => Response(
      statusCode: HttpStatus.methodNotAllowed,
    ),
  };
}

Response _get({required String id}) {
  return Response(
    body: 'GET - 200 - Task $id',
  );
}
