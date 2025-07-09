import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as image;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class TensorflowUtils {
  static const String tfAsset = "assets/yolo/android/yolov5s.tflite";

  static Future<Map<String, dynamic>> predict(Uint8List imageBytes) async {
    debugPrint("predict start with imageBytes: ${imageBytes.length}");
    Map<String, dynamic> result = {};
    final Interpreter interpreter = await Interpreter.fromAsset(tfAsset);

    final inputTensor = interpreter.getInputTensors().first;
    debugPrint("Model input shape: ${inputTensor.shape}");
    debugPrint("Model input type: ${inputTensor.type}");
    debugPrint("Model input name: ${inputTensor.name}");

    image.Image? oriImage = image.decodeImage(imageBytes);
    if (oriImage == null) {
      return result;
    }
    image.Image resizedImage = image.copyResize(
      oriImage,
      width: 640,
      height: 640,
    ); // yolo 模型输入大小为 640x640

    // 先归一化到0~1
    List<List<List<List<double>>>> input = List.generate(1, (_) => 
      List.generate(3, (c) => // channel
        List.generate(640, (y) =>
          List.generate(640, (x) {
            final pixel = resizedImage.getPixel(x, y);
            if (c == 0) return pixel.r / 255.0;
            if (c == 1) return pixel.g / 255.0;
            return pixel.b / 255.0;
          })
        )
      )
    );
    debugPrint("input.runtimeType: ${input.runtimeType}"); // List
    debugPrint("input.length: ${input.length}"); // 1
    debugPrint("input[0].length: ${input[0].length}"); // 640
    debugPrint("input[0][0].length: ${input[0][0].length}"); // 640
    debugPrint("input[0][0][0].length: ${input[0][0][0].length}"); // 3
    
    // 归一化到0~1
    input = input.map((batch) => batch.map((row) => row.map((pixel) => pixel.map((v) => v / 255.0).toList()).toList()).toList()).toList();

    debugPrint("input.runtimeType: ${input.runtimeType}"); // List
    debugPrint("input.length: ${input.length}"); // 1
    debugPrint("input[0].length: ${input[0].length}"); // 640
    debugPrint("input[0][0].length: ${input[0][0].length}"); // 640
    debugPrint("input[0][0][0].length: ${input[0][0][0].length}"); // 3

 // 4. 构造输出张量（根据模型输出shape）
    var outputShapes = interpreter.getOutputTensors().map((t) => t.shape).toList();
    var output = List.filled(outputShapes[0].reduce((a, b) => a * b), 0.0).reshape(outputShapes[0]);

    // 5. 推理
    interpreter.run(input, output);

    // 6. 

    // 6. 
    result['output'] = output;

    debugPrint("output: $output");

    interpreter.close();
    return result;
  }
}
