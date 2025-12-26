import 'package:json_annotation/json_annotation.dart';

/// A simple enum that describes the branch of the non profit association.
enum Branch {
  /// Non profit association branch - Park.
  @JsonValue('park')
  park,

  /// Non profit association branch - Mill.
  @JsonValue('mill')
  mill,

  /// Non profit association branch - Theatre.
  @JsonValue('theatre')
  theatre,
}
