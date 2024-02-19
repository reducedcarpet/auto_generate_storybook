import 'dart:io';
import 'package:path/path.dart' as path;

Future<List<FileSystemEntity>> findAllWidgets() async {
  final String currentDirectory = Directory.current.path;

  final dir = Directory('$currentDirectory\\lib');
  print("\nDIR: $dir \n");
  final List<FileSystemEntity> entities = await checkDirectoryForWidgets(dir);
  return entities;
}

Future<List<FileSystemEntity>> checkDirectoryForWidgets(Directory dir) async {
  final List<FileSystemEntity> entities = await dir.list().toList();
  final List<FileSystemEntity> result = [];

  for (final FileSystemEntity entity in entities) {
    var entityType = await FileSystemEntity.type(entity.path);
    if (entityType == FileSystemEntityType.file) {
      if (path.extension(entity.path).toLowerCase().endsWith(".dart")) {
        result.add(entity);
      }
    } else if (entityType == FileSystemEntityType.directory) {
      result.addAll(
        await checkDirectoryForWidgets(Directory(entity.path)),
      );
    }
  }

  return result;
}