import 'dart:io';

import '../code_gen_stateless_widgets_parameters.dart';
import '../code_gen_story_list.dart';
import '../code_gen_utils.dart';
import '../code_gen_stateless_widgets.dart';
import '../../utils/recursive_utils.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

import '../visitors/constructor_parameters.dart';
import 'code_gen_story_files_stateless.dart';
import 'defaults.dart';

Future<String> generateStatelessWidgetParametersStoryPage(
  FileSystemEntity classFile,
  String originalProjectName,
) async {
  final String basename = path.basename(classFile.path);
  ReCase reCase = ReCase(path.withoutExtension(basename));
  final String pascalCaseName = reCase.pascalCase;

  String dirPascalCaseName = getPascalCaseName(classFile);

  final parameters = await getFirstConstructorParameters(classFile.path);
  //print("ParametersL $parameters");

  final List<Parameter> codeBuilderParameters = parameters.map(
    (param) {
      print("ADDING PARAMETER: ${param.name} ${param.type}");
      return Parameter(
        (p) => p
          ..name = param.name.toString()
          ..type = Reference(param.type!),
      );
    },
  ).toList();

  //print("codeBuilderParameters $codeBuilderParameters");
  print("DEFAULTS: $defaults");

  final childInstance = refer(pascalCaseName).newInstance(
    [],
    Map.fromEntries(
      codeBuilderParameters.map(
        (param) {
          print("type symbol:  ${param.type?.symbol.toString()}");
          print("TYPE value: " + defaults[param.type?.symbol].toString());
          String value = defaults[param.type?.symbol].toString();
          if(param.type?.symbol.toString() == "String") {
            value = "\"$value\"";
          }
          return MapEntry<String, Expression>(param.name, refer(value));
        },
      ),
    ),
  );

  final widgetPage = Class(
    (b) => b
      ..name = '${dirPascalCaseName}StorybookScreen'
      ..extend = refer('StatelessWidget', 'package:flutter/material.dart')
      ..constructors.add(
        Constructor(
          (b) => b
            ..constant = true // Make the constructor constant
            ..optionalParameters.add(
              Parameter(
                (b) => b
                  ..name = 'key'
                  ..toSuper = true // Forward to the super class constructor
                  ..named = true,
              ),
            ),
        ),
      )
      ..methods.add(
        Method(
          (b) => b
            ..name = 'build'
            ..annotations.add(
              refer('override'),
            )
            ..returns = refer('Widget', 'package:flutter/material.dart')
            ..requiredParameters.add(
              Parameter(
                (b) => b
                  ..name = 'context'
                  ..type = refer('BuildContext'),
              ),
            )
            ..body = Block.of(
              [
                refer('StorybookAdaptor')
                    .constInstance([], {'child': childInstance})
                    .returned
                    .statement,
              ],
            ),
        ),
      ),
  );

  final library = Library(
    (b) => b
      ..body.add(widgetPage)
      ..directives.addAll(
        [
          Directive.import('package:flutter/material.dart'),
          Directive.import('storybook_adaptor.dart'),
          Directive.import(generateProjectImport(originalProjectName, classFile)),
        ],
      ),
  );

  final emitter = DartEmitter();

  return DartFormatter().format('${library.accept(emitter)}');
}

String generateProjectImport(String originalProjectName, FileSystemEntity classFile) {
  String path = subtractLibPath(classFile);
  path = path.replaceAll("\\", "/");
  return "package:$originalProjectName/${path}";
}
