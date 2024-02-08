import 'dart:io';

bool deleteTestDirectory() {
  final String currentDirectory = Directory.current.path;
  final dir = Directory('$currentDirectory/test');
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
    return true;
  }
  return false;
}