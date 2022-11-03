// ignore_for_file: constant_identifier_names
import 'dart:io';

import 'package:collab_vm_server_dart/guacutils.dart';
import 'dart:convert';

import 'package:collab_vm_server_dart/images.dart';

enum Rank
{
  USER,
  MODERATOR,
  ADMIN;
}

class User
{
  User(this.name, this.socket);

  String name = "";
  Rank rank = Rank.USER;
  WebSocket socket;
}

class CVM
{
  List<User> users = [];
  List<User> turnQueue = [];
  String address = "";
  int port = 6004;

  CVM(this.address, this.port);

  Function()? onConnect;
  Function(String name)? onChatMessage;
  Function(WebSocket client)? onList;

  void start() async {
    final thumb = File("assets/thumbnail.png");
    Images.thumbnail = base64Encode(await thumb.readAsBytes());
    final cur = File("assets/cursor.png");
    Images.cursor = base64Encode(await cur.readAsBytes());
    HttpServer server = await HttpServer.bind(address, port);
    server.transform(WebSocketTransformer(protocolSelector: _protocol)).listen(_onWebSocketData);
  }
  dynamic _protocol(List<String> protocols){
    return 'guacamole';
  }
  User findUser(WebSocket socket){
    return users.firstWhere((element) => element.socket == socket);
  }

  void broadcast(var message)
  {
    for(var user in users){
      user.socket.add(message);
    }
  }

  void sendScreendata(WebSocket client, String data, String x, String y){
    client.add(GuacUtils.encode(["png", "14", "0", x, y, Images.cursor]));
    client.add(GuacUtils.encode(["sync", "0"]));
  }

  void _onWebSocketData(WebSocket client){
    client.listen((data) {
        final decypher = GuacUtils.decode(data);
        if(data == "3.nop;"){
          client.add("3.nop;");
        }
        if(data == "4.list;") {
          onList!(client);
        }
        if(data.startsWith("4.chat")){
          final saidUser = findUser(client);
          broadcast(GuacUtils.encode(["chat", saidUser.name, decypher[1]]));
        }
        if(data == "4.turn;"){
          client.add(GuacUtils.encode(["turn", "20000", "1", findUser(client).name]));//4.turn,5.17999,1.1,17.thug hunter lover;
        }
        if(data.startsWith("5.mouse")){
          sendScreendata(client, data, decypher[1], decypher[2]);
        } // ,1.1,1.0,3.251,3.366,1.0;
        if(data.startsWith("6.rename")){
          users.removeWhere((element) => element.socket == client);
          users.add(User(decypher[1], client));
          client.add(GuacUtils.encode(["rename", "0", "0", decypher[1], "0"]));
          client.add(GuacUtils.encode(["connect", "1", "1", "1", "0"]));
          broadcast(GuacUtils.encode(["adduser", "1", decypher[1], "0"])); // 7.adduser,1.1,9.guest9602,1.0;
          client.add(GuacUtils.encode(["size", "0", "640", "480"]));
          sendScreendata(client, Images.thumbnail, "0", "0");
        }
      }
    );
  }
}