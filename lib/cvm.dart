// ignore_for_file: constant_identifier_names
import 'dart:io';
import 'package:dart_rfb/dart_rfb.dart';
import 'package:collab_vm_server_dart/guacutils.dart';
import 'dart:convert';
import 'dart:async';
import 'package:collab_vm_server_dart/images.dart';
import 'package:image/image.dart' as img;

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
  bool connected = false;
}

class CVM
{
  List<User> users = [];
  List<User> turnQueue = [];
  RemoteFrameBufferClient vnc;
  String address = "";
  int port = 6004;

  CVM(this.address, this.port, ) : vnc = RemoteFrameBufferClient();

  Function()? onConnect;
  Function(String name)? onChatMessage;
  Function(WebSocket client)? onList;

  void start() async {
    await vnc.connect(hostname: "192.168.1.102");
    vnc.updateStream.listen(
    (final RemoteFrameBufferClientUpdate update) {
      for(var screen in update.rectangles){
        final image = img.Image(
          width: screen.width,
          height: screen.width,
          format: img.Format.uint32
        );
        if(screen.encodingType == RemoteFrameBufferEncodingType.raw()){
          for(var i = 0; i < (screen.width * screen.height); i++){
          int b = screen.byteData.getUint8(i);
          int g = screen.byteData.getUint8(i + 1);
          int r = screen.byteData.getUint8(i + 2);
          int a = screen.byteData.getUint8(i + 3);
          image.elementAt(i).b = b;
          image.elementAt(i).g = g;
          image.elementAt(i).r = r;
          image.elementAt(i).a = a;
          }
        }
        final png = base64Encode(img.encodePng(image));
        for(var user in users){
            sendScreendata(user.socket, png, screen.x.toString(), screen.y.toString());
        }
      }
    });
    vnc.handleIncomingMessages();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      vnc.requestUpdate();
    });
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
    client.add(GuacUtils.encode(["png", "14", "0", x, y, data]));
    client.add(GuacUtils.encode(["sync", "0"]));
  }

  void _onWebSocketData(WebSocket client){
    client.listen((data) {
        final decypher = GuacUtils.decode(data);
        switch(decypher[0]){
          case "nop":
            client.add("3.nop;");
            break;
          case "list":
            onList!(client);
            break;
          case "chat":
            final saidUser = findUser(client);
            broadcast(GuacUtils.encode(["chat", saidUser.name, decypher[1]]));
            break;
          case "turn":
            client.add(GuacUtils.encode(["turn", "20000", "1", findUser(client).name]));
            break;
          case "mouse":
            sendScreendata(client, Images.cursor, decypher[1], decypher[2]);
            break;
          case "rename":
            users.removeWhere((element) => element.socket == client);
            users.add(User(decypher[1], client));
            client.add(GuacUtils.encode(["rename", "0", "0", decypher[1], "0"]));
            client.add(GuacUtils.encode(["connect", "1", "1", "1", "0"]));
            broadcast(GuacUtils.encode(["adduser", "1", decypher[1], "0"])); // 7.adduser,1.1,9.guest9602,1.0;
            client.add(GuacUtils.encode(["size", "0", "640", "480"]));
            
            //sendScreendata(client, Images.thumbnail, "0", "0");
            break;
        }
      }
    );
  }
}