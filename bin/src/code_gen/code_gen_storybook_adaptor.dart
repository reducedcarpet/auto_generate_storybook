import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import 'code_gen_constants.dart';

Future<String> generateStorybookAdaptor(String projectName) async {
  final adaptorPage = Class(
    (b) => b
      ..name = 'StorybookAdaptor'
      ..extend = refer('StatelessWidget', 'package:flutter/material.dart')
      ..constructors.add(
        Constructor(
          (b) => b
            ..constant = true // Make the constructor constant
            ..optionalParameters.addAll(
              [
                Parameter(
                      (b) => b
                    ..name = 'child'
                    ..required = true
                    ..named = true
                    ..toThis = true,
                ),
                Parameter(
                  (b) => b
                    ..name = 'key'
                    ..toSuper = true // Forward to the super class constructor
                    ..named = true,
                ),
              ],
            ),
        ),
      )
      ..fields.add(
        Field(
          (b) => b
            ..name = 'child'
            ..modifier = FieldModifier.final$
            ..type = refer('Widget', 'package:flutter/material.dart'),
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
                refer("child", 'package:flutter/material.dart').returned.statement,
              ],
            ),
        ),
      ),
  );

  final library = Library(
    (b) => b
      ..body.add(adaptorPage)
      ..directives.addAll(
        [
          Directive.import('package:flutter/material.dart'),
        ],
      ),
  );

  final emitter = DartEmitter();

  return DartFormatter().format('${library.accept(emitter)}');
}

Future<void> saveGeneratedStorybookAdaptorFile(
  String projectName,
) async {
  final content = generateStorybookAdaptor(projectName);
  final file = File('$projectName/lib/generated/$storybookAdaptorFileName');
  file.writeAsStringSync(await content);
}
