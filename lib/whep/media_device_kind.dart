import 'package:flutter_webrtc/flutter_webrtc.dart';

enum MediaDeviceKind {
  audioInput, audioOutput, videoInput, videoOutput
}

extension MediaDeviceKindValue on MediaDeviceKind {
  String get value {
    switch (this) {
      case MediaDeviceKind.audioInput:
        return "audioinput";
      case MediaDeviceKind.audioOutput:
        return "audiooutput";
      case MediaDeviceKind.videoInput:
        return "videoinput";
      case MediaDeviceKind.videoOutput:
        return "videooutput";
    }
  }
}