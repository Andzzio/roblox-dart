import 'package:roblox_dart/packages/types/instance.dart';

class Players extends Instance {
  external factory Players();

  external Instance? get localPlayer;
  external int get maxPlayers;
  external int get numPlayers;

  external List<Instance> getPlayers();
  external Instance? getPlayerByUserId(int userId);
  external int getUserIdFromNameAsync(String name);
}
