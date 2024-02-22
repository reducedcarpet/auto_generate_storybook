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

import 'visitors/primitive_parameters.dart';

Future<bool> checkFileViaAnalyzerStatelessWidgetWithParameters(String filePath) async {
  String fileContent = await File(filePath).readAsString();

  // Parse the file content
  ParseStringResult parseResult = parseString(content: fileContent, path: filePath);

  // Get the AST
  CompilationUnit compilationUnit = parseResult.unit;

  // Now you can explore the AST. For example, printing all class declarations:
  for (ClassDeclaration classDecl
      in compilationUnit.declarations.whereType<ClassDeclaration>()) {
    if (isStatelessWidget(compilationUnit, classDecl)) {
      if (widgetTakesOnlyPrimitiveParameters(compilationUnit)) {
        return true;
      }
    }
  }

  return false;
}

bool isStatelessWidget(CompilationUnit compilationUnit, ClassDeclaration classDecl) {
  if (classDecl.extendsClause == null) {
    return false;
  }

  if (classDecl.extendsClause?.superclass.toString() == 'StatelessWidget') {
    return true;
  }

  return false;
}
