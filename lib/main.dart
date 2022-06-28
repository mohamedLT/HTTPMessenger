// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:messenger_clone/data_structres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:messenger_clone/server_com.dart';

//--------------Entry Point --------------------//
const MaterialColor maincolor = Colors.lightBlue;

void main() async {
  runApp(const MyApp());
  ServerCommunication.users = await ServerCommunication.getAll();
  ServerCommunication.startTimer();
  final prefs = await SharedPreferences.getInstance();
  var userName = prefs.getString('user_name');
  if (userName != null && ServerCommunication.users.isNotEmpty) {
    ServerCommunication.currentUser =
        ServerCommunication.users.firstWhere((u) => u.userName == userName);
  }
}

//----------------- App Class --------------------------//

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        () {
          ServerCommunication.setActive(ServerCommunication.currentUser, false);
        };
        break;
      case AppLifecycleState.resumed:
        () {
          ServerCommunication.setActive(ServerCommunication.currentUser, true);
        };
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'messenger_clone',
      theme: ThemeData(primarySwatch: Colors.blue, canvasColor: Colors.white),
      home: ServerCommunication.currentUser.userName.isEmpty
          ?  SignIn()
          : const AllList(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}

//------------------Main Widget ------------------------//

class chatPage extends StatefulWidget {
  final user other;
  chatPage(this.other, {Key? key}) : super(key: key) {
    ServerCommunication.currentChatingPartner = other;
  }

  @override
  State<chatPage> createState() => _chatPageState();
}

class _chatPageState extends State<chatPage> {
  ValueNotifier<bool>? isDialOpen;

  @override
  Widget build(BuildContext context) {
    ServerCommunication.state = this;
    final msgController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(user.fullName(widget.other),
            style: const TextStyle(color: Colors.black)),
      ),
//------------------------- floating action button ----------------------//
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          openCloseDial: isDialOpen,
          backgroundColor: maincolor,
          overlayColor: Colors.grey,
          overlayOpacity: 0.5,
          spacing: 15,
          spaceBetweenChildren: 15,
          children: [
            SpeedDialChild(
                backgroundColor: maincolor,
                child: const Icon(Icons.people),
                label: 'All',
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AllList(
                                fromChat: true,
                              )));
                }),
            SpeedDialChild(
                backgroundColor: maincolor,
                child: const Icon(Icons.person),
                label: 'Actives',
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ActiveList()));
                }),
          ],
        ),
      ),
//----------------- Message Cards -----------------------------//
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
              child: Column(
            children: () {
              var data = <Widget>[];
              for (var msg in ServerCommunication.currentMessages) {
                data.add(
                  MessageCard(
                      content: message(msg.data, msg.dateTime, msg.sender)),
                );
              }
              return data;
            }()
              ..add(const SizedBox(
                height: 50,
              )),
          )),
        ),
//------------------ Chat Text Field ----------------------------//
        SizedBox(
          height: 40,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Colors.grey.withOpacity(0.5)))),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: SizedBox(
                      width: MediaQuery.of(context).size.width - 50,
                      height: 30,
                      child: TextField(
                        controller: msgController,
                        decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.only(top: 2, left: 8),
                            hintText: "hi ",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20))),
                      )),
                ),
                IconButton(
                  color: maincolor,
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (msgController.text.isNotEmpty) {
                      ServerCommunication.sendMessage(
                          message(msgController.text, DateTime.now(),
                              ServerCommunication.currentUser),
                          [ServerCommunication.currentUser, widget.other]);
                    }
                  },
                )
              ],
            ),
          ),
        )
      ]),
    );
  }
}

class MessageCard extends StatefulWidget {
  const MessageCard({Key? key, required this.content}) : super(key: key);

  final message content;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  bool isSenderCurrentUser() =>
      widget.content.sender.userName ==
      ServerCommunication.currentUser.userName;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1, 4, 16, 0),
      child: LayoutBuilder(builder: ((context, constraints) {
        return Card(
          shape: const RoundedRectangleBorder(),
          color: isSenderCurrentUser()
              ? Colors.grey.withOpacity(0.2)
              : Colors.lightBlue.withOpacity(0.2),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        isSenderCurrentUser()
                            ? "me"
                            : user.fullName(widget.content.sender),
                        textAlign: TextAlign.left)),
                Divider(
                  color: Colors.white,
                  endIndent: constraints.maxWidth - 100,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.content.data,
                  ),
                ),
              ],
            ),
          ),
        );
      })),
    );
  }
}

class AllList extends StatelessWidget {
  final bool fromChat;
  const AllList({Key? key, this.fromChat = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: fromChat
            ? IconButton(
                color: maincolor,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                ),
              )
            : null,
        title: const Text("Chats", style: TextStyle(color: Colors.black)),
      ),
      body: ListView.builder(
        itemCount: ServerCommunication.users.length,
        itemBuilder: (BuildContext context, int index) {
          if (ServerCommunication.currentUser !=
              ServerCommunication.users[index]) {
            return ListTile(
              leading: Icon(
                  color: ServerCommunication.users[index].active
                      ? Colors.blue
                      : null,
                  Icons.person),
              title: Text(user.fullName(ServerCommunication.users[index])),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            chatPage(ServerCommunication.users[index])));
              },
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

class ActiveList extends StatelessWidget {
  const ActiveList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          color: maincolor,
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
        title: const Text(
          "Active Chats",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: () {
        var actives =
            (ServerCommunication.users.where((u) => u.active)).toList();
        return ListView.builder(
          itemCount: actives.length,
          itemBuilder: (BuildContext context, int index) {
            if (ServerCommunication.currentUser != actives[index]) {
              return ListTile(
                leading: const Icon(
                  Icons.person,
                  color: Colors.blue,
                ),
                title: Text(user.fullName(actives[index])),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              chatPage(ServerCommunication.users[index])));
                },
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      }(),
    );
  }
}

class SignUp extends StatefulWidget {
  SignUp({Key? key}) : super(key: key);
  @override
  State<SignUp> createState()=>SignUpState();
  
    final userNameController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final passWordController = TextEditingController();
  
  
  }
  class SignUpState extends State<SignUp>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 50,
              width: 200,
              child: TextField(
                controller: widget.userNameController,
                decoration: const InputDecoration(labelText: "User Name"),
              ),
            ),
            SizedBox(
              height: 50,
              width: 200,
              child: TextField(
                controller: widget.firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
              ),
            ),
            SizedBox(
              height: 50,
              width: 200,
              child: TextField(
                controller: widget.lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
              ),
            ),
            SizedBox(
              height: 50,
              width: 200,
              child: TextField(
                controller: widget.passWordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "PassWord"),
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                        child: const Text("Register"),
                        onPressed: () {
                          var u = user(widget.firstNameController.text,
                              widget.lastNameController.text, widget.userNameController.text);
                          ServerCommunication.sendUser(
                                  u, widget.passWordController.text)
                              .then((x) async {
                            if (x["value"]) {
                              ServerCommunication.currentUser = u;
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const AllList()));
                              ServerCommunication.users =
                                  await ServerCommunication.getAll();
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString('user_name',
                                  ServerCommunication.currentUser.userName);
                            } else {
                              final snack = SnackBar(
                                content: Text(x["reason"] != "uncorrect data"
                                    ? x["reason"]
                                    : "Error"),
                                backgroundColor: Colors.redAccent,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(snack);
                            }
                          });
                        }))),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                child: const Text("Back"),
                onPressed: () => Navigator.pop(context),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SignIn extends StatefulWidget {
  SignIn({Key? key}) : super(key: key);
  @override
  State<SignIn> createState() => SignInState();
    final userNameController = TextEditingController();
    final passwordController = TextEditingController();
 }
 class SignInState extends State<SignIn>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 50,
            width: 200,
            child: TextField(
              controller: widget.userNameController,
              decoration: const InputDecoration(labelText: "User Name"),
            ),
          ),
          SizedBox(
            height: 50,
            width: 200,
            child: TextField(
              obscureText: true,
              controller: widget.passwordController,
              decoration: const InputDecoration(labelText: "PassWord"),
            ),
          ),
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: ElevatedButton(
                  child: const Text("Sign In"),
                  onPressed: () {
                    ServerCommunication.checkUser(
                            widget.userNameController.text, widget.passwordController.text)
                        .then((x) async {
                      const snack = SnackBar(
                        content: Text("incorrect username or password"),
                        backgroundColor: maincolor,
                      );
                      if (x) {
                        ServerCommunication.currentUser =
                            ServerCommunication.users.firstWhere(
                                (u) => u.userName == widget.userNameController.text);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AllList()));
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('user_name',
                            ServerCommunication.currentUser.userName);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(snack);
                      }
                    });
                  }),
            ),
          ),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              child: const Text("Sign Up"),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) =>  SignUp()));
              },
            ),
          )
        ],
      ),
    ));
  }
}
