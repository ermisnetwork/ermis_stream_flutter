import Flutter
import UIKit
import WebRTC

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let controller = window?.rootViewController as! FlutterViewController
      let ermisStreamChannel = FlutterMethodChannel(name: "network.ermis.test_stream", binaryMessenger: controller.binaryMessenger)
      ermisStreamChannel.setMethodCallHandler({ (call, result) in
          print("Method called: \(call.method)")
          if call.method == "setUpWebRTC" {
              self.setUpWebRTC()
          } else {
              result(FlutterMethodNotImplemented)
          }
      })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

    private func setUpWebRTC() {
        debugPrint("TTTTTT SETUP WEBRTC")
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        videoEncoderFactory.preferredCodec = RTCVideoCodecInfo(name: kRTCVideoCodecVp8Name)

        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        let peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }
}

