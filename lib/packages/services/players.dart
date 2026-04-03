import 'package:roblox_dart/packages/types/instance.dart';
import 'package:roblox_dart/packages/types/rbx_script_signal.dart';

class Players extends Instance {
  external factory Players();

  external Instance? get localPlayer;
  external int get maxPlayers;
  external int get numPlayers;
  external bool get characterAutoLoads;
  external set characterAutoLoads(bool value);
  external int get respawnTime;
  external set respawnTime(int value);

  external List<Instance> getPlayers();
  external Instance? getPlayerByUserId(int userId);
  external int getUserIdFromNameAsync(String name);
  external String getNameFromUserIdAsync(int userId);
  external String getNameFromPlayer(Instance player);

  external RBXScriptSignal<Function(Instance)> get playerAdded;
  external RBXScriptSignal<Function(Instance)> get playerRemoving;
}
