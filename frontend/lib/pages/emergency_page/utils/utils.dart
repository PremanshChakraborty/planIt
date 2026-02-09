import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Request necessary permissions (SAFE VERSION)
Future<bool> requestPermissions() async {
  var locationStatus = await Permission.locationWhenInUse.status;
  if (!locationStatus.isGranted &&
      !await Permission.locationWhenInUse.request().isGranted) {
    return false;
  }
  return true;
}

/// Share emergency message instead of sending SMS directly
Future<bool> sendEmergencySMS(
    BuildContext context, List<String> emergencyContacts) async {
  try {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    String locationUrl =
        "https://www.google.com/maps?q=${position.latitude},${position.longitude}";

    String message =
        "I need help! Here is my location: $locationUrl";

    await Share.share(message);
    return true;
  } catch (e) {
    return false;
  }
}

/// Open dialer instead of calling directly
Future<bool> callPolice(BuildContext context) async {
  return callEmergency(context, "100");
}

/// Open dialer for any emergency number
Future<bool> callEmergency(BuildContext context, String number) async {
  try {
    final uri = Uri.parse("tel:$number");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}
