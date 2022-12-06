import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
    final bool? isDataSaved = prefs.getBool('datasaved');
    final bool?     islogged = prefs.getBool('loggedin');
    if(isDataSaved!=null&&isDataSaved){
      nextPage();
    }
    else if(islogged!=null&&islogged){
      setState(() {
        index = 3;
      });
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
        docref = docref.collection(heading).doc(courseValue);
        showListItems(mp[courseValue]);
      }
    }
    else{
      showListItems(heading);
    }
  }
  void nextPage(){
    try {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => HomePage(title: "Welcome",number: phoneNumber,)));
    }
    on Exception catch(e){
      ssd(e.toString());
    }
  }
  List<String> coursesItems = ["SELECT"];
  String courseValue = "SELECT";
  Map<String,dynamic> mp = new Map();



  // firebase functions
  String verificationID = "";
  String heading = "College";
  var edb = FirebaseFirestore.instance;
  var user = <String, dynamic>{};
  DocumentReference docref = FirebaseFirestore.instance.collection("Manual").doc("Manual");
  saveBasicDetails(String name,String dob,String num){
    var db = FirebaseFirestore.instance;
    user["Name"] = name;
    user["DOB"] = dob;
    user["Phone"] = num;
    db.collection("Users").doc(num).set(user)
        .then((value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('datasaved', true);
      await prefs.setString("number", phoneNumber);
      setState(() {
        isLoading = false;
        index = 4;
        showListItems(heading);
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
  saveEducationalDetails(){
    var db  = FirebaseFirestore.instance;
    try{
      db.collection("Users").doc(phoneNumber).set(user)
          .then((value){
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
    on FirebaseException catch(e){
      ssd(e.toString());
    }
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
          index = 3;
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
      await auth.signInWithCredential(cred).then(
              (value) {
            setState(() {
              isLoading = false;
              index = 3;
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
      heading = s;
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
              child: Text("Enter the verification code recieved on your phone number")
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
              child: Text("Please fill your educational details to connect to your batchmates")
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
                    child: Text(value),
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
    if(index==2) return page2();
    if(index==3) return page3();
    else return page4();
  }

  @override
  initState(){
    index = widget.i;
    CheckisLoggedin();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: pages(),
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

class Feeds extends StatefulWidget{
  const Feeds({super.key, required this.title});

  final String title;
  @override
  State<Feeds> createState() => _FeedState();
}
class _FeedState extends State<Feeds>{

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
  const HomePage({super.key, required this.title,required this.number});
  final String title;
  final String number;
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {

  int _currentIndex = 0;
  String _number = "";

  Widget homPage(){
    if(_currentIndex==1){
      return Chats(title: "Messages",number: _number,);
    }else if(_currentIndex==0){
      return const Feeds(title: "Notices");
    }else if(_currentIndex==2){
      return const Search(title: "Search People");
    }else{
      return const Account(title: "My Account",);
    }
  }
  // Widget icon(){
  //   if(_currentIndex==0){
  //     return Icon(Icons.add);
  //   }else if(_currentIndex==1){
  //     return Icon(Icons.add);
  //   }else if(_currentIndex==2){
  //     return Icon(Icons.add);
  //   }else if(_currentIndex==3){
  //     return Icon(Icons.search);
  //   }else{
  //     return Icon(Icons.edit);
  //   }
  // }

  // floatingaction(){
  //   if(_currentIndex==0){
  //     Navigator.push(context, MaterialPageRoute(builder: (context) => NChats(title: "New Chat",number: _number,)));
  //   }else if(_currentIndex==1){
  //
  //   }else if(_currentIndex==2){
  //
  //   }else if(_currentIndex==3){
  //
  //   }else{
  //
  //   }
  // }
  @override
  void initState() {
    _number = widget.number;
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
