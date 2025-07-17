import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as image;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TensorflowUtils {
  static const String tfAsset = "assets/yolo/android/yolov5s.tflite";
  static const String efficientAsset =
      "assets/efficient/android/20250717-1-tf-model.tflite";

  static Future<Map<String, dynamic>> predict(Uint8List imageBytes) async {
    debugPrint("predict start with imageBytes: ${imageBytes.length}");

    // 初始化返回结果
    Map<String, dynamic> result = {
      "pet_type": "",
      "breed": "",
      "fur_Length": "",
    };

    try {
      // 1. 使用YOLO模型检测宠物
      final yoloInterpreter = await Interpreter.fromAsset(tfAsset);

      // 获取YOLO模型输入信息
      final yoloInputTensor = yoloInterpreter.getInputTensors().first;
      debugPrint("YOLO Model input shape: ${yoloInputTensor.shape}");

      // 解码并调整图片大小
      image.Image? oriImage = image.decodeImage(imageBytes);
      if (oriImage == null) {
        debugPrint("Failed to decode image");
        return result;
      }

      image.Image resizedImage = image.copyResize(
        oriImage,
        width: 640,
        height: 640,
      );

      // 准备YOLO输入数据
      List<List<List<List<double>>>> yoloInput = List.generate(
        1,
        (_) => List.generate(
          3,
          (c) => List.generate(
            640,
            (y) => List.generate(640, (x) {
              final pixel = resizedImage.getPixel(x, y);
              double value;
              if (c == 0) {
                value = pixel.r.toDouble();
              } else if (c == 1) {
                value = pixel.g.toDouble();
              } else {
                value = pixel.b.toDouble();
              }
              return value / 255.0;
            }),
          ),
        ),
      );

      // 获取YOLO输出形状
      var yoloOutputShapes =
          yoloInterpreter.getOutputTensors().map((t) => t.shape).toList();
      var yoloOutput = List.filled(
        yoloOutputShapes[0].reduce((a, b) => a * b),
        0.0,
      ).reshape(yoloOutputShapes[0]);

      // 运行YOLO推理
      yoloInterpreter.run(yoloInput, yoloOutput);

      // 解析YOLO输出，检测是否有猫(15)或狗(16)
      int detectedPetClass = -1;
      double maxConfidence = 0.5; // 置信度阈值
      List<double> matchedXyxy = [];

      // YOLOv5输出格式通常为 [batch, num_boxes, 5+num_classes]
      // 其中每个框的格式为 [x, y, w, h, confidence, class1, class2, ...]
      List<dynamic> outputList = yoloOutput;

      debugPrint("YOLO output shape: ${outputList.shape}");

      // 遍历检测结果
      if (outputList.isNotEmpty) {
        for (int i = 0; i < outputList.length; i++) {
          var detection = outputList[i];
          if (detection is List) {
            // 处理不同格式的YOLO输出
            for (var det in detection) {
              if (det is List && det.length >= 6) {
                double confidence = det[4].toDouble();
                if (confidence > maxConfidence) {
                  // 查找类别概率最高的类别
                  for (int j = 5; j < det.length; j++) {
                    double classProb = det[j].toDouble();
                    if (classProb > 0.5) {
                      int classId = j - 5;
                      if (classId == 15 || classId == 16) {
                        detectedPetClass = classId;
                        maxConfidence = confidence;
                        matchedXyxy = det.sublist(0, 4) as List<double>;
                        break;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      yoloInterpreter.close();

      // 如果没有检测到猫或狗，直接返回
      if (detectedPetClass != 15 && detectedPetClass != 16) {
        debugPrint("No cat or dog detected by YOLO");
        return result;
      }

      // 设置宠物类型
      result["pet_type"] = detectedPetClass == 15 ? "猫" : "狗";
      debugPrint("Detected pet type11: ${result["pet_type"]}");
      debugPrint("Detected pet at $matchedXyxy");

      // 2. 使用EfficientNet识别品种
      debugPrint("准备加载EfficientNet模型: $efficientAsset");
      // 要求：模型输入 shape 不符合 TFLite 的要求（NCHW 而不是 NHWC）
      final efficientInterpreter = await Interpreter.fromAsset(
        efficientAsset,
      ).onError((e, stack) {
        debugPrint("Error loading EfficientNet model: $e");
        debugPrint("Stack trace: $stack");
        throw e!;
      });
      debugPrint("EfficientNet模型加载成功");

      // 获取EfficientNet模型输入信息
      final efficientInputTensor = efficientInterpreter.getInputTensors().first;
      debugPrint(
        "EfficientNet Model input shape: ${efficientInputTensor.shape}",
      );

      // TODO : 这里加载tensorflow的模型依然还是会在计算的过程中出现Bad state: failed precondition
      // 获取输入尺寸
      int inputHeight = efficientInputTensor.shape[1];
      int inputWidth = efficientInputTensor.shape[2];

      debugPrint("test1");
      // 调整图片大小以适应EfficientNet

      // 调整图标为yolo识别后的区域。
      image.Image yoloCropImage = image.copyCrop(
        oriImage,
        x: matchedXyxy[0].toInt(),
        y: matchedXyxy[1].toInt(),
        width: matchedXyxy[2].toInt() - matchedXyxy[0].toInt(),
        height: matchedXyxy[3].toInt() - matchedXyxy[1].toInt(),
      );
      image.Image efficientResizedImage = image.copyResize(
        yoloCropImage,
        width: inputWidth,
        height: inputHeight,
      );

      // 准备EfficientNet输入数据
      List<List<List<List<double>>>> efficientInput = [
        List.generate(
          inputHeight,
          (y) => List.generate(inputWidth, (x) {
            final pixel = efficientResizedImage.getPixel(x, y);
            return [
              pixel.r.toDouble() / 255.0,
              pixel.g.toDouble() / 255.0,
              pixel.b.toDouble() / 255.0,
            ];
          }),
        ),
      ];
      debugPrint("test2");
      // 获取EfficientNet输出形状
      var efficientOutputShapes =
          efficientInterpreter.getOutputTensors().map((t) => t.shape).toList();
      var efficientOutput = List.filled(
        efficientOutputShapes[0].reduce((a, b) => a * b),
        0.0,
      ).reshape(efficientOutputShapes[0]);
      debugPrint("efficientOutput shape: ${efficientOutput.shape}");
      debugPrint("efficientInput shape: ${efficientInput.shape}");
      debugPrint("test3");
      // 运行EfficientNet推理
      try {
        efficientInterpreter.run(efficientInput, efficientOutput);
      } catch (e, stack) {
        debugPrint("Error during EfficientNet inference: $e");
        debugPrintStack(stackTrace: stack);
        throw e;
      }

      // 解析EfficientNet输出
      List<double> probabilities = [];
      if (efficientOutput is List) {
        for (var val in efficientOutput) {
          if (val is List) {
            probabilities.addAll(val.map((v) => v.toDouble()));
          } else {
            probabilities.add(val.toDouble());
          }
        }
      }
      debugPrint("test4");
      // 找到最高概率的类别索引
      int predictedClass = 0;
      double maxProb = 0.0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          predictedClass = i;
        }
      }

      debugPrint(
        "Predicted breed class: $predictedClass, probability: $maxProb",
      );

      efficientInterpreter.close();

      // 3. 根据宠物类型加载对应的品种数据
      String breedDataPath =
          detectedPetClass == 15
              ? "assets/petdata/cat_breeds.json"
              : "assets/petdata/dog_breeds.json";

      try {
        String breedDataString = await rootBundle.loadString(breedDataPath);
        List<dynamic> breedData = json.decode(breedDataString);

        // 查找对应的品种信息
        // 注意：EfficientNet的类别索引可能需要调整，这里假设从0开始
        int breedIndex = predictedClass + 2; // 因为row_number从2开始

        for (var breed in breedData) {
          if (breed["row_number"] == breedIndex) {
            result["breed"] = breed["pet_name_cn"] ?? "";
            result["fur_Length"] = breed["pet_fur_length"] ?? "";
            break;
          }
        }

        // 如果没找到精确匹配，使用第一个匹配或默认
        if (result["breed"].isEmpty && breedData.isNotEmpty) {
          int adjustedIndex = (predictedClass % breedData.length);
          var breed = breedData[adjustedIndex];
          result["breed"] = breed["pet_name_cn"] ?? "";
          result["fur_Length"] = breed["pet_fur_length"] ?? "";
        }
      } catch (e) {
        debugPrint("Error loading breed data: $e");
      }
    } catch (e) {
      debugPrint("Error in predict: $e");
    }

    debugPrint("Final result: $result");
    return result;
  }
}
