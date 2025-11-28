import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/config/constants.dart';
import 'package:travel_app/providers/auth_provider.dart';

class UploadService {
  // Replace with your actual Node.js Base URL
  final String baseUrl = "${Constants.uri}/api/user/profile"; 
  // Note: Use 10.0.2.2 for Android Emulator, 'localhost' for iOS Simulator, or your LAN IP for physical devices.

  final ImagePicker _picker = ImagePicker();

  /// Main function to call from your Button
  Future<void> updateProfilePhoto(String userToken, BuildContext context) async {
    try {
      // 1. Pick Image
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return; // User cancelled
      File imageFile = File(image.path);

      print("Step 1: Image picked: ${image.path}");

      // 2. Get Signature from Node.js
      final signatureData = await _getUploadSignature(userToken);
      
      // 3. Upload to Cloudinary
      final cloudResponse = await _uploadToCloudinary(imageFile, signatureData);
      
      // 4. Save URL & Public ID to your Backend
      await _saveToBackend(
        userToken, 
        cloudResponse['secure_url'], 
        cloudResponse['public_id']
      );

      print("Success! Profile photo updated.");

      Provider.of<Auth>(context, listen: false).updateProfilePhoto(cloudResponse['secure_url']);

    } catch (e) {
      print("Error updating profile photo: $e");
      // Show a Snackbar or Alert Dialog here based on 'e'
    }
  }

  // --- Helper: Get Signature ---
  Future<Map<String, dynamic>> _getUploadSignature(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/upload-signature'),
      headers: {
        'x-auth-token': token, // Assuming you use Bearer tokens
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get signature: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  // --- Helper: Upload to Cloudinary ---
  Future<Map<String, dynamic>> _uploadToCloudinary(File file, Map<String, dynamic> sigData) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/${sigData['cloudName']}/image/upload');
    
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = sigData['apiKey']
      ..fields['timestamp'] = sigData['timestamp'].toString()
      ..fields['signature'] = sigData['signature']
      ..fields['folder'] = sigData['folder']
      ..fields['upload_preset'] = sigData['uploadPreset']
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed: $respStr');
    }
    return jsonDecode(respStr);
  }

  // --- Helper: Update User in MongoDB ---
  Future<void> _saveToBackend(String token, String url, String publicId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/update-photo'),
      headers: {
        'x-auth-token': token,
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'imageUrl': url,
        'publicId': publicId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save to backend: ${response.body}');
    }
  }
}