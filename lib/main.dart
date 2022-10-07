import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite/sqflite.dart';
import 'firebase_options.dart';
import 'authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    webRecaptchaSiteKey: 'recaptcha-v3-site-key',  // If you're building a web app.
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  Widget loadingW(){
    return Container(
      alignment: Alignment.center,
      child: Text(
        "Inway",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
  Widget w(){
    return FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, AsyncSnapshot<SharedPreferences> snapshot) {
          if(snapshot.hasData) {
            return firstPage(snapshot.data);
          }
          else{
            return loadingW();
          }
        }
    );
  }
  Widget firstPage(SharedPreferences? pref) {
    SharedPreferences prefs = pref!;
    bool isDataSaved = false, islogged = false;
    if(prefs.getBool('datasaved')!=null){
      isDataSaved = prefs.getBool('datasaved')!;
    }
    if(prefs.getBool('loggedin')!=null){
      islogged    = prefs.getBool('loggedin')!;
    }
    String num = "";
    if(prefs.getString('number')!=null){
      num = prefs.getString('number')!;
    }
    if(isDataSaved!=null&&isDataSaved){
      return  HomePage(title: "Welcome",number: num,);
    }
    else if(islogged!=null&&islogged){
      return const RegistrationPage(title: "Register", i: 3);
    }
    else{
      return const RegistrationPage(title: "Register", i: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: const RegistrationPage(title: 'Welcome'),
      home: w(),
    );
  }
}


class ChatPage extends StatefulWidget{
  const ChatPage({super.key,required this.map,required this.number, required this.db});
  final Map map;
  final String number;
  final Database db;

  @override
  State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage>{

  List<Map> messages = [];
  TextEditingController mesBox = new TextEditingController();
  ScrollController lstview = new ScrollController();
  String _number = '';
  late Database db;
  Map<String,dynamic> mp={};

  Widget chats(){
    return Expanded(
      child: ListView.builder(
        controller: lstview,
          reverse: true,
          padding: const EdgeInsets.all(1),
          itemCount: messages.length,
          itemBuilder: (BuildContext context, int index) {
            return messageItem(messages[index]);
          }
      ),
    );
  }
  Widget messageItem(Map message){
    if(message["sender"]==_number){
      return sentMessage(message);
    }
    else{
      return recievedMessage(message);
    }
  }
  Widget recievedMessage(Map mes){
    return Container(
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: Card(
              color: Color.fromRGBO(10, 170, 180, 0.6),
              child: Column(
                children: [
                  Container(
                    constraints: BoxConstraints(
                        minWidth: 0,
                        maxWidth: double.infinity
                    ),
                    alignment: Alignment.topLeft,
                    child: Text(mes["message"]),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      minWidth: 0,
                      maxWidth: double.infinity
                    ),
                    alignment: Alignment.bottomRight,
                    padding: EdgeInsets.only(right: 3,bottom: 1),
                    child: Text(
                        mes["time"],
                      style: TextStyle(
                        fontSize: 10
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(),
          )
        ],
      ),
    );
  }
  Widget sentMessage(Map mes){
    return Container(
      child: Row(
        children: [
          Expanded(
            child: Container(),
          ),
          Flexible(
            flex: 3,
            child: Card(

              child: InkWell(
                splashColor: Colors.green,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 3,top: 1,right: 3),
                      constraints: BoxConstraints(
                          minWidth: 0,
                          maxWidth: double.infinity
                      ),
                      alignment: Alignment.topLeft,
                      child: Text(mes["message"]),
                    ),
                    Container(
                      constraints: BoxConstraints(
                          minWidth: 0,
                          maxWidth: double.infinity
                      ),
                      alignment: Alignment.bottomRight,
                      padding: EdgeInsets.only(right: 3,bottom: 1),
                      child: Text(
                        mes["time"],
                        style: TextStyle(
                            fontSize: 10
                        ),
                      ),
                    )
                  ],
                ),
              )
            ),
          ),
        ],
      ),
    );
  }
  Widget mainBody(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        chats(),
        Card(
          child: Container(
            margin: EdgeInsets.all(6),
            child: TextFormField(
              maxLines: 7,
              minLines: 1,
              controller: mesBox,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(

                hintText: "Type here",
                prefixIcon: IconButton(
                  icon: Icon(Icons.emoji_emotions),
                  color: Colors.black54,
                  onPressed: (){},
                ),
                suffixIcon: Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.link),
                        onPressed: (){},
                      ),
                      IconButton(
                        icon: Icon(Icons.camera_alt),
                        color: Colors.black54,
                        onPressed: (){},
                      ),
                    ],
                  ),
                )

              ),
            ),
          )
        )
      ],
    );
  }

  void ssd(String ss){
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(ss),
        );
      },
    );
  }
  Future<void> refreshContacts() async {
    mp["date"] = DateFormat("dd-MM-yyyy").format(DateTime.now());
    mp["time"] = DateFormat("HH:mm").format(DateTime.now());
    mp["id"]   = DateTime.now().millisecondsSinceEpoch;
    await db.delete("contacts",where: "number = ?",whereArgs: [mp["number"].toString()]).then((value) async {
      await db.insert("contacts", mp);
    }).onError((error, stackTrace){
      ssd(error.toString());
    });
  }
  Future<void> getChats() async {
    await db.query(mp["number"].toString().replaceAll("+", "_"),orderBy: "id DESC").then((value){
      // print(value);
      setState((){
        messages = List.from(value);
      });
    }).catchError((e){
      
    });
  }
  Future<void> sendMessageSQL() async {
    String _time = DateFormat("HH:mm").format(DateTime.now());
    String _date = DateFormat("dd-MM-yyyy").format(DateTime.now());
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    final Map<String,dynamic> mpp = {
      "date": _date,
      "time": _time,
      "id": timestamp,
      "message": mesBox.text,
      "sender" : _number,
      "status" : 0
    };
    mesBox.clear();

    await db.insert(mp["number"].toString().replaceAll("+", "_"),mpp).then((value){
      setState(() {
        messages.insert(0,mpp);
        refreshContacts();
      });
    }).onError((error, stackTrace) async {
      await db.execute(
        """
        create table """+mp["number"].replaceAll("+", "_")+""" (
          message TEXT,
          sender  VARCHAR(20),
          time    VARCHAR(10),
          date    VARCHAR(12),
          id      INTEGER,
          status  INTEGER
        );
        """
      ).then((value) async {
        await db.insert(mp["number"].toString().replaceAll("+", "_"),mpp).then((value){
          setState(() {
            messages.insert(0,mpp);
            refreshContacts();
          });
        }).onError((error, stackTrace){
          ssd(error.toString());
        });
      });
    });
    // await db.execute("INSERT INTO "+_number.toString().replaceAll("+", "_")+"")
  }

  @override
  void initState() {
    _number = widget.number;
    db = widget.db;
    widget.map.forEach((key, value) {
      mp[key.toString()] = value;
    });
    getChats();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    // return WillPopScope(
    //   onWillPop: onBackPressed,
    //   child: Scaffold(
    //       appBar: AppBar(
    //         title: Text(
    //           widget.map["name"],
    //         ),
    //       ),
    //       body: mainBody(),
    //       floatingActionButton: Container(
    //         margin: EdgeInsets.only(bottom: 40),
    //         child: FloatingActionButton(
    //           child: Icon(Icons.send),
    //           onPressed: (){
    //             if(mesBox.text.isNotEmpty){
    //               sendMessageSQL();
    //             }
    //           },
    //         ),
    //       )
    //   ),
    // );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.map["name"],
        ),
      ),
      body: mainBody(),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 40),
        child: FloatingActionButton(
          child: Icon(Icons.send),
          onPressed: (){
            if(mesBox.text.isNotEmpty){
              sendMessageSQL();
            }
          },
        ),
      )
    );
  }
  @override
  void dispose() {
    super.dispose();
  }
}

class NChats extends StatefulWidget{
  const NChats({super.key,required this.title,required this.number});
  final String title;
  final String number;

  @override
  State<NChats> createState() => _NChatState();
}
class _NChatState extends State<NChats>{


  TextEditingController searchC = TextEditingController();
  Widget allContactsItem(Map mp, String image){
    return Card(
        child: InkWell(
          onTap: (){
            startChat(mp);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                "assets/lily.jpg",
                height: 50,
                width:  50,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Text(
                          mp["name"],
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        child: Text(
                          mp["number"],
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        )
    );
  }
  Widget chatsL(List<Map> allContacts){
    if(allContacts.length>0) {
      return ListView.builder(
          padding: const EdgeInsets.all(1),
          itemCount: allContacts.length,
          itemBuilder: (BuildContext context, int index) {
            return allContactsItem(allContacts[index], "image");
          }
      );
    }
    else{
      return Container(
        child: Text("No contact"),
      );
    }
  }
  Widget ChatList(){
    return Container(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Card(
            elevation: 1,
            child: TextField(
              decoration: InputDecoration(
                  hintText: "Search",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                      Icons.search
                  )
              ),
              controller: searchC,
            ),
          ),

          Expanded(
            child: chatsL(allContact),
          )

        ],
      ),
    );
  }
  Widget Body(){
    if(isLoading){
      return Container(
        height: double.infinity,
        width: double.infinity,
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      );
    }
    else{
      return ChatList();
    }
  }

  int _index = 0;
  bool isLoading =true;
  List<Map<String,String>> allContact = [];
  List<Contact> allContacts = [];
  var db;

  void startChat(Map mp){
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => ChatPage(map:mp,number: widget.number,db: db,)));
  }
  void ssd(String ss){
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(ss),
        );
      },
    );
  }

  filterContacts(){
    setState(() {
      isLoading = false;
    });
  }
  getAllinList() async {
    await ContactsService.getContacts(withThumbnails: false)
    .then((data){
      Map<String,bool> check={};
      allContact.clear();
      data.forEach((element) {
        List<Item> nums = element.phones!;
        if(nums!=null){
          nums.forEach((e) {
            if(e.value!=null){
              String  num = e.value!;
              num = num.replaceAll(" ", "");
              num = num.replaceAll("-", "");
              if(num.length==10&&!num.startsWith("+91")){
                num = "+91$num";
              }
              if(num.length==11&&num.startsWith("0")){
                num = "+91"+num.substring(1);
              }
              if(!check.containsKey(num)) {
                String name = num;
                if (element.displayName != null) {
                  name = element.displayName!;
                }
                check[num]=true;
                Map<String, String> map = {"number": num, "name": name};
                allContact.add(map);
              }
            }
          });
        }
      });
      filterContacts();
    })
    .catchError((error){

    });
  }
  getDB() async {
    await getDatabasesPath().then((value) async {
      String Path = value.toString()+"/database.db";
      await openDatabase(Path,version: 1,
          onCreate: (Database db,int version) async {
            await db.execute(
                """ create table contacts(
                    number VARCHAR(20),
                    name TEXT,
                    time INTEGER
                  );
            """
            ).then((value){
            });
          },
      ).then((value){
        db = value;
      });
    }).catchError((e){
      ssd(e.toString());
    });
  }

  @override
  void initState() {
    getAllinList();
    getDB();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {


    print(allContact.length);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Body(),
      floatingActionButton: FloatingActionButton(
          onPressed: (){
            setState(() {
              isLoading = true;
            });
            getAllinList();
          },
        child: Icon(
            Icons.refresh,
        ),
      ),
    );
  }

}

class Chats extends StatefulWidget{
  const Chats({super.key, required this.title, required this.number});

  final String title;
  final String number;
  @override
  State<Chats> createState() => _ChatState();
}
class _ChatState extends State<Chats> with WidgetsBindingObserver{

  TextEditingController searchC = new TextEditingController();
  String _number = "";

  Widget navigationText(String s,int i){
    if(_index == i){
      return Text(
        s,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          // decoration: TextDecoration.underline,
          color: Colors.black
        ),
      );
    }
    else{
      return Text(
        s,
      );
    }
  }
  Widget chatContacts(){
    if(isLoading){
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    else{
      return ContactList();
    }
  }
  Widget ContactList(){
    if(chatlist.isEmpty){
      return Center(
        child: Text("Start a new Chat"),
      );
    }
    else{
      return ListView.builder(
          padding: const EdgeInsets.all(1),
          itemCount: chatlist.length,
          itemBuilder: (BuildContext context, int index) {
            return ContactItem(chatlist[index], "image");
          }
      );
    }
  }
  Widget ContactItem(Map mp,String image){
    return Card(
        child: InkWell(
          onTap: (){
            startChat(mp);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                "assets/lily.jpg",
                height: 50,
                width:  50,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Text(
                          mp["name"],
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        child: Text(
                          mp["number"],
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        )
    );
  }

  int _index = 0;
  bool isLoading = true;
  List<Map> chatlist = [];

  String Path = "";
  var db;


  Future<void> getAllChats2(Database db) async {
    await db.query("contacts",orderBy: "id DESC").then((value){
      setState(() {
        chatlist = value;
        isLoading = false;
      });
    }).catchError((e){
    });
  }
  void getAllChats() async {
    await getDatabasesPath().then((value) async {
      Path = value.toString()+"/database.db";
      await openDatabase(Path,version: 1,
        onCreate: (Database db,int version) async {
          await db.execute(
              """ create table contacts(
                    number VARCHAR(20),
                    name TEXT,
                    id INTEGER,
                    time VARCHAR(10),
                    date VARCHAR(12)
                  );
            """
          ).then((value){
            setState(() {
              isLoading = false;
            });
          });
        },
        onOpen: (Database db) async {
          getAllChats2(db);
        }
      ).then((value){
        db = value;
      });
    }).catchError((e){
      ssd(e.toString());
    });
  }
  Future<void> startChat(Map mp) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => ChatPage(map:mp,number: _number,db: db,))).then((value){
          getAllChats2(db);
    });
  }
  void ssd(String ss){
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(ss),
        );
      },
    );
  }


  @override
  initState() {
    super.initState();
    _number = widget.number;
    getAllChats();
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    getAllChats2(db);
    super.didChangeAppLifecycleState(state);
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: chatContacts(),

      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => NChats(title: "New Chat",number: _number,)));
        },
        child: Icon(Icons.add),
      ),
    );
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    db.close();
    super.dispose();
  }
}

