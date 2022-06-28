// ignore_for_file: camel_case_types
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'data_structres.dart';
import 'main.dart';

class ServerCommunication {
  static const mainURL = "http://MohamedLatifi.pythonanywhere.com";
  static user currentUser = user("", "", "");
  static user currentChatingPartner = user("", "", "");
  static var users = <user>[];
  static State<chatPage>? state;
  static List<message> currentMessages = [];
  static bool eqList(List a, List b) {
    if (a.length == b.length) {
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  static Timer? timer;

  static void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (tim) async {
      var newmsg = await getMessages(
          [currentUser.userName, currentChatingPartner.userName]);
      if (!eqList(newmsg, currentMessages)) {
        currentMessages = newmsg;
        state?.setState(() {});
      }
    });
  }

  static Future<http.Response> postRequest(String path, String data) async {
    var url = Uri.parse("$mainURL/$path");
	print(url);
    return await http.post(url, body: data);
  }

  static Future<http.Response> getRequest(String path) async {
    var url = Uri.parse("$mainURL/$path");
	print(url);
    return await http.get(url);
  }

  static Future<dynamic> sendData(String mode, String path,
      [String data = ""]) async {
    if (mode.toLowerCase().contains("p")) {
      var response = await postRequest(path, data);
      return jsonDecode(response.body);
    } else {
      var response = await getRequest(path);
      return jsonDecode(response.body);
    }
  }

  static Future<List<user>> getAll() async {
    List<dynamic> data = await sendData("g", "list");
    var users = <user>[];
    for (Map<String, dynamic> obj in data) {
      var name = obj["full_name"].toString().split(" ");
      users.add(user(name[0], name[1], obj["user_name"], obj["active"]));
    }
	print(users.length);
    return users;
  }

  static Future<void> sendMessage(message msg, List<user> users) async {
    var data = {
      "time": DateFormat('d/M/y H:m').format(msg.dateTime),
      "sender": msg.sender.userName,
      "users": [for (var u in users) u.userName],
      "content": msg.data
    };
    await sendData("p", "addmsg", jsonEncode(data));
  }

  static Future<Map<String, dynamic>> setActive(user u, bool active) async {
    var data = {
      "user_name": u.userName,
      "active": active,
    };
    Map<String, dynamic> respose =
        await sendData("p", "setactive", jsonEncode(data));
    u.active = active;
    return respose;
  }

  static Future<Map<String, dynamic>> sendUser(user u, String password) async {
    var data = {
      "full_name": "${u.firstName} ${u.lastName}",
      "user_name": u.userName,
      "password": sha256.convert(utf8.encode(password)).toString(),
    };
    Map<String, dynamic> respose =
        await sendData("p", "user", jsonEncode(data));
    return respose;
  }

  static Future<bool> checkUser(String userName, String password) async {
    var data = {
      "user_name": userName,
      "password": sha256.convert(utf8.encode(password)).toString(),
    };
    var respose = await sendData("p", "check", jsonEncode(data));
    return respose["value"];
  }

  static Future<List<message>> getMessages(List<String> users) async {
    var data = {
      "users": users,
    };
    List<dynamic> respose = await sendData("p", "getmsg", jsonEncode(data));
    var messages = <message>[];
    for (var res in respose) {
      var u = ServerCommunication.users
          .firstWhere((us) => us.userName == res["sender"]);
      messages.add(message(
          res["content"], DateFormat('d/M/y H:m').parse(res["time"]), u));
    }
    return messages;
  }
}
