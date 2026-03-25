import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:roblox_dart/compiler/macros/list_macros.dart';
import 'package:roblox_dart/compiler/macros/string_macros.dart';
import 'package:roblox_dart/compiler/macros/type_macros.dart';
import 'package:roblox_dart/luau/declaration/luau_anonymous_function.dart';
import 'package:roblox_dart/luau/expression/luau_assignment_expression.dart';
import 'package:roblox_dart/luau/expression/luau_binary_expression.dart';
import 'package:roblox_dart/luau/expression/luau_call_expression.dart';
import 'package:roblox_dart/luau/expression/luau_conditional_expression.dart';
import 'package:roblox_dart/luau/expression/luau_function_invocation.dart';
import 'package:roblox_dart/luau/expression/luau_index_expression.dart';
import 'package:roblox_dart/luau/expression/luau_list_literal.dart';
import 'package:roblox_dart/luau/expression/luau_map_literal.dart';
import 'package:roblox_dart/luau/statement/luau_do_statement.dart';
import 'package:roblox_dart/luau/statement/luau_expression_statement.dart';
import 'package:roblox_dart/luau/statement/luau_for_in_statement.dart';
import 'package:roblox_dart/luau/statement/luau_for_statement.dart';
import 'package:roblox_dart/luau/declaration/luau_function.dart';
import 'package:roblox_dart/luau/statement/luau_if_statement.dart';
import 'package:roblox_dart/luau/expression/luau_literal.dart';
import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/declaration/luau_parameter.dart';
import 'package:roblox_dart/luau/statement/luau_return_statement.dart';
import 'package:roblox_dart/luau/statement/luau_try_catch.dart';
import 'package:roblox_dart/luau/statement/luau_variable_declaration.dart';
import 'package:roblox_dart/luau/statement/luau_while_statement.dart';

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
    List<LuauNode> namedUnpackers = [];
    bool hasNamedParams = false;

    final paramList = node.functionExpression.parameters?.parameters;

    if (paramList != null) {
      for (var param in paramList) {
        final paramName = param.name?.lexeme ?? "";
        String? luauType;

        if (param is SimpleFormalParameter && param.type != null) {
          final dartType = param.type!.toSource();
          luauType = _translateType(dartType);
        } else if (param is DefaultFormalParameter &&
            param.parameter is SimpleFormalParameter) {
          final simpleParam = param.parameter as SimpleFormalParameter;
          if (simpleParam.type != null) {
            luauType = _translateType(simpleParam.type!.toSource());
          }
        }

        final typeString = luauType != null ? ": $luauType" : "";

        if (param is DefaultFormalParameter && param.defaultValue != null) {
          final defaultLego = param.defaultValue!.accept(this);

          if (defaultLego != null) {
            if (param.isNamed) {
              hasNamedParams = true;
              final extraction = LuauLiteral(
                value:
                    "local $paramName$typeString = if namedArgs and namedArgs.$paramName ~= nil then namedArgs.$paramName else ${defaultLego.emit()}",
              );
              namedUnpackers.add(
                LuauExpressionStatement(expression: extraction),
              );
            } else {
              fnParams.add(LuauParameter(name: paramName, type: luauType));
              final fallback = LuauLiteral(
                value:
                    "if $paramName == nil then\n\t\t$paramName = ${defaultLego.emit()}\n\tend",
              );
              namedUnpackers.add(LuauExpressionStatement(expression: fallback));
            }
          }
        } else if (param.isNamed) {
          hasNamedParams = true;
          final extraction = LuauLiteral(
            value: "local $paramName$typeString = namedArgs[\"$paramName\"]",
          );
          namedUnpackers.add(LuauExpressionStatement(expression: extraction));
        } else {
          fnParams.add(LuauParameter(name: paramName, type: luauType));
        }
      }
    }

    if (hasNamedParams) {
      fnParams.add(LuauParameter(name: "namedArgs", type: "any"));
    }

    final List<LuauNode> luauBody = [];

    luauBody.addAll(namedUnpackers);

    final body = node.functionExpression.body;
    if (body is BlockFunctionBody) {
      for (var statement in body.block.statements) {
        final childLego = statement.accept(this);

        if (childLego != null) {
          luauBody.add(childLego);
        }
      }
    } else if (body is ExpressionFunctionBody) {
      final legoValue = body.expression.accept(this);
      if (legoValue != null) {
        luauBody.add(LuauReturnStatement(expression: legoValue));
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
  LuauNode? visitFunctionExpressionInvocation(
    FunctionExpressionInvocation node,
  ) {
    final legoFunction = node.function.accept(this);
    if (legoFunction == null) return null;

    final finalLuauArgs = _processArguments(node.argumentList);

    return LuauFunctionInvocation(
      function: legoFunction,
      arguments: finalLuauArgs,
    );
  }

  @override
  LuauNode? visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) return null;

    List<LuauParameter> fnParams = [];

    final paramList = node.parameters?.parameters;

    if (paramList != null) {
      for (var param in paramList) {
        final paramName = param.name?.lexeme ?? "";
        String? luauType;

        if (param is SimpleFormalParameter && param.type != null) {
          luauType = _translateType(param.type!.toSource());
        }

        fnParams.add(LuauParameter(name: paramName, type: luauType));
      }
    }
    final List<LuauNode> luauBody = [];
    final body = node.body;

    if (body is BlockFunctionBody) {
      for (var statement in body.block.statements) {
        final childLego = statement.accept(this);

        if (childLego != null) luauBody.add(childLego);
      }
    } else if (body is ExpressionFunctionBody) {
      final legoValue = body.expression.accept(this);
      if (legoValue != null) {
        luauBody.add(LuauReturnStatement(expression: legoValue));
      }
    }

    return LuauAnonymousFunction(parameters: fnParams, body: luauBody);
  }

  @override
  LuauNode? visitCascadeExpression(CascadeExpression node) {
    final targetLego = node.target.accept(this);
    if (targetLego == null) return null;

    String innerCode = "local _c = ${targetLego.emit()}\n";

    for (var section in node.cascadeSections) {
      final sectionLego = section.accept(this);
      if (sectionLego != null) {
        innerCode += "\t\t_c.${sectionLego.emit()}\n";
      } else {
        String source = section.toSource().trim();
        if (source.startsWith("?..")) {
          innerCode += "\t\tif _c ~= nil then _c.${source.substring(3)} end\n";
        } else if (source.startsWith("..")) {
          innerCode += "\t\t_c.${source.substring(2)}\n";
        }
      }
    }
    innerCode += "\t\treturn _c";

    return LuauLiteral(value: "(function()\n\t\t$innerCode\nend)()");
  }

  @override
  LuauNode? visitAsExpression(AsExpression node) {
    final legoExpr = node.expression.accept(this);
    if (legoExpr != null) {
      final dartType = node.type.toSource();
      final luauType = _translateType(dartType) ?? "any";

      return LuauLiteral(value: "${legoExpr.emit()} :: $luauType");
    }
    return null;
  }

  @override
  LuauNode? visitIsExpression(IsExpression node) {
    final legoExpr = node.expression.accept(this);
    if (legoExpr != null) {
      final dartType = node.type.toSource();
      final luauType = _translateType(dartType) ?? "any";
      final operator = node.notOperator == null ? "==" : "~=";

      return LuauLiteral(
        value: "typeof(${legoExpr.emit()}) $operator '$luauType'",
      );
    }
    return null;
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
  LuauNode? visitNullLiteral(NullLiteral node) {
    return LuauLiteral(value: "nil");
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

      final isLeftString =
          node.leftOperand.staticType?.isDartCoreString ?? false;
      final isRightString =
          node.rightOperand.staticType?.isDartCoreString ?? false;

      if (operator == "+" && (isLeftString || isRightString)) {
        luauOperator = "..";
      }

      if (operator == "??") {
        final leftStr = leftLego.emit();

        final isSimple = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_.]*$').hasMatch(leftStr);

        if (isSimple) {
          return LuauLiteral(
            value:
                "(if $leftStr ~= nil then $leftStr else ${rightLego.emit()})",
          );
        } else {
          return LuauLiteral(
            value:
                "(function() local _v = $leftStr; if _v ~= nil then return _v else return ${rightLego.emit()} end end)()",
          );
        }
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
  LuauNode? visitPostfixExpression(PostfixExpression node) {
    final varLego = node.operand.accept(this);
    if (varLego != null) {
      final symbol = node.operator.lexeme;

      if (symbol == "++") {
        return LuauAssignmentExpression(
          left: varLego,
          operator: "+=",
          right: LuauLiteral(value: "1"),
        );
      } else if (symbol == "--") {
        return LuauAssignmentExpression(
          left: varLego,
          operator: "-=",
          right: LuauLiteral(value: "1"),
        );
      } else if (symbol == "!") {
        return varLego;
      }
    }
    return null;
  }

  @override
  LuauNode? visitMethodInvocation(MethodInvocation node) {
    final String methodName = node.methodName.name;
    final List<LuauNode> finalLuauArgs = _processArguments(node.argumentList);

    LuauNode? targetLego;
    bool isColon = false;

    if (node.target != null) {
      targetLego = node.target!.accept(this);

      final targetExpression = node.target!;
      bool isStaticClassAccess = false;

      final isList = targetExpression.staticType?.isDartCoreList ?? false;
      final isString = targetExpression.staticType?.isDartCoreString ?? false;
      final String targetName = targetExpression.toSource();

      final args = finalLuauArgs.map((a) => a.emit()).toList();

      // macros
      if (isList) {
        final result = ListMacros.resolve(methodName, targetLego!.emit(), args);
        if (result != null) return LuauLiteral(value: result);
      }

      if (isString) {
        final result = StringMacros.resolve(
          methodName,
          targetLego!.emit(),
          args,
        );
        if (result != null) return LuauLiteral(value: result);
      }

      if (targetName == "int" || targetName == "double") {
        final result = TypeMacros.resolve(methodName, targetLego!.emit(), args);
        if (result != null) return LuauLiteral(value: result);
      }

      // colon vs dot
      if (targetExpression is Identifier) {
        final element = targetExpression.element;

        if (element is ClassElement ||
            element is ExtensionElement ||
            element is PrefixElement) {
          isStaticClassAccess = true;
        }
      }

      const robloxNamespaces = {
        "math",
        "table",
        "string",
        "coroutine",
        "task",
        "Vector3",
        "Vector2",
        "CFrame",
        "Color3",
        "UDim2",
        "Instance",
      };

      if (isStaticClassAccess || robloxNamespaces.contains(targetName)) {
        isColon = false;
      } else {
        isColon = true;
      }
    }

    return LuauCallExpression(
      methodName: methodName,
      arguments: finalLuauArgs,
      target: targetLego,
      useColon: isColon,
    );
  }

  @override
  LuauNode? visitTryStatement(TryStatement node) {
    final List<LuauNode> tryBody = [];
    for (var statement in node.body.statements) {
      final lego = statement.accept(this);
      if (lego != null) tryBody.add(lego);
    }

    List<LuauNode> catchBody = [];
    String? errorName;

    if (node.catchClauses.isNotEmpty) {
      final clause = node.catchClauses.first;
      errorName = clause.exceptionParameter?.name.lexeme;

      for (var statement in clause.body.statements) {
        final lego = statement.accept(this);
        if (lego != null) catchBody.add(lego);
      }
    }

    return LuauTryCatch(
      tryBody: tryBody,
      errorName: errorName,
      catchBody: catchBody,
    );
  }

  @override
  LuauNode? visitSwitchStatement(SwitchStatement node) {
    final legoCondition = node.expression.accept(this);
    if (legoCondition == null) return null;

    List<LuauNode> cases = [];

    for (var member in node.members) {
      if (member is SwitchCase) {
        final legoCase = member.expression.accept(this);
        if (legoCase == null) continue;

        final condition = LuauBinaryExpression(
          left: legoCondition,
          operator: "==",
          right: legoCase,
        );

        final List<LuauNode> body = [];
        for (var statement in member.statements) {
          if (statement is BreakStatement) continue;
          final lego = statement.accept(this);
          if (lego != null) body.add(lego);
        }

        cases.add(
          LuauIfStatement(
            condition: condition,
            thenBranch: body,
            isElseIf: cases.isNotEmpty,
          ),
        );
      } else if (member is SwitchDefault) {
        final List<LuauNode> body = [];
        for (var statement in member.statements) {
          if (statement is BreakStatement) continue;
          final lego = statement.accept(this);
          if (lego != null) body.add(lego);
        }

        if (cases.isNotEmpty && body.isNotEmpty) {
          final lastIf = cases.last as LuauIfStatement;
          lastIf.elseBranch.addAll(body);
        }
      }
    }

    if (cases.isEmpty) return null;

    (cases.first as LuauIfStatement).isElseIf = false;

    return cases.first;
  }

  @override
  LuauNode? visitPropertyAccess(PropertyAccess node) {
    final targetLego = node.target?.accept(this);
    final propertyName = node.propertyName.name;

    final isList = node.target?.staticType?.isDartCoreList ?? false;
    final isString = node.target?.staticType?.isDartCoreString ?? false;

    if ((isList || isString) && propertyName == "length") {
      return LuauLiteral(value: "#${targetLego!.emit()}");
    }

    return LuauLiteral(value: "${targetLego!.emit()}.$propertyName");
  }

  @override
  LuauNode? visitPrefixedIdentifier(PrefixedIdentifier node) {
    final targetLego = node.prefix.accept(this);
    final propertyName = node.identifier.name;

    final isList = node.prefix.staticType?.isDartCoreList ?? false;
    final isString = node.prefix.staticType?.isDartCoreString ?? false;

    if ((isList || isString) && propertyName == 'length') {
      return LuauLiteral(value: "#${targetLego!.emit()}");
    }

    return LuauLiteral(value: "${targetLego!.emit()}.$propertyName");
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

  @override
  LuauNode? visitWhileStatement(WhileStatement node) {
    final legoCondition = node.condition.accept(this);

    if (legoCondition == null) return null;

    final backpackBody = _packBody(node.body);

    return LuauWhileStatement(condition: legoCondition, body: backpackBody);
  }

  @override
  LuauNode? visitForStatement(ForStatement node) {
    if (node.forLoopParts is ForPartsWithDeclarations) {
      final forParts = node.forLoopParts as ForPartsWithDeclarations;
      final legoInit = forParts.variables.accept(this);
      final legoCond = forParts.condition?.accept(this);

      final List<LuauNode> legoUpdaters = [];

      for (var updater in forParts.updaters) {
        final lego = updater.accept(this);
        if (lego != null) legoUpdaters.add(lego);
      }
      final backpackBody = _packBody(node.body);

      return LuauForStatement(
        initializer: legoInit,
        condition: legoCond,
        updaters: legoUpdaters,
        body: backpackBody,
      );
    } else if (node.forLoopParts is ForEachPartsWithDeclaration) {
      final forInParts = node.forLoopParts as ForEachPartsWithDeclaration;

      final itemName = forInParts.loopVariable.name.lexeme;
      final legoList = forInParts.iterable.accept(this);

      final isList = forInParts.iterable.staticType?.isDartCoreList ?? false;

      if (legoList != null) {
        return LuauForInStatement(
          itemName: itemName,
          list: legoList,
          body: _packBody(node.body),
          usePairs: !isList,
        );
      }
    }
    return null;
  }

  @override
  LuauNode? visitDoStatement(DoStatement node) {
    final legoCondition = node.condition.accept(this);
    if (legoCondition == null) return null;

    final backpackBody = _packBody(node.body);

    return LuauDoStatement(body: backpackBody, condition: legoCondition);
  }

  @override
  LuauNode? visitListLiteral(ListLiteral node) {
    final List<LuauNode> legoElements = [];

    for (var element in node.elements) {
      final lego = element.accept(this);
      if (lego != null) legoElements.add(lego);
    }

    return LuauListLiteral(elements: legoElements);
  }

  @override
  LuauNode? visitSetOrMapLiteral(SetOrMapLiteral node) {
    final Map<LuauNode, LuauNode> legoEntries = {};

    for (var element in node.elements) {
      if (element is MapLiteralEntry) {
        final key = element.key.accept(this);
        final value = element.value.accept(this);
        if (key != null && value != null) {
          legoEntries[key] = value;
        }
      }
    }

    return LuauMapLiteral(entries: legoEntries);
  }

  @override
  LuauNode? visitIndexExpression(IndexExpression node) {
    final legoTarget = node.target?.accept(this);
    LuauNode? legoIndex = node.index.accept(this);

    if (legoTarget != null && legoIndex != null) {
      final isList = node.target?.staticType?.isDartCoreList ?? false;
      if (isList) {
        legoIndex = LuauBinaryExpression(
          left: legoIndex,
          operator: "+",
          right: LuauLiteral(value: "1"),
        );
      }
      return LuauIndexExpression(target: legoTarget, index: legoIndex);
    }
    return null;
  }

  @override
  LuauNode? visitPrefixExpression(PrefixExpression node) {
    final operand = node.operand.accept(this);
    if (operand != null) {
      final operator = node.operator.lexeme;
      if (operator == "!") {
        return LuauLiteral(value: "not ${operand.emit()}");
      } else if (operator == "-") {
        return LuauLiteral(value: "-${operand.emit()}");
      }
    }
    return null;
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

  String? _translateType(String? dartType) {
    if (dartType == null || dartType == "void") return null;

    bool isNullable = dartType.endsWith("?");
    String cleanType = isNullable
        ? dartType.substring(0, dartType.length - 1)
        : dartType;

    const types = {
      "int": "number",
      "double": "number",
      "String": "string",
      "bool": "boolean",
    };

    String luauType = types[cleanType] ?? "any";

    return isNullable ? "$luauType?" : luauType;
  }

  List<LuauNode> _processArguments(ArgumentList argumentList) {
    final List<LuauNode> positionalArgs = [];
    final Map<LuauNode, LuauNode> namedArgs = {};

    for (var arg in argumentList.arguments) {
      if (arg is NamedExpression) {
        final keyName = arg.name.label.name;
        final keyLego = LuauLiteral(value: '"$keyName"');
        final valueLego = arg.expression.accept(this);

        if (valueLego != null) {
          namedArgs[keyLego] = valueLego;
        }
      } else {
        final argLego = arg.accept(this);
        if (argLego != null) {
          positionalArgs.add(argLego);
        }
      }
    }

    final List<LuauNode> finalLuauArgs = List.from(positionalArgs);

    if (namedArgs.isNotEmpty) {
      finalLuauArgs.add(LuauMapLiteral(entries: namedArgs));
    }

    return finalLuauArgs;
  }
}
