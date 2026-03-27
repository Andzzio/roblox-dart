import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;
import 'package:roblox_dart/compiler/macros/list_macros.dart';
import 'package:roblox_dart/compiler/macros/string_macros.dart';
import 'package:roblox_dart/compiler/macros/type_macros.dart';
import 'package:roblox_dart/compiler/parameter_result.dart';
import 'package:roblox_dart/luau/declaration/luau_anonymous_function.dart';
import 'package:roblox_dart/luau/declaration/luau_class.dart';
import 'package:roblox_dart/luau/declaration/luau_constructor.dart';
import 'package:roblox_dart/luau/declaration/luau_enum.dart';
import 'package:roblox_dart/luau/declaration/luau_method.dart';
import 'package:roblox_dart/luau/expression/luau_assignment_expression.dart';
import 'package:roblox_dart/luau/expression/luau_binary_expression.dart';
import 'package:roblox_dart/luau/expression/luau_call_expression.dart';
import 'package:roblox_dart/luau/expression/luau_conditional_expression.dart';
import 'package:roblox_dart/luau/expression/luau_function_invocation.dart';
import 'package:roblox_dart/luau/expression/luau_index_expression.dart';
import 'package:roblox_dart/luau/expression/luau_list_literal.dart';
import 'package:roblox_dart/luau/expression/luau_map_literal.dart';
import 'package:roblox_dart/luau/statement/luau_continue_statement.dart';
import 'package:roblox_dart/luau/statement/luau_do_statement.dart';
import 'package:roblox_dart/luau/statement/luau_expression_statement.dart';
import 'package:roblox_dart/luau/statement/luau_for_in_statement.dart';
import 'package:roblox_dart/luau/statement/luau_for_statement.dart';
import 'package:roblox_dart/luau/declaration/luau_function.dart';
import 'package:roblox_dart/luau/statement/luau_if_statement.dart';
import 'package:roblox_dart/luau/expression/luau_literal.dart';
import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/declaration/luau_parameter.dart';
import 'package:roblox_dart/luau/statement/luau_numeric__for_statement.dart';
import 'package:roblox_dart/luau/statement/luau_pair_for_each.dart';
import 'package:roblox_dart/luau/statement/luau_return_statement.dart';
import 'package:roblox_dart/luau/statement/luau_try_catch.dart';
import 'package:roblox_dart/luau/statement/luau_variable_declaration.dart';
import 'package:roblox_dart/luau/statement/luau_variable_declaration_group.dart';
import 'package:roblox_dart/luau/statement/luau_while_statement.dart';

class RobloxVisitor extends SimpleAstVisitor<LuauNode> {
  List<LuauNode>? _currentLoopUpdaters;
  String? currentFilePath;
  String? projectRoot;
  String? runtimePath;
  int _tryDepth = 0;
  String? _currentClassName;
  String? _currentSuperClassName;
  final Set<String> allClassMembers = {};
  final Set<String> staticClassMembers = {};
  final Set<String> _currentClassMembers = {};
  final Set<String> exports = {};
  final Set<String> _importedNames = {};

  @override
  LuauNode? visitImportDirective(ImportDirective node) {
    print("DEBUG: Visiting ImportDirective: ${node.uri.stringValue}");
    final uri = node.uri.stringValue;
    if (uri == null) return null;

    String varName;
    if (node.prefix != null) {
      varName = node.prefix!.name;
    } else {
      final segments = uri.split('/');
      final fileName = segments.last.split('.').first;
      varName = fileName;

      int counter = 1;
      String originalName = varName;
      while (_importedNames.contains(varName)) {
        counter++;
        varName = "$originalName$counter";
      }
    }
    _importedNames.add(varName);

    // Si es un servicio interno de Roblox
    if (uri.startsWith('package:roblox_dart/services.dart')) {
      return LuauVariableDeclaration(
        name: varName,
        initializer: LuauLiteral(value: 'game:GetService("$varName")'),
      );
    }

    String luauPath;
    if (uri.startsWith('package:') || uri.startsWith('dart:')) {
      final cleanUri = uri.split('/').last.replaceAll('.dart', '');
      luauPath = '_RD.import(script, "Parent", "$cleanUri")';
    } else {
      if (currentFilePath != null && projectRoot != null) {
        final currentDir = p.dirname(currentFilePath!);
        final importedFileAbsolute = p.normalize(p.join(currentDir, uri));
        String relPathStr = p
            .relative(importedFileAbsolute, from: currentDir)
            .replaceAll('.dart', '');

        final parts = relPathStr.split(p.separator);
        List<String> segments = ['"Parent"'];

        for (var part in parts) {
          if (part == '.') {
            continue;
          } else if (part == '..') {
            segments.add('"Parent"');
          } else {
            segments.add('"$part"');
          }
        }
        luauPath = '_RD.import(script, ${segments.join(", ")})';
      } else {
        final cleanUri = uri.replaceAll('.dart', '').replaceAll('/', '.');
        luauPath = '_RD.import(script, "Parent", "$cleanUri")';
      }
    }

    String output = "local $varName = require($luauPath)\n";

    if (node.prefix == null) {
      final libraryImportElement = node.libraryImport;
      final importedLibrary = libraryImportElement?.importedLibrary;

      if (importedLibrary != null) {
        final names = importedLibrary.exportNamespace.definedNames2.keys;

        for (var name in names) {
          if (name != varName && !name.startsWith('_')) {
            output += "local $name = $varName.$name\n";
          }
        }
      } else {
        print(
          "DEBUG: No se pudo resolver la librería importada para '$varName' en análisis estático.",
        );
      }
    }

    return LuauLiteral(value: output);
  }

  @override
  LuauNode? visitEnumDeclaration(EnumDeclaration node) {
    final String enumName = node.namePart.typeName.lexeme;

    final List<String> constantNames = [];
    final constantsList = node.body.constants;

    for (var constant in constantsList) {
      constantNames.add(constant.name.lexeme);
    }

    exports.add(enumName);

    return LuauEnum(name: enumName, constants: constantNames);
  }

  @override
  LuauNode? visitExportDirective(ExportDirective node) {
    print("DEBUG: Visiting ExportDirective: ${node.uri.stringValue}");
    final uri = node.uri.stringValue;
    if (uri == null) return null;

    final segments = uri.split('/');
    final fileName = segments.last.split('.').first;
    String varName = fileName;

    int counter = 1;
    String originalName = varName;
    while (_importedNames.contains(varName)) {
      counter++;
      varName = "$originalName$counter";
    }
    _importedNames.add(varName);

    String luauPath;
    if (currentFilePath != null && projectRoot != null) {
      final currentDir = p.dirname(currentFilePath!);
      final importedFileAbsolute = p.normalize(p.join(currentDir, uri));
      String relPathStr = p
          .relative(importedFileAbsolute, from: currentDir)
          .replaceAll('.dart', '');

      final parts = relPathStr.split(p.separator);
      List<String> segmentsList = ['"Parent"'];

      for (var part in parts) {
        if (part == '.') {
          continue;
        } else if (part == '..') {
          segmentsList.add('"Parent"');
        } else {
          segmentsList.add('"$part"');
        }
      }
      luauPath = '_RD.import(script, ${segmentsList.join(", ")})';
    } else {
      final cleanUri = uri.replaceAll('.dart', '').replaceAll('/', '.');
      luauPath = '_RD.import(script, "Parent", "$cleanUri")';
    }

    try {
      final exportElement = node.libraryExport;
      if (exportElement != null) {
        final library = exportElement.exportedLibrary;
        if (library != null) {
          final names = library.exportNamespace.definedNames2.keys;
          for (var name in names) {
            exports.add("$varName.$name");
          }
        }
      }
    } catch (e) {
      print(
        "DEBUG: Fallo al extraer las variables exportadas de '$varName': $e",
      );
    }

    return LuauVariableDeclaration(
      name: varName,
      initializer: LuauLiteral(value: 'require($luauPath)'),
    );
  }

  @override
  LuauNode? visitFunctionDeclaration(FunctionDeclaration node) {
    String functionName = node.name.lexeme;

    if (node.isGetter) {
      functionName = "get_$functionName";
    } else if (node.isSetter) {
      functionName = "set_$functionName";
    }

    bool isLocal =
        node.parent is Block ||
        node.parent is BlockFunctionBody ||
        node.parent is FunctionDeclarationStatement;

    String? returnTypeLuau;

    if (node.returnType != null) {
      final dartType = node.returnType!.toSource();
      returnTypeLuau = _translateType(dartType);
    }

    final paramResult = _splitParameters(
      node.functionExpression.parameters?.parameters,
    );

    final List<LuauNode> luauBody = [];
    luauBody.addAll(paramResult.unpackers);

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

    if (_tryDepth == 0 && _currentClassName == null) {
      exports.add(functionName);
    }

    return LuauFunction(
      name: functionName,
      body: luauBody,
      parameters: paramResult.fnParams,
      returnType: returnTypeLuau,
      isLocal: isLocal,
    );
  }

  @override
  LuauNode? visitGenericTypeAlias(GenericTypeAlias node) {
    return null;
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
      final luauType = _translateType(dartType) ?? dartType;
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
  LuauNode? visitReturnStatement(ReturnStatement node) {
    LuauNode? legoValue;

    if (node.expression != null) {
      legoValue = node.expression!.accept(this);
    }

    if (_tryDepth > 0) {
      if (legoValue != null) {
        return LuauLiteral(
          value:
              "_hasReturned = true\n\t\t_returnValue = ${legoValue.emit()}\n\t\treturn",
        );
      } else {
        return LuauLiteral(value: "_hasReturned = true\n\t\treturn");
      }
    }

    return LuauReturnStatement(expression: legoValue);
  }

  @override
  LuauNode? visitBreakStatement(BreakStatement node) {
    if (_tryDepth > 0) {
      return LuauLiteral(value: "_hasBroken = true\n\t\treturn");
    }
    return LuauExpressionStatement(expression: LuauLiteral(value: "break"));
  }

  @override
  LuauNode? visitContinueStatement(ContinueStatement node) {
    if (_tryDepth > 0) {
      return LuauLiteral(value: "_hasContinued = true\n\t\treturn");
    }
    return LuauContinueStatement(updaters: _currentLoopUpdaters);
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
  LuauNode? visitVariableDeclarationList(VariableDeclarationList node) {
    List<LuauVariableDeclaration> decls = [];

    String? luauType;
    if (node.type != null) {
      luauType = _translateType(node.type!.toSource());
    }

    for (var variable in node.variables) {
      final name = variable.name.lexeme;
      LuauNode? valueLego;

      if (variable.initializer != null) {
        valueLego = variable.initializer!.accept(this);
      }

      decls.add(
        LuauVariableDeclaration(
          name: name,
          initializer: valueLego,
          type: luauType,
        ),
      );
    }

    return LuauVariableDeclarationGroup(declarations: decls);
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
  LuauNode? visitDoubleLiteral(DoubleLiteral node) {
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
    final left = node.leftHandSide;
    final right = node.rightHandSide.accept(this);
    if (right == null) return null;

    // 1. Handle SimpleIdentifier (Local or Top-level setter)
    if (left is SimpleIdentifier) {
      final element = left.element;
      if (element != null) {
        try {
          final dynamic dynElem = element;
          if (dynElem.isSetter == true) {
            bool isInstance =
                !dynElem.isStatic &&
                element.enclosingElement is InterfaceElement;
            return LuauCallExpression(
              target: isInstance ? LuauLiteral(value: "self") : null,
              methodName: "set_${left.name}",
              arguments: [right],
              useColon: isInstance,
            );
          }
        } catch (_) {}
      }
    }

    // 2. Handle PropertyAccess (obj.prop = val -> obj:set_prop(val))
    if (left is PropertyAccess) {
      final property = left.propertyName;
      final element = property.element;
      if (element != null) {
        try {
          final dynamic dynElem = element;
          if (dynElem.isSetter == true) {
            final targetLego = left.target?.accept(this);
            return LuauCallExpression(
              target: targetLego,
              methodName: "set_${property.name}",
              arguments: [right],
              useColon: true,
            );
          }
        } catch (_) {}
      }
    }

    // 3. Handle PrefixedIdentifier (A.prop = val -> A:set_prop(val))
    if (left is PrefixedIdentifier) {
      final property = left.identifier;
      final element = property.element;
      if (element != null) {
        try {
          final dynamic dynElem = element;
          if (dynElem.isSetter == true) {
            final targetLego = left.prefix.accept(this);
            return LuauCallExpression(
              target: targetLego,
              methodName: "set_${property.name}",
              arguments: [right],
              useColon: true,
            );
          }
        } catch (_) {}
      }
    }

    final leftLego = left.accept(this);
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
  LuauNode? visitMethodInvocation(MethodInvocation node) {
    final String methodName = node.methodName.name;
    final List<LuauNode> finalLuauArgs = _processArguments(node.argumentList);

    LuauNode? targetLego;
    bool isColon = false;
    LuauNode? resultNode;

    if (node.target != null) {
      final targetExpression = node.target!;

      if (targetExpression is SuperExpression) {
        final superTargetName = _currentSuperClassName ?? "super";
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

        if (resultNode == null) {
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
      }
    } else {
      print("DEBUG: Method ${node.methodName} isCascaded: ${node.isCascaded}");
      isColon = node.isCascaded;
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
  LuauNode? visitTryStatement(TryStatement node) {
    _tryDepth++;

    final List<LuauNode> tryBody = [];
    for (var statement in node.body.statements) {
      final lego = statement.accept(this);
      if (lego != null) tryBody.add(lego);
    }

    _tryDepth--;

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

    List<LuauNode> finallyBody = [];
    if (node.finallyBlock != null) {
      for (var statement in node.finallyBlock!.statements) {
        final lego = statement.accept(this);
        if (lego != null) finallyBody.add(lego);
      }
    }

    return LuauTryCatch(
      tryBody: tryBody,
      errorName: errorName,
      catchBody: catchBody,
      finallyBody: finallyBody,
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
  LuauNode? visitAssertStatement(AssertStatement node) {
    final condition = node.condition.accept(this);
    if (condition == null) return null;

    final List<LuauNode> args = [condition];

    if (node.message != null) {
      final msg = node.message!.accept(this);
      if (msg != null) args.add(msg);
    }

    final call = LuauCallExpression(
      methodName: "assert",
      arguments: args,
      useColon: false,
    );

    return LuauExpressionStatement(expression: call);
  }

  @override
  LuauNode? visitPropertyAccess(PropertyAccess node) {
    final target = node.target?.accept(this);
    final property = node.propertyName;
    final element = property.element;

    print(
      "DEBUG: PropertyAccess: ${node.toSource()}, element: ${element?.runtimeType}, string: $element",
    );

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
      } catch (_) {}
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

    print(
      "DEBUG: PrefixedIdentifier: ${node.toSource()}, element: ${element?.runtimeType}, string: $element",
    );

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
      } catch (_) {}
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
      final str = element.toString();
      isStaticMember =
          str.contains('static') ||
          (element is PropertyAccessorElement && element.isStatic) ||
          (element is VariableElement && element.isStatic) ||
          (element is FieldElement && element.isStatic);
      try {
        final dynamic dynamicElement = element;
        if (dynamicElement.isStatic == true) isStaticMember = true;
      } catch (_) {}
    }

    if (isStaticMember && _currentClassName != null) {
      return LuauLiteral(value: "$_currentClassName.$name");
    }

    if (!isStaticMember &&
        _currentClassName != null &&
        staticClassMembers.contains(name)) {
      return LuauLiteral(value: "$_currentClassName.$name");
    }

    if (!isInstanceMember && !isGetter && _currentClassName != null) {
      isInstanceMember =
          allClassMembers.contains(name) || _currentClassMembers.contains(name);
    }

    // Top-level or library getter redirection
    if (isGetter && _currentClassName == null) {
      // Don't redirect during declaration or if it's a property/method access property
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

    if ((isInstanceMember || isGetter) && _currentClassName != null) {
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
    String safeValue = node.value
        .replaceAll('\\', r'\\')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('`', r'\`');

    return LuauLiteral(value: safeValue);
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

      final numericFor = _tryParseNumericFor(forParts, node.body);
      if (numericFor != null) return numericFor;

      final legoInit = forParts.variables.accept(this);
      final legoCond = forParts.condition?.accept(this);

      final List<LuauNode> legoUpdaters = [];

      for (var updater in forParts.updaters) {
        final lego = updater.accept(this);
        if (lego != null) legoUpdaters.add(lego);
      }

      final oldUpdaters = _currentLoopUpdaters;
      _currentLoopUpdaters = legoUpdaters;

      final backpackBody = _packBody(node.body);

      _currentLoopUpdaters = oldUpdaters;

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
      } else {
        final key = element.accept(this);
        if (key != null) {
          legoEntries[key] = LuauLiteral(value: "true");
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
  LuauNode? visitClassDeclaration(ClassDeclaration node) {
    String? className;
    try {
      className = (node as dynamic).name.lexeme;
    } catch (_) {
      try {
        className = (node as dynamic).namePart.typeName.lexeme;
      } catch (_) {
        className = "UnknownClass";
      }
    }
    _currentClassName = className;
    _currentClassMembers.clear();

    String? superClassName;
    if (node.extendsClause != null) {
      superClassName = node.extendsClause!.superclass
          .toSource()
          .split('<')
          .first;
      _currentSuperClassName = superClassName;
    } else {
      _currentSuperClassName = null;
    }

    final dynamic dynamicNode = node;
    try {
      final dynamic classElement =
          dynamicNode.declaredElement ?? dynamicNode.declaredFragment?.element;
      if (classElement != null) {
        final List allTypes = classElement.allSupertypes ?? [];
        for (var type in allTypes) {
          final dynamic element = type.element;
          if (element == null) continue;
          final List members = element.methods;
          for (var m in members) {
            _currentClassMembers.add(m.name);
          }
          final List fields = element.fields;
          for (var f in fields) {
            _currentClassMembers.add(f.name);
          }
        }
      }
    } catch (_) {}

    final List<LuauNode> luauBody = [];

    if (node.withClause != null) {
      for (var mixin in node.withClause!.mixinTypes) {
        String mixinName = "UnknownMixin";
        try {
          mixinName = (mixin as dynamic).name.lexeme;
        } catch (_) {
          try {
            mixinName = (mixin as dynamic).name2.lexeme;
          } catch (_) {}
        }
        luauBody.add(
          LuauLiteral(
            value:
                "for k, v in pairs($mixinName) do\n\tif k ~= \"new\" and k ~= \"__index\" then\n\t\t$className[k] = v\n\tend\nend",
          ),
        );
      }
    }

    final classBody = node.body as BlockClassBody;
    final members = classBody.members;

    for (var member in members) {
      if (member is FieldDeclaration) {
        for (var variable in member.fields.variables) {
          _currentClassMembers.add(variable.name.lexeme);
        }
      } else if (member is MethodDeclaration) {
        _currentClassMembers.add(member.name.lexeme);
      }
    }

    final List<LuauNode> constructorNodes = [];
    final List<LuauNode> methods = [];
    final List<LuauNode> fieldInitializers = [];
    final List<LuauNode> staticFields = [];

    for (var member in members) {
      if (member is FieldDeclaration) {
        final isStatic = member.isStatic;
        for (var variable in member.fields.variables) {
          if (variable.initializer != null) {
            final initLego = variable.initializer!.accept(this);
            if (initLego != null) {
              if (isStatic) {
                staticFields.add(
                  LuauAssignmentExpression(
                    left: LuauLiteral(
                      value: "$className.${variable.name.lexeme}",
                    ),
                    operator: "=",
                    right: initLego,
                  ),
                );
              } else {
                fieldInitializers.add(
                  LuauExpressionStatement(
                    expression: LuauAssignmentExpression(
                      left: LuauLiteral(value: "self.${variable.name.lexeme}"),
                      operator: "=",
                      right: initLego,
                    ),
                  ),
                );
              }
            }
          }
        }
      } else if (member is ConstructorDeclaration) {
        final ctorNode = _buildConstructor(member, fieldInitializers);
        if (ctorNode != null) constructorNodes.add(ctorNode);
      } else if (member is MethodDeclaration) {
        final methodNode = member.accept(this);
        if (methodNode != null) methods.add(methodNode);
      }
    }

    if (constructorNodes.isEmpty) {
      constructorNodes.add(
        LuauConstructor(
          className: _currentClassName!,
          constructorName: "new",
          parameters: [],
          body: [],
          fieldInitializers: fieldInitializers,
        ),
      );
    }

    final classNode = LuauClass(
      name: _currentClassName!,
      constructors: constructorNodes,
      methods: methods,
      staticFields: staticFields,
      superClassName: superClassName,
    );

    if (_currentClassName != null) {
      exports.add(_currentClassName!);
    }

    _currentClassName = null;
    _currentSuperClassName = null;
    _currentClassMembers.clear();

    return classNode;
  }

  LuauNode? _buildConstructor(
    ConstructorDeclaration node,
    List<LuauNode> fieldInit,
  ) {
    final paramResult = _splitParameters(node.parameters.parameters);
    final List<LuauNode> luauBody = [];

    luauBody.addAll(paramResult.unpackers);
    luauBody.addAll(paramResult.fieldAssignments);

    String? customSelfInit;

    if (node.initializers.isNotEmpty) {
      for (var init in node.initializers) {
        if (init is SuperConstructorInvocation) {
          final ctorName = init.constructorName?.name ?? "new";
          final args = _processArguments(init.argumentList);

          final superFormalParams = node.parameters.parameters
              .whereType<SuperFormalParameter>()
              .map((p) => p.name.lexeme)
              .toList();

          final List<String> allArgs = [...superFormalParams];
          allArgs.addAll(args.map((a) => a.emit()));

          final argsStr = allArgs.join(", ");
          customSelfInit =
              "${_currentSuperClassName ?? "super"}.$ctorName($argsStr)";
        } else if (init is RedirectingConstructorInvocation) {
          final ctorName = init.constructorName?.name ?? "new";
          final args = _processArguments(init.argumentList);
          final argsStr = args.map((a) => a.emit()).join(", ");
          customSelfInit = "$_currentClassName.$ctorName($argsStr)";
        } else if (init is ConstructorFieldInitializer) {
          final fieldName = init.fieldName.name;
          final value = init.expression.accept(this);
          if (value != null) {
            luauBody.add(
              LuauExpressionStatement(
                expression: LuauAssignmentExpression(
                  left: LuauLiteral(value: "self.$fieldName"),
                  operator: "=",
                  right: value,
                ),
              ),
            );
          }
        }
      }
    }

    if (customSelfInit == null && _currentSuperClassName != null) {
      final superParams = node.parameters.parameters
          .whereType<SuperFormalParameter>()
          .map((p) => p.name.lexeme)
          .toList();
      if (superParams.isNotEmpty) {
        final argsStr = superParams.join(", ");
        customSelfInit = "$_currentSuperClassName.new($argsStr)";
      }
    }

    final body = node.body;
    if (body is BlockFunctionBody) {
      for (var statement in body.block.statements) {
        final childLego = statement.accept(this);
        if (childLego != null) luauBody.add(childLego);
      }
    }

    String ctorName = node.name != null ? node.name!.lexeme : "new";

    return LuauConstructor(
      className: _currentClassName!,
      constructorName: ctorName,
      parameters: paramResult.fnParams,
      body: luauBody,
      fieldInitializers: fieldInit,
      customSelfInitialization: customSelfInit,
      isFactory: node.factoryKeyword != null,
    );
  }

  @override
  LuauNode? visitAdjacentStrings(AdjacentStrings node) {
    String combined = "";
    for (var string in node.strings) {
      final lego = string.accept(this);
      if (lego != null) {
        String val = lego.emit();
        if ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'")) ||
            (val.startsWith('`') && val.endsWith('`'))) {
          combined += val.substring(1, val.length - 1);
        } else {
          combined += val;
        }
      }
    }
    return LuauLiteral(value: "`$combined`");
  }

  @override
  LuauNode? visitFunctionDeclarationStatement(
    FunctionDeclarationStatement node,
  ) {
    return node.functionDeclaration.accept(this);
  }

  @override
  LuauNode? visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final typeName = constructorName.type.toSource().split("<").first;
    final String ctorName = constructorName.name?.toSource() ?? "new";

    if (typeName == "DateTime" && ctorName == "now") {
      return LuauLiteral(value: "os.date('%Y-%m-%d %H:%M:%S')");
    }

    final args = _processArguments(node.argumentList);

    return LuauCallExpression(
      target: LuauLiteral(value: typeName),
      methodName: ctorName,
      arguments: args,
    );
  }

  @override
  LuauNode? visitMethodDeclaration(MethodDeclaration node) {
    String methodName = node.name.lexeme;
    if (node.isGetter) {
      methodName = "get_$methodName";
    } else if (node.isSetter) {
      methodName = "set_$methodName";
    }
    List<LuauParameter> fnParams = [];

    if (node.parameters != null) {
      for (var param in node.parameters!.parameters) {
        fnParams.add(
          LuauParameter(name: param.name?.lexeme ?? "", type: "any"),
        );
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

    return LuauMethod(
      className: _currentClassName!,
      methodName: methodName,
      parameters: fnParams,
      body: luauBody,
      isStatic: node.isStatic,
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

  ParameterResult _splitParameters(Iterable<FormalParameter>? parameters) {
    List<LuauParameter> fnParams = [];
    List<LuauNode> unpackers = [];
    List<LuauNode> fieldAssignments = [];
    bool hasNamed = false;

    if (parameters != null) {
      for (var param in parameters) {
        final paramName = param.name?.lexeme ?? "";
        String? luauType;

        NormalFormalParameter? baseParam;
        Expression? defaultValue;

        if (param is DefaultFormalParameter) {
          baseParam = param.parameter;
          defaultValue = param.defaultValue;
        } else if (param is NormalFormalParameter) {
          baseParam = param;
        }

        if (baseParam is SimpleFormalParameter && baseParam.type != null) {
          luauType = _translateType(baseParam.type!.toSource());
        } else if (baseParam is FieldFormalParameter &&
            baseParam.type != null) {
          luauType = _translateType(baseParam.type!.toSource());
        } else if (baseParam is SuperFormalParameter &&
            baseParam.type != null) {
          luauType = _translateType(baseParam.type!.toSource());
        }

        final typeString = luauType != null ? ": $luauType" : "";

        if (baseParam is FieldFormalParameter) {
          fieldAssignments.add(
            LuauExpressionStatement(
              expression: LuauLiteral(value: "self.$paramName = $paramName"),
            ),
          );
        }

        if (param.isNamed) {
          hasNamed = true;
          String extractionValue;
          if (defaultValue != null) {
            final defaultLego = defaultValue.accept(this);
            extractionValue =
                "local $paramName$typeString = if namedArgs and namedArgs.$paramName ~= nil then namedArgs.$paramName else ${defaultLego?.emit()}";
          } else {
            extractionValue =
                "local $paramName$typeString = if namedArgs then namedArgs.$paramName else nil";
          }
          unpackers.add(
            LuauExpressionStatement(
              expression: LuauLiteral(value: extractionValue),
            ),
          );
          if (param.isRequired) {
            unpackers.add(
              LuauExpressionStatement(
                expression: LuauLiteral(
                  value:
                      'assert($paramName ~= nil, "Parameter \'$paramName\' is required")',
                ),
              ),
            );
          }
        } else {
          fnParams.add(LuauParameter(name: paramName, type: luauType));
          if (defaultValue != null) {
            final defaultLego = defaultValue.accept(this);
            final fallback = LuauLiteral(
              value:
                  "if $paramName == nil then\n\t\t$paramName = ${defaultLego?.emit()}\n\tend",
            );
            unpackers.add(LuauExpressionStatement(expression: fallback));
          }
        }
      }
    }

    if (hasNamed) {
      fnParams.add(LuauParameter(name: "namedArgs", type: "any"));
    }

    return ParameterResult(fnParams, unpackers, fieldAssignments, hasNamed);
  }

  LuauNode? _tryParseNumericFor(
    ForPartsWithDeclarations parts,
    Statement body,
  ) {
    if (parts.variables.variables.length != 1) return null;
    final variable = parts.variables.variables.first;
    final varName = variable.name.lexeme;
    if (parts.condition is! BinaryExpression) return null;
    final cond = parts.condition as BinaryExpression;
    if (cond.leftOperand.toSource() != varName) return null;
    if (cond.operator.lexeme != "<" && cond.operator.lexeme != "<=") {
      return null;
    }
    if (parts.updaters.length != 1) return null;
    final updater = parts.updaters.first;
    String updaterSrc = updater.toSource().replaceAll(" ", "");

    bool isSimpleInc =
        updaterSrc == "$varName++" ||
        updaterSrc == "++$varName" ||
        updaterSrc == "$varName+=1" ||
        updaterSrc == "$varName=$varName+1";

    if (!isSimpleInc) return null;

    final startLego = variable.initializer?.accept(this);
    final endLego = cond.rightOperand.accept(this);
    if (startLego == null || endLego == null) return null;

    LuauNode finalEnd = endLego;
    if (cond.operator.lexeme == "<") {
      finalEnd = LuauBinaryExpression(
        left: endLego,
        operator: "-",
        right: LuauLiteral(value: "1"),
      );
    }
    return LuauNumericForStatement(
      variable: varName,
      start: startLego,
      end: finalEnd,
      body: _packBody(body),
    );
  }
}
