import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_fat_weight/models/userdata.dart';
import 'package:pet_fat_weight/pages/homepage.dart';
import 'package:pet_fat_weight/widgets/constantvalues.dart';

class UserRegister extends StatefulWidget {
  const UserRegister({super.key});

  @override
  State<UserRegister> createState() => _UserRegisterState();
}

class _UserRegisterState extends State<UserRegister> {
  bool _isFirstLogin = true;
  final UserDataHelper _userDataHelper = UserDataHelper();
  final TextEditingController _userNameController = TextEditingController();
  Set<String> _selectedGender = {"male"};

  @override
  void initState() {
    super.initState();
    _checkUserFirstLogin();
  }

  Future<void> _checkUserFirstLogin() async {
    final user = await _userDataHelper.getUser('1');
    user == null ? _isFirstLogin = true : _isFirstLogin = false;
  }

  void _registerUser() {
    String userName = _userNameController.text;
    if (userName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please enter your name")));
      return;
    }
    _userDataHelper.insertUser(
      User(
        account: '1',
        nickname: userName,
        avatar: 'assets/images/avatar.png',
        registerDate: DateTime.now(),
        gender: _selectedGender.first,
      ),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _userNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFirstLogin) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text("Register Page"), centerTitle: true),
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              Text("Your Name", style: GoogleFonts.baloo2(fontSize: 20)),
              TextField(
                decoration: InputDecoration(
                  hintText: "Eg : balke ",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                controller: _userNameController,
              ),
              SegmentedButton(
                segments: [
                  ButtonSegment(value: "male", label: FaIcon(Icons.male)),
                  ButtonSegment(value: "female", label: FaIcon(Icons.female)),
                ],
                selected: _selectedGender,
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedGender = newSelection;
                  });
                },
                selectedIcon: FaIcon(FontAwesomeIcons.cat, color: yellowColor),
                style: ButtonStyle(
                  fixedSize: WidgetStateProperty.all(Size(200, 100)),
                ),
              ),
              Spacer(),
              ElevatedButton(onPressed: _registerUser, child: Text("Register")),
            ],
          ),
        ),
      ),
    );
  }
}
