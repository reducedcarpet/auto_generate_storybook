import 'dart:io';

import 'code_gen_utils.dart';
import '../utils/recursive_utils.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

import 'code_gen_constants.dart';

Future<String> generateStoryFile(String projectName, List<FileSystemEntity> classFiles) async {
  final List<FileSystemEntity> allWidgets = classFiles;
  final List<Expression> stories = await generateAllStories(allWidgets);
  final List<Directive> directives = await generateAllDirectives(
    allWidgets,
    projectName,
  );

  final field = Field((b) => b
    ..name = 'stories'
    ..type = refer('List<Story>')
    ..modifier = FieldModifier.final$
    ..assignment = literalList(stories, refer('Story')).code);

  final library = Library(
    (b) => b
      ..body.add(field)
      ..directives.addAll(
        [
          Directive.import('package:storybook_flutter/storybook_flutter.dart'),
          ...directives,
        ],
      ),
  );

  final emitter = DartEmitter();

  return DartFormatter().format('${library.accept(emitter)}');
}

Future<void> saveGeneratedStoryFileStateless(String projectName, List<FileSystemEntity> classNames) async {
  final content = generateStoryFile(projectName, classNames);
  final file = File('$projectName/lib/generated/$storiesFileName');
  file.writeAsStringSync(await content);
}

Expression generateStoryObjectForClass(String className, String path, String name) {
  final field = refer('Story').newInstance(
    [],
    {
      'name': literal("$path$name"),
      'builder': Method(
        (b) => b
          ..lambda = true
          ..requiredParameters.add(Parameter((b) => b..name = '_'))
          ..body = refer('${className}StorybookScreen').constInstance(
            [],
          ).code,
      ).closure,
    },
  );

  return field;
}

Directive generateDirectiveForWidget(FileSystemEntity widgetFile, String projectName) {
  final fileName = '${getKebabCaseName(widgetFile)}_storybook_widget.g.dart';
  return Directive.import('package:$projectName/generated/$fileName');
}

Future<List<Directive>> generateAllDirectives(
  List<FileSystemEntity> goldenImages,
  String projectName,
) async {
  final List<Directive> directives = [];

  for (final FileSystemEntity fileEntity in goldenImages) {
    var entityType = await FileSystemEntity.type(fileEntity.path);
    if (entityType != FileSystemEntityType.file) {
      continue;
    }

    Logger.standard().stdout('Generating Story object for $fileEntity');

    directives.add(generateDirectiveForWidget(fileEntity, projectName));
  }

  return directives;
}

Future<List<Expression>> generateAllStories(List<FileSystemEntity> classNames) async {
  final List<Expression> stories = [];

  for (final FileSystemEntity className in classNames) {
    Logger.standard().stdout('Generating Story object for $className');

    String basename = getPascalCaseName(className);
    String originalName = path.basenameWithoutExtension(className.path);
    originalName = ReCase(originalName).pascalCase;

    String relative = relativePath(className);

    stories.add(
      generateStoryObjectForClass(
        basename,
        relative,
        originalName,
      ),
    );
  }

  return stories;
}
