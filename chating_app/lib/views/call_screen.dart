import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:get/get.dart';

class CallScreen extends StatelessWidget {
  final String callID;
  final String userID;
  final String userName;
  final bool isVideo;

  const CallScreen({
    Key? key,
    required this.callID,
    required this.userID,
    required this.userName,
    required this.isVideo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: 12345678, // Replace with your ZEGO app ID
      appSign: "your_app_sign_key_here", // Replace with your ZEGO app sign
      userID: userID,
      userName: userName,
      callID: callID,
      config: isVideo 
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
    );
  }
}
