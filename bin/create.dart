import 'dart:io';

import 'package:args/args.dart';
import 'package:auto_generate_storybook/code_gen/code_gen_goldens.dart';
import 'package:auto_generate_storybook/code_gen/code_gen_main.dart';
import 'package:auto_generate_storybook/code_gen/code_gen_pubspec_yaml.dart';
import 'package:auto_generate_storybook/code_gen/code_gen_stories.dart';
import 'package:auto_generate_storybook/code_gen/code_gen_utils.dart';
import 'package:cli_util/cli_logging.dart';

import 'utils.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser();

  parser.addOption('path');
  parser.addOption('flavor');
  parser.addOption('flavors');

  final parsedArgs = parser.parse(args);

  if (parsedArgs['flavor'] != null && parsedArgs['flavors'] != null) {
    throw Exception('Cannot use both flavor and flavors arguments');
  }

  final path = parsedArgs['path'] as String?;

  final superProjectName = await getPackageName();

  createFlutterWebProject(path ?? "storybook", superProjectName!);
}

Future<void> createFlutterWebProject(String projectName, String superPackageName) async {
  // Define the command and arguments
  String command = "flutter";
  var arguments = ['create', '--platforms', 'web', projectName];

  // Start the process
  var process = await Process.start(command, arguments, runInShell: true);

  // Capture and print the output
  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);

  // Wait for the process to complete and get the exit code
  var exitCode = await process.exitCode;
  if (exitCode == 0) {
    print('Project $projectName created successfully.');
  } else {
    print('Failed to create project $projectName.');
  }

  if (exitCode != 0) {
    return;
  }

  Logger.standard().stdout('Project $projectName created successfully.');

  // generate code
  await codeGenGoldens(projectName);
  Logger.standard().stdout('Project $projectName generated goldens successfully.');

  await moveGoldensToAssets(projectName);
  Logger.standard().stdout('Project $projectName copied golden images to assets successfully.');

  saveGeneratedStoryFile(projectName);
  Logger.standard().stdout('Project $projectName generated stories.dart successfully.');

  saveGeneratedMainFile(projectName);
  Logger.standard().stdout('Project $projectName generated main.dart successfully.');

  saveGeneratedPubSpecFile(projectName);
  Logger.standard().stdout('Project $projectName generated pubspec.yaml successfully.');

  String commandBuild = "flutter";
  var argumentsBuild = ['build', 'web'];

  // Start the Build process
  var processBuild = await Process.start(
    commandBuild,
    argumentsBuild,
    runInShell: true,
    workingDirectory: projectName,
  );

  // Capture and print the output
  await stdout.addStream(processBuild.stdout);
  await stderr.addStream(processBuild.stderr);

  // Wait for the process to complete and get the exit code
  await processBuild.exitCode;
}
