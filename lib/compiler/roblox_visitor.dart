import 'package:roblox_dart/compiler/visitor/class_visitor.dart';
import 'package:roblox_dart/compiler/visitor/expression_visitor.dart';
import 'package:roblox_dart/compiler/visitor/import_visitor.dart';
import 'package:roblox_dart/compiler/visitor/literal_visitor.dart';
import 'package:roblox_dart/compiler/visitor/roblox_visitor_base.dart';
import 'package:roblox_dart/compiler/visitor/statement_visitor.dart';

class RobloxVisitor extends RobloxVisitorBase
    with
        ImportVisitor,
        ClassVisitor,
        ExpressionVisitor,
        StatementVisitor,
        LiteralVisitor {}
