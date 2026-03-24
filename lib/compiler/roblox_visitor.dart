import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:roblox_dart/luau/luau_call_expression.dart';
import 'package:roblox_dart/luau/luau_function.dart';
import 'package:roblox_dart/luau/luau_node.dart';

class RobloxVisitor extends SimpleAstVisitor<LuauNode> {
  @override
  LuauNode? visitFunctionDeclaration(FunctionDeclaration node) {
    final String functionName = node.name.lexeme;
    final List<LuauNode> luauBody = [];

    final body = node.functionExpression.body;
    if (body is BlockFunctionBody) {
      for (var statement in body.block.statements) {
        final childLego = statement.accept(this);

        if (childLego != null) {
          luauBody.add(childLego);
        }
      }
    }

    return LuauFunction(name: functionName, body: luauBody);
  }

  @override
  LuauNode? visitExpressionStatement(ExpressionStatement node) {
    return node.expression.accept(this);
  }

  @override
  LuauNode? visitMethodInvocation(MethodInvocation node) {
    final String methodName = node.methodName.name;

    final String methodArgs = node.argumentList.arguments
        .map((arg) => arg.toSource())
        .join(", ");

    return LuauCallExpression(methodName: methodName, arguments: methodArgs);
  }
}
