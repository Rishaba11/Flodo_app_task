// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskDraftAdapter extends TypeAdapter<TaskDraft> {
  @override
  final int typeId = 2;

  @override
  TaskDraft read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskDraft(
      title: fields[0] as String,
      description: fields[1] as String,
      dueDate: fields[2] as DateTime?,
      blockedById: fields[3] as String?,
      statusIndex: fields[4] as int,
      editingTaskId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskDraft obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.dueDate)
      ..writeByte(3)
      ..write(obj.blockedById)
      ..writeByte(4)
      ..write(obj.statusIndex)
      ..writeByte(5)
      ..write(obj.editingTaskId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskDraftAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}