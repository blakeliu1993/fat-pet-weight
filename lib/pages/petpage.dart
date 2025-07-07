import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_fat_weight/widgets/pickimagewidget.dart';

class PetPage extends StatefulWidget {
  const PetPage({super.key});

  @override
  State<PetPage> createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _options = ["大模型", "本地识别", "三方API", "后端服务"];
  int _selectedOptions = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text("PetPage"),
          SegmentedButton<int>(
            segments: List.generate(
              _options.length,
              (index) =>
                  ButtonSegment(value: index, label: Text(_options[index])),
            ),
            selected: {_selectedOptions},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedOptions = newSelection.first;
              });
            },
          ),
          PickImageWidget(),
        ],
      ),
    );
  }

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
}
