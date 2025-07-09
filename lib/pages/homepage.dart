/// HomePage shoule be able to switch to three pages : pet page , data page , user page .
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pet_fat_weight/pages/datapage.dart';
import 'package:pet_fat_weight/pages/mepage.dart';
import 'package:pet_fat_weight/pages/petpage.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// HomePage is the main page of the app .
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  final List<Widget> _bodyPages = [
    const MePage(),
    const PetPage(),
    const DataPage(),
  ];

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    // 申请摄像头权限
    final cameraPermissionStatus = await Permission.camera.request();
    debugPrint("cameraPermissionStatus: $cameraPermissionStatus");

    PermissionStatus storagePermissionStatus = PermissionStatus.denied;

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ 用 mediaImages
        storagePermissionStatus = await Permission.mediaLibrary.request();
      } else {
        // Android 13以下用 storage
        storagePermissionStatus = await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      storagePermissionStatus = await Permission.photos.request();
    } else {
      storagePermissionStatus = PermissionStatus.granted;
    }

    debugPrint("storagePermissionStatus: $storagePermissionStatus");

    if (storagePermissionStatus.isDenied || cameraPermissionStatus.isDenied) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else if (Platform.isIOS) {
        exit(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HomePage"), centerTitle: true),
      body: _bodyPages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Me"),
          const BottomNavigationBarItem(icon: Icon(Icons.pets), label: "Pet"),
          const BottomNavigationBarItem(
            icon: Icon(Icons.data_exploration),
            label: "Data",
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          // setState(() {
          //   _currentIndex = index;
          // });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Ohter functions are not available now"),
              ),
            );  
          }
        },
      ),
    );
  }
}
