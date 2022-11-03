

import 'package:collab_vm_server_dart/cvm.dart';
import 'package:collab_vm_server_dart/guacutils.dart';
import 'package:collab_vm_server_dart/images.dart';

void main() async {
  CVM server = CVM('0.0.0.0', 5600);
  server.onList = (client){
    client.add(GuacUtils.encode(["list", "dartvm", "DartVM", Images.thumbnail]));
    client.add(GuacUtils.encode(["disconnect"]));
  };
  server.start();
}

