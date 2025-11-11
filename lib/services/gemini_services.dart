import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? "";

  // First, let's check what models are available
  static Future<List<String>> getAvailableModels() async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models?key=$apiKey",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> models = [];
        for (var model in data["models"]) {
          models.add(model["name"].split("/").last);
          print("Available model: ${model["name"]}");
        }
        return models;
      }
    } catch (e) {
      print("Error fetching models: $e");
    }
    return [];
  }

  static Future<String> sendMessage(String message) async {
    // Get available models first
    final models = await getAvailableModels();
    print("Available models: $models");

    // Try gemini-pro first (most common)
    final model =
        models.contains("gemini-pro")
            ? "gemini-pro"
            : models.isNotEmpty
            ? models.first
            : "gemini-pro";

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$apiKey",
    );

    final body = {
      "contents": [
        {
          "parts": [
            {"text": message},
          ],
        },
      ],
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["candidates"] != null &&
            data["candidates"].isNotEmpty &&
            data["candidates"][0]["content"] != null &&
            data["candidates"][0]["content"]["parts"] != null &&
            data["candidates"][0]["content"]["parts"].isNotEmpty) {
          final text = data["candidates"][0]["content"]["parts"][0]["text"];
          return text ?? "⚠️ No response received.";
        } else {
          return "⚠️ Invalid response format from API.";
        }
      } else {
        print("\nERROR BODY => ${response.body}\n");
        return "⚠️ API Error: ${response.statusCode} - ${response.reasonPhrase}";
      }
    } catch (e) {
      print("Exception: $e");
      return "⚠️ Something went wrong connecting to AI.";
    }
  }
}
