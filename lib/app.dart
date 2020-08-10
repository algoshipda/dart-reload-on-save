import 'package:watcher/watcher.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

final String dir = '/Users/hyunseokoh/Desktop/Dev/memi/lib';
final String ws = 'ws://127.0.0.1:51640/r4CNMDqdwrc=/ws';

Future<void> main() async {
  DirectoryWatcher watcher = DirectoryWatcher(dir);
  VmService serviceClient = await vmServiceConnectUri(ws, log: MyLog());
  serviceClient.onSend.listen((str) => print('--> ${str}'));

  print(await serviceClient.getVersion());

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
