import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_fat_weight/pages/firstshow.dart';
import 'package:pet_fat_weight/pages/homepage.dart';
import 'package:pet_fat_weight/widgets/constantvalues.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.getFont('Baloo 2');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.black),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            iconColor: WidgetStateProperty.all(Colors.white),
            overlayColor: WidgetStateProperty.all(Colors.white),
            shadowColor: WidgetStateProperty.all(Colors.white),
            side: WidgetStateProperty.all(BorderSide(color: Colors.white)),
            padding: WidgetStateProperty.all(EdgeInsets.all(10)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            minimumSize: WidgetStateProperty.all(Size(100, 50)),
          ),
        ),
        textTheme: GoogleFonts.baloo2TextTheme(Theme.of(context).textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(blackColor),
            foregroundColor: WidgetStateProperty.all(yellowColor),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(blackColor),
            foregroundColor: WidgetStateProperty.all(whiteColor),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
