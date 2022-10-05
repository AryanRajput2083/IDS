import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
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

  Widget w(){
    return FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, AsyncSnapshot<SharedPreferences> snapshot) {
          if(snapshot.hasData) {
            return firstPage(snapshot.data);
          }
          else{
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
        }
    );
  }
  Widget firstPage(SharedPreferences? prefs) {
    bool? isDataSaved = prefs?.getBool('datasaved');
    bool? islogged = prefs?.getBool('loggedin')!;
    if(isDataSaved!=null&&isDataSaved){
      return const HomePage(title: "Welcome");
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
  const ChatPage({super.key,required this.map});
  final Map map;

  @override
  State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage>{

  TextEditingController mesBox = new TextEditingController();
  Widget chats(){
    return Expanded(
      child: Container(),
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
  @override
  Widget build(BuildContext context) {

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

          },
        ),
      )
    );
  }

}

class NChats extends StatefulWidget{
  const NChats({super.key,required this.title});
  final String title;

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

  void startChat(Map mp){
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => ChatPage(map:mp)));
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

  @override
  void initState() {
    getAllinList();
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
  const Chats({super.key, required this.title});

  final String title;
  @override
  State<Chats> createState() => _ChatState();
}
class _ChatState extends State<Chats>{

  TextEditingController searchC = new TextEditingController();

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
  Widget allContactsItem(String name, String image){
    return Card(
      child: InkWell(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                "assets/lily.jpg",
                height: 50,
                width:  50,
              ),
              Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(name),
              )
            ],
          ),
      )
    );
  }
  Widget chatsL(contactList){
    if(contactList.length>0) {
      return ListView.builder(
          padding: const EdgeInsets.all(1),
          itemCount: chatContacts.length,
          itemBuilder: (BuildContext context, int index) {
            return allContactsItem(chatContacts[index].givenName.toString(), "image");
          }
      );
    }
    else{
      return Container(
        child: Text("Start a new Chat"),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _index = 0;
                        });
                      },
                      child: navigationText("CHATS", 0)
                  ),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _index = 1;
                        });
                      },
                      child: navigationText("GROUPS", 1)
                  ),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          _index = 2;
                        });
                      },
                      child: navigationText("NOTICES", 2)
                  ),
                ],
              ),
            ),
            Expanded(
              child: chatsL(chatContacts),
            ),
          ],
        ),
      );
  }

  int _index = 0;
  List<Contact> chatContacts = [];

  getAllChats() async {

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
    getAllChats();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: ChatList(),

    );
  }

}

