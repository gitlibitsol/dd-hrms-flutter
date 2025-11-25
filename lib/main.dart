import 'package:flutter/material.dart';
import 'SplashScreen.dart';

void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'DD-Hrms',         // Set your app title
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // Primary color for your app
      ),
      debugShowCheckedModeBanner: false,  // Remove the debug banner
      home: SplashScreen(), // Set SplashScreen as the initial page
    );
  }
}
