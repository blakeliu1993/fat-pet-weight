import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:image_picker/image_picker.dart';
import 'package:pet_fat_weight/utils/httpproc.dart';
import 'package:pet_fat_weight/utils/imagecompress.dart';
import 'package:pet_fat_weight/utils/tensorflow.dart';
import 'package:pet_fat_weight/widgets/constantvalues.dart';

class PetPage extends StatefulWidget {
  const PetPage({super.key});

  @override
  State<PetPage> createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _options = ["LLM", "Native", "API", "Server"];
  final List<FaIcon> _optionsIcon = [
    FaIcon(FontAwesomeIcons.brain),
    FaIcon(FontAwesomeIcons.mobile),
    FaIcon(FontAwesomeIcons.server),
    FaIcon(FontAwesomeIcons.cloud),
  ];
  int _selectedOptions = 0;
  final ValueNotifier<XFile> _selectedImage = ValueNotifier(XFile(""));
  Map<String, dynamic> _petInfo = {};
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      child: Container(
        height: screenHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [blueGradientStart, blueGradientEnd],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              SegmentedButton<int>(
                segments: List.generate(
                  _options.length,
                  (index) => ButtonSegment(
                    value: index,
                    label: Text(_options[index]),
                    icon: _optionsIcon[index],
                  ),
                ),
                selected: {_selectedOptions},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedOptions = newSelection.first;
                  });
                },
              ),
              ValueListenableBuilder<XFile>(
                valueListenable: _selectedImage,
                builder: (context, value, child) {
                  return SizedBox(
                    width: screenWidth,
                    height: screenWidth * 3 / 4,
                    child:
                        value.path.isNotEmpty
                            ? Image.file(File(value.path))
                            : Text("No image selected"),
                  );
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _cameraImage,
                      child: Text("Camera"),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _galleryImage,
                      child: Text("Gallery"),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _startAnalysis,
                child: Text("Start Analysis"),
              ),
              ...List.generate(_petInfo.length, (index) {
                return SelectableText.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _petInfo.keys.toList()[index],
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ": "),
                      TextSpan(
                        text: _petInfo.values.toList()[index].toString(),
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }),

              ElevatedButton(
                onPressed: _uploadEsResult,
                child: Text("Any Issue ? Click me"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadEsResult() async {
    //https://alidocs.dingtalk.com/notable/share/form/v011wvqrebAwQ2rvnak_modftrA_iacJAgh
    String url =
        "https://alidocs.dingtalk.com/notable/share/form/v011wvqrebAwQ2rvnak_modftrA_iacJAgh";
    HttpProc.launchrURL(url);
  }

  Future<void> _cameraImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      _selectedImage.value = image;
    }
  }

  Future<void> _galleryImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _selectedImage.value = image;
    }
  }

  Future<void> _startAnalysis() async {
    if (_selectedImage.value.path.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Please select an image first")));
      }
      return;
    }
    // 删除数据，避免无法判断加载是否完成。
    if (_petInfo.isNotEmpty) {
      setState(() {
        _petInfo = {};
      });
    }
    final image = File(_selectedImage.value.path);
    final imageBytes = await image.readAsBytes();
    final imageBase64 = base64Encode(imageBytes);

    debugPrint("Current mode is : $_selectedOptions");

    switch (_selectedOptions) {
      case 0:
        // LLM
        // LLM QW_VL_TURBO required less than 10Mb base64 Image , means origin image should be around 7-8Mb
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Uploading to Qwen-VL-PLUS...")),
          );
        }
        var compressedImage = await compressImageWithLimit(
          imagePath: image.path,
        );

        final result = await HttpProc.useLlmClassifyImage(
          compressedImage ?? imageBase64,
        );
        debugPrint("result : $result");
        try {
          var jsonResult = jsonDecode(result);
          debugPrint("jsonResult : $jsonResult");
          setState(() {
            _petInfo = jsonResult;
          });
        } catch (e, stack) {
          debugPrintStack(
            stackTrace: stack,
            label: "json decode error with $e",
          );
        }
        break;
      case 1:
        // Native
        debugPrint("current time is : ${DateTime.now()}");
        TensorflowUtils.predict(imageBytes)
            .then((result) {
              debugPrint("Native result: $result");
              setState(() {
                _petInfo = result;
              });
              debugPrint("Native finished at time : ${DateTime.now()}");
            })
            .catchError((error) {
              debugPrint("Error during prediction: $error");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Prediction failed: $error")),
                );
              }
            });
        break;
      case 2:
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("API is not implemented")));
        }
        break;
      case 3:
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Server is not implemented")));
        }
        break;
    }
  }

  // ImagePicker suggest to use this method to retrieve lost data
  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _imagePicker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      if (response.type == RetrieveType.image) {
        debugPrint("image");
      }
    } else {
      debugPrint("error");
    }
  }

  @override
  void dispose() {
    super.dispose();
    _commentController.dispose();
  }
}
