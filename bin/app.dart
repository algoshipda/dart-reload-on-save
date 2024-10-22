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
  watcher.events.listen((event) async {
    try {
      await serviceClient.callMethod('s0.reloadSources', isolateId: isolateId);
    } catch (e) {
      if (e is RPCError) {
        print('[RPCError] ${e.message}');
      } else {
        throw e;
      }
    }
  });

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
    List<List<String>> options = [
      [MyArgParser.INPUT, MyArgParser.INPUT_ABBR],
      [MyArgParser.WS, MyArgParser.WS_ABBR],
    ];

    for (var option in options) {
      String name = option[0];
      String abbr = option[1];
      parser.addOption(
        name,
        abbr: abbr,
      );
    }

    argResults = parser.parse(arguments);

    if (argResults[MyArgParser.INPUT] == null) {
      throw RequiredParamNotSpecified(MyArgParser.INPUT);
    }

    if (argResults[MyArgParser.WS] == null) {
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
