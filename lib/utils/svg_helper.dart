import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgHelper {
  static Widget getSvgIcon(String providerId, {double size = 40}) {
    String assetPath;
    
    switch (providerId) {
      case 'chatgpt':
        assetPath = 'assets/svg/chatgpt_icon.svg';
        break;
      case 'google':
        assetPath = 'assets/svg/gemini_icon.svg';
        break;
      default:
        // Fallback to a question mark icon
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
          child: const Text(
            '?',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        );
    }
    
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
    );
  }
} 