import 'package:args/args.dart';
import 'src/code_gen/story_files/code_gen_story_files_stateless.dart';
import 'src/code_gen/code_gen_main.dart';
import 'src/code_gen/code_gen_pubspec_yaml.dart';
import 'src/code_gen/code_gen_storybook_adaptor.dart';
import 'src/utils/file_utils.dart';
import 'package:cli_util/cli_logging.dart';

import 'src/defaults.dart';
import 'src/flutter_commands.dart';
import 'src/utils/utils.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser();

  parser.addOption('name');

  final parsedArgs = parser.parse(args);

  String? projectName = parsedArgs['name'] as String?;
  projectName ??= await getProjectName();

  final superProjectName = await getPackageName();

  createFlutterWebProject(
    projectName ?? projectNameDefault,
    superProjectName!,
  );
}

Future<void> createFlutterWebProject(String projectName, String superPackageName) async {
  // TODO check first for test directory to find goldens.

  final int exitCode = await flutterCreateWeb(projectName);

  if (exitCode != 0) {
    return;
  }

  Logger.standard().stdout('Project $projectName created successfully within $superPackageName.');

  deleteTestDirectory(projectName);
  Logger.standard().stdout('Deleted Test Directory of new Project.');

  await generateCode(projectName, superPackageName);

  //await dartFixApply(projectName);

  //await flutterBuildWeb(projectName);
}

Future<void> generateCode(String projectName, String originalProjectName) async {
  // generate code
  await codeGenStoryFiles(projectName, originalProjectName);
  Logger.standard().stdout('Project $projectName generated goldens successfully.');
  Logger.standard().stdout('Project $projectName generated stories.dart successfully.');

  saveGeneratedMainFile(projectName);
  Logger.standard().stdout('Project $projectName generated main.dart successfully.');

  // pull in dependencies from top-level pubspec, along with assets and fonts.
  await saveGeneratedPubSpecFile(projectName);
  Logger.standard().stdout('Project $projectName generated pubspec.yaml successfully.');

  await saveGeneratedStorybookAdaptorFile(projectName);
  Logger.standard().stdout('Project $projectName generated storybook_adaptor.dart successfully.');
}
