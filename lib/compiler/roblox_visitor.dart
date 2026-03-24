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

    final String methodArgs = node.argumentList.arguments
        .map((arg) => arg.toSource())
        .join(", ");

    luauOutput += "\t$methodName($methodArgs)\n\n";

    super.visitMethodInvocation(node);
  }
}
