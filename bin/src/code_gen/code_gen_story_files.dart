import 'dart:io';

import 'code_gen_story_list.dart';
import 'code_gen_utils.dart';
import 'code_gen_widgets.dart';
import '../utils/recursive_utils.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

String generateWidgetStoryPage(FileSystemEntity classFile) {
  final String basename = path.basename(classFile.path);
  print("basename: $basename");
  print("classFile: ${classFile.path}");
  ReCase reCase = ReCase(path.withoutExtension(basename));
  final String pascalCaseName =  reCase.pascalCase;

  String dirPascalCaseName = getPascalCaseName(classFile);

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
                  ..named = true
                  ..type = refer('Key?', 'package:flutter/material.dart'),
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
                refer(pascalCaseName, 'package:flutter/material.dart')
                    .constInstance(
                      [],
                      {

                      },
                    )
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
          Directive.import('package:flutter/painting.dart'),
          Directive.import('package:vtgfull/ui/screens/about_screen.dart'),
        ],
      ),
  );

  final emitter = DartEmitter();

  return DartFormatter().format('${library.accept(emitter)}');
}

Future<void> codeGenGoldens(String projectName) async {
  final goldenWidgets = await findAllWidgets();
  final classFiles = <FileSystemEntity>[];

  Directory generateDir = Directory('$projectName/lib/generated');
  if (!await generateDir.exists()) {
    await generateDir.create();
  }

  for (final FileSystemEntity widgetFile in goldenWidgets) {
    print("Checking: ${getPascalCaseName(widgetFile)}");
    if(await checkFileViaAnalyzer(widgetFile.path)) {
      classFiles.add(widgetFile);
      final generatedPage = generateWidgetStoryPage(widgetFile);
      final fileName = path.join(
          generateDir.path, '${getKebabCaseName(widgetFile)}_storybook_widget.g.dart');
      await saveGeneratedPage(fileName, generatedPage);
    }
  }

  await saveGeneratedStoryFile(projectName, classFiles);
}
