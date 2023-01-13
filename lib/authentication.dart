import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:contacts_service/contacts_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:webcontent_converter/page.dart';
import 'package:webcontent_converter/webcontent_converter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'firebase_options.dart';
import 'authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';





class Confessions extends StatefulWidget{
  const Confessions({super.key, required this.title});

  final String title;
  @override
  State<Confessions> createState() => _ConfessionState();
}
class _ConfessionState extends State<Confessions>{

  @override
  void initState() {
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: Container(
        child: Text("Helo god"),
      ),

    );
  }

}



class HomePage extends StatefulWidget{
  const HomePage({super.key, required this.title,required this.Key});
  final String title;
  final String Key;
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {

  int _currentIndex = 0;
  String _key = "";

  Widget homPage(){
    if(_currentIndex==1){
      return Chats(title: "Messages");
    }else if(_currentIndex==0){
      return const Notices(title: "Notices");
    }else if(_currentIndex==2){
      return const Search(title: "Search People");
    }else{
      return const Account(title: "My Account",);
    }
  }
  @override
  void initState() {
    _key = widget.Key;
    super.initState();
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: homPage(),
      // floatingActionButton: FloatingActionButton(
      //   child: icon(),
      //   onPressed: (){
      //     floatingaction();
      //   },
      // ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.onSurface,
        unselectedItemColor: colorScheme.onSurface.withOpacity(.60),
        currentIndex: _currentIndex,
        onTap: (i){
          setState(() {
            _currentIndex = i;
          });
        },
        items: [
          BottomNavigationBarItem(
            label: "Notices",
            icon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            label: "Messages",
            icon: Icon(Icons.chat),
          ),
          // BottomNavigationBarItem(
          //   label: "confession",
          //   icon: Icon(Icons.home_work),
          // ),
          BottomNavigationBarItem(
            label: "Search",
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            label: "Account",
            icon: Icon(Icons.account_box),
          ),

        ],
      ),
    );
  }

}



class Notices extends StatefulWidget{
  const Notices({super.key, required this.title});

  final String title;
  @override
  State<Notices> createState() => _NoticesState();
}
class _NoticesState extends State<Notices>{

  @override
  void initState() {
    super.initState();
    initF();
  }
  initF() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ph = prefs.getString('number');
    final String? isPro = prefs.getString('professionalDetail');
    key = prefs.getString("ky")!;
    if(isPro==null){
      isProf = false;
      return;
    }
    else{
      setState((){
        isProf = true;
      });
    }
    if(ph!=null){
      phoneNumber = ph;
    }
    final int? k = prefs.getInt("latest");
    if(k!=null){
      latest = k;
    }
    else{
      FirstTime();
    }
    await getDatabasesPath().then((value) async {
      String Path = value.toString()+"/database.db";
      await openDatabase(Path,version: 1,
          onCreate: (Database db,int version) async {
            Batch b = db.batch();
            b.execute(
                """ create table AllChats(
                    id INTEGER,
                    time VARCHAR(10),
                    date VARCHAR(12),
                    message TEXT,            
                    sender TEXT,
                    receiver TEXT,                    
                    status INTEGER,
                    received VARCHAR(22),
                    read     VARCHAR(22),                    
                    ky TEXT,
                    uniq TEXT UNIQUE
                  );
              """
            );
            b.execute(
                """
            create table AllContacts(
                    number VARCHAR(20),
                    name TEXT,
                    dp TEXT,
                    ky TEXT
                  );
            """
            );
            b.execute(
                """
            create table AllNotices(
                    admin TEXT,
                    name TEXT,
                    time VARCHAR(25),
                    id INTEGER UNIQUE,
                    Subject TEXT,
                    Body TEXT,
                    status INTEGER,
                    favourite INTEGER
                  );
            """
            );
            await b.commit().then((value){
            });
          },
          onOpen: (Database db) async {
            getAllNotices(db);
            attachFirebase();
          }
      ).then((value){
        db = value;
      });
    }).catchError((e){
      ssd(e.toString()+" ssss");
    });
  }
  FirstTime() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$key/latest");
    await ref.get().then((value) async {
      if(value.exists){
        latest = value.value as int;
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt("latest", latest);
        getFavs();
      }
    });
  }
  getFavs(){
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$phoneNumber/favourites");
    ref.get().then((value){
      List<dynamic> l = value.value as List<dynamic>;
      FirebaseFirestore.instance.collection("Notices").where("id", whereIn: l).get().then((value) async {
        Batch b = db.batch();
        value.docs.forEach((element) {
          Map<String, dynamic> tm1 = element.data();

          Map<String, dynamic> tmp = new Map();
          tmp['name'] = tm1["name"];
          tmp["Subject"] = tm1["Subject"];
          tmp["Body"] = tm1["Body"];
          tmp["id"] = tm1["id"];
          tmp["time"] = tm1["time"];
          tmp["admin"] = tm1["admin"];
          tmp["status"] = 1;
          tmp["favourite"] = 1;
          b.insert("AllNotices", tmp);
        });
        await b.commit().whenComplete((){
          getAllNotices(db);
        });
      });
    });
  }

  String phoneNumber = "";
  String key = "";
  late Database db;
  bool isloading = false;
  int latest = 0;
  List<Map<String, dynamic>> _list = [];
  bool isProf = false;

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
  getAllNotices(Database d) async {
    List<String> col = ["time", "name", "admin", "max(id) as id", "count(case status when 0 then 0 else null end) as unread"];
    await d.query("AllNotices", columns: col, groupBy: "name", orderBy: "id DESC").then((value){
      setState((){
        _list = value;
      });
    }).onError((error, stackTrace){
      ssd(error.toString());
    });
  }

  attachFirebase(){
    print("started");
    CollectionReference ref = FirebaseFirestore.instance.collection("Notices");
    fs.Query q = ref.where("s",isEqualTo: 1);
    bool b = true;
    Map<String, dynamic> info = new Map();
    FirebaseDatabase.instance.ref("Users/$key/professional").get().then((value){
      value.children.forEach((e) {
        info[e.key.toString()] = e.value;
      });
      q = ref.where("College",arrayContains: info["College"]);

      // TODO make change here
      // q = ref.where("audience", whereIn: info["audience"]);
      // TODO till here
      attachFirebase2(q, info);
    });

  }
  attachFirebase2(fs.Query q, Map<String, dynamic> mp){
    q.where("id", isGreaterThan: latest).snapshots().listen((event) async {
      Batch b = db.batch();
      for(var doc in event.docs){
        Map<String, dynamic> tm1 = new Map();
        tm1 = doc.data() as Map<String, dynamic>;

        bool bb = false;
        mp.forEach((key, value) {
          List<dynamic>? s = tm1[key];
          if(s==null||s.contains(value)){}
          else{
            bb = true;
          }
        });
        if(bb){
          break;
        }

        Map<String, dynamic> tmp = new Map();
        tmp['name'] = tm1["name"];
        tmp["Subject"] = tm1["Subject"];
        tmp["Body"] = tm1["Body"];
        tmp["id"] = tm1["id"];
        tmp["time"] = tm1["time"];
        tmp["admin"] = tm1["admin"];
        tmp["status"] = 0;
        tmp["favourite"] = 0;
        b.insert("AllNotices", tmp);
        latest = max(latest, tmp["id"]);
      }
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt("latest", latest);
      DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$key/latest");
      ref.set(latest);
      await b.commit().then((value){
        getAllNotices(db);
      }).onError((error, stackTrace){
        // ssd(error.toString());
      });
    }).onError((e){
      ssd(e.toString());
    });
  }

  Widget lists(){
    if(!isProf){
      return Container(
        alignment: Alignment.center,
        child: Text("You donot have a professional account. Please add your professional details to receive notices",
        maxLines: 3,),
      );
    }
    if(_list.length==0){
      return Container(
        alignment: Alignment.center,
        child: Text("No new Notice"),
      );
    }
    return ListView.builder(
      itemCount: _list.length,
      itemBuilder: (BuildContext b, int i){
        return item(i);
      },
    );
  }
  // unread, name, admin, time
  Widget item(int i){
    Map<String, dynamic> mp = _list[i];
    int c = mp['unread'];
    String time = mp['time'].toString().split(" ")[1];
    String date = mp['time'].toString().split(" ")[0];
    String cdate = DateFormat("dd/MM/yyyy").format(DateTime.now());
    if(cdate==date) date = "";
    else{
      time = "";
    }

    return Card(
        elevation: c>0?1:0,
        color: c>0?Colors.white:Color.fromRGBO(240, 240, 240, 1.0),
        child: InkWell(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => Notices1(title: mp["name"], db: db, name: mp['name'],))).whenComplete((){
                getAllNotices(db);
              });
            },
            onLongPress: (){

            },
            child: Container(
                padding: EdgeInsets.all(4),
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                            child: Container(
                              padding: EdgeInsets.all(2),
                              child: Text(
                                mp['name'].toString(),
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            )
                        ),


                        Visibility(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              alignment: Alignment.center,
                              width: 16,
                              height: 16,
                              color: Colors.green,
                              padding: EdgeInsets.all(2),
                              child: Text(
                                c.toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          visible: c>0,
                        )

                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                            child: Container(
                              padding: EdgeInsets.all(2),
                              child: Text(
                                "Admin: "+mp['admin'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(33, 35, 36, 1.0),
                                ),
                              ),
                            )
                        ),

                        Container(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            date+time,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(33, 35, 36, 1.0),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                )




            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(
              Icons.favorite_border,
            ),
            onPressed: () async {
              if(isProf) {
                await Navigator.push(
                    context, MaterialPageRoute(builder: (context) =>
                    Notices1(title: "Favorites", db: db, name: "_favorites",)))
                    .then((value) {
                      getAllNotices(db);
                });
              }
            },
          )
        ],
      ),

      body: Container(
        child: Container(
          width: double.infinity,
          child: Column(
            children: [
              Visibility(
                visible: isloading,
                child: LinearProgressIndicator(),
              ),

              Expanded(
                child: Container(
                  padding: EdgeInsets.all(3),
                  child:  lists(),
                ),
              )
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
        ),
        onPressed: () async {
          if(isProf) {
            await Navigator.push(context, MaterialPageRoute(
                builder: (context) => NewNotice(title: "Publish a notice")))
                .then((value) {
              getAllNotices(db);
            });
          }
        },
      ),

    );
  }

}

class Notices1 extends StatefulWidget{
  const Notices1({super.key, required this.title, required this.db, required this.name});

  final String title, name;
  final Database db;
  @override
  State<Notices1> createState() => _NoticesState1();
}
class _NoticesState1 extends State<Notices1>{

  @override
  void initState() {
    super.initState();
    initF();
  }
  initF() async {
    name = widget.name;
    db = widget.db;
    final prefs = await SharedPreferences.getInstance();
    final String? ph = prefs.getString('number');
    key = prefs.getString("ky")!;
    if(ph!=null){
      phoneNumber = ph;
    }
    final int? k = prefs.getInt("latest");
    if(k!=null){
      latest = k;
    }
    getAllNotices(db);
    attachFirebase();
  }

  String key = "";
  String phoneNumber = "";
  late Database db;
  bool isloading = false;
  int latest = 0;
  String name = "";
  List<Map<String, dynamic>> _list = [];

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
  getAllNotices(Database d) async {
    // title: "Favorites",db: db, name: "_favorites"
    if(name=="_favorites"){
      await d.query("AllNotices", where: "favourite = 1", orderBy: "id DESC").then((value){
        setState((){
          _list = value;
        });
      }).onError((error, stackTrace){
        ssd(error.toString());
      });
      return;
    }
    await d.query("AllNotices", where: "name = ?", whereArgs: [name], orderBy: "id DESC").then((value){
      setState((){
        _list = value;
      });
    }).onError((error, stackTrace){
      ssd(error.toString());
    });
  }

  attachFirebase(){
    print("started");
    CollectionReference ref = FirebaseFirestore.instance.collection("Notices");
    fs.Query q = ref.where("s",isEqualTo: 1);
    bool b = true;
    Map<String, dynamic> info = new Map();
    FirebaseDatabase.instance.ref("Users/$key/professional").get().then((value){
      value.children.forEach((e) {
        info[e.key.toString()] = e.value;
        // if(b){
        //   b = false;
        //   q = ref.where(e.key!,arrayContains: e.value);
        // }
        // else{
        //   q = q.where(e.key!,arrayContains: e.value);
        // }
      });
      // TODO implement here
      q = ref.where("College",arrayContains: info["College"]);
      attachFirebase2(q, info);
    });

  }
  attachFirebase2(fs.Query q, Map<String, dynamic> mp){
    q.where("id", isGreaterThan: latest).snapshots().listen((event) async {
      Batch b = db.batch();
      for(var doc in event.docs){
        Map<String, dynamic> tm1 = new Map();
        tm1 = doc.data() as Map<String, dynamic>;

        bool bb = false;
        mp.forEach((key, value) {
          List<dynamic>? s = tm1[key];
          if(s==null||s.contains(value)){}
          else{
            bb = true;
          }
        });
        if(bb){
          break;
        }

        Map<String, dynamic> tmp = new Map();
        tmp['name'] = tm1["name"];
        tmp["Subject"] = tm1["Subject"];
        tmp["Body"] = tm1["Body"];
        tmp["id"] = tm1["id"];
        tmp["time"] = tm1["time"];
        tmp["admin"] = tm1["admin"];
        tmp["status"] = 0;
        tmp["favoutite"] = 0;
        b.insert("AllNotices", tmp);
        latest = max(latest, tmp["id"]);
      }
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt("latest", latest);
      DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$key/latest");
      ref.set(latest);
      await b.commit().then((value){
        getAllNotices(db);
      }).onError((error, stackTrace){
        // ssd(error.toString());
      });
    }).onError((e){
      ssd(e.toString());
    });
  }

  Widget lists(){
    return ListView.builder(
      itemCount: _list.length,
      itemBuilder: (BuildContext b, int i){
        return item(i);
      },
    );
  }
  // unread, name, admin, time
  Widget item(int i){
    Map<String, dynamic> mp = _list[i];
    String time = mp['time'].toString().split(" ")[1];
    String date = mp['time'].toString().split(" ")[0];
    String cdate = DateFormat("dd/MM/yyyy").format(DateTime.now());
    if(cdate==date) date = "Today";


    return Card(
        elevation: mp["status"]==0?1:0,
        color: mp["status"]==0?Colors.white:Color.fromRGBO(240, 240, 240, 1.0),
        child: InkWell(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => Notices2(title: "Groups", db: db, id: mp['id'],))).whenComplete((){
                initF();
              });
            },
            onLongPress: (){

            },
            child: Container(
                padding: EdgeInsets.all(6),
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                            child: Container(
                              padding: EdgeInsets.all(2),
                              child: Text(
                                mp['Subject'].toString(),
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            )
                        ),

                        Visibility(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              alignment: Alignment.center,
                              width: 6,
                              height: 6,
                              color: Colors.green,
                              padding: EdgeInsets.all(2),
                            ),
                          ),
                          visible: mp["status"]==0,
                        )

                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                            child: Container(
                              padding: EdgeInsets.all(2),
                              child: Text(
                                date,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(33, 35, 36, 1.0),
                                ),
                              ),
                            )
                        ),

                        Container
                          (
                          padding: EdgeInsets.all(2),
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(33, 35, 36, 1.0),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                )




            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: Container(
        child: Container(
          width: double.infinity,
          child: Column(
            children: [
              Visibility(
                visible: isloading,
                child: LinearProgressIndicator(),
              ),

              Expanded(
                child: Container(
                  padding: EdgeInsets.all(3),
                  child:  lists(),
                ),
              )
            ],
          ),
        ),
      ),

    );
  }

}

class Notices2 extends StatefulWidget{
  const Notices2({super.key, required this.title, required this.db, required this.id});

  final String title;
  final int id;
  final Database db;
  @override
  State<Notices2> createState() => _NoticesState2();
}
class _NoticesState2 extends State<Notices2>{

  @override
  void initState() {
    super.initState();
    initF();
  }
  initF() async {
    id = widget.id;
    db = widget.db;
    final prefs = await SharedPreferences.getInstance();
    final String? ph = prefs.getString('ky');
    if(ph!=null){
      key = ph;
    }
    final int? k = prefs.getInt("latest");
    if(k!=null){
      latest = k;
    }
    getNotice(db);
    // attachFirebase();
  }

  String key = "";
  late Database db;
  bool isloading = false;
  int latest = 0;
  int id = 0;
  Map<String, dynamic> _list = new Map();
  String setHTML(String b) {
    b = b.replaceAll('\n', '<br>');
    RegExp exp = RegExp(r'\s*https?://\S+');
    Iterable<RegExpMatch> matches = exp.allMatches(b);
    for( final m in matches){
      String hh = m[0]!;
      String ss = '''
        <a href = "$hh">$hh</a>
      ''';
      b = b.replaceAll(hh, ss);
    }
    return ('''
      <html>
        <head>
        </head>      
        <body style="background-color:#fff; font-size: 36px;">
          $b
        </body>
      </html>
    ''');
  }

  ssd(String ss){
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(ss),
        );
      },
    );
  }
  getNotice(Database d) async {
    await d.query("AllNotices", where: "id = ?", whereArgs: [id],).then((value) async {
      await d.update("AllNotices", {"status":1}, where: "id = $id");
      setState(() {
        _list = value[0];
      });
    }).onError((error, stackTrace){
      ssd(error.toString());
    });
  }
  updateFav(int i) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$key/favourites");
    await ref.get().then((v) async {
      List<dynamic> l = [];
      if(v.exists){
        print(v.value);
        List<dynamic> ll = v.value as List<dynamic>;
        ll.forEach((element) { l.add(element);   });
        if(i==0){
          l.remove(id);
        }
      }
      if(i==1) l.add(id);
      await ref.set(l);
    });
    await db.update("AllNotices", {"favourite":i},where: "id = $id").then((value){
      getNotice(db);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text("Notice"),
        actions: [
          IconButton(
            icon: Icon(
              _list['favourite']==0?Icons.favorite_border:Icons.favorite,
              color: _list['favourite']==0?Colors.white:Colors.red,
            ),
            onPressed: (){
              if(_list['favourite']==0){
                updateFav(1);
              }
              else{
                updateFav(0);
              }
            },
          )
        ],
      ),

      body: Container(
        padding: EdgeInsets.all(4),
        child: Column(
          children: [
            Card(
              child: Container(
                margin: EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  border: Border.all(),
                ),
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height*0.08,
                ),
                padding: EdgeInsets.all(7),
                width: double.infinity,
                child: Text(
                  _list["Subject"],
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child:  WebView(
                // zoomEnabled: true,
                initialUrl: Uri.dataFromString(
                    setHTML(_list["Body"]),
                    mimeType: 'text/html',
                    encoding: Encoding.getByName('utf-8')
                ).toString(),

              ),
            )
          ],
        ),
      ),

    );
  }
}

class NewNotice extends StatefulWidget{
  const NewNotice({super.key, required this.title});

  final String title;
  @override
  State<NewNotice> createState() => _NewNoticeState();
}
class _NewNoticeState extends State<NewNotice>{

  @override
  void initState() {
    super.initState();
    initF();
    if(Platform.isAndroid)
      WebView.platform = AndroidWebView();
  }
  initF() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ph = prefs.getString('ky');
    if(ph!=null){
      key = ph;
      getGroups();
    }
  }

  TextEditingController subj = new TextEditingController();
  TextEditingController bodyy= new TextEditingController();

  int nbar = 0;
  String generatedPdfFilePath = '';
  String groupValue = "SELECT";
  List<String> groups = ["SELECT"];
  String setHTML(String b) {
    b = b.replaceAll('\n', '<br>');
    RegExp exp = RegExp(r'\s*https?://\S+');
    Iterable<RegExpMatch> matches = exp.allMatches(b);
    for( final m in matches){
      String hh = m[0]!;
      String ss = '''
        <a href = "$hh">$hh</a>
      ''';
      b = b.replaceAll(hh, ss);
    }
    return ('''
      <html>
        <head>
        </head>      
        <body style="background-color:#fff; font-size: 36px;">
          $b
        </body>
      </html>
    ''');
  }
  String key = "";
  bool isloading = false;

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
  c(i,j){
    if(i==j){
      return Colors.white;
    }
    return Colors.black;
  }
  Future<void> generateDocument() async {
    final htmlContent = bodyy.text;
    Directory appDocDir = await getApplicationDocumentsDirectory();
    final targetPath = appDocDir.path+'/sample.pdf';
    await WebcontentConverter.contentToPDF(
      content: htmlContent,
      savedPath: targetPath,
      format: PaperFormat.a4,
      margins: PdfMargins.px(top: 55, bottom: 55, right: 55, left: 55),
    ).then((v) async {
      ssd(v!);
      File file = File(v!);
      PDFDocument doc = await PDFDocument.fromFile(file);
    }).onError((error, stackTrace){
      ssd(error.toString());
    });

  }

  getGroups() async {
    groups.clear();
    groups.add("SELECT");
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$key/Groups");
    await ref.get().then((DataSnapshot v){
      v.children.forEach((element) {
        groups.add(element.key!);
      });
      setState(() {
        groups.add("MANAGE GROUPS");
      });
    });
  }
  uploadNotice() async {
    setState(() {
      isloading = true;
    });
    Map<String, dynamic> mp = new Map();
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$key/Groups/$groupValue");
    FirebaseFirestore rr  = FirebaseFirestore.instance;
    await ref.get().then((DataSnapshot v){
      print(v.child('name').value);
      v.children.forEach((element) {
        mp[element.key!] = element.value;
      });

      // TODO make change here
      //
      // TODO till here

      mp['Subject'] = subj.text;
      mp['Body']    = bodyy.text;
      mp['id']      = DateTime.now().millisecondsSinceEpoch;
      mp['time']    = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());

      rr.collection("Notices").doc(mp["id"].toString()).set(mp).then((value){
        setState(() {
          isloading = true;
        });

        Navigator.pop(context);
      });
    }).onError((error, stackTrace){
      setState(() {
        isloading = false;
      });
      ssd(error.toString());
    });
  }

  Widget iconButtons(){
    return Flex(
      direction: Axis.horizontal,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit,
            color: c(0,nbar),
          ),
          onPressed: (){
            setState(() {
              nbar = 0;
            });
          },
        ),
        IconButton(
          icon: Icon(
            Icons.preview,
            color: c(1,nbar),
          ),
          onPressed: (){
            setState(() {
              nbar = 1;
              FocusManager.instance.primaryFocus?.unfocus();
            });
          },
        ),
        IconButton(
          icon: Icon(
            Icons.link,
            color: Colors.black,
          ),
          onPressed: (){
            setState(() {

            });
          },
        ),
        IconButton(
            icon: Icon(
              Icons.download,
              color: Colors.black,
            ),
            onPressed: () {
              // generateDocument();
            }
        ),
      ],
    );
  }
  Widget main1(){
    if(nbar==0){
      return Expanded(
        child: TextField(
          maxLines: 25,
          controller: bodyy,
          decoration: InputDecoration(
            hintText: "Body",
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 1, color: Colors.blue),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 2, color: Colors.blue),
            ),
          ),
        ),
      );
    }

    return Expanded(
        child: Container(
          child: WebView(
            // zoomEnabled: true,
            initialUrl: Uri.dataFromString(
                setHTML(bodyy.text),
                mimeType: 'text/html',
                encoding: Encoding.getByName('utf-8')
            ).toString(),

          ),
          decoration: BoxDecoration(
            border: Border.all(),
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: Container(
        padding: EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,

          children: [

            Visibility(
              visible: isloading,
              child: LinearProgressIndicator(),
            ),
            Container(
              padding: EdgeInsets.all(3),
              child: Text(
                "Select your audience :",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(52, 49, 49, 1.0),
                ),
              ),
            ),
            Container(
              child: DropdownButton<String>(
                icon: Icon(Icons.arrow_drop_down),
                iconSize: 24,
                elevation: 16,
                value: groupValue,
                items: groups.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Container(
                      child: Text(value),
                      width: MediaQuery.of(context).size.width-100,
                    ),
                  );
                }).toList(),
                onChanged: (String? data) async {
                  setState(() {
                    groupValue = data!;
                  });
                  if(groupValue=="MANAGE GROUPS"){
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => ManageGroups(title: "Groups"))).then((value){
                      initF();
                    });
                  }
                },
              ),
            ),

            // subject
            TextField(
              controller: subj,
              decoration: InputDecoration(
                  hintText: "Subject",
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(width: 1,color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(width: 1,color: Colors.blue),
                  )
              ),
            ),

            // iconbuttons container
            Container(
                margin: EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(15),topRight: Radius.circular(15)),
                  color: Colors.blue,
                ),
                child: iconButtons()
            ),

            // input box and webview container
            main1(),
          ],
        ),

      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.upload_rounded,
        ),
        onPressed: () async {
          if(groupValue!="SELECT"&&groupValue!="MANAGE YOUR GROUPS"&&subj.text.isNotEmpty&&bodyy.text.isNotEmpty){
            uploadNotice();
          }
          else{
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Empty field"),
            ));
          }
        },
      ),

    );
  }

}

class ManageGroups extends StatefulWidget{
  const ManageGroups({super.key, required this.title});

  final String title;
  @override
  State<ManageGroups> createState() => _ManageGroupState();
}
class _ManageGroupState extends State<ManageGroups>{
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initF();
  }
  initF() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ph = prefs.getString('ky');
    if(ph!=null){
      key = ph;
      getItems();
    }
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

  bool isloading = true;
  List<Map<String, dynamic>> _list = [];
  String key = "";

  getItems() async {
    _list.clear();
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$key/Groups");
    await ref.get().then((DataSnapshot v){
      v.children.forEach((element) {
        Map<String, dynamic> m = new Map();
        element.children.forEach((e) {
          m[e.key!] = e.value;
        });
        _list.add(m);
      });
      setState(() {
        isloading = false;
      });
    }).onError((error, stackTrace){
      ssd(error.toString());
    });
  }
  deleteI(int i) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$key/Groups/${_list[i]['name'].toString()}");
    await ref.remove().then((value){
      setState(() {
        _list.removeAt(i);
      });
    }).onError((error, stackTrace){
      ssd(error.toString());
    });
  }

  Widget lists(){
    return ListView.builder(
      itemCount: _list.length,
      itemBuilder: (BuildContext buildcontext, int i){
        return item(i);
      },
    );
  }
  Widget item(int i){
    Map<String, dynamic> mp = _list[i];
    return Card(
      child: Container(
        // margin: EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Color.fromRGBO(255, 254, 250, 1.0),
          ),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [

              Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(2),
                        child: Text(
                          mp['name'].toString(),
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(2),
                        child: Text(
                          "admin: ${mp['admin'].toString()}",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(50, 50, 50, 1.0)
                          ),
                        ),
                      ),
                    ],
                  )
              ),

              Container(
                child: IconButton(
                  icon: Icon(
                    Icons.delete_rounded,
                    color: Colors.red,
                  ),
                  onPressed: (){
                    deleteI(i);
                  },
                ),
              )

            ],
          )


      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: Container(
        child: Column(
          children: [
            Visibility(
              child: LinearProgressIndicator(),
              visible: isloading,
            ),
            Container(
              padding: EdgeInsets.all(3),
              margin: EdgeInsets.all(3),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => Audience(title: "Groups"))).then((value){
                      initF();
                    });
                  },
                  child: Text("New Group"),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(3),
                child: lists(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Audience extends StatefulWidget{
  const Audience({super.key, required this.title});

  final String title;
  @override
  State<Audience> createState() => _AudienceState();
}
class _AudienceState extends State<Audience>{

  @override
  initState() {
    super.initState();
    showFields();
    initF();
  }
  initF() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ph = prefs.getString('ky');
    final String? mm = prefs.getString('personalDetail');
    if(ph!=null){
      key = ph;
    }
    if(mm!=null){
      mp = jsonDecode(mm);
    }
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

  String key = "";
  Map<String, dynamic> mp = new Map();
  TextEditingController name = new TextEditingController();
  List<String> fields = ["SELECT"];
  String fieldValue = 'SELECT';
  List<String> values = ["SELECT"];
  String valueValue = 'SELECT';
  bool isloading = true;
  Map<String, dynamic> prop = new Map();
  List<String> listItems = [];

  showFields() async {
    fields.clear();
    fields.add("SELECT");
    fieldValue = "SELECT";
    DocumentReference docref = FirebaseFirestore.instance.collection("Manual").doc("Fields");
    await docref.get().then((DocumentSnapshot doc){
      print(doc.data());
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        isloading = false;
        data.values.forEach((element) {
          fields.add(element.toString());
        });
      });
    });
  }
  showValues() async {
    values.clear();
    values.add("SELECT");
    valueValue = "SELECT";
    DocumentReference docref = FirebaseFirestore.instance.collection("Manual").doc("Manual");
    await docref.collection(fieldValue).get().then((event){
      for (DocumentSnapshot doc in event.docs) {
        values.add(doc.id);
      }
      setState((){
        valueValue = "SELECT";
      });
    });
  }
  saveData() async {
    String nn = name.text;
    if(nn.isNotEmpty){
      setState(() {
        isloading = true;
      });
      prop['name'] = nn;
      prop['admin']= mp['Name'];
      prop['ky']= key;
      DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$key/Groups/$nn");
      await ref.set(prop).then((value){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Group Saved"),
        ));
        Navigator.pop(context);
      }).onError((error, stackTrace){
        setState(() {
          isloading = false;
        });
        ssd(error.toString());
      });
    }
  }

  Widget item(int i){
    List<String> l = listItems[i].split('|');
    return Container(
      margin: EdgeInsets.only(top: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Color.fromRGBO(43, 182, 187, 1.0)),
        borderRadius: BorderRadius.circular(3),
        color: Color.fromRGBO(216, 250, 255, 1.0),
      ),
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    l[0].toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      fontSize: 14,
                    ),
                  ),
                  width: double.infinity,
                ),
                Container(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    l[1].toString(),
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  width: double.infinity,
                ),
              ],
            ),
          ),
          Container(
            width: 100,
            child: IconButton(
              onPressed: (){
                setState(() {
                  listItems.removeAt(i);
                });
                // String g = prop[l[0].toString()]!;
                // List<String> ll = g.split('|');
                // if(ll.length>1){
                //   String j = "";
                //   for (var value in ll) {
                //     if(value!=l[1].toString()){
                //       j = j+"|"+value;
                //     }
                //   }
                //   j = j.substring(1);
                //   setState(() {
                //     prop[l[0]] = j;
                //   });
                // }
                // else{
                //   setState(() {
                //     prop.remove(l[0].toString());
                //   });
                // }
                List<String> g = prop[l[0]]!;
                if(g.length>1){
                  g.remove(l[1]);
                  prop[l[0]] = g;
                }
                else{
                  prop.remove(l[0]);
                }
              },
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.done),
            onPressed: (){
              saveData();
            },
          )
        ],
      ),

      body: Container(
          child: Column(
            children: [

              // progress Indicator
              Visibility(
                visible: isloading,
                child: LinearProgressIndicator(),
              ),

              // name textfield
              Container(
                child: TextField(
                  controller: name,
                  decoration: InputDecoration(
                      hintText: "Name of group",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 1,color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 1,color: Colors.blue),
                      )
                  ),
                ),
                padding: EdgeInsets.all(4),
              ),


              DropdownButton<String>(
                icon: Icon(Icons.arrow_drop_down),
                iconSize: 24,
                elevation: 16,
                value: fieldValue,
                items: fields.map<DropdownMenuItem<String>>((String value) {
                  String nn = value.split(" ").last;
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Container(
                      child: Text(value),
                      width: MediaQuery.of(context).size.width-100,
                    ),
                  );
                }).toList(),
                onChanged: (String? data) {
                  setState(() {
                    fieldValue = data!;
                    showValues();
                  });
                },
              ),
              DropdownButton<String>(
                icon: Icon(Icons.arrow_drop_down),
                iconSize: 24,
                elevation: 16,
                value: valueValue,
                items: values.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Container(
                      child: Text(value),
                      width: MediaQuery.of(context).size.width-100,
                    ),
                  );
                }).toList(),
                onChanged: (String? data) {
                  setState(() {
                    valueValue = data!;
                  });
                },
              ),

              Container(
                padding: EdgeInsets.all(4),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (){
                      // if(fieldValue!='SELECT'&&valueValue!='SELECT'){
                      //   String ff = fieldValue.split(" ").last;
                      //   if(prop.containsKey(ff)) {
                      //     List<String> f = prop[ff].toString().split('|');
                      //     if(f.contains(valueValue)){}
                      //     else {
                      //       prop[ff] = prop[ff].toString() + "|" + valueValue;
                      //       setState(() {
                      //         listItems.add(ff+"|"+valueValue);
                      //         valueValue = 'SELECT';
                      //       });
                      //     }
                      //   }
                      //   else {
                      //     prop[ff] = valueValue;
                      //     setState(() {
                      //       listItems.add(ff + "|" + valueValue);
                      //       valueValue = 'SELECT';
                      //     });
                      //   }
                      // }
                      if(fieldValue!='SELECT'&&valueValue!='SELECT'){
                        String ff = fieldValue.split(" ").last;
                        if(prop.containsKey(ff)) {
                          List<String> f = prop[ff];
                          if(f.contains(valueValue)){}
                          else {
                            prop[ff].add(valueValue);
                            setState(() {
                              listItems.add(ff+"|"+valueValue);
                              valueValue = 'SELECT';
                            });
                          }
                        }
                        else {
                          List<String> f = [valueValue];
                          prop[ff] = f;
                          setState(() {
                            listItems.add(ff + "|" + valueValue);
                            valueValue = 'SELECT';
                          });
                        }
                      }
                    },
                    child: Text(
                      "Add filter",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    style: TextButton.styleFrom(primary: Colors.blue),
                  ),
                ),
              ),

              Expanded(
                child: Container(
                  padding: EdgeInsets.all(4),
                  child: ListView.builder(
                    itemCount: listItems.length,
                    itemBuilder: (BuildContext buildc, int index){
                      return item(index);
                    },
                  ),
                ),
              )
            ],
          )
      ),

    );
  }

}

