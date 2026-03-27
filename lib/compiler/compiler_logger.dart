class CompilerLogger {
  static bool verbose = false;
  static void debug(String msg) {
    if (verbose) print('[DEBUG] $msg');
  }
}
