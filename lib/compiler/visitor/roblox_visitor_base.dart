import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:roblox_dart/compiler/parameter_result.dart';
import 'package:roblox_dart/luau/declaration/luau_constructor.dart';
import 'package:roblox_dart/luau/declaration/luau_parameter.dart';
import 'package:roblox_dart/luau/expression/luau_assignment_expression.dart';
import 'package:roblox_dart/luau/expression/luau_binary_expression.dart';
import 'package:roblox_dart/luau/expression/luau_literal.dart';
import 'package:roblox_dart/luau/expression/luau_map_literal.dart';
import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/statement/luau_expression_statement.dart';
import 'package:roblox_dart/luau/statement/luau_numeric__for_statement.dart';

abstract class RobloxVisitorBase extends SimpleAstVisitor<LuauNode> {
  List<LuauNode>? currentLoopUpdaters;
  String? currentFilePath;
  String? projectRoot;
  String? runtimePath;
  int tryDepth = 0;
  String? currentClassName;
  String? currentSuperClassName;
  final Set<String> allClassMembers = {};
  final Set<String> staticClassMembers = {};
  final Set<String> currentClassMembers = {};
  final Set<String> exports = {};
  final Set<String> importedNames = {};

  String? translateType(String? dartType) {
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

  List<LuauNode> processArguments(ArgumentList argumentList) {
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

  ParameterResult splitParameters(Iterable<FormalParameter>? parameters) {
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
          luauType = translateType(baseParam.type!.toSource());
        } else if (baseParam is FieldFormalParameter &&
            baseParam.type != null) {
          luauType = translateType(baseParam.type!.toSource());
        } else if (baseParam is SuperFormalParameter &&
            baseParam.type != null) {
          luauType = translateType(baseParam.type!.toSource());
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

  List<LuauNode> packBody(Statement dartCode) {
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

  LuauNode? tryParseNumericFor(ForPartsWithDeclarations parts, Statement body) {
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
      body: packBody(body),
    );
  }

  LuauNode? buildConstructor(
    ConstructorDeclaration node,
    List<LuauNode> fieldInit,
  ) {
    final paramResult = splitParameters(node.parameters.parameters);
    final List<LuauNode> luauBody = [];

    luauBody.addAll(paramResult.unpackers);
    luauBody.addAll(paramResult.fieldAssignments);

    String? customSelfInit;

    if (node.initializers.isNotEmpty) {
      for (var init in node.initializers) {
        if (init is SuperConstructorInvocation) {
          final ctorName = init.constructorName?.name ?? "new";
          final args = processArguments(init.argumentList);

          final superFormalParams = node.parameters.parameters
              .whereType<SuperFormalParameter>()
              .map((p) => p.name.lexeme)
              .toList();

          final List<String> allArgs = [...superFormalParams];
          allArgs.addAll(args.map((a) => a.emit()));

          final argsStr = allArgs.join(", ");
          customSelfInit =
              "${currentSuperClassName ?? "super"}.$ctorName($argsStr)";
        } else if (init is RedirectingConstructorInvocation) {
          final ctorName = init.constructorName?.name ?? "new";
          final args = processArguments(init.argumentList);
          final argsStr = args.map((a) => a.emit()).join(", ");
          customSelfInit = "$currentClassName.$ctorName($argsStr)";
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

    if (customSelfInit == null && currentSuperClassName != null) {
      final superParams = node.parameters.parameters
          .whereType<SuperFormalParameter>()
          .map((p) => p.name.lexeme)
          .toList();
      if (superParams.isNotEmpty) {
        final argsStr = superParams.join(", ");
        customSelfInit = "$currentSuperClassName.new($argsStr)";
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
      className: currentClassName!,
      constructorName: ctorName,
      parameters: paramResult.fnParams,
      body: luauBody,
      fieldInitializers: fieldInit,
      customSelfInitialization: customSelfInit,
      isFactory: node.factoryKeyword != null,
    );
  }

  void reset() {
    currentLoopUpdaters = null;
    currentFilePath = null;
    projectRoot = null;
    runtimePath = null;
    tryDepth = 0;
    currentClassName = null;
    currentSuperClassName = null;
    allClassMembers.clear();
    staticClassMembers.clear();
    currentClassMembers.clear();
    exports.clear();
    importedNames.clear();
  }
}
