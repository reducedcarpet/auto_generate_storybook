import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

Future<List<ConstructorParameter>> getFirstConstructorParameters(String filePath) async {
  var collection = AnalysisContextCollection(includedPaths: [filePath]);
  var context = collection.contextFor(filePath);
  var result = await context.currentSession.getParsedUnit(filePath);

  if (result is ParsedUnitResult && result.unit != null) {
    var visitor = _FirstConstructorVisitor();
    result.unit!.accept(visitor);
    return visitor.constructorParameters;
  }

  return [];
}

class _FirstConstructorVisitor extends RecursiveAstVisitor<void> {
  List<ConstructorParameter> constructorParameters = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    Map<String, TypeAnnotation?> fieldTypes = {};
    for (final ClassMember member in node.members) {
      if (member is FieldDeclaration) {
        for (var variable in member.fields.variables) {
          if (variable.declaredElement == null && variable.isFinal) {
            fieldTypes[variable.name.toString()] = member.fields.type;
          }
        }
      }
    }

    final constructors = node.members.whereType<ConstructorDeclaration>();

    for (final ConstructorDeclaration constructor in constructors) {
      // If we already found a constructor, don't overwrite it.
      if (constructorParameters.isNotEmpty) {
        return;
      }

      for (final FormalParameter parameter in constructor.parameters.parameters) {
        if (parameter.isRequired) {
          final String? type = fieldTypes[parameter.name.toString()].toString();
          final String name = parameter.name.toString();
          constructorParameters.add(ConstructorParameter(name, type));
        }
      }
    }
  }
}

class ConstructorParameter {
  final String? name;
  final String? type;

  ConstructorParameter(this.name, this.type);

  @override
  String toString() => 'Type: $type, Name: $name';
}
