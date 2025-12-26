// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Todo _$TodoFromJson(Map<String, dynamic> json) =>
    _Todo(json['name'] as String, age: (json['age'] as num?)?.toInt());

Map<String, dynamic> _$TodoToJson(_Todo instance) => <String, dynamic>{
  'name': instance.name,
  'age': instance.age,
};
