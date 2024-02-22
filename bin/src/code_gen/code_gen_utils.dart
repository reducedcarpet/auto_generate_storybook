import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

Future<void> saveGeneratedPage(String fileName, String contents) async {
  File file = File(fileName);
  await file.writeAsString(contents);
}

String subtractLibPath(FileSystemEntity image) {
  final String currentDirectory = Directory.current.path + "\\lib";
  String relative = path.relative(image.path, from: currentDirectory);
  return relative;
}

String relativePath(FileSystemEntity image) {
  String relative = subtractLibPath(image);
  // strip file name
  relative = relative.substring(0, relative.lastIndexOf(path.basename(image.path)));
  relative = relative.replaceAll("\\", "/");
  return relative;
}

String encodedImagePath(FileSystemEntity image) {
  String relative = subtractLibPath(image);

  relative = relative.replaceAll("\\", "__");
  relative = relative.replaceAll("/", "__");

  return relative;
}

String encodedDartPath(FileSystemEntity image) {
  String relative = subtractLibPath(image);

  relative = relative.replaceAll("\\", "__");
  relative = relative.replaceAll("/", "__");

  return path.basenameWithoutExtension(relative);
}

String encodedKebabPath(FileSystemEntity image) {
  String relative = subtractLibPath(image);

  relative = relative.replaceAll("\\", "_");
  relative = relative.replaceAll("/", "_");

  return path.basenameWithoutExtension(relative);
}

String getPascalCaseName(FileSystemEntity image) {
  String imagePath = encodedKebabPath(image);
  String basename = path.withoutExtension(imagePath);
  ReCase reCase = ReCase(basename);
  basename = reCase.pascalCase;
  return basename;
}

String getKebabCaseName(FileSystemEntity image) {
  String imagePath = encodedKebabPath(image);
  String basename = path.withoutExtension(imagePath);
  return basename;
}