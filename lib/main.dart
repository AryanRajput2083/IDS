import 'dart:async';
import 'dart:convert';
import 'dart:core';
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
    String key = "";
    if(prefs.getString('number')!=null){
      key = prefs.getString('number')!;
    }
    if(isDataSaved!=null&&isDataSaved){
      return  HomePage(title: "Welcome",Key : key,);
      // return const RegistrationPage(title: "Register", i: 3);
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
      title: 'IDS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: const RegistrationPage(title: 'Welcome'),
      home: w(),
    );
  }
}



class Search extends StatefulWidget{
  const Search({super.key, required this.title});

  final String title;
  @override
  State<Search> createState() => _SearchState();
}
class _SearchState extends State<Search>{

  @override
  void initState() {
    super.initState();

  }

  TextEditingController searchC = new TextEditingController();
  bool isloading = false;
  List<Map<String, dynamic>> ppl = [];
  bool srchd = false;

  search() async {
    String ff = searchC.text.trim();
    List<String> ll = searchC.text.trim().split(" ");
    if(ll.length<1){
      return;
    }
    setState(() {
      isloading = true;
    });
    await FirebaseFirestore.instance.collection("Users").where("Name",whereIn: [ff,ff.toLowerCase(),ff.toUpperCase()]).get().then((value){
      ppl.clear();
      value.docs.forEach((element) {
        ppl.add(element.data() as Map<String, dynamic>);
      });
    });
    if(ll.length>1) {
      await FirebaseFirestore.instance.collection("Users").where(
          "Name", whereIn: ll).get().then((value) {
        value.docs.forEach((element) {
          ppl.add(element.data() as Map<String, dynamic>);
        });
      });
    }
    setState(() {
      srchd = true;
      isloading = false;
    });
  }

  Widget main(){
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
                  ),
              ),
              keyboardType: TextInputType.name,
              controller: searchC,
            ),
          ),

          Expanded(
            child: results(),
          )

        ],
      ),
    );
  }
  Widget results(){
    if(isloading){
      return Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      );
    }
    if(ppl.length==0){
      return Container(
        alignment: Alignment.center,
        child: srchd?Text("No result found"):Text("search people to connect them"),
      );
    }
    return ListView.builder(
      itemCount: ppl.length,
      itemBuilder: (BuildContext ctx, int i){
        return item(i);
      },
    );
  }
  Widget item(int i){
    Map<String, dynamic> mp = ppl[i];
    bool b=(mp['dp']=='');
    return Card(
      child: InkWell(
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (context) => Profile(Key: mp["Key"], title: mp['Name'],)));
        },
        // child: Text("data"),
        child: ListTile(
          title: Text(mp['Name']),
          leading: b?CircleAvatar(
            foregroundImage: AssetImage("assets/contact.png"),
          ):CircleAvatar(
            foregroundImage: NetworkImage(mp['dp']),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: main(),

      floatingActionButton: FloatingActionButton(
        onPressed: (){
          search();
        },
        child: Icon(
          Icons.search,
        ),
      ),

    );
  }

}

class Profile extends StatefulWidget{
  const Profile({super.key, required this.title, required this.Key});
  
  final String title, Key;
  @override
  State<Profile> createState() => _ProfileState();
}
class _ProfileState extends State<Profile>{

  @override
  void initState() {
    mp['ky'] = widget.Key;
    getData();
    getdb();
    super.initState();
    initF();
  }

  bool isloading = true;
  Map<String, dynamic> mp = new Map();
  bool isprof = false;
  Map<String, dynamic> prof = new Map();
  late Database db;
  String _key = '';

  initF() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ph = await prefs.getString('number');
    final key = await prefs.getString("ky")!;
    if (key != null) {
      _key = key;
    }
  }
  getData() async {
    int g=3;
    await FirebaseDatabase.instance.ref("Users/${mp['ky']}/personal/Name").get().then((value){
      mp['name'] = value.value;
      g--;
      if(g==0){
        setState(() {
          isloading = false;
        });
      }
    });
    await FirebaseDatabase.instance.ref("Users/${mp['ky']}/personal/dp").get().then((value){
      mp['dp'] = value.value;
      g--;
      if(g==0){
        setState(() {
          isloading = false;
        });
      }
    });
    await FirebaseDatabase.instance.ref("Users/${mp['ky']}/professional").get().then((value){
      if(value.exists){
        value.children.forEach((element) {
          prof[element.key!] = element.value;
        });
        setState(() {
          isprof = true;
        });
      }
      g--;
      if(g==0){
        setState(() {
          isloading = false;
        });
      }
    });
  }
  getdb() async {
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
      ).then((value){
        db = value;
      });
    }).catchError((e){
    });
  }

  Widget main(){
    return ListView(
      children: [
        dp(),
        personal(),
        professional()
      ],
    );
  }
  Widget dp(){
    double h = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: dp2(h/4),
      ),
    );
  }
  Widget dp2(double h){
    if(mp['dp'].toString().startsWith('http')){
      return Image.network(
        mp['dp'],
        height: h,
        width:  h,
      );
    }
    return Image.asset(
      "assets/contact.png",
      height: h,
      width:  h,
    );
  }
  Widget hd(int i){
    if(i==0){
      return Text(
        "Personal Details",
        style: TextStyle(
          fontSize: 20,
          color: Colors.blueGrey,
        ),
      );
    }
    return Container();
  }
  Widget personal(){
    return Container(
      padding: EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        child: Container(
          padding: EdgeInsets.all(5),
          width: double.infinity,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                width: double.infinity,
                child: Text(
                  "Name",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                width: double.infinity,
                child: Text(
                  mp["name"].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text(
                    "Send Message",
                  ),
                  onPressed: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (context) => ChatPage(map:mp,Key: _key,db: db)));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget professional(){
    if(!isprof){
      return Container();
    }
    String s = "";
    List<dynamic> kyy= [], vlu = [];
    prof.forEach((key, value) {
      kyy.add(key);
      vlu.add(value);
    });
    return Container(
      padding: EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        child: Container(
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(
            minHeight: 100,
            maxHeight: 250,
          ),
          child: ListView.builder(
            itemCount: prof.length,
            itemBuilder: (BuildContext b, int i){
              return Container(
                child: Column(
                  children: [
                    hd(i),
                    Container(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      width: double.infinity,
                      child: Text(
                        kyy[i].toString(),
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      width: double.infinity,
                      child: Text(
                        vlu[i].toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: isloading?
      Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ):
      main(),
    );
  }

}



class Account extends StatefulWidget{
  const Account({super.key, required this.title});

  final String title;
  @override
  State<Account> createState() => _AccountState();
}
class _AccountState extends State<Account>{

  @override
  void initState() {
    initF();
    super.initState();
  }
  initF() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ph = await prefs.getString('number');
    final key = await prefs.getString("ky")!;
    if(ph!=null){
      phoneNumber = ph;
    }
    if(key!=null){
      _key = key;
    }

    FirebaseDatabase.instance.ref("Users/$_key/personal").get().then((value){
      pers = new Map();
      value.children.forEach((element) {
        pers[element.key!.toString()] = element.value!;
      });
      setState(() {
        file=pers["dp"];
      });
    });
    FirebaseDatabase.instance.ref("Users/$_key/professional").get().then((value){
      if(value.exists) {
        prof = new Map();
        value.children.forEach((element) {
          prof[element.key!.toString()] = element.value!;
        });
      }
      else{
        prof = "";
      }
      setState(() {

      });
    });
  }

  String _key = '';
  String phoneNumber = "";
  var pers = null;
  var prof = null;
  var file = null;
  late Database db;
  bool isloading = false;


  showDialogBox(){
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: Text('Action'),
          children: [
            SimpleDialogOption(
              child: Text('Remove photo'),
              onPressed: (){
                removedp();
                Navigator.of(ctx).pop();
                setState(() {
                  file = null;
                });
              },
            ),
            SimpleDialogOption(
              child: Text('Select from gallery'),
              onPressed: (){
                Navigator.of(ctx).pop();
                pickFile();
              },
            ),
          ],
        );
      },
    );
  }
  pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      await ImageCropper().cropImage(
        sourcePath: result.files.single.path!,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop the image',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true),
          IOSUiSettings(
            title: 'Crop the image',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      ).then((value){
        // TODO compress image function not working
        testCompressAndGetFile(File(value!.path));
        // setState(() {
        //   file = File(value!.path);
        // });
      }).onError((error, stackTrace){
        // ssd(error.toString());
      });
    } else {
      // User canceled the picker
    }
  }
  testCompressAndGetFile(File fil) async {
    final tmpDir = (await getTemporaryDirectory()).path;
    final targetPath = '$tmpDir/temp.jpeg';
    await FlutterImageCompress.compressAndGetFile(
      fil.absolute.path,targetPath,
      minWidth: 500,
      minHeight: 500,
    )
        .then((value){
      if(value!=null){
        setState(() {
          // file = File(fil.absolute.path);
          file = value!;
        });
        uploadDP();
      }
    }).onError((error, stackTrace){
      print(error.toString());
    });
  }
  uploadDP(){
    final storage = FirebaseStorage.instance.ref('displayPicture/${_key}.jpeg');
    final uploadTask = storage.putFile(file);
    uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) async {
      switch (taskSnapshot.state) {
        case TaskState.running:
          break;
        case TaskState.error:
        // Handle unsuccessful uploads
          print("failed to upload image");
          break;
        case TaskState.success:
          String url = await storage.getDownloadURL();
          await FirebaseDatabase.instance.ref("Users/$_key/personal/dp").set(url);
          await FirebaseFirestore.instance.collection("Users").doc(phoneNumber).update(
              {
                "dp" : url
              });
          setState(() {
            file = url;
          });
          break;
      }
    });
  }
  removedp(){
    final storage = FirebaseStorage.instance.ref('displayPicture/${_key}.jpeg');
    FirebaseFirestore.instance.collection("Users").doc(phoneNumber).update(
        {
          "dp" : ""
        });
    storage.delete().then((value) => file=null);
  }
  deleteAccount1(){
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Delete'),
          content: Text("All your data will be lost once you delete your account. Are you sure to delete your account?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text(
                "CANCEL",
                style: TextStyle(
                    color: Colors.green
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                deleteAccount2();
              },
              child: Text(
                "DELETE",
                style: TextStyle(
                    color: Colors.red
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  deleteAccount2(){
    setState(() {
      isloading = true;
    });
    int g=4;
    FirebaseDatabase.instance.ref("Messages/$_key").remove().then((value){
      g--;
      if(g==0){
        deleteAccount3();
      }
    });
    FirebaseDatabase.instance.ref("Users/$_key").remove().then((value){
      g--;
      if(g==0){
        deleteAccount3();
      }
    });
    FirebaseDatabase.instance.ref("Contacts/$phoneNumber").remove().then((value){
      g--;
      if(g==0){
        deleteAccount3();
      }
    });
    FirebaseFirestore.instance.collection("Users").doc(phoneNumber).delete().then((value){
      g--;
      if(g==0){
        deleteAccount3();
      }
    });
  }
  deleteAccount3() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await getDatabasesPath().then((value) async {
      String Path = value.toString() + "/database.db";
      await deleteDatabase(Path);
    });
    User? u = FirebaseAuth.instance.currentUser;
    if(u!=null){
      await u.delete().then((v){
        SystemNavigator.pop();
      }).onError((error, stackTrace){
        FirebaseAuth.instance.signOut();
        SystemNavigator.pop();
      });
    }
    SystemNavigator.pop();
  }
  feedbackPage() async{
    print("ffff");
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => Feedback(k: _key,))).whenComplete((){
    });
  }

  Widget dp(){
    double h = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.only(top: 8),
      child: GestureDetector(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: dp2(h/3),
        ),
        onTap: () {
          showDialogBox();
        },
      ),
    );
  }
  Widget dp2(double h){
    if(file!=null&&file.startsWith('http')){
      print("file.runtimeType2");
      return Image.network(
        file,
        height: h,
        width:  h,
      );
    }
    if(file!=null&&file!=""){
      print("file.runtimeType1");
      return Image.file(
        file,
        height: h,
        width:  h,
      );
    }
    print("file.runtimeType");
    return Image.asset(
      "assets/contact.png",
      height: h,
      width:  h,
    );
  }
  Widget hd(int i){
    if(i==0){
      return Text(
        "Professional Details",
        style: TextStyle(
          fontSize: 20,
          color: Colors.blueGrey,
        ),
      );
    }
    return Container();
  }
  Widget personalDetail(){
    if(pers==null){
      return Container(
        padding: EdgeInsets.all(8),
        child: Card(
          child: Container(
            child: LinearProgressIndicator(),
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        child: Container(
          padding: EdgeInsets.all(5),
          width: double.infinity,
          child: Column(
            children: [
              Text(
                "Personal Details",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blueGrey,
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                width: double.infinity,
                child: Text(
                  "Name",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                width: double.infinity,
                child: Text(
                  pers["Name"].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                width: double.infinity,
                child: Text(
                  "Date of Birth",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                width: double.infinity,
                child: Text(
                  pers["DOB"].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                width: double.infinity,
                child: Text(
                  "Phone number",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                width: double.infinity,
                child: Text(
                  pers["Phone"].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
  Widget professionalDetail(){
    if(prof==null){
      return Container();
    }
    if(prof==""){
      return Container(
        alignment: Alignment.center,
        child: TextButton(
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(6),
            child: Text("Add professional data to convert to professional account"),
          ),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationPage(title: "Professional Details", i: 4))).then((value){

            });
          },
        ),
      );
    }
    String s = "";
    List<dynamic> kyy= [], vlu = [];
    prof.forEach((key, value) {
      kyy.add(key);
      vlu.add(value);
    });
    return Container(
      padding: EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        child: Container(
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(
            minHeight: 100,
            maxHeight: 250,
          ),
          child: ListView.builder(
            itemCount: prof.length,
            itemBuilder: (BuildContext b, int i){
              return Container(
                child: Column(
                  children: [
                    hd(i),
                    Container(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      width: double.infinity,
                      child: Text(
                        kyy[i].toString(),
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      width: double.infinity,
                      child: Text(
                        vlu[i].toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
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
              icon: Icon(
                Icons.feedback,
              ),
              onPressed: (){
                feedbackPage();
              },
            ),
            PopupMenuButton(
              itemBuilder: (ctx)=>[
                PopupMenuItem(
                  child: Text("delete your account"),
                  value: 0,
                ),
              ],
              onSelected: (i){
                switch (i){
                  case 0:
                    deleteAccount1();
                    break;
                  default:
                    break;
                }
              },
            )
          ],
        ),

        body: isloading?
        Container(
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        )
            :
        Container(
          color: Color.fromRGBO(219, 219, 219, 1.0),
          child: ListView(
            children: [
              dp(),
              personalDetail(),
              professionalDetail()
            ],
          ),
        )

    );
  }

}

class Feedback extends StatefulWidget{
  const Feedback({super.key, required this.k});

  final String k;
  @override
  State<Feedback> createState() => _FeedbackState();
}
class _FeedbackState extends State<Feedback>{

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseDatabase.instance.ref("Users/${widget.k}/personal").get().then((value){
      value.children.forEach((e) {
        mp[e.key!] = e.value;
      });
    });
  }

  TextEditingController c = new TextEditingController();
  Map<String, dynamic> mp = new Map();

  sendF(String h){
    if(h.trim().isNotEmpty){
      mp['message'] = h.trim();
      FirebaseDatabase.instance.ref("Feedback").push().set(mp).then((value){
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feedback"),
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        width: double.infinity,
        child: TextField(
          controller: c,
          decoration: InputDecoration(
            hintText: "Enter feedback",
          ),
          maxLines: 15,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
            Icons.send_sharp
        ),
        onPressed: (){
          sendF(c.text);
        },
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
class _ChatState extends State<Chats> with WidgetsBindingObserver{

  initF() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ph1= prefs.getString("ky")!;
    if(ph1!=null){
      _key = ph1;
    }
  }
  @override
  initState() {
    super.initState();
    initF();
    getdb();
    WidgetsBinding.instance.addObserver(this);
  }

  TextEditingController searchC = new TextEditingController();
  String _key = "";

  int _index = 0;
  bool isLoading = false;
  List<Map> chatlist = [];

  String Path = "";
  late Database db;
  Map<String,String> allContacts = {};
  //name, number, key, id, dp, message, sender, unread, date, time, status
  getdb() async {
    await getDatabasesPath().then((value) async {
      Path = value.toString()+"/database.db";
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
              setState(() {
                isLoading = false;
              });
            });
          },
      ).then((value){
        db = value;
        attachFirebaseListener();
        getAllChats(db);
      });
    }).catchError((e){
      ssd(e.toString()+" ssss");
    });
  }
  getAllChats(Database db) async {
    String qu = """
      select AllContacts.name as name, AllContacts.number as number, AllChats.ky as key, max(AllChats.id) as id, AllContacts.dp as dp,
        AllChats.message as message, AllChats.sender as sender, AllChats.date as date, AllChats.time as time, AllChats.status as status,
        count(CASE WHEN not AllChats.status=2 AND not AllChats.sender="$_key" THEN 0 ELSE NULL END) as unread
        from AllChats left join AllContacts on AllContacts.ky=AllChats.ky
        where number IS NOT NULL group by key order by id desc; 
    """;
    if(widget.title=="Requests"){
      qu = """
      select AllContacts.name as name, AllContacts.number as number, AllChats.ky as key, max(AllChats.id) as id, AllContacts.dp as dp,
        AllChats.message as message, AllChats.sender as sender, AllChats.date as date, AllChats.time as time, AllChats.status as status,
        count(CASE WHEN not AllChats.status=2 AND not AllChats.sender="$_key" THEN 0 ELSE NULL END) as unread
        from AllChats left join AllContacts on AllContacts.ky=AllChats.ky
        where number IS NULL group by key order by id desc; 
      """;
    }
    await db.rawQuery(qu).then((value){
      if(widget.title=='Requests'){
        chatlist.clear();
        value.forEach((element) async {
          Map<String, dynamic> m = new Map();
          m.addAll(element);
          await FirebaseDatabase.instance.ref("Users/$_key/personal/Name").get().then((v){
            m['name'] = v.value;
          });
          chatlist.add(m);
        });
        setState(() {

        });
      }
      else {
        setState(() {
          chatlist = value;
          isLoading = false;
        });
      }
    }).onError((error, stackTrace){
      ssd(error.toString());
    });
  }
  startChat(Map mp) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => ChatPage(map:mp,Key: _key,db: db))).whenComplete((){
      getAllChats(db);
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

  attachFirebaseListener(){

    FirebaseDatabase fdb = FirebaseDatabase.instance;
    final received = fdb.ref("Messages/$_key/Inbox");
    final sent     = fdb.ref("Messages/$_key/Outbox");

    received.onChildAdded.listen((event) async {
      Map<String, dynamic> mss = {};
      event.snapshot.children.forEach((element) {
        mss[element.key!] = element.value.toString();
      });
      mss["ky"] = mss["sender"];
      db.insert("AllChats", mss).then((value){}).onError((error, stackTrace){
        ssd(error.toString());
      }).whenComplete((){
      //   TODO change according to activity
        getAllChats(db);
      });
      event.snapshot.ref.remove();
      String _time = DateFormat("dd-MM-yyyy HH:mm").format(DateTime.now());
      fdb.ref("Messages/"+mss["sender"]+"/Outbox/"+mss["id"]).update({"received":_time, "status":1,}).onError((error, stackTrace){
        ssd(error.toString());
      });
    });

    sent.onChildChanged.listen((event) async {
      Map<String, dynamic> mss = {};
      event.snapshot.children.forEach((element) {
        mss[element.key!] = element.value.toString();
      });
      db.update("AllChats", mss,where: "uniq = ? " ,whereArgs: [mss["uniq"]]).then((value){
        // TODO change according to activity
        if(mss["status"]==2){
          event.snapshot.ref.remove();
        }
      }).onError((error, stackTrace){
        ssd(error.toString());
      });
    });

  }

  Widget status(int i){
    if(i==1){
      return Icon(
        size: 14,
        Icons.done_all_sharp
      );
    }
    if(i==2){
      return Icon(
        size: 14,
        Icons.done_all_rounded,
        color: Colors.red,
      );
    }
    if(i==-1){
      return Icon(
        size: 14,
        Icons.ad_units_sharp,
      );
    }
    return Icon(
        size: 14,
        Icons.done
    );
  }
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
    String date = DateFormat("dd-MM-yyyy").format(DateTime.now());
    if(date!=mp['date']){
      date = mp['date'];
    }
    else{
      date = mp['time'];
    }
    int c = mp['unread'];
    return Card(
        child: InkWell(
          onTap: (){
            startChat(mp);
          },
          onLongPress: (){

          },
          child: Container(
            padding: EdgeInsets.all(4),
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
                child: Container(
                  padding: EdgeInsets.only(left: 4),
                  height: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              child: Text(
                                mp["name"]!=null?mp["name"]:mp[""],
                                textAlign: TextAlign.left,
                              ),
                            ),
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
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Visibility(
                            visible: mp['sender']==_key,
                            child: status(mp['status']),
                          ),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              child: Text(
                                mp["message"]!=null?mp["message"]:"NULL",
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          )
        )
    );
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    getAllChats(db);
    super.didChangeAppLifecycleState(state);
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          widget.title!='Requests'?
          IconButton(
            icon: Icon(Icons.request_quote),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => Chats(title: "Requests",))).whenComplete((){
                getAllChats(db);
              });
            },
          ):Container()
        ],
      ),

      body: chatContacts(),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => NChats(title: "New Chat", db: db,))).whenComplete((){
            getAllChats(db);
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

class NChats extends StatefulWidget{
  const NChats({super.key,required this.title, required this.db});
  final String title;
  final Database db;

  @override
  State<NChats> createState() => _NChatState();
}
class _NChatState extends State<NChats>{


  TextEditingController searchC = TextEditingController();
  Widget dp(String url) {
    // getApplicationDocumentsDirectory().then((value){
    //   final filePath = "${value.absolute}/dp/$num.jpeg";
    //   final file = File(filePath);
    //   if(file!=null){
    //     return Image.file(
    //       file,
    //       height: 50,
    //       width:  50,
    //     );
    //   }
    // }).onError((error, stackTrace){
    //   ssd(error.toString()+" jj");
    // });

    if(url!=""){
      return Image.network(
        url,
        height: 50,
        width:  50,
      );
    }
    return Image.asset(
      "assets/contact.png",
      height: 50,
      width:  50,
    );
  }
  Widget allContactsItem(Map mp, String image){
    return Card(
        child: InkWell(
          onTap: (){
            startChat(mp);
          },
          child: Container(
            padding: EdgeInsets.all(4),
            child : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: dp(mp["dp"]),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.only(bottom: 4),
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
  List<Map<String,String>> allContact1 = [];
  List<Contact> allContacts = [];
  Map<String,String> allC = {};
  late Database db;
  String key = "";
  String phoneNumber = "";

  void startChat(Map mp){
    print(mp);
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => ChatPage(map:mp,Key: key,db: db)));
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
    Batch b = db.batch();
    b.execute('drop table AllContacts');
    b.execute("""create table AllContacts(
        number VARCHAR(20),
        name TEXT,
        dp TEXT,
        ky TEXT
    );
    """);
    allContact.clear();
    int g = allContact1.length;
    for(int i=0;i<allContact1.length;i++){
      Map<String, String> element = allContact1[i];
      if(element['number']!=phoneNumber) {
        FirebaseDatabase.instance.ref("Contacts/${element["number"]}").get().then((value) async {
          if (value.exists) {
            print("here it is " + element["number"].toString());
            String h = "";
            await FirebaseDatabase.instance.ref("Users/${value.value.toString()}/personal/dp").get().then((value){
              h = value.value.toString();
            });
            element["dp"] = h;
            element["ky"]= value.value.toString();
            allC[element["number"].toString()] = element["name"].toString();
            // downloadDP(element["dp"].toString(), element["number"].toString());
            b.insert("AllContacts", element);
            setState(() {
              allContact.add(element);
              g--;
            });
            if(g==0){
              await b.commit().whenComplete((){
                setState(() {
                  isLoading = false;
                });
              });
            }
          }
          else{
            // print("not user $i");
            g--;
            if(g==0){
              await b.commit().whenComplete((){
                setState(() {
                  isLoading = false;
                });
              });
            }
          }
        });
      }
      else{
        g--;
        if(g==0){
          await b.commit().whenComplete((){
            setState(() {
              isLoading = false;
            });
          });
        }
      }
    }
  }
  downloadDP(String url,String phn) async {
    if(url==""){
      // TODO delete file if exists
      return;
    }
    // final ref = FirebaseStorage.instance.refFromURL(url);

    final ref = FirebaseStorage.instance.ref("displayPicture/$phn.jpeg");
    final appDocDir = await getApplicationDocumentsDirectory();
    final filePath = "${appDocDir.path}/dp/$phn.jpeg";
    // ssd(filePath);
    File file = File(filePath);

    var downloadTask = ref.writeToFile(file);
    downloadTask.snapshotEvents.listen((taskSnapshot) {
      switch (taskSnapshot.state) {
        case TaskState.running:
        // TODO: Handle this case.
          break;
        case TaskState.paused:
        // TODO: Handle this case.
          break;
        case TaskState.success:
          ssd("success");
        // TODO: Handle this case.
          break;
        case TaskState.canceled:
        // TODO: Handle this case.
          break;
        case TaskState.error:
          ssd("ss");
          break;
      }
    });
  }
  getAllinList() async {
    await ContactsService.getContacts(withThumbnails: false)
    .then((data){
      Map<String,bool> check={};
      allContact1.clear();
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
                allContact1.add(map);
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
  askPermissions() async {
    if (await Permission.contacts.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
      getAllinList();
    }
    else{
      ssd("Permission not granted, please enable permission for contacts");
    }
  }
  initF() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ph = prefs.getString('number');
    final String? ph1= prefs.getString("ky")!;
    if(ph!=null){
      phoneNumber = ph;
    }
    if(ph1!=null){
      key = ph1;
    }
  }

  @override
  void initState() {
    initF();
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

class ChatPage extends StatefulWidget{
  const ChatPage({super.key,required this.map, required this.Key, required this.db,});
  final Map map;
  final String Key;
  final Database db;

  @override
  State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage>{

  List<Map> messages = [];
  TextEditingController mesBox = new TextEditingController();
  ScrollController lstview = new ScrollController();
  String _key = '';
  late Database db;
  var receivedd;
  var sentt;
  String url = '';

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
    if(message["sender"]==_key){
      return sentMessage(message);
    }
    else{
      return receivedMessage(message);
    }
  }
  Widget status(int i){
    print(i);
    if(i==1){
      return Icon(
          size: 12,
          Icons.done_all_sharp
      );
    }
    if(i==2){
      return Icon(
        size: 12,
        Icons.done_all_rounded,
        color: Colors.red,
      );
    }
    if(i==-1){
      return Icon(
        size: 12,
        Icons.ad_units_sharp,
      );
    }
    return Icon(
        size: 9,
        Icons.done
    );
  }
  Widget receivedMessage(Map mes){
    return Container(
      child: Row(
        children: [
          Flexible(
            child: Card(
              color: Color.fromRGBO(123, 172, 139, 1.0),
              child: InkWell(
                onLongPress: (){
                  String d = '';
                  d= d+"Received :\n"+mes['date']+" "+mes['time'];
                  showDialogBox(d);
                },
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
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
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
              child: InkWell(
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
                onLongPress: (){
                  String d = '';
                  d= d+"Sent :\n"+mes['date']+" "+mes['time'];
                  d = d+"\nReceived :\n"+mes['received'];
                  d = d+"\nSeen :\n"+mes['read'];
                  showDialogBox(d);
                },
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

  @override
  void initState() {
    _key = widget.Key;
    db = widget.db;
    widget.map.forEach((key, value) {
      mp[key.toString()] = value;
    });
    if(!mp.containsKey('ky'))
      mp['ky'] = widget.map['key'];
    getdp();
    getChats();
    attachFirebaseListener();
    super.initState();
  }

  // todo download and save dp here
  getdp() async {
    await FirebaseStorage.instance.ref("displayPicture/${mp['ky']}.jpeg").getDownloadURL().then((value){
      setState(() {
        url = value;
      });
    });
  }
  showDialogBox(String d){
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Details'),
          content: Text(d),
          actions: [
            TextButton(onPressed: (){Navigator.of(ctx).pop();}, child: Text("OK"))
          ],
        );
      },
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
  getChats() async {
    await db.query("AllChats",where:"ky = ?", whereArgs: [mp["ky"]], orderBy: "id DESC").then((value){
      updateStatusMessages();
      print(value);
      setState((){
        messages = List.from(value);
      });
    }).catchError((e){
      ssd(e.toString());
    });
  }
  deleteAllChats() async {
    await db.delete("AllChats",where:"ky = ?", whereArgs: [mp["ky"]], ).then((value){
      getChats();
    }).catchError((e){
      ssd(e.toString());
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
      "status" : -1,
      "received" : "",
      "read"     : "",
      "uniq"    : timestamp.toString()+_key,
      "sender" : _key,
      "receiver" : mp["ky"].toString(),
      "ky"      : mp["ky"].toString(),
    };
    mesBox.clear();
    await db.insert("AllChats",mpp).then((value){
      setState(() {
        messages.insert(0,mpp);
        sendMessageToServer(mpp);
      });
    }).onError((error, stackTrace) async {
      ssd(error.toString());
    });
  }

  updateStatusMessages() async {

    await db.query("AllChats",orderBy: "id DESC",where: "not status = ? AND sender = ?",
        whereArgs: [2, mp["ky"]]).then((value) async {
      value.forEach((element) {
        DatabaseReference outbox = FirebaseDatabase.instance.ref("Messages/"+element["sender"].toString()+"/Outbox/"+element["id"].toString());
        outbox.update({"status" : 2, "read" : DateFormat("dd-MM-yyyy HH:mm").format(DateTime.now()) });
      });
      await db.update("AllChats",
          {"status" : 2, "read" : DateFormat("dd-MM-yyyy HH:mm").format(DateTime.now()) },
          where: "not status = ? AND sender = ?",  whereArgs: [2, mp["ky"]]).then((value){
      }).onError((error, stackTrace){
        ssd(error.toString()+" update2");
      });
    }).onError((error, stackTrace) {
      ssd(error.toString());
    });
  }
  sendMessageToServer(Map<String,dynamic> mpp) async {
    mpp["time"] = DateFormat("HH:mm").format(DateTime.now());
    mpp["date"] = DateFormat("dd-MM-yyyy").format(DateTime.now());
    mpp["status"] = 0;

    DatabaseReference outbox = FirebaseDatabase.instance.ref("Messages/$_key/Outbox/"+mpp["id"].toString());
    DatabaseReference inbox  = FirebaseDatabase.instance.ref("Messages/"+mp["ky"].toString()+"/Inbox/"+mpp["id"].toString());

    await outbox.set(mpp).then((value) async {
    }).onError((error, stackTrace){
      ssd(error.toString());
    });
    await inbox.set(mpp).then((value) async {

    });
    await db.update("AllChats", mpp,where: "uniq = ?",whereArgs: [mpp["uniq"]]).then((value){
      getChats();
    }).onError((error, stackTrace){
      ssd(error.toString()+" senttt");
    });

  }
  attachFirebaseListener(){

    FirebaseDatabase fdb = FirebaseDatabase.instance;
    final received = fdb.ref("Messages/$_key/Inbox");
    final sent     = fdb.ref("Messages/$_key/Outbox");

    received.onChildAdded.listen((event) async {
      Map<String, dynamic> mss = {};
      event.snapshot.children.forEach((element) {
        mss[element.key!] = element.value.toString();
      });
      print("helo "+mss.toString());
      mss["ky"] = mss["sender"];
      db.insert("AllChats", mss).whenComplete((){
        //   TODO change according to activity
        getChats();
      });
      event.snapshot.ref.remove();
      String _time = DateFormat("dd-MM-yyyy HH:mm").format(DateTime.now());
      fdb.ref("Messages/"+mss["sender"]+"/Outbox/"+mss["id"]).update({"received":_time, "status":1,}).onError((error, stackTrace){
        ssd(error.toString());
      });
    });

    sent.onChildChanged.listen((event) async {
      Map<String, dynamic> mss = {};
      event.snapshot.children.forEach((element) {
        mss[element.key!] = element.value.toString();
      });
      db.update("AllChats", mss,where: "uniq = ? " ,whereArgs: [mss["uniq"]]).then((value){
        // TODO change according to activity
        if((mss["status"])==2){
          event.snapshot.ref.remove();
        }
        if(mss["receiver"].toString()==mp["ky"].toString()){
          getChats();
        }
      }).onError((error, stackTrace){
        ssd(error.toString());
      });
    });

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
                  deleteAllChats();
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
            url==''?
            CircleAvatar(
              foregroundImage: AssetImage("assets/contact.png"),
            ):
            CircleAvatar(
              foregroundImage: NetworkImage(url),
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
    super.dispose();
  }
}



class RegistrationPage extends StatefulWidget{
  const RegistrationPage({super.key,required this.title,required this.i});
  final String title;
  final int i;

  @override
  State<RegistrationPage> createState()=> _RegistrationState();
}
class _RegistrationState extends State<RegistrationPage> with WidgetsBindingObserver{

  TextEditingController dateInput = TextEditingController();
  TextEditingController phoneInput = TextEditingController();
  TextEditingController codeInput = TextEditingController();
  TextEditingController nameInput = TextEditingController();

  int index = 1;
  String phoneNumber = "";
  bool isLoading = false;

  // normal functions
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
  Future<void> initfunction() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ss = prefs.getString('Details');
    final String? ph1 = prefs.getString('ky');
    final String? ph = prefs.getString('number');
    if(ph1!=null){
      key = ph1;
    }
    if(ph!=null){
      phoneNumber = ph;
    }
    if(ss!=null){
      user = jsonDecode(ss);
    }
    if(index==3){
      retriveBasicInfo();
    }
  }
  void page1f(){
    if(phoneInput.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("please enter your phone number"),
      ));
    }
    else{
      setState(() {
        isLoading = true;
        phoneNumber = "+91${phoneInput.text}";
        sendVerificationCode(phoneNumber);
      });
    }
  }
  void page2f(){
    if(codeInput.text.isNotEmpty) {
      setState(() {
        isLoading = true;
        verifyCode(codeInput.text);
      });
    }
  }
  void page3f(){
    if(nameInput.text.isNotEmpty&&dateInput.text.isNotEmpty){
      setState(() {
        isLoading = true;
        saveBasicDetails(nameInput.text,dateInput.text,phoneNumber);
      });
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please fill all the fields"),
      ));
    }
  }
  void page4f(){
    if(courseValue!="SELECT"){
      user[heading] = courseValue;
      if(mp[courseValue].toString()==""){
        setState(() {
          isLoading = true;
          saveEducationalDetails();
        });
      }
      else{
        showListItems(mp[courseValue]);
      }
    }
    else{
      showListItems(heading);
    }
  }
  Future<void> nextPage() async {
    try {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => HomePage(title: "Welcome",Key: key,)));
    }
    on Exception catch(e){
      ssd(e.toString());
    }
  }
  void showDialogBox(){
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: Text('Action'),
          children: [
            SimpleDialogOption(
              child: Text('Remove photo'),
              onPressed: (){
                Navigator.of(ctx).pop();
                setState(() {
                  file = null;
                });
              },
            ),
            SimpleDialogOption(
              child: Text('Select from gallery'),
              onPressed: (){
                Navigator.of(ctx).pop();
                pickFile();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      await ImageCropper().cropImage(
        sourcePath: result.files.single.path!,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop the image',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true),
          IOSUiSettings(
            title: 'Crop the image',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      ).then((value){
        // TODO compress image function not working
        testCompressAndGetFile(File(value!.path));
        // setState(() {
        //   file = File(value!.path);
        // });
      }).onError((error, stackTrace){
        // ssd(error.toString());
      });
    } else {
      // User canceled the picker
    }
  }
  Future<void> testCompressAndGetFile(File fil) async {
    final tmpDir = (await getTemporaryDirectory()).path;
    final targetPath = '$tmpDir/temp.jpeg';
    await FlutterImageCompress.compressAndGetFile(
      fil.absolute.path,targetPath,
      minWidth: 500,
      minHeight: 500,
    )
        .then((value){
      if(value!=null){
        setState(() {
          // file = File(fil.absolute.path);
          file = value!;
        });
      }
    }).onError((error, stackTrace){
      print(error.toString());
    });
  }
  Future<void> saveDPlocally()async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String path = appDocumentsDirectory.path+'/details/dp.jpeg';
    File ff = await file.copy(path);
  }
  List<String> coursesItems = ["SELECT"];
  String courseValue = "SELECT";
  Map<String,dynamic> mp = new Map();
  Map<String, dynamic> userDetail = new Map();
  var file = null;


  // firebase functions
  String imageFile = "";
  String verificationID = "";
  String heading = "College";
  String key = "";
  bool exist = false;
  var edb = FirebaseFirestore.instance;
  var user = <String, dynamic>{};
  DocumentReference docreff = FirebaseFirestore.instance.collection("Manual").doc("Manual");
  DocumentReference docref  = FirebaseFirestore.instance.collection("Manual").doc("Manual");
  retriveBasicInfo() async {
    await FirebaseFirestore.instance.collection("Users").doc(phoneNumber).get().then((value){
      if(value.exists){
        Map<String , dynamic> mp= value.data() as Map<String, dynamic>;
        print(mp);
        key = mp["Key"];
        exist = true;
        DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$key/personal");
        ref.get().then((val){
          if(val.exists){
            setState(() {
              nameInput.text = val.child('Name').value.toString();
              dateInput.text = val.child('DOB').value.toString();
              file = val.child('dp').value.toString();
            });
          }
        }).onError((error, stackTrace){
          ssd(error.toString());
        });
      }
    }).onError((error, stackTrace){
      ssd(error.toString());
    });
  }
  saveBasicDetails(String name,String dob,String num){
    user["Name"] = name;
    user["DOB"] = dob;
    user["Phone"] = num;
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users");
    if(exist){
      ref = FirebaseDatabase.instance.ref("Users/$key");
    }
    else{
      ref = FirebaseDatabase.instance.ref("Users").push();
      key = ref.key!;
      print(key);
    }
    if(file.toString().startsWith("http")){
      saveBasicDetails2(file, num,ref);
    }
    else if(file==null||file=="") {
      saveBasicDetails2("", num,ref);
    }
    else{
      final storage = FirebaseStorage.instance.ref('displayPicture/${key}.jpeg');
      final uploadTask = storage.putFile(file);
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) async {
        switch (taskSnapshot.state) {
          case TaskState.running:
            // final progress =
            //     100.0 * (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes);
            // print("Upload is $progress% complete.");
            break;
          case TaskState.error:
          // Handle unsuccessful uploads
            ssd("failed to upload image");
            setState(() {
              isLoading = false;
            });
            break;
          case TaskState.success:
            String url = await storage.getDownloadURL();
            saveDPlocally();
            saveBasicDetails2(url, num,ref);
            break;
        }
      });
    }
  }
  saveBasicDetails2(String s,String num,var ref){
    user['dp'] = s;

    user["Key"] = key;
    ref.child("personal").set(user).then((value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('datasaved', true);
      String str = jsonEncode(user);
      await prefs.setString("personalDetail", str);
      await prefs.setString("ky", key);

      if(!exist){
        await FirebaseFirestore.instance.collection("Users").doc(phoneNumber).set(user).then((value){
          setState(() {
            isLoading = false;
            index = 4;
            showListItems(heading);
            user.clear();
          });
        }).onError((error, stackTrace){
          ssd(error.toString());
        });
      }
      else{
        setState(() {
          isLoading = false;
          index = 4;
          showListItems(heading);
          user.clear();
        });
      }

      FirebaseDatabase.instance.ref("Contacts/$phoneNumber").set(key);
    }, onError: (e) {
      setState(() {
        isLoading = false;
      });
      ssd(e.toString());
    }
    );
  }
  saveEducationalDetails(){
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users/$key/professional");
    ref.set(user)
        .then((value) async {
          final prefs = await SharedPreferences.getInstance();
          String str = jsonEncode(user);
          await prefs.setString("professionalDetail", str);
          setState(() {
            isLoading = false;
            nextPage();
          });
        },
        onError: (e){
          setState(() {
            isLoading = false;
          });
          ssd(e.toString());
        }
      );
  }
  sendVerificationCode(String num) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: num,
      verificationCompleted: (PhoneAuthCredential credential) {
        signInwithCredent(credential);
      },
      verificationFailed: (FirebaseAuthException e) {},
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          isLoading = false;
          verificationID = verificationId;
          index = 2;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }
  CheckisLoggedin(){
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) async {
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedin', true);
        setState(() {
          isLoading = false;
        });
      }
      else{
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('loggedin', false);
        setState(() {
          isLoading = false;
          index = 1;
        });
      }
    });
  }
  verifyCode(String code) async {
    setState(() {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationID, smsCode: code);
      isLoading = true;
      signInwithCredent(credential);
    });
  }
  signInwithCredent(PhoneAuthCredential cred) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    try {
      await auth.signInWithCredential(cred).then((value) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString("number", phoneNumber);
            setState(() {
              isLoading = false;
              index = 3;
              retriveBasicInfo();
            });
          },
          onError: (e){
            ssd(e.toString());
            setState(() {
              isLoading = false;
              index = 1;
            });
          }
      );
    }
    on FirebaseAuthException catch(e){
      ssd(e.message.toString());
      setState(() {
        isLoading = false;
        index = 1;
      });
    }
  }
  showListItems(String s) async {
    setState(() {
      mp.clear();
      coursesItems.clear();
      coursesItems.add("SELECT");
      courseValue = "SELECT";
      isLoading = true;
      var ff = s.split(" ");
      heading = ff.last;
    });
    await docref.collection(s).get().then((event) {
      for (DocumentSnapshot doc in event.docs) {
        final d = doc.data() as Map<String,dynamic>;
        coursesItems.add(doc.id);
        mp[doc.id] = d["Next"];
      }
      setState((){
        isLoading = false;
      });
    });
  }

  Widget displayPicture(){
    if(file!=null&&file!=""){
      if(file.toString().startsWith("http")){
        return Image.network(file);
      }
      return Image.file(file);
    }
    return Image.asset('assets/contact.png');
  }
  // send verification code page
  Widget page1(){
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              margin:  EdgeInsets.all(6),
              alignment: Alignment.topLeft,
              child: Text("Enter your Phone number to create your account")
          ),


          Container(
            margin:  EdgeInsets.all(6),
            child: TextFormField(
              controller: phoneInput,
              decoration: InputDecoration(
                  prefixText: "+91",
                  hintText: "Phone Number",
                  prefixIcon: Icon(
                      Icons.person
                  )
              ),
              maxLength: 10,
              keyboardType: TextInputType.phone,
            ),
          ),


          Container(
            margin:  EdgeInsets.all(6),
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              child: Text("Send verification code"),
              onPressed: (){
                page1f();
              },
            ),
          )


        ],
      ),
    );
  }

  // verify code page
  Widget page2(){
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [

          Container(
              margin:  EdgeInsets.all(6),
              alignment: Alignment.topLeft,
              child: Text("Enter the verification code received on your phone number")
          ),


          Container(
            alignment: Alignment.center,
            padding:  EdgeInsets.all(6),
            child: TextFormField(
              controller: codeInput,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: "- - - - - -",
                contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              ),
              maxLength: 6,
              keyboardType: TextInputType.phone,
            ),
          ),


          Container(
            padding: EdgeInsets.all(6),
            margin:  EdgeInsets.all(6),
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              child: Text("Verify"),
              onPressed: (){
                page2f();
              },
            ),
          )


        ],
      ),
    );
  }

  // compulsary details like name, dob, gender page
  Widget page3(){
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              padding: EdgeInsets.all(6),
              margin:  EdgeInsets.all(6),
              alignment: Alignment.center,
              child: Text(
                "Enter your details",
                style: TextStyle(
                    fontSize: 18
                ),
              )
          ),

          Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.width*0.6,
              maxHeight: MediaQuery.of(context).size.width*0.6,
              maxWidth : MediaQuery.of(context).size.width*0.6,
            ),
            child: GestureDetector(
              child: displayPicture(),
              onTap: () {
                showDialogBox();
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(6),
            margin:  EdgeInsets.all(6),
            child: TextFormField(
              controller: nameInput,
              decoration: InputDecoration(
                hintText: "Name",
              ),
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
            ),
          ),

          Container(
            padding: EdgeInsets.all(6),
            margin:  EdgeInsets.all(6),
            child: TextFormField(
                controller: dateInput,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: "Date of Birth",
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      // DateTime.now() - not to allow to choose before today.
                      // lastDate: DateTime(2100));
                      lastDate: DateTime.now()
                  );

                  if (pickedDate !=
                      null) { //pickedDate output format => 2021-03-10 00:00:00.000
                    String formattedDate = DateFormat('yyyy-MM-dd').format(
                        pickedDate);
                    //formatted date output using intl package =>  2021-03-16
                    setState(() {
                      dateInput.text =
                          formattedDate; //set output date to TextField value.
                    });
                  }
                  else {}
                }
            ),
          ),


          Container(
            padding: EdgeInsets.all(6),
            margin:  EdgeInsets.all(6),
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              child: Text("Next"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(100, 40),
              ),
              onPressed: (){
                page3f();
              },
            ),
          )


        ],
      ),
    );
  }

  // current educational details page
  Widget page4(){
    return Container(
      margin: EdgeInsets.fromLTRB(10, 3, 10, 2),
      child: Column(
        children: [

          // title
          Container(
              margin:  EdgeInsets.all(6),
              alignment: Alignment.topLeft,
              child: Text("Please fill your professional details for professional account")
          ),

          // course selection
          Container(
            margin: EdgeInsets.only(top: 10,left: 6),
            alignment: Alignment.topLeft,
            child: Text(
              heading,
            ),
          ),
          Container(
              alignment: Alignment.topLeft,
              padding:  EdgeInsets.all(3),
              margin: EdgeInsets.all(6),
              child: DropdownButton<String>(
                icon: Icon(Icons.arrow_drop_down),
                iconSize: 24,
                elevation: 16,
                value: courseValue,
                items: coursesItems.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Container(
                      width: MediaQuery.of(context).size.width-100,
                      child: Text(
                        value,
                      ),
                    )
                  );
                }).toList(),
                onChanged: (String? data) {
                  setState(() {
                    courseValue = data!;
                  });
                },
              )
          ),

          // buttons
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin:  EdgeInsets.all(6),
                  alignment: Alignment.bottomRight,
                  child: OutlinedButton(
                    child: Text("Skip"),
                    onPressed: (){
                      nextPage();
                    },
                  ),
                ),
                Container(
                  margin:  EdgeInsets.all(6),
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    child: Text("Next"),
                    onPressed: (){
                      page4f();
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget pages(){
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Visibility(
            visible: isLoading,
            child: LinearProgressIndicator(),
          ),
          selectPage()
        ],
      ),
    );
  }
  Widget selectPage(){
    if(index==1) return page1();
    else if(index==2) return page2();
    else if(index==3) return page3();
    else return page4();
  }

  @override
  initState(){
    index = widget.i;
    print(index);
    CheckisLoggedin();
    initfunction();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: pages(),
      resizeToAvoidBottomInset: false,
    );
  }
}
