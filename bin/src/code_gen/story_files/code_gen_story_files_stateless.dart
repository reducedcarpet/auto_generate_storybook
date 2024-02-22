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

import 'code_gen_story_files_stateless_parameters.dart';

String generateStatelessWidgetStoryPage(
    FileSystemEntity classFile, String originalProjectName,) {
  final String basename = path.basename(classFile.path);
  ReCase reCase = ReCase(path.withoutExtension(basename));
  final String pascalCaseName = reCase.pascalCase;

  String dirPascalCaseName = getPascalCaseName(classFile);

  final childInstance = refer(pascalCaseName).newInstance([]);

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

Future<void> codeGenStoryFiles(String projectName, String originalProjectName) async {
  final goldenWidgets = await findAllWidgets();
  final statelessFiles = <FileSystemEntity>[];
  final statelessParameterFiles = <FileSystemEntity>[];
  final statefulFiles = <FileSystemEntity>[];

  Directory generateDir = Directory('$projectName/lib/generated');
  if (!await generateDir.exists()) {
    await generateDir.create();
  }

  for (final FileSystemEntity widgetFile in goldenWidgets) {
    print("Checking: ${getPascalCaseName(widgetFile)}");

    if (await checkFileViaAnalyzerStatelessWidgets(widgetFile.path)) {
      statelessFiles.add(widgetFile);

      final generatedPage = generateStatelessWidgetStoryPage(
        widgetFile,
        originalProjectName,
      );
      final fileName = path.join(
        generateDir.path,
        '${getKebabCaseName(widgetFile)}_storybook_widget.g.dart',
      );
      await saveGeneratedPage(fileName, generatedPage);
    }

    else if (await checkFileViaAnalyzerStatelessWidgetWithParameters(widgetFile.path)) {
      if(statefulFiles.contains(widgetFile)) {
        continue;
      }

      statelessParameterFiles.add(widgetFile);
      final generatedPage = await generateStatelessWidgetParametersStoryPage(
        widgetFile,
        originalProjectName,
      );
      final fileName = path.join(
        generateDir.path,
        '${getKebabCaseName(widgetFile)}_storybook_widget.g.dart',
      );
      await saveGeneratedPage(fileName, generatedPage);
    }
  }

  final allFiles = <FileSystemEntity>{};
  allFiles.addAll(statelessFiles);
  allFiles.addAll(statelessParameterFiles);

  await saveGeneratedStoryFileStateless(projectName, allFiles.toList());
}

String generateProjectImport(String originalProjectName, FileSystemEntity classFile) {
  String path = subtractLibPath(classFile);
  path = path.replaceAll("\\", "/");
  return "package:$originalProjectName/${path}";
}
