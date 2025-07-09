
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HttpProc{
  static const String _llmBaseUrl = "https://dashscope.aliyuncs.com";
  static const String _llmApiKey = "sk-d0c569db320a4592ba29d108796b7d9c";
  static const String _llmModel = "qwen-vl-plus";

  static Future<String> useLlmClassifyImage(String imageBase64) async {

    Uri url = Uri.parse("$_llmBaseUrl/compatible-mode/v1/chat/completions");
    Map<String,String> headers = {
      "Authorization": "Bearer $_llmApiKey",
      "Content-Type": "application/json",
    };
    Map<String,dynamic> body = {
      "model": _llmModel,
      "messages": [
        {
          "role": "user",
          "content": [
            // {"type":"text", "text": "你是一名宠物护理专家，能够准确的根据图片识别出图片中的宠物类型、宠物种类、宠物的长、宠物的身高、宠物的体重、宠物的毛发长度。"},
            {"type":"text", "text": '''你是一名经验丰富的宠物护理专家，擅长从宠物图片中提取专业信息。请根据提供的宠物图片，识别出以下内容，并以指定的 JSON 格式返回：
宠物类型（如：猫、狗、兔子等）
宠物品种（如：金毛寻回犬、布偶猫等）
宠物身长（单位：厘米）
宠物身高（单位：厘米）
宠物体重（单位：千克）
毛发长度（如：短毛、中等、长毛
{
  "pet_type": "",
  "breed": "",
  "length_cm": 0,
  "height_cm": 0,
  "weight_kg": 0,
  "fur_length": ""
}
注意事项：
请确保所有单位准确一致（厘米、千克）。
如果不确定，可以基于常见品种估算，但请保持专业和合理性。
所有字段必须填写，不能留空，如果图片无法识别出宠物，请返回pet_type=nuknow，其他字段保持模板数值。
请返回json格式，不要返回其他内容。
'''},
            {"type":"image_url", "image_url": {"url": "data:image/jpeg;base64,$imageBase64"}}
          ]
        }
      ]
    };
    debugPrint("request url : $url , request headers : $headers , request body : $body");
    var response = await http.post(url, headers: headers, body: jsonEncode(body));
    debugPrint("response : ${response.body}");
    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      String content = data["choices"][0]["message"]["content"];
      if(content.contains("```json")){
        content = content.replaceAll("```json", "").replaceAll("```", "");
        return content;
      }
      return content;
    } else {
      throw Exception("Failed to classify image");
    }

  }  

  static const String _esUrl = "http://192.168.112.229:";

  static Future<bool> uploadEsResult(Map<String, dynamic> petInfo, String imagePath) async {
    final result = false;
    // upload image 


    // upload to es
    Uri esUrl = Uri.parse("$_esUrl/api/v1/pet/upload");
    Map<String,String> headers = {
      "Content-Type": "application/json",
    };
    Map<String,dynamic> body = {
      "pet_info": petInfo,
      "image_path": imagePath,
    };
    try{
      var response = await http.post(esUrl, headers: headers, body: jsonEncode(body));
    }catch(e,stack){}

    return result;
  }
}