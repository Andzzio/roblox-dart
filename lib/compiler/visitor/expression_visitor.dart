import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:roblox_dart/compiler/compiler_logger.dart';
import 'package:roblox_dart/compiler/macros/list_macros.dart';
import 'package:roblox_dart/compiler/macros/macro_resolver.dart';
import 'package:roblox_dart/compiler/macros/string_macros.dart';
import 'package:roblox_dart/compiler/macros/type_macros.dart';
import 'package:roblox_dart/compiler/visitor/roblox_visitor_base.dart';
import 'package:roblox_dart/luau/declaration/luau_anonymous_function.dart';
import 'package:roblox_dart/luau/declaration/luau_parameter.dart';
import 'package:roblox_dart/luau/expression/luau_assignment_expression.dart';
import 'package:roblox_dart/luau/expression/luau_binary_expression.dart';
import 'package:roblox_dart/luau/expression/luau_call_expression.dart';
import 'package:roblox_dart/luau/expression/luau_function_invocation.dart';
import 'package:roblox_dart/luau/expression/luau_literal.dart';
import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/statement/luau_pair_for_each.dart';
import 'package:roblox_dart/luau/statement/luau_return_statement.dart';

mixin ExpressionVisitor on RobloxVisitorBase {
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
    final left = node.leftHandSide;
    final right = node.rightHandSide.accept(this);
    if (right == null) return null;

    if (left is SimpleIdentifier) {
      final element = left.element;
      if (element != null) {
        try {
          final dynamic dynElem = element;
          if (dynElem.isSetter == true) {
            bool isInstance = !dynElem.isStatic &&
                element.enclosingElement is InterfaceElement;
            return LuauCallExpression(
              target: isInstance ? LuauLiteral(value: "self") : null,
              methodName: "set_${left.name}",
              arguments: [right],
              useColon: isInstance,
            );
          }
        } catch (e) {
          CompilerLogger.debug('isSetter check failed (SimpleIdentifier): $e');
        }
      }
    }

    if (left is PropertyAccess) {
      final property = left.propertyName;
      final element = property.element;
      if (element != null) {
        try {
          final dynamic dynElem = element;
          if (dynElem.isSetter == true) {
            if (!MacroResolver.isRobloxType(left.target?.staticType)) {
              final targetLego = left.target?.accept(this);
              return LuauCallExpression(
                target: targetLego,
                methodName: "set_${property.name}",
                arguments: [right],
                useColon: true,
              );
            }
          }
        } catch (e) {
          CompilerLogger.debug('isSetter check failed (PropertyAccess): $e');
        }
      }
    }

    if (left is PrefixedIdentifier) {
      final property = left.identifier;
      final element = property.element;
      if (element != null) {
        try {
          final dynamic dynElem = element;
          if (dynElem.isSetter == true) {
            if (!MacroResolver.isRobloxType(left.prefix.staticType)) {
              final targetLego = left.prefix.accept(this);
              return LuauCallExpression(
                target: targetLego,
                methodName: "set_${property.name}",
                arguments: [right],
                useColon: true,
              );
            }
          }
        } catch (e) {
          CompilerLogger.debug('isSetter check failed (PropertyAccess): $e');
        }
      }
    }

    final leftLego = left.accept(this);

    if (node.operator.lexeme == "??=") {
      final leftStr = leftLego!.emit();
      return LuauLiteral(
        value: "if $leftStr == nil then $leftStr = ${right.emit()} end",
      );
    }

    if (leftLego != null) {
      return LuauAssignmentExpression(
        left: leftLego,
        right: right,
        operator: node.operator.lexeme,
      );
    }
    return null;
  }

  @override
  LuauNode? visitPostfixExpression(PostfixExpression node) {
    final varLego = node.operand.accept(this);
    if (varLego != null) {
      final symbol = node.operator.lexeme;

      if (symbol == "++" || symbol == "--") {
        final op = symbol == "++" ? "+=" : "-=";

        bool isStatement =
            node.parent is ExpressionStatement || node.parent is ForParts;

        if (isStatement) {
          return LuauAssignmentExpression(
            left: varLego,
            operator: op,
            right: LuauLiteral(value: "1"),
          );
        } else {
          final varStr = varLego.emit();
          return LuauLiteral(
            value:
                "(function() local _v = $varStr; $varStr $op 1; return _v end)()",
          );
        }
      } else if (symbol == "!") {
        return varLego;
      }
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
      } else if (operator == "~") {
        return LuauLiteral(value: "bit32.bnot(${operand.emit()})");
      } else if (operator == "++" || operator == "--") {
        final op = operator == "++" ? "+=" : "-=";

        bool isStatement =
            node.parent is ExpressionStatement || node.parent is ForParts;

        if (isStatement) {
          return LuauAssignmentExpression(
            left: operand,
            operator: op,
            right: LuauLiteral(value: "1"),
          );
        } else {
          final varStr = operand.emit();
          return LuauLiteral(
            value: "(function() $varStr $op 1; return $varStr end)()",
          );
        }
      }
    }
    return null;
  }

  @override
  LuauNode? visitMethodInvocation(MethodInvocation node) {
    final String methodName = node.methodName.name;
    final List<LuauNode> finalLuauArgs = processArguments(node.argumentList);

    LuauNode? targetLego;
    bool isColon = false;
    LuauNode? resultNode;

    if (node.target != null) {
      final targetExpression = node.target!;

      if (targetExpression is SuperExpression) {
        final superTargetName = currentSuperClassName ?? "super";
        targetLego = LuauLiteral(value: superTargetName);
        isColon = false;
        finalLuauArgs.insert(0, LuauLiteral(value: "self"));
      } else {
        targetLego = targetExpression.accept(this);

        bool isStaticClassAccess = false;

        final isList = targetExpression.staticType?.isDartCoreList ?? false;
        final isString = targetExpression.staticType?.isDartCoreString ?? false;
        final isMap = targetExpression.staticType?.isDartCoreMap ?? false;
        final String targetName = targetExpression.toSource();

        final args = finalLuauArgs.map((a) => a.emit()).toList();

        if (isList) {
          final result = ListMacros.resolve(
            methodName,
            targetLego?.emit() ?? (node.isCascaded ? "_c" : "self"),
            args,
          );
          if (result != null) resultNode = LuauLiteral(value: result);
        }

        if (resultNode == null &&
            targetName == "DateTime" &&
            methodName == "now") {
          resultNode = LuauLiteral(value: "os.date('%Y-%m-%d %H:%M:%S')");
        }

        if (resultNode == null &&
            isMap &&
            methodName == "forEach" &&
            finalLuauArgs.length == 1) {
          resultNode = LuauPairForEach(
            target: targetLego ?? LuauLiteral(value: "_c"),
            callback: finalLuauArgs[0],
          );
        }

        if (resultNode == null && isString) {
          final result = StringMacros.resolve(
            methodName,
            targetLego?.emit() ?? (node.isCascaded ? "_c" : "self"),
            args,
          );
          if (result != null) resultNode = LuauLiteral(value: result);
        }

        if (resultNode == null &&
            (targetName == "int" || targetName == "double")) {
          final result = TypeMacros.resolve(
            methodName,
            targetLego!.emit(),
            args,
          );
          if (result != null) resultNode = LuauLiteral(value: result);
        }

        if (resultNode == null &&
            targetName == "Instance" &&
            methodName == "of") {
          final typeArgs = node.typeArguments?.arguments;
          if (typeArgs != null && typeArgs.isNotEmpty) {
            final typeName = typeArgs.first.toSource().split('<').first;
            resultNode = LuauLiteral(value: 'Instance.new("$typeName")');
          }
        }

        if (resultNode == null) {
          final result = MacroResolver.resolveMethod(
            targetExpression.staticType,
            methodName,
            targetLego?.emit() ?? (node.isCascaded ? "_c" : "self"),
            args,
          );
          if (result != null) resultNode = LuauLiteral(value: result);
        }

        if (resultNode == null) {
          if (targetExpression is Identifier) {
            final element = targetExpression.element;

            if (element is ClassElement ||
                element is ExtensionElement ||
                element is PrefixElement) {
              isStaticClassAccess = true;
            }
          }

          const luauBuiltins = {"math", "table", "string", "coroutine", "task"};

          if (isStaticClassAccess || luauBuiltins.contains(targetName)) {
            isColon = false;
          } else {
            isColon = true;
          }
        }
      }
    } else {
      isColon = node.isCascaded;
      if (!isColon && currentClassName != null) {
        if (currentClassMembers.contains(methodName) ||
            allClassMembers.contains(methodName)) {
          targetLego = LuauLiteral(value: "self");
          isColon = true;
        }
      }
      //
    }

    if (resultNode == null) {
      final args = finalLuauArgs.map((a) => a.emit()).toList();
      final target = targetLego?.emit() ?? (node.isCascaded ? "_c" : "self");
      final result = TypeMacros.resolve(methodName, target, args);
      if (result != null) resultNode = LuauLiteral(value: result);
    }

    resultNode ??= LuauCallExpression(
      methodName: methodName,
      arguments: finalLuauArgs,
      target: targetLego,
      useColon: isColon,
    );

    if (node.isNullAware && targetLego != null) {
      return LuauLiteral(
        value:
            "(if ${targetLego.emit()} ~= nil then ${resultNode.emit()} else nil)",
      );
    }

    return resultNode;
  }

  @override
  LuauNode? visitFunctionExpressionInvocation(
    FunctionExpressionInvocation node,
  ) {
    final legoFunction = node.function.accept(this);
    if (legoFunction == null) return null;

    final finalLuauArgs = processArguments(node.argumentList);

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
          luauType = translateType(param.type!.toSource());
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
  LuauNode? visitPropertyAccess(PropertyAccess node) {
    final target = node.target?.accept(this);
    final property = node.propertyName;
    final element = property.element;

    CompilerLogger.debug(
      "PropertyAccess: ${node.toSource()}, element: ${element?.runtimeType}",
    );

    if (MacroResolver.isRobloxType(node.target?.staticType)) {
      final result = MacroResolver.resolveProperty(
        node.target?.staticType,
        property.name,
        target?.emit() ?? '_c',
      );
      if (result != null) {
        if (node.isNullAware) {
          return LuauLiteral(
            value: "(if ${target!.emit()} ~= nil then $result else nil)",
          );
        }
        return LuauLiteral(value: result);
      }
    }

    if (element != null &&
        element.toString().contains('PropertyAccessorElement')) {
      final dynamic dynamicElement = element;
      try {
        if (dynamicElement.isGetter == true) {
          return LuauCallExpression(
            target: target,
            methodName: "get_${property.name}",
            arguments: [],
            useColon: true,
          );
        }
      } catch (e) {
        CompilerLogger.debug('isGetter check failed (PropertyAccess): $e');
      }
    }

    final propertyName = node.propertyName.name;
    final isList = node.target?.staticType?.isDartCoreList ?? false;
    final isString = node.target?.staticType?.isDartCoreString ?? false;

    if ((isList || isString) && propertyName == "length") {
      final lengthNode = LuauLiteral(value: "#${target!.emit()}");
      if (node.isNullAware) {
        return LuauLiteral(
          value:
              "(if ${target.emit()} ~= nil then ${lengthNode.emit()} else nil)",
        );
      }
      return lengthNode;
    }

    if (target != null) {
      final propertyNode = LuauLiteral(value: "${target.emit()}.$propertyName");
      if (node.isNullAware) {
        return LuauLiteral(
          value:
              "(function() local _v = ${target.emit()}; if _v ~= nil then return _v.$propertyName else return nil end end)()",
        );
      }
      return propertyNode;
    }

    return LuauLiteral(value: propertyName);
  }

  @override
  LuauNode? visitPrefixedIdentifier(PrefixedIdentifier node) {
    final targetLego = node.prefix.accept(this);
    final property = node.identifier;
    final element = property.element;

    CompilerLogger.debug(
      "PrefixedIdentifier: ${node.toSource()}, element: ${element?.runtimeType}",
    );

    if (MacroResolver.isRobloxType(node.prefix.staticType)) {
      final result = MacroResolver.resolveProperty(
        node.prefix.staticType,
        property.name,
        targetLego?.emit() ?? '_c',
      );
      if (result != null) {
        return LuauLiteral(value: result);
      }
    }

    if (element != null &&
        element.toString().contains('PropertyAccessorElement')) {
      final dynamic dynamicElement = element;
      try {
        if (dynamicElement.isGetter == true) {
          return LuauCallExpression(
            target: targetLego,
            methodName: "get_${property.name}",
            arguments: [],
            useColon: true,
          );
        }
      } catch (e) {
        CompilerLogger.debug('isGetter check failed (PrefixedIdentifier): $e');
      }
    }

    final propertyName = property.name;
    final isList = node.prefix.staticType?.isDartCoreList ?? false;
    final isString = node.prefix.staticType?.isDartCoreString ?? false;

    if ((isList || isString) && propertyName == 'length') {
      return LuauLiteral(value: "#${targetLego!.emit()}");
    }

    return LuauLiteral(value: "${targetLego!.emit()}.$propertyName");
  }

  @override
  LuauNode? visitSimpleIdentifier(SimpleIdentifier node) {
    final name = node.name;
    final element = node.element;

    if (element is LocalVariableElement || element is FormalParameterElement) {
      return LuauLiteral(value: name);
    }

    bool isInstanceMember = false;
    bool isGetter = false;
    if (element != null) {
      try {
        final dynamic dynElem = element;
        if (dynElem.isGetter == true) {
          isGetter = true;
          isInstanceMember =
              !dynElem.isStatic && element.enclosingElement is InterfaceElement;
        } else if (dynElem.isSetter == true) {
          isInstanceMember =
              !dynElem.isStatic && element.enclosingElement is InterfaceElement;
        } else if (element is MethodElement) {
          isInstanceMember =
              !element.isStatic && element.enclosingElement is InterfaceElement;
        }
      } catch (_) {
        if (element is MethodElement) {
          isInstanceMember =
              !element.isStatic && element.enclosingElement is InterfaceElement;
        }
      }
    }

    bool isStaticMember = false;
    if (element != null) {
      isStaticMember =
          (element is PropertyAccessorElement && element.isStatic) ||
              (element is VariableElement && element.isStatic) ||
              (element is FieldElement && element.isStatic);
      try {
        final dynamic dynamicElement = element;
        if (dynamicElement.isStatic == true) isStaticMember = true;
      } catch (e) {
        CompilerLogger.debug('isStatic check failed (SimpleIdentifier): $e');
      }
    }

    if (isStaticMember && currentClassName != null) {
      return LuauLiteral(value: "$currentClassName.$name");
    }

    if (!isStaticMember &&
        currentClassName != null &&
        staticClassMembers.contains(name)) {
      return LuauLiteral(value: "$currentClassName.$name");
    }

    if (!isInstanceMember && !isGetter && currentClassName != null) {
      isInstanceMember =
          allClassMembers.contains(name) || currentClassMembers.contains(name);
    }

    if (isGetter && currentClassName == null) {
      if (node.parent is VariableDeclaration ||
          node.parent is FunctionDeclaration ||
          (node.parent is PropertyAccess &&
              (node.parent as PropertyAccess).propertyName == node) ||
          (node.parent is MethodInvocation &&
              (node.parent as MethodInvocation).methodName == node)) {
        return LuauLiteral(value: name);
      }
      return LuauCallExpression(
        target: null,
        methodName: "get_$name",
        arguments: [],
        useColon: false,
      );
    }

    if ((isInstanceMember || isGetter) && currentClassName != null) {
      if (node.parent is MethodDeclaration ||
          node.parent is VariableDeclaration ||
          node.parent is ConstructorDeclaration) {
        return LuauLiteral(value: name);
      }
      if (node.parent is PropertyAccess &&
          (node.parent as PropertyAccess).propertyName == node) {
        return LuauLiteral(value: name);
      }
      if (node.parent is MethodInvocation &&
          (node.parent as MethodInvocation).methodName == node) {
        if ((node.parent as MethodInvocation).target != null) {
          return LuauLiteral(value: name);
        }
      }

      if (isGetter) {
        return LuauCallExpression(
          target: LuauLiteral(value: "self"),
          methodName: "get_$name",
          arguments: [],
          useColon: true,
        );
      }

      return LuauLiteral(value: "self.$name");
    }

    return LuauLiteral(value: name);
  }

  @override
  LuauNode? visitThisExpression(ThisExpression node) {
    return LuauLiteral(value: "self");
  }

  @override
  LuauNode? visitSuperExpression(SuperExpression node) {
    return LuauLiteral(value: "super");
  }

  @override
  LuauNode? visitCascadeExpression(CascadeExpression node) {
    final targetLego = node.target.accept(this);
    if (targetLego == null) return null;

    String innerCode = "local _c = ${targetLego.emit()}\n";

    for (var section in node.cascadeSections) {
      final sectionLego = section.accept(this);
      if (sectionLego != null) {
        final emitted = sectionLego.emit();
        if (emitted.startsWith(':') || emitted.startsWith('.')) {
          innerCode += "\t\t_c$emitted\n";
        } else {
          innerCode += "\t\t_c.$emitted\n";
        }
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
      final luauType = translateType(dartType) ?? "any";

      return LuauLiteral(value: "${legoExpr.emit()} :: $luauType");
    }
    return null;
  }

  @override
  LuauNode? visitIsExpression(IsExpression node) {
    final legoExpr = node.expression.accept(this);
    if (legoExpr != null) {
      final dartType = node.type.toSource();
      final luauType = translateType(dartType) ?? dartType;
      final isNegated = node.notOperator != null;

      final operator = isNegated ? "~=" : "==";
      final isPrimitive = ["number", "string", "boolean"].contains(luauType);

      if (isPrimitive) {
        return LuauLiteral(
          value: "typeof(${legoExpr.emit()}) $operator '$luauType'",
        );
      } else {
        final expr = legoExpr.emit();

        final condition =
            "(typeof($expr) == 'table' and getmetatable($expr) == $luauType)";

        if (isNegated) {
          return LuauLiteral(value: "not $condition");
        } else {
          return LuauLiteral(value: condition);
        }
      }
    }
    return null;
  }

  @override
  LuauNode? visitThrowExpression(ThrowExpression node) {
    final expression = node.expression.accept(this);
    return LuauCallExpression(
      methodName: "error",
      arguments: [expression ?? LuauLiteral(value: "nil")],
      useColon: false,
    );
  }

  @override
  LuauNode? visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final typeName = constructorName.type.toSource().split("<").first;
    final String ctorName = constructorName.name?.toSource() ?? "new";

    if (typeName == "DateTime" && ctorName == "now") {
      return LuauLiteral(value: "os.date('%Y-%m-%d %H:%M:%S')");
    }

    final args = processArguments(node.argumentList);

    return LuauCallExpression(
      target: LuauLiteral(value: typeName),
      methodName: ctorName,
      arguments: args,
    );
  }
}
