import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color greyColor = Colors.grey;
  static const Color errorColor = Colors.red;

  // Sizes
  static const double defaultPadding = 16.0;
  static const double iconSize = 24.0;

  // Text Styles
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
  );

  // Text Content
  static const String retryText = '重试';

  // ASMR Assets
  static const String defaultAsmrSample = 'assets/ASMR 002 - Compressed with FlexClip.mp4';
  
  // Default sample content for new characters
  static const List<String> defaultSampleContents = [
    '让我用轻柔的声音帮助你放松...',
    '今天我们来做一些深呼吸练习...'
  ];
}
