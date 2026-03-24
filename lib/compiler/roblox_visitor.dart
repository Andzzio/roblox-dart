import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:roblox_dart/luau/luau_binary_expression.dart';
import 'package:roblox_dart/luau/luau_call_expression.dart';
import 'package:roblox_dart/luau/luau_function.dart';
import 'package:roblox_dart/luau/luau_literal.dart';
import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/luau_variable_declaration.dart';

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
  LuauNode? visitVariableDeclarationStatement(
    VariableDeclarationStatement node,
  ) {
    return node.variables.accept(this);
  }

  @override
  LuauNode? visitSimpleStringLiteral(SimpleStringLiteral node) {
    return LuauLiteral(value: node.toSource());
  }

  @override
  LuauNode? visitIntegerLiteral(IntegerLiteral node) {
    return LuauLiteral(value: node.toSource());
  }

  @override
  LuauNode? visitBinaryExpression(BinaryExpression node) {
    final leftLego = node.leftOperand.accept(this);
    final rightLego = node.rightOperand.accept(this);
    final operator = node.operator.lexeme;

    if (leftLego != null && rightLego != null) {
      String luauOperator = operator;
      if (operator == "+" &&
          (node.leftOperand is StringLiteral ||
              node.rightOperand is StringLiteral)) {
        luauOperator = "..";
      }
      return LuauBinaryExpression(
        left: leftLego,
        operator: luauOperator,
        right: rightLego,
      );
    }
    return null;
  }

  @override
  LuauNode? visitMethodInvocation(MethodInvocation node) {
    final String methodName = node.methodName.name;

    final List<LuauNode> methodArgs = [];

    for (var arg in node.argumentList.arguments) {
      final argLego = arg.accept(this);
      if (argLego != null) {
        methodArgs.add(argLego);
      }
    }

    return LuauCallExpression(methodName: methodName, arguments: methodArgs);
  }

  @override
  LuauNode? visitParenthesizedExpression(ParenthesizedExpression node) {
    final innerLego = node.expression.accept(this);

    if (innerLego != null) {
      final String value = "(${innerLego.emit()})";
      return LuauLiteral(value: value);
    }

    return null;
  }

  @override
  LuauNode? visitSimpleIdentifier(SimpleIdentifier node) {
    return LuauLiteral(value: node.name);
  }

  @override
  LuauNode? visitStringInterpolation(StringInterpolation node) {
    String luauInterpolatedText = "`";

    for (var element in node.elements) {
      final part = element.accept(this);

      if (part != null) {
        luauInterpolatedText += part.emit();
      }
    }
    luauInterpolatedText += "`";
    return LuauLiteral(value: luauInterpolatedText);
  }

  @override
  LuauNode? visitInterpolationExpression(InterpolationExpression node) {
    final innerLego = node.expression.accept(this);

    if (innerLego != null) {
      return LuauLiteral(value: "{${innerLego.emit()}}");
    }
    return null;
  }

  @override
  LuauNode? visitInterpolationString(InterpolationString node) {
    return LuauLiteral(value: node.value);
  }

  @override
  LuauNode? visitVariableDeclarationList(VariableDeclarationList node) {
    final declarationDart = node.variables.first;

    final name = declarationDart.name.lexeme;

    String? luauType;

    if (node.type != null) {
      final dartType = node.type!.toSource();

      const tipados = {
        "int": "number",
        "double": "number",
        "String": "string",
        "bool": "boolean",
      };

      luauType = tipados[dartType] ?? "any";
    }

    LuauNode? valueLego;

    if (declarationDart.initializer != null) {
      valueLego = declarationDart.initializer!.accept(this);
    }

    return LuauVariableDeclaration(
      name: name,
      initializer: valueLego,
      type: luauType,
    );
  }
}
