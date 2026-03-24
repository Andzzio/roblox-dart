import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:roblox_dart/luau/luau_assignment_expression.dart';
import 'package:roblox_dart/luau/luau_binary_expression.dart';
import 'package:roblox_dart/luau/luau_call_expression.dart';
import 'package:roblox_dart/luau/luau_conditional_expression.dart';
import 'package:roblox_dart/luau/luau_expression_statement.dart';
import 'package:roblox_dart/luau/luau_function.dart';
import 'package:roblox_dart/luau/luau_if_statement.dart';
import 'package:roblox_dart/luau/luau_literal.dart';
import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/luau_parameter.dart';
import 'package:roblox_dart/luau/luau_return_statement.dart';
import 'package:roblox_dart/luau/luau_variable_declaration.dart';
import 'package:roblox_dart/luau/luau_while_statement.dart';

class RobloxVisitor extends SimpleAstVisitor<LuauNode> {
  @override
  LuauNode? visitFunctionDeclaration(FunctionDeclaration node) {
    final String functionName = node.name.lexeme;
    String? returnTypeLuau;

    if (node.returnType != null) {
      final dartType = node.returnType!.toSource();
      returnTypeLuau = _translateType(dartType);
    }

    List<LuauParameter> fnParams = [];
    final paramList = node.functionExpression.parameters?.parameters;

    if (paramList != null) {
      for (var param in paramList) {
        final paramName = param.name?.lexeme ?? "";
        String? luauType;

        if (param is SimpleFormalParameter && param.type != null) {
          final dartType = param.type!.toSource();
          luauType = _translateType(dartType);
        }
        fnParams.add(LuauParameter(name: paramName, type: luauType));
      }
    }

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

    return LuauFunction(
      name: functionName,
      body: luauBody,
      parameters: fnParams,
      returnType: returnTypeLuau,
    );
  }

  @override
  LuauNode? visitReturnStatement(ReturnStatement node) {
    LuauNode? legoValue;

    if (node.expression != null) {
      legoValue = node.expression!.accept(this);
    }

    return LuauReturnStatement(expression: legoValue);
  }

  @override
  LuauNode? visitExpressionStatement(ExpressionStatement node) {
    final lego = node.expression.accept(this);
    if (lego != null) {
      return LuauExpressionStatement(expression: lego);
    }
    return null;
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
  LuauNode? visitBooleanLiteral(BooleanLiteral node) {
    return LuauLiteral(value: node.toSource());
  }

  @override
  LuauNode? visitBinaryExpression(BinaryExpression node) {
    final leftLego = node.leftOperand.accept(this);
    final rightLego = node.rightOperand.accept(this);
    final operator = node.operator.lexeme;

    if (leftLego != null && rightLego != null) {
      const dartOperators = {"!=": "~=", "&&": "and", "||": "or"};

      String luauOperator = dartOperators[operator] ?? operator;
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
  LuauNode? visitAssignmentExpression(AssignmentExpression node) {
    final leftLego = node.leftHandSide.accept(this);
    final rightLego = node.rightHandSide.accept(this);

    if (leftLego != null && rightLego != null) {
      return LuauAssignmentExpression(
        left: leftLego,
        operator: node.operator.lexeme,
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

      luauType = _translateType(dartType);
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

  List<LuauNode> _packBody(Statement dartCode) {
    List<LuauNode> backpack = [];

    if (dartCode is Block) {
      for (var statement in dartCode.statements) {
        final lego = statement.accept(this);
        if (lego != null) backpack.add(lego);
      }
    } else {
      final lego = dartCode.accept(this);
      if (lego != null) backpack.add(lego);
    }
    return backpack;
  }

  @override
  LuauNode? visitIfStatement(IfStatement node) {
    final legoCondition = node.expression.accept(this);

    if (legoCondition == null) return null;

    final backpackThen = _packBody(node.thenStatement);
    List<LuauNode> backpackElse = [];

    if (node.elseStatement != null) {
      if (node.elseStatement is IfStatement) {
        final elseIfNode = node.elseStatement!.accept(this);
        if (elseIfNode is LuauIfStatement) {
          elseIfNode.isElseIf = true;
          backpackElse.add(elseIfNode);
        }
      } else {
        backpackElse = _packBody(node.elseStatement!);
      }
    }

    return LuauIfStatement(
      condition: legoCondition,
      thenBranch: backpackThen,
      elseBranch: backpackElse,
    );
  }

  @override
  LuauNode? visitConditionalExpression(ConditionalExpression node) {
    final legoConditional = node.condition.accept(this);
    final legoThen = node.thenExpression.accept(this);
    final legoElse = node.elseExpression.accept(this);

    if (legoConditional != null && legoThen != null && legoElse != null) {
      return LuauConditionalExpression(
        condition: legoConditional,
        thenExpression: legoThen,
        elseExpression: legoElse,
      );
    }
    return null;
  }

  String? _translateType(String? dartType) {
    if (dartType == null || dartType == "void") return null;
    const types = {
      "int": "number",
      "double": "number",
      "String": "string",
      "bool": "boolean",
    };

    return types[dartType] ?? "any";
  }

  @override
  LuauNode? visitWhileStatement(WhileStatement node) {
    final legoCondition = node.condition.accept(this);

    if (legoCondition == null) return null;

    final backpackBody = _packBody(node.body);

    return LuauWhileStatement(condition: legoCondition, body: backpackBody);
  }
}
