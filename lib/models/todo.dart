import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo.freezed.dart';
part 'todo.g.dart';

@freezed
abstract class Todo with _$Todo {
  // Added constructor. Must not have any parameter
  const Todo._();

  const factory Todo(String name, {int? age}) = _Todo;

  factory Todo.fromJson(Map<String, Object?> json) => _$TodoFromJson(json);

  Map<String, dynamic> toJsonShort() => <String, dynamic>{
    'name': name,
    'age': age,
  };
}
