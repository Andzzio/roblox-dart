import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:roblox_dart/compiler/visitor/roblox_visitor_base.dart';
import 'package:roblox_dart/luau/declaration/luau_class.dart';
import 'package:roblox_dart/luau/declaration/luau_constructor.dart';
import 'package:roblox_dart/luau/declaration/luau_enum.dart';
import 'package:roblox_dart/luau/declaration/luau_function.dart';
import 'package:roblox_dart/luau/declaration/luau_method.dart';
import 'package:roblox_dart/luau/declaration/luau_parameter.dart';
import 'package:roblox_dart/luau/expression/luau_assignment_expression.dart';
import 'package:roblox_dart/luau/expression/luau_literal.dart';
import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/statement/luau_expression_statement.dart';
import 'package:roblox_dart/luau/statement/luau_return_statement.dart';

mixin ClassVisitor on RobloxVisitorBase {
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
      returnTypeLuau = translateType(dartType);
    }

    final paramResult = splitParameters(
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

    if (tryDepth == 0 && currentClassName == null) {
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
  LuauNode? visitMixinDeclaration(MixinDeclaration node) {
    final name = node.name.lexeme;
    currentClassName = name;
    final List<LuauNode> methods = [];
    for (var member in node.body.members) {
      if (member is MethodDeclaration) {
        final lego = member.accept(this);
        if (lego != null) methods.add(lego);
      }
    }
    currentClassName = null;
    return LuauClass(name: name, constructors: [], methods: methods);
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
    currentClassName = className;
    currentClassMembers.clear();

    String? superClassName;
    if (node.extendsClause != null) {
      superClassName = node.extendsClause!.superclass
          .toSource()
          .split('<')
          .first;
      currentSuperClassName = superClassName;
    } else {
      currentSuperClassName = null;
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
            currentClassMembers.add(m.name);
          }
          final List fields = element.fields;
          for (var f in fields) {
            currentClassMembers.add(f.name);
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
        final mixinElement = mixin.element;
        if (mixinElement is MixinElement) {
          for (var m in mixinElement.methods) {
            currentClassMembers.add(m.name!);
          }
          for (var f in mixinElement.fields) {
            currentClassMembers.add(f.name!);
          }
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
          currentClassMembers.add(variable.name.lexeme);
        }
      } else if (member is MethodDeclaration) {
        currentClassMembers.add(member.name.lexeme);
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
          } else if (isStatic) {
            staticFields.add(
              LuauAssignmentExpression(
                left: LuauLiteral(value: "$className.${variable.name.lexeme}"),
                operator: "=",
                right: LuauLiteral(value: "nil"),
              ),
            );
          }
        }
      } else if (member is ConstructorDeclaration) {
        final isFactory = member.factoryKeyword != null;
        final ctorNode = buildConstructor(
          member,
          isFactory ? [] : fieldInitializers,
        );
        if (ctorNode != null) constructorNodes.add(ctorNode);
      } else if (member is MethodDeclaration) {
        final methodNode = member.accept(this);
        if (methodNode != null) methods.add(methodNode);
      }
    }

    if (constructorNodes.isEmpty) {
      constructorNodes.add(
        LuauConstructor(
          className: currentClassName!,
          constructorName: "new",
          parameters: [],
          body: [],
          fieldInitializers: fieldInitializers,
        ),
      );
    }

    final classNode = LuauClass(
      name: currentClassName!,
      constructors: constructorNodes,
      methods: methods,
      staticFields: staticFields,
      superClassName: superClassName,
      mixinInjections: luauBody,
    );

    if (currentClassName != null) {
      exports.add(currentClassName!);
    }

    currentClassName = null;
    currentSuperClassName = null;
    currentClassMembers.clear();

    return classNode;
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
      className: currentClassName!,
      methodName: methodName,
      parameters: fnParams,
      body: luauBody,
      isStatic: node.isStatic,
    );
  }
}
