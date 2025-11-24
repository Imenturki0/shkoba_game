import 'package:flutter/material.dart';
import 'package:shkoba_game/screens/join_room_screen.dart';
import 'screens/shkoba_game.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       title: 'لعبة شكوبة',
      theme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
      home: JoinRoomScreen(), // ننادي الشاشة من الملف الثاني
    );
  }
}



  