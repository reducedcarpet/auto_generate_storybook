import 'dart:io';

import '../utils/utils.dart';

Future<String> generatePubSpecFile(String projectName) async {
  StringBuffer buffer = StringBuffer();

  final pubSpec = await loadOriginalProjectPubspec();


  final dependencies = pubSpec['dependencies'] as Map;
  String dependenciesString = "";
  dependencies.forEach((key, value) {
    if(key == "flutter" || key == "flutter_web_plugins") {
      return;
    };

    if (value is String) {
      // Simple version dependency
      dependenciesString += '  $key: $value\n';
    } else if (value is Map) {
      // SDK dependency or similar
      var sdk = value['sdk'];
      if (sdk != null) {
        dependenciesString += '  $key:\n    sdk: $sdk\n';
      }
    }
  });

  print("\n pubSpec: ${dependenciesString}");


  buffer.writeln('name: $projectName');
  buffer.writeln('description: A new Flutter project.');
  buffer.writeln('publish_to: "none"');
  buffer.writeln("\n");
  buffer.writeln('version: 1.0.0+1');
  buffer.writeln("\n");
  buffer.writeln('environment:');
  buffer.writeln('  sdk: ">=3.0.0 <4.0.0"');
  buffer.writeln("\n");
  buffer.writeln('dependencies:');
  buffer.writeln('  flutter:');
  buffer.writeln('    sdk: flutter');
  buffer.writeln('  flutter_web_plugins:');
  buffer.writeln('    sdk: flutter');
  buffer.writeln(dependenciesString);
  buffer.writeln("  ${pubSpec["name"]}:");
  buffer.writeln('    path: ../');
  buffer.writeln('');
  buffer.writeln('  storybook_flutter: ^0.14.0');
  buffer.writeln("\n");
  buffer.writeln('dev_dependencies:');
  buffer.writeln('  flutter_test:');
  buffer.writeln('    sdk: flutter');
  buffer.writeln('  flutter_lints: ^3.0.1');
  buffer.writeln("\n");
  buffer.writeln('flutter:');
  buffer.writeln('  uses-material-design: true');
  buffer.writeln('  assets:');
  buffer.writeln('    - ../assets/');
  buffer.writeln("\n");

  return buffer.toString();
}

Future<void> saveGeneratedPubSpecFile(String projectName) async {
  final content = await generatePubSpecFile(projectName);
  final file = File('$projectName/pubspec.yaml');
  file.writeAsStringSync(content);
}