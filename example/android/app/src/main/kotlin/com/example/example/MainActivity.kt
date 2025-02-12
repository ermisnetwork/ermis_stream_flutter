package com.example.example

import io.flutter.embedding.android.FlutterActivity
import org.webrtc.PeerConnectionFactory
import org.webrtc.VideoEncoderFactory
import org.webrtc.VideoDecoderFactory
import org.webrtc.DefaultVideoEncoderFactory
import org.webrtc.DefaultVideoDecoderFactory
import org.webrtc.MediaCodecVideoEncoder
import org.webrtc.MediaCodecVideoDecoder
import org.webrtc.VideoCapturer
import org.webrtc.VideoSource

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine() {
        super.configureFlutterEngine()
        val options = PeerConnectionFactory.Options()
    }
}
