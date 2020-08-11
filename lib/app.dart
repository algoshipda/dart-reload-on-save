import 'package:watcher/watcher.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  MyArgParser parser = MyArgParser(arguments);

  String dir = p.absolute(parser.input);
  String ws = parser.ws;

  DirectoryWatcher watcher = DirectoryWatcher(dir);
  VmService serviceClient = await vmServiceConnectUri(ws, log: MyLog());
  serviceClient.onSend.listen((str) => print('--> ${str}'));

  VM vm = await serviceClient.getVM();
  String isolateId = vm.isolates[0].id;
  watcher.events.listen((event) =>
      serviceClient.callMethod('s0.reloadSources', isolateId: isolateId));

  await watcher.ready;
}

class MyLog implements Log {
  void severe(String message) {
    print(message);
  }

  void warning(String message) {
    print(message);
  }
}

class MyArgParser {
  final Iterable<String> arguments;
  final ArgParser parser = ArgParser();

  ArgResults argResults;

  static String INPUT = 'input';
  static String INPUT_ABBR = 'i';
  static String WS = 'ws';
  static String WS_ABBR = 'w';

  MyArgParser(this.arguments) {
    parser.addOption(
      'input',
      abbr: 'i',
    );
    parser.addOption(
      'ws',
      abbr: 'w',
    );
    argResults = parser.parse(arguments);

    if (argResults[MyArgParser.INPUT].isEmpty) {
      throw RequiredParamNotSpecified(MyArgParser.INPUT);
    }

    if (argResults[MyArgParser.WS].isEmpty) {
      throw RequiredParamNotSpecified(MyArgParser.WS);
    }
  }

  String get input => argResults['input'];
  String get ws => argResults['ws'];
}

class RequiredParamNotSpecified implements Exception {
  String key;
  RequiredParamNotSpecified(this.key);

  String toString() => "Required param ${key} is not specified";
}
