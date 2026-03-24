import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class RobloxVisitor extends RecursiveAstVisitor<void> {
  String luauOutput = "";

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final String functionName = node.name.lexeme;

    luauOutput += "local function $functionName()\n";

    super.visitFunctionDeclaration(node);

    luauOutput += "end\n\n";

    if (functionName == "main") {
      luauOutput += "$functionName()\n\n";
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final String methodName = node.methodName.name;

    if (methodName == "print") {
      final String rawArg = node.argumentList.arguments.first.toSource();

      luauOutput += "\tprint($rawArg)\n";
    }

    super.visitMethodInvocation(node);
  }
}
