import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_fat_weight/widgets/constantvalues.dart';

class PickImageWidget extends StatefulWidget {
  final ValueNotifier<XFile> image;
  const PickImageWidget({super.key, required this.image});

  @override
  State<PickImageWidget> createState() => _PickImageWidgetState();
}

class _PickImageWidgetState extends State<PickImageWidget> {
  XFile? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      _image = picked;
    });
    widget.image.value = picked!;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: greyColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white),
        ),
        child: _image != null
            ? Image.file(File(_image!.path))
            : Icon(Icons.camera, size: 40, color: Colors.white),
      ),
    );
  }
}

class TakeImageWidget extends StatefulWidget {
  final ValueNotifier<XFile> image;
  const TakeImageWidget({super.key, required this.image});

  @override
  State<TakeImageWidget> createState() => _TakeImageWidgetState();
}

class _TakeImageWidgetState extends State<TakeImageWidget> {
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      widget.image.value = picked!;
    });
    
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: greyColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white),
        ),
        child: widget.image.value.path.isNotEmpty ? Image.file(File(widget.image.value.path)) : Icon(Icons.add_a_photo, size: 40, color: Colors.white),
      ),
    );
  }
}
