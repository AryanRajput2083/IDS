import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'helper_registration.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RegistrationPage(title: 'Welcome'),
    );
  }
}

class HomePage extends StatefulWidget{
  const HomePage({super.key, required this.title});
  final String title;
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>{

  int _currentIndex = 0;
  Widget account(){
    return Container(

    );
  }
  Widget chats(){
    return Container(

    );
  }
  Widget confessions(){
    return Container(

    );
  }
  Widget posts(){
    return Container(

    );
  }
  Widget searchPage(){
    return Container(

    );
  }
  Widget homPage(){
    if(_currentIndex==0){
      return chats();
    }else if(_currentIndex==1){
      return posts();
    }else if(_currentIndex==2){
      return confessions();
    }else if(_currentIndex==3){
      return searchPage();
    }else{
      return account();
    }
  }
  final tit = [
    "Messages",
    "Posts",
    "Confessions",
    "Search",
    "Profile"
  ];
  @override
  Widget build(BuildContext context) {

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tit[_currentIndex]),
      ),

      body: homPage(),

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
            label: "messages",
            icon: Icon(Icons.chat),
          ),
          BottomNavigationBarItem(
            label: "posts",
            icon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            label: "confession",
            icon: Icon(Icons.home_work),
          ),
          BottomNavigationBarItem(
            label: "search",
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            label: "account",
            icon: Icon(Icons.account_box),
          ),

        ],
      ),
    );
  }

}

class RegistrationPage extends StatefulWidget{
  const RegistrationPage({super.key,required this.title});
  final String title;

  @override
  State<RegistrationPage> createState()=> _RegistrationState();
}
class _RegistrationState extends State<RegistrationPage> with WidgetsBindingObserver{

  TextEditingController dateInput = TextEditingController();
  TextEditingController phoneInput = TextEditingController();
  TextEditingController codeInput = TextEditingController();
  TextEditingController nameInput = TextEditingController();

  int index = 1;

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
  void page1f(){
    if(phoneInput.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("please enter your phone number"),
      ));
    }
    else{
      sendVerificationCode("+91"+phoneInput.text);
    }
  }
  void page2f(){
    if(codeInput.text.isNotEmpty) {
      verifyCode(codeInput.text);
    }
  }
  void page3f(){
    setState(() {
      index=4;
    });
  }
  void nextPage(){
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomePage(title: "Welcome")));
  }
  List<String> coursesItems = ["a","b",""];
  String courseValue = "";
  void saveDetails(){

  }


  // firebase functions
  String verificationID = "";
  sendVerificationCode(String num) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: num,
      verificationCompleted: (PhoneAuthCredential credential) {
        signInwithCredent(credential);
      },
      verificationFailed: (FirebaseAuthException e) {},
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
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
        .listen((User? user) {
      if (user != null) {
        setState(() {
          index = 3;
        });
      }
      else{
        setState(() {
          index = 1;
        });
      }
    });
  }
  verifyCode(String code) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationID, smsCode: code);
    signInwithCredent(credential);
  }
  signInwithCredent(PhoneAuthCredential cred) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    try {
      await auth.signInWithCredential(cred);
      setState(() {
        index = 3;
      });
    }
    on FirebaseAuthException catch(e){
      ssd(e.message.toString());
      setState(() {
        index = 1;
      });
    }
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
            margin: EdgeInsets.only(top: 10),
            alignment: Alignment.topLeft,
            child: Text(
              "Select your course",
            ),
          ),
          Container(
            alignment: Alignment.topLeft,
            padding:  EdgeInsets.all(6),
            child: DropdownButton<String>(
              icon: Icon(Icons.arrow_drop_down),
              iconSize: 24,
              elevation: 16,
              value: coursesItems[0],
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
                    child: Text("Save"),
                    onPressed: (){
                      saveDetails();
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
    if(index==1) return page1();
    if(index==2) return page2();
    if(index==3) return page3();
    else return page4();
  }

  @override
  void initState() {
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

