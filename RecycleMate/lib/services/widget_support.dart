import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AppWidget{
  static TextStyle headlineTextStyle(double size){
    return TextStyle(
      color: Colors.black,
      fontSize: size,
      fontWeight: FontWeight.bold
    );
  }

  static TextStyle normalTextStyle(double size){
    return TextStyle(
        color: Colors.black,
        fontSize: size,
        fontWeight: FontWeight.w500
    );
  }
  static TextStyle whiteTextStyle(double size){
    return TextStyle(
        color: Colors.white,
        fontSize: size,
        fontWeight: FontWeight.bold
    );
  }

  static TextStyle greenTextStyle(double size){
    return TextStyle(
        color: Colors.green,
        fontSize: size,
        fontWeight: FontWeight.bold
    );
  }
}