import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
Future<String?> compressImageWithLimit({
  int maxBase64Length = 10 * 1024 * 1024,
  int miniQuality = 50,
  int minWidth = 1280,
  int minHeight = 720,
  required String imagePath,
}) async {
  int quality = 95;
  List<int>? compressedBbytes;
  StringBuffer base64String = StringBuffer();
  
  while(quality > miniQuality){
    try{
      compressedBbytes = await FlutterImageCompress.compressWithFile(imagePath, quality: quality, minWidth: minWidth, minHeight: minHeight);
      if(compressedBbytes == null) return null;
      base64String.write(base64Encode(compressedBbytes));
      if(base64String.length < maxBase64Length){
        return base64String.toString();
      }
      quality -= 5;
    }catch(e,stack){
      debugPrintStack(stackTrace: stack,label: "compress error with $e");
    }
  }
  return null;
}