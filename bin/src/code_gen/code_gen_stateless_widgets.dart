// load string from file
// check from file if it is a stateless widget
// do I need to create a instantiation of the widget to discover stuff about it?

// discover stateless widget name
// instantiate it in a story.
// generate mock data for widget.
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';

Future<String> readFileContent(FileSystemEntity file) async {
  if (file is File) {
    return await file.readAsString();
  } else {
    return ''; // Or handle the case where the entity is not a file (e.g., a directory)
  }
}

bool containsStatelessWidget(String fileContent) {
  // This is a simple and naive way to check; it might not be accurate
  return fileContent.contains('extends StatelessWidget');
}

bool containsStatefulWidget(String fileContent) {
  // This is a simple and naive way to check; it might not be accurate
  return fileContent.contains('extends StatefulWidget');
}

Future<bool> checkFileForStatelessWidget(FileSystemEntity file) async {
  String content = await readFileContent(file);
  return containsStatelessWidget(content);
}

Future<bool> checkFileViaAnalyzerStatelessWidgets(String filePath) async {
  String fileContent = await File(filePath).readAsString();

  // Parse the file content
  ParseStringResult parseResult = parseString(content: fileContent, path: filePath);

  // Get the AST
  CompilationUnit compilationUnit = parseResult.unit;

  // Now you can explore the AST. For example, printing all class declarations:
  for (ClassDeclaration classDecl
      in compilationUnit.declarations.whereType<ClassDeclaration>()) {
    if (isStatelessWidget(compilationUnit, classDecl)) {
      if (hasEmptyOrDefaultConstructor(compilationUnit, classDecl.name.toString())) {
        return true;
      }
    }
  }

  return false;
}

bool hasEmptyOrDefaultConstructor(CompilationUnit unit, String className) {
  final classDeclaration = unit.declarations.whereType<ClassDeclaration?>().firstWhere(
        (declaration) => declaration?.name.toString() == className,
        orElse: () => null,
      );

  if (classDeclaration == null) return false;

  // Check if there's an explicit constructor
  final constructors = classDeclaration.members.whereType<ConstructorDeclaration>();
  if (constructors.isEmpty) {
    // No explicit constructors, so a default constructor is implied
    return true;
  }

  // Check if any constructor is empty or has only optional parameters
  return constructors.any((constructor) {
    final parameters = constructor.parameters.parameters;
    return parameters.isEmpty || parameters.every((param) => param.isOptional);
  });
}

bool isStatelessWidget(CompilationUnit compilationUnit, ClassDeclaration classDecl) {
  if (classDecl.extendsClause == null) {
    return false;
  }

  if (classDecl.extendsClause?.superclass.toString() == 'StatelessWidget') {
    return true;
  }

  return false;

  final superClassElement = classDecl.extendsClause!.superclass.element;

  if (classDecl.extendsClause!.superclass.name2.isIdentifier) {
    final nextClass = findClassByName(
      compilationUnit,
      classDecl.extendsClause!.superclass.toString(),
    );
    print("nextClass: $nextClass");
  }

  if (superClassElement is ClassElement) {
    // Get the ClassDeclaration for the superclass
    final classElement = superClassElement;
    var superClassDeclaration = classElement.declaration as ClassDeclaration;

    print("superClassDeclaration: $superClassDeclaration");

    return isStatelessWidget(compilationUnit, superClassDeclaration);
  }

  return classDecl.extendsClause!.superclass.toString() == 'StatelessWidget';
}

ClassDeclaration? findClassByName(CompilationUnit unit, String className) {
  print("CHECKING CLASS: " + className);
  print("NUmber of declarations: " + unit.declarations.length.toString());
  int index = 0;
  for (CompilationUnitMember declaration in unit.declarations) {
    if (declaration is ClassDeclaration) {
      print("CHECKING: " + declaration.name.lexeme.toString());
    }

    if (declaration is ClassDeclaration && declaration.name.lexeme == className) {
      print("\n\nFOUND IT!");
      return declaration;
    }
    index++;
  }
  print("Returning null having checked $index classes.");

  return null;
}
