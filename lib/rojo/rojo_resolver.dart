import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

typedef RbxPath = List<String>;

class _Partition {
  final String fsPath;
  final RbxPath rbxPath;
  _Partition(this.fsPath, this.rbxPath);
}

class RojoResolver {
  final List<_Partition> _partitions = [];
  final List<String> _rbxPath = [];

  static RojoResolver fromPath(String projectJsonPath) {
    final resolver = RojoResolver();
    final file = File(projectJsonPath);
    if (!file.existsSync()) return resolver;
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    resolver._parseTree(
      p.dirname(projectJsonPath),
      '',
      json['tree'] as Map<String, dynamic>,
      doNotPush: true,
    );
    return resolver;
  }

  void _parseTree(String basePath, String name, Map<String, dynamic> tree,
      {bool doNotPush = false}) {
    if (!doNotPush) _rbxPath.add(name);

    final nodePath = tree['\$path'];
    if (nodePath is String) {
      final full = p.normalize(p.join(basePath, nodePath));
      if (Directory(full).existsSync()) {
        _partitions.insert(0, _Partition(full, List.from(_rbxPath)));
      }
    }

    for (final key in tree.keys) {
      if (!key.startsWith('\$')) {
        _parseTree(basePath, key, tree[key] as Map<String, dynamic>);
      }
    }

    if (!doNotPush) _rbxPath.removeLast();
  }

  RbxPath? getRbxPathFromFilePath(String filePath) {
    filePath = p.normalize(filePath);
    final stripped = filePath
        .replaceAll(RegExp(r'\.(server|client)\.luau$'), '')
        .replaceAll(RegExp(r'\.luau$'), '');

    for (final partition in _partitions) {
      if (p.isWithin(partition.fsPath, stripped) ||
          stripped == partition.fsPath) {
        final rel = p.relative(stripped, from: partition.fsPath);
        final parts = rel == '.' ? <String>[] : p.split(rel);
        return [...partition.rbxPath, ...parts];
      }
    }
    return null;
  }

  static List<String> relative(RbxPath from, RbxPath to) {
    int diffIndex = from.length > to.length ? from.length : to.length;
    final minLen = from.length < to.length ? from.length : to.length;
    for (int i = 0; i < minLen; i++) {
      if (from[i] != to[i]) {
        diffIndex = i;
        break;
      }
      if (i == minLen - 1) diffIndex = minLen;
    }
    return [
      for (int i = 0; i < from.length - diffIndex; i++) 'Parent',
      for (int i = diffIndex; i < to.length; i++) to[i],
    ];
  }
}
