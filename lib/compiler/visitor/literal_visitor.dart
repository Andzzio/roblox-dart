import 'package:analyzer/dart/ast/ast.dart';
import 'package:roblox_dart/compiler/visitor/roblox_visitor_base.dart';
import 'package:roblox_dart/luau/expression/luau_binary_expression.dart';
import 'package:roblox_dart/luau/expression/luau_index_expression.dart';
import 'package:roblox_dart/luau/expression/luau_list_literal.dart';
import 'package:roblox_dart/luau/expression/luau_literal.dart';
import 'package:roblox_dart/luau/expression/luau_map_literal.dart';
import 'package:roblox_dart/luau/luau_node.dart';

mixin LiteralVisitor on RobloxVisitorBase {
  @override
  LuauNode? visitNullLiteral(NullLiteral node) {
    return LuauLiteral(value: "nil");
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
  LuauNode? visitInterpolationString(InterpolationString node) {
    String safeValue = node.value
        .replaceAll('\\', r'\\')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('`', r'\`');

    return LuauLiteral(value: safeValue);
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
}
