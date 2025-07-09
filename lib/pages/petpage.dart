import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:image_picker/image_picker.dart';
import 'package:pet_fat_weight/utils/httpproc.dart';
import 'package:pet_fat_weight/utils/imagecompress.dart';
import 'package:pet_fat_weight/utils/tensorflow.dart';

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
      child: Column(
        children: [
          Text("PetPage"),
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
          // ListView.builder(
          //   itemBuilder: (context, index) {
          //     return SelectableText.rich(
          //       TextSpan(
          //         children: [
          //           TextSpan(
          //             text: _petInfo.keys.toList()[index],
          //             style: TextStyle(
          //               color: Colors.black,
          //               fontSize: 16,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //           TextSpan(text: ": "),
          //           TextSpan(
          //             text: _petInfo.values.toList()[index].toString(),
          //             style: TextStyle(color: Colors.black, fontSize: 16),
          //           ),
          //         ],
          //       ),
          //     );
          //   },
          //   itemCount: _petInfo.length,
          // ),
          Container(
            height: screenHeight * 0.05,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black, width: 1),
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Right:"),
                Radio(value: "right", groupValue: _petInfo["isRight"], onChanged: (value) {
                  setState(() {
                    _petInfo["isRight"] = value;
                  });
                }),
                VerticalDivider(
                  width: 10,
                  color: Colors.black,
                  thickness: 1,
                ),
                Text("Wrong:"),
                Radio(value: "wrong", groupValue: _petInfo["isRight"], onChanged: (value) {
                  setState(() {
                    _petInfo["isRight"] = value;
                  });
                }),
              ],
            ),
          ),
          if(_petInfo["isRight"] == "wrong") TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: "Please input your comment",
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
            ),
          ),
          ElevatedButton(onPressed: _uploadEsResult, child: Text("Report")),
        ],
      ),
    );
  }

  Future<void> _uploadEsResult() async {
    if (_petInfo.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Please Start Analysis First")));
      }
      return;
    }
    if(_commentController.text.isNotEmpty){
      _petInfo["comment"] = _commentController.text;
    }
    if (_petInfo.isNotEmpty) {
      bool updalodResult = await HttpProc.uploadEsResult(
        _petInfo,
        _selectedImage.value.path,
      );
      if (updalodResult) {
        setState(() {
          _selectedImage.value = XFile("");
          _petInfo = {};
          _commentController.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Upload Success")));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload Failed , Maybe try again later.")),
          );
        }
      }
    }
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
            SnackBar(
              content: Text(
                "Uploading to Qwen-VL-PLUS...",
              ),
            ),
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
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Native is developing...")));
        }
        break;
        // final result = await TensorflowUtils.predict(imageBytes);
        // debugPrint("result: $result");
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
