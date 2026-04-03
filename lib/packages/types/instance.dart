import 'package:roblox_dart/packages/types/rbx_script_signal.dart';

class Instance {
  external String name;
  external String className;
  external Instance? parent;
  external bool archivable;

  external Instance(String className, [bool recursive]);

  external void destroy();
  external Instance? findFirstChild(String name, [bool recursive]);
  external Instance waitForChild(String name, [double? timeOut]);
  external Instance clone();
  external bool isA(String className);
  external List<Instance> getChildren();
  external List<Instance> getDescendants();
  external String getFullName();
  external bool isDescendantOf(Instance ancestor);
  external bool isAncestorOf(Instance descendant);
  external Instance? findFirstChildOfClass(String className);
  external Instance? findFirstChildWhichIsA(String className);
  external Instance? findFirstAncestorOfClass(String className);
  external Instance? findFirstDescendant(String name);
  external Instance? findFirstAncestorWhichIsA(String className);

  external void clearAllChildren();
  external RBXScriptSignal<Function(Instance)> getPropertyChangedSignal(
      String property);

  external RBXScriptSignal<Function(Instance)> get childAdded;
  external RBXScriptSignal<Function(Instance)> get childRemoved;
  external RBXScriptSignal<Function(Instance)> get descendantAdded;
  external RBXScriptSignal<Function(Instance)> get descendantRemoving;
  external RBXScriptSignal<Function(Instance, Instance)> get ancestryChanged;

  external static T of<T extends Instance>();
}
