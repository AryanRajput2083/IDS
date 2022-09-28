import 'package:flutter/material.dart';
import 'package:inway/main.dart';


class LoginPage extends StatefulWidget{
  const LoginPage({super.key, required this.title});
  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage>{

  bool passVis = true;
  TextEditingController username_controller = TextEditingController();
  TextEditingController password_controller = TextEditingController();
  void regist_func(){

  }
  void forget_func(){

  }
  void login_func(){
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomePage(title: "Welcome")));
  }
  Widget logPage(){
    return Center(
      child: Container(
        padding: EdgeInsets.all(4),
        margin: EdgeInsets.all(8),

        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.center,
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // username textbox
              Container(
                padding: EdgeInsets.all(4),
                margin: EdgeInsets.all(4),
                child: TextField(
                  controller: username_controller,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "username",
                  ),
                ),
              ),

              // password textbox
              Container(
                padding: EdgeInsets.all(4),
                margin: EdgeInsets.all(4),
                child: TextField(
                  controller: password_controller,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  obscureText: passVis,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "password",
                      suffixIcon: IconButton(
                        icon: Icon(
                            passVis?Icons.visibility_off:Icons.visibility
                        ),
                        onPressed: (){
                          setState(() {
                            passVis = !passVis;
                          });
                        },
                      )
                  ),
                ),
              ),

              // login  button
              Container(
                padding: EdgeInsets.all(4),
                margin: EdgeInsets.all(4),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 45)
                    ),
                    onPressed: (){
                      login_func();
                    },
                    child: Text("Log in")
                ),
              ),

              // other buttons
              Container(
                margin: EdgeInsets.all(4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: (){
                        forget_func();
                      },
                      child: Text(
                        "Forget Password",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: (){
                        regist_func();
                      },
                      child: Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
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

      body: logPage(),
    );
  }
}


