/// {@template todo}
/// A simple base model class to extend other classes from.
///
/// Contains a [id], [createdAt], [updatedAt] and [deletedAt];
/// {@endtemplate}
class BaseModel {
  /// {@macro todo}
  const BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  /// The unique identifier of the model.
  final String id;

  /// Model created at [DateTime].
  final DateTime createdAt;

  /// Model updated at [DateTime].
  final DateTime updatedAt;

  /// Model deleted at [DateTime].
  final DateTime? deletedAt;
}
