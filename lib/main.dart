import 'dart:async';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
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
  const ChatPage({super.key,required this.map,required this.number, required this.db, required this.allC});
  final Map map;
  final String number;
  final Database db;
  final Map<String,String> allC;

  @override
  State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage>{

  List<Map> messages = [];
  TextEditingController mesBox = new TextEditingController();
  ScrollController lstview = new ScrollController();
  String _number = '';
  late Database db;
  var recievedd;
  var sentt;

  Map<String,dynamic> mp={};
  Map<String,String> allContacts = {};

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
  Widget status(int i){
    print(i);
    if(i==1){
      return Icon(
        size: 9,
        Icons.done_all_sharp
      );
    }
    if(i==2){
      return Icon(
        size: 9,
        Icons.done_all_rounded,
        color: Colors.red,
      );
    }
    return Icon(
      size: 9,
      Icons.done
    );
  }
  Widget recievedMessage(Map mes){

    return Container(
      child: Row(
        children: [
          Flexible(
            child: Card(
              color: Color.fromRGBO(10,170,180,0.3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      minWidth: 80,
                      maxWidth: MediaQuery.of(context).size.width-100,
                    ),
                    padding: EdgeInsets.all(4),
                    child: Text(mes["message"]),
                  ),
                  // Flexible(
                  Text(
                    mes["time"],
                    style: TextStyle(
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget sentMessage(Map mes){

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      minWidth: 80,
                      maxWidth: MediaQuery.of(context).size.width-100,
                    ),
                    padding: EdgeInsets.all(4),
                    child: Text(mes["message"]),
                  ),
                  Container(
                    child: Wrap(
                      direction: Axis.horizontal,
                      alignment: WrapAlignment.end,
                      children: [
                        Container(
                          child: Text(
                            mes["time"],
                            style: TextStyle(
                              fontSize: 10,
                            ),
                          ),
                          padding: EdgeInsets.all(1),

                        ),
                        Container(
                          child: status(mes["status"]),
                          padding: EdgeInsets.all(1),

                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            child: Row(
              children: [
                Flexible(
                  flex: 5,
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
                ),
                Flexible(
                  flex: 1,
                  child: IconButton(
                    onPressed: (){
                      if(mesBox.text.isNotEmpty){
                        sendMessage();
                      }
                    },
                    icon: Icon(Icons.send),
                    color: Colors.blue,
                  ),
                ),
              ],
            )
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
    // mp["new"]  = 0;
    await db.delete("contacts",where: "number = ?",whereArgs: [mp["number"].toString()]).then((value) async {
      await db.insert("contacts", mp);
    }).onError((error, stackTrace){
      ssd(error.toString()+" Contt");
    });
  }
  Future<void> getChats() async {
    await db.query(mp["number"].toString().replaceAll("+", "_"),orderBy: "id DESC").then((value){
      updateStatusMessages();
      setState((){
        messages = List.from(value);
      });
    }).catchError((e){
      
    });
  }
  void sendMessage(){
    sendMessageSQL();
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
      "reciever" : mp["number"].toString(),
      "status" : -1,
      "recieved" : "",
      "read"     : "",
      "sname"    : ""
    };
    mesBox.clear();

    await db.insert(mp["number"].toString().replaceAll("+", "_"),mpp).then((value){
      setState(() {
        messages.insert(0,mpp);
        refreshContacts();
        sendMessageToServer(mpp);
      });
    }).onError((error, stackTrace) async {
      await db.execute(
        """
        create table """+mp["number"].replaceAll("+", "_")+""" (
          message TEXT,
          sender  VARCHAR(20),
          reciever VARCHAR(20),
          time    VARCHAR(10),
          date    VARCHAR(12),
          id      INTEGER UNIQUE,
          status  INTEGER,
          recieved VARCHAR(22),
          read     VARCHAR(22),
          sname    VARCHAR(50)
        );
        """
      ).then((value) async {
        await db.insert(mp["number"].toString().replaceAll("+", "_"),mpp).then((value){
          setState(() {
            messages.insert(0,mpp);
            refreshContacts();
            sendMessageToServer(mpp);
          });
        }).onError((error, stackTrace){
          ssd(error.toString()+" SendSQL");
        });
      });
    });
  }

  updateStatusMessages() async {

    await db.query(mp["number"].toString().replaceAll("+", "_"),orderBy: "id DESC",where: "not status = ? AND reciever = ?",
        whereArgs: [2, _number]).then((value) async {
      value.forEach((element) {
        DatabaseReference outbox = FirebaseDatabase.instance.ref("Messages/"+element["sender"].toString()+"/Outbox/"+element["id"].toString());
        outbox.update({"status" : 2, "read" : DateFormat("dd-MM-yyyy HH:mm").format(DateTime.now()) });
      });
      db.update(mp["number"].toString().replaceAll("+", "_"),
          {"status" : 2, "read" : DateFormat("dd-MM-yyyy HH:mm").format(DateTime.now()) },
          where: "not status = ? AND reciever = ?",whereArgs: [2, _number]).then((value){
      }).onError((error, stackTrace){
        ssd(error.toString()+" update2");
      });
    }).onError((error, stackTrace) {
      ssd(error.toString());
    });
  }
  Future<void> sendMessageToServer(Map<String,dynamic> mpp) async {
    mpp["time"] = DateFormat("HH:mm").format(DateTime.now());
    mpp["date"] = DateFormat("dd-MM-yyyy").format(DateTime.now());
    mpp["status"] = 0;

    DatabaseReference outbox = FirebaseDatabase.instance.ref("Messages/$_number/Outbox/"+mpp["id"].toString());
    DatabaseReference inbox  = FirebaseDatabase.instance.ref("Messages/"+mp["number"].toString()+"/Inbox/"+mpp["id"].toString());

    await outbox.set(mpp).then((value) async {
      await inbox.set(mpp).then((value) async {
        await db.update(mp["number"].toString().replaceAll("+", "_"), mpp,where: "id = ?",whereArgs: [mpp["id"]]).then((value){
          getChats();
        }).onError((error, stackTrace){
          ssd(error.toString()+" senttt");
        });
      });
    }).onError((error, stackTrace){
      ssd(error.toString());
    });

  }
  attachFirebaseListener(){

    FirebaseDatabase fdb = FirebaseDatabase.instance;
    final recieved = fdb.ref("Messages/$_number/Inbox");
    final sent     = fdb.ref("Messages/$_number/Outbox");

    recievedd = recieved.onChildAdded.listen((event) async {
      Map<String, dynamic> mss = {};
      event.snapshot.children.forEach((element) {
        mss[element.key!] = element.value.toString();
      });
      String table = mss["sender"].toString().replaceAll("+", "_")!;
      Batch sqlBatch = db.batch();


      String nm = mss["sname"].toString();
      if(allContacts.containsKey(mss["sender"].toString())) {
        nm = allContacts[mss["sender"].toString()]!;
      }
      final mp = {
        "number" : mss["sender"].toString(),
        "name"   : nm,
        "time"   : mss["time"].toString(),
        "date"   : mss["date"].toString(),
        "id"     : mss["id"]
      };
      sqlBatch.execute(
          """
              create table IF NOT EXISTS """+table+""" (
                message TEXT,
                sender  VARCHAR(20),
                reciever VARCHAR(20),
                time    VARCHAR(10),
                date    VARCHAR(12),
                id      INTEGER UNIQUE,
                status  INTEGER,
                recieved VARCHAR(22),
                read     VARCHAR(22),
                sname    VARCHAR(50)
              );
              """
      );
      sqlBatch.insert(table, mss);
      sqlBatch.delete("contacts",where: "number = ?",whereArgs: [mss["sender"].toString()]);
      sqlBatch.insert("contacts", mp);

      await sqlBatch.commit().whenComplete((){
        // TODO change it according to activity
        getChats();
      });

      event.snapshot.ref.remove();
      String _time = DateFormat("dd-MM-yyyy HH:mm").format(DateTime.now());
      fdb.ref("Messages/"+mss["sender"]+"/Outbox/"+mss["id"]).update({"recieved":_time, "status":1,}).onError((error, stackTrace){
        ssd(error.toString());
      });
    });

    sentt = sent.onChildChanged.listen((event) async {
      Map<String, dynamic> mss = {};
      event.snapshot.children.forEach((element) {
        mss[element.key!] = element.value.toString();
      });
      String table = mss["reciever"].toString().replaceAll("+", "_")!;

      await db.update(table, mss,where: "id = ? " ,whereArgs: [mss["id"]]).then((value){
        // TODO change according to activity
        if((mss["status"].toString())=="2"){
          event.snapshot.ref.remove();
        }
        if(mss["reciever"].toString()==mp["number"].toString()){
          getChats();
        }
      }).onError((error, stackTrace){
        ssd(error.toString());
      });
    });

  }

  @override
  void initState() {
    _number = widget.number;
    db = widget.db;
    widget.map.forEach((key, value) {
      mp[key.toString()] = value;
    });
    widget.allC.forEach((key, value) {
      allContacts[key.toString()] = value;
    });
    getChats();
    attachFirebaseListener();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.map["name"],
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context)=>[
              PopupMenuItem(
                child: Text("delete chat"),
                onTap: () async {
                  await db.delete(mp["number"].toString().replaceAll("+", "_")).then((value){
                    setState(() {
                      getChats();
                    });
                  }).onError((error, stackTrace){

                  });
                },
              ),
            ],
          )
        ],
        leading: Row(
          children: [
            IconButton(onPressed: (){
              Navigator.pop(context);
            },
                icon: Icon(Icons.arrow_back)
            ),

            ClipRRect(
              borderRadius: BorderRadius.circular(30.0),
              child: Image.asset(
                "assets/contact.png",
                width: 40,
                height: 40,
              ),
            )
          ],
        ),
        leadingWidth: 100,
      ),
      body: mainBody(),

    );
  }
  @override
  void dispose() {
    sentt.off();
    recievedd.off();
    super.dispose();
  }
}

class NChats extends StatefulWidget{
  const NChats({super.key,required this.title,required this.number, required this.db});
  final String title;
  final String number;
  final Database db;

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
              ClipRRect(
                borderRadius: BorderRadius.circular(30.0),
                child: Image.asset(
                  "assets/contact.png",
                  height: 50,
                  width:  50,
                ),
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
              onChanged: (s) async {
                await db.query("AllContacts",where: "name like '$s%'").then((value){
                  allContact.clear();
                  setState(() {
                    value.forEach((element) {
                      allContact.add(Map<String,String>.from(element));
                    });
                  });
                });
              },
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
  Map<String,String> allC = {};
  late Database db;

  void startChat(Map mp){
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => ChatPage(map:mp,number: widget.number,db: db,allC: allC,)));
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

  filterContacts() async {

    allC.clear();
    Batch b = db.batch();
    b.execute('drop table AllContacts');
    b.execute(""" create table AllContacts(
        number VARCHAR(20),
    name TEXT
    );
    """);
    allContact.forEach((element) {
      allC[element["number"].toString()] = element["name"].toString();
      b.insert("AllContacts", element);
    });
    await b.commit().whenComplete((){
      setState(() {
        isLoading = false;
      });
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
                Map<String, String> map = {"number": num, "name": name,};
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
                    name TEXT
                  );
            """
            ).then((value){
            });
          },
      ).then((value){
        db = value;
        getAllinList();
      });
    }).catchError((e){
      ssd(e.toString()+ " 00ff");
    });
  }
  askPermissions() async {
    if (await Permission.contacts.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
      getAllinList();
    }
    else{
      ssd("Permission not granted, please enable permission for contacts");
    }
  }

  @override
  void initState() {
    db = widget.db;
    askPermissions();
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
          onLongPress: (){

          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30.0),
                child: Image.asset(
                  "assets/contact.png",
                  height: 50,
                  width:  50,
                ),
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
  late Database db;
  Map<String,String> allContacts = {};


  Future<void> getAllChats2(Database db) async {
    await db.query("contacts",orderBy: "id DESC").then((value){
      setState(() {
        chatlist = value;
        isLoading = false;
      });
    }).whenComplete((){
      getAllContacts();
    });
  }
  void getAllChats() async {
    await getDatabasesPath().then((value) async {
      Path = value.toString()+"/database.db";
      await openDatabase(Path,version: 1,
        onCreate: (Database db,int version) async {
          Batch b = db.batch();
          b.execute(
              """ create table contacts(
                    number VARCHAR(20),
                    name TEXT,
                    id INTEGER,
                    time VARCHAR(10),
                    date VARCHAR(12),
                    dp TEXT,
                    new INTEGER
                  );
              """
          );
          b.execute(
            """
            create table AllContacts(
                    number VARCHAR(20),
                    name TEXT
                  );
            """
          );
          await b.commit().then((value){
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
      ssd(e.toString()+" ssss");
    });
  }
  Future<void> startChat(Map mp) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => ChatPage(map:mp,number: _number,db: db,allC: allContacts,))).whenComplete((){
          getAllChats2(db);
    }).whenComplete((){
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
  getAllContacts() async {
    allContacts.clear();
    await db.query("AllContacts").then((value){
      value.forEach((e) {
        allContacts[e["number"].toString()] = e["name"].toString();
      });
    }).onError((error, stackTrace){
      ssd(error.toString()+" con11");
    }).whenComplete(() {
      attachFirebaseListener();
    });
  }

  attachFirebaseListener(){

    FirebaseDatabase fdb = FirebaseDatabase.instance;
    final recieved = fdb.ref("Messages/$_number/Inbox");
    final sent     = fdb.ref("Messages/$_number/Outbox");

    recieved.onChildAdded.listen((event) async {
      Map<String, dynamic> mss = {};
      event.snapshot.children.forEach((element) {
        mss[element.key!] = element.value.toString();
      });
      String table = mss["sender"].toString().replaceAll("+", "_")!;
      Batch sqlBatch = db.batch();

      String nm = mss["sname"].toString();
      if(allContacts.containsKey(mss["sender"].toString())) {
        nm = allContacts[mss["sender"].toString()]!;
      }

      final mp = {
        "number" : mss["sender"].toString(),
        "name"   : nm,
        "time"   : mss["time"].toString(),
        "date"   : mss["date"].toString(),
        "id"     : mss["id"]
      };
      sqlBatch.execute(
          """
              create table IF NOT EXISTS """+table+""" (
                message TEXT,
                sender  VARCHAR(20),
                reciever VARCHAR(20),
                time    VARCHAR(10),
                date    VARCHAR(12),
                id      INTEGER UNIQUE,
                status  INTEGER,
                recieved VARCHAR(22),
                read     VARCHAR(22),
                sname    VARCHAR(50)
              );
              """
      );
      sqlBatch.insert(table, mss);
      sqlBatch.delete("contacts",where: "number = ?",whereArgs: [mss["sender"].toString()]);
      sqlBatch.insert("contacts", mp);

      await sqlBatch.commit().whenComplete((){
        // TODO change it according to activity
        getAllChats2(db);
      });

      event.snapshot.ref.remove();
      String _time = DateFormat("dd-MM-yyyy HH:mm").format(DateTime.now());
      fdb.ref("Messages/"+mss["sender"]+"/Outbox/"+mss["id"]).update({"recieved":_time, "status":1,}).onError((error, stackTrace){
        ssd(error.toString());
      });
    });

    sent.onChildChanged.listen((event) async {
      Map<String, dynamic> mss = {};
      event.snapshot.children.forEach((element) {
        mss[element.key!] = element.value.toString();
      });
      String table = mss["reciever"].toString().replaceAll("+", "_")!;

      await db.update(table, mss,where: "id = ? " ,whereArgs: [mss["id"]]).then((value){
        // TODO change according to activity
        if(mss["status"]==2){
          ssd("ss");
          event.snapshot.ref.remove();
        }
      }).onError((error, stackTrace){
        ssd(error.toString());
      });
    });

  }

  @override
  initState() {
    super.initState();
    _number = widget.number;
    getAllChats();
    getAllContacts();
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
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => NChats(title: "New Chat",number: _number,db: db,))).then((value){
            getAllContacts();
          });
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

