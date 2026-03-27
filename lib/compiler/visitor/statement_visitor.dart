import 'package:analyzer/dart/ast/ast.dart';
import 'package:roblox_dart/compiler/visitor/roblox_visitor_base.dart';
import 'package:roblox_dart/luau/expression/luau_binary_expression.dart';
import 'package:roblox_dart/luau/expression/luau_call_expression.dart';
import 'package:roblox_dart/luau/expression/luau_conditional_expression.dart';
import 'package:roblox_dart/luau/expression/luau_literal.dart';
import 'package:roblox_dart/luau/luau_node.dart';
import 'package:roblox_dart/luau/statement/luau_continue_statement.dart';
import 'package:roblox_dart/luau/statement/luau_do_statement.dart';
import 'package:roblox_dart/luau/statement/luau_expression_statement.dart';
import 'package:roblox_dart/luau/statement/luau_for_in_statement.dart';
import 'package:roblox_dart/luau/statement/luau_for_statement.dart';
import 'package:roblox_dart/luau/statement/luau_if_statement.dart';
import 'package:roblox_dart/luau/statement/luau_return_statement.dart';
import 'package:roblox_dart/luau/statement/luau_try_catch.dart';
import 'package:roblox_dart/luau/statement/luau_variable_declaration.dart';
import 'package:roblox_dart/luau/statement/luau_variable_declaration_group.dart';
import 'package:roblox_dart/luau/statement/luau_while_statement.dart';

mixin StatementVisitor on RobloxVisitorBase {
  @override
  LuauNode? visitReturnStatement(ReturnStatement node) {
    LuauNode? legoValue;

    if (node.expression != null) {
      legoValue = node.expression!.accept(this);
    }

    if (tryDepth > 0) {
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
    if (tryDepth > 0) {
      return LuauLiteral(value: "_hasBroken = true\n\t\treturn");
    }
    return LuauExpressionStatement(expression: LuauLiteral(value: "break"));
  }

  @override
  LuauNode? visitContinueStatement(ContinueStatement node) {
    if (tryDepth > 0) {
      return LuauLiteral(value: "_hasContinued = true\n\t\treturn");
    }
    return LuauContinueStatement(updaters: currentLoopUpdaters);
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
  LuauNode? visitVariableDeclarationList(VariableDeclarationList node) {
    List<LuauVariableDeclaration> decls = [];

    String? luauType;
    if (node.type != null) {
      luauType = translateType(node.type!.toSource());
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
  LuauNode? visitIfStatement(IfStatement node) {
    final legoCondition = node.expression.accept(this);

    if (legoCondition == null) return null;

    final backpackThen = packBody(node.thenStatement);
    List<LuauNode> backpackElse = [];

    if (node.elseStatement != null) {
      if (node.elseStatement is IfStatement) {
        final elseIfNode = node.elseStatement!.accept(this);
        if (elseIfNode is LuauIfStatement) {
          elseIfNode.isElseIf = true;
          backpackElse.add(elseIfNode);
        }
      } else {
        backpackElse = packBody(node.elseStatement!);
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

    final backpackBody = packBody(node.body);

    return LuauWhileStatement(condition: legoCondition, body: backpackBody);
  }

  @override
  LuauNode? visitForStatement(ForStatement node) {
    if (node.forLoopParts is ForPartsWithDeclarations) {
      final forParts = node.forLoopParts as ForPartsWithDeclarations;

      final numericFor = tryParseNumericFor(forParts, node.body);
      if (numericFor != null) return numericFor;

      final legoInit = forParts.variables.accept(this);
      final legoCond = forParts.condition?.accept(this);

      final List<LuauNode> legoUpdaters = [];

      for (var updater in forParts.updaters) {
        final lego = updater.accept(this);
        if (lego != null) legoUpdaters.add(lego);
      }

      final oldUpdaters = currentLoopUpdaters;
      currentLoopUpdaters = legoUpdaters;

      final backpackBody = packBody(node.body);

      currentLoopUpdaters = oldUpdaters;

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
          body: packBody(node.body),
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

    final backpackBody = packBody(node.body);

    return LuauDoStatement(body: backpackBody, condition: legoCondition);
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
  LuauNode? visitTryStatement(TryStatement node) {
    tryDepth++;

    final List<LuauNode> tryBody = [];
    for (var statement in node.body.statements) {
      final lego = statement.accept(this);
      if (lego != null) tryBody.add(lego);
    }
    tryDepth--;

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
  LuauNode? visitFunctionDeclarationStatement(
    FunctionDeclarationStatement node,
  ) {
    return node.functionDeclaration.accept(this);
  }
}
