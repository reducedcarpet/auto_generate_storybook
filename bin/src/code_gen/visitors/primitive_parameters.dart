import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

bool widgetTakesOnlyPrimitiveParameters(CompilationUnit unit) {
  StatelessWidgetVisitor visitor = StatelessWidgetVisitor();
  unit.accept(visitor);
  return visitor.takesOnlyPrimitiveParameters;
}

class StatelessWidgetVisitor extends RecursiveAstVisitor<void> {
  bool takesOnlyPrimitiveParameters = true;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    //print("VISIITING CLASS DECLARATION: ${node.name}");

    Map<String, TypeAnnotation?> fieldTypes = {};
    for (var member in node.members) {
      if (member is FieldDeclaration) {
        for (var variable in member.fields.variables) {
          if (variable.declaredElement == null && variable.isFinal) {
            fieldTypes[variable.name.toString()] = member.fields.type;
          }
        }
      }
    }

    //print("FIELDS: ${fieldTypes.keys}");

    var constructors = node.members.whereType<ConstructorDeclaration>();
    if(constructors.isEmpty) {
      takesOnlyPrimitiveParameters = true;
      return;
    }

    for (var constructor in constructors) {

      for (var parameter in constructor.parameters.parameters) {
        String? parameterType;

        if (parameter.declaredElement == null && fieldTypes.containsKey(parameter.name.toString())) {
          // Field-formal parameter, get type from class field
          parameterType = fieldTypes[parameter.name.toString()].toString();
        } else {
          // Regular parameter, get the type directly
          parameterType = parameter.declaredElement?.type.toString();
        }

        if (parameterType != null && !isPrimitiveType(parameterType) && parameter.isRequired) {
          takesOnlyPrimitiveParameters = false;
          return;
        }
      }

      //if(constructor.parameters.parameters.isEmpty) {
      //  takesOnlyPrimitiveParameters = false;
      //  return;
      //}

      //for (var parameter in constructor.parameters.parameters) {
      //  var type = parameter.declaredElement?.type;
      //  print("Parameter: $parameter");

      //  if (type != null && !isPrimitiveType(type.toString()) && parameter.isRequired) {
      //    takesOnlyPrimitiveParameters = false;
      //    return;
      //  }
      //}
    }
  }

  bool isPrimitiveType(String type) {
    return ['int', 'double', 'String', 'bool', 'num'].contains(type);
  }
}
