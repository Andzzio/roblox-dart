class Instance {
  external String name;
  external String className;
  external Instance? parent;

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

  external static T of<T extends Instance>();
}
