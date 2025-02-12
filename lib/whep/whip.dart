import 'dart:io';

import 'package:ermis_stream/api/api_client.dart';
import 'package:ermis_stream/api/endpoint/endpoint.dart';
import 'package:ermis_stream/api/payload/create_whip_session_request_body.dart';
import 'package:ermis_stream/config/config.dart';
import 'package:ermis_stream/whep/codec_capability_selector.dart';
import 'package:ermis_stream/whep/media_device_kind.dart';
import 'package:ermis_stream/whep/whip_mode.dart';
import 'package:ermis_stream/whep/whip_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../api/model/base_model.dart';
import '../api/model/session_token_model.dart';
import '../utilities/logger.dart';

class WHIP {
  ApiClient apiClient = ApiClient();

  String? _token;
  RTCPeerConnection? _pc;
  late WhipMode _mode;
  String? _videoCodec;
  String? _resourcePath;
  WhipState state = WhipState.idle;
  Object? lastError;

  Function(WhipState)? onState;
  Function(RTCTrackEvent)? onTrack;
  Function(RTCSignalingState state)? onSignalingState;
  Function(RTCPeerConnectionState state)? onConnectionState;
  Function(RTCIceGatheringState state)? onIceGatheringState;
  Function(RTCIceConnectionState state)? onIceConnectionState;
  Function(MediaStream stream)? onAddStream;
  Function(MediaStream stream)? onRemoveStream;
  Function(MediaStream stream, MediaStreamTrack track)? onAddTrack;
  Function(MediaStream stream, MediaStreamTrack track)? onRemoveTrack;
  Function(RTCDataChannel channel)? onDataChannel;
  Function()? onRenegotiationNeeded;
  Function(dynamic devices)? onMediaDeviceInfoListChanged;

  WHIP();

  //region Public
  /// Initialize peer connection and setup.
  Future<void> initialize(
      {required WhipMode mode, MediaStream? stream, String? videoCodec}) async {
    if (_pc != null) {
      return;
    }
    await WebRTC.initialize();
    if (videoCodec != null) {
      this._videoCodec = videoCodec;
    }
    this._mode = mode;
    final configuration = {
      'sdpSemantics': 'unified-plan',
      'continualGatheringPolicy': 'gatherContinually',
      'candidateNetworkPolicy': 'all',
      'tcpCandidatePolicy': 'disabled',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };

    var defaultConstraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    _pc = await createPeerConnection(configuration, defaultConstraints);
    _pc?.onIceCandidate = _onIceCandidate;
    _pc?.onIceConnectionState = onIceConnectionState;
    _pc?.onTrack = (RTCTrackEvent event) => onTrack?.call(event);
    _pc?.onSignalingState = onSignalingState;
    _pc?.onConnectionState = onConnectionState;
    _pc?.onAddStream = (MediaStream stream) {
      onAddStream?.call(stream);
    };
    _pc?.onAddTrack = onAddTrack;

    navigator.mediaDevices.ondevicechange =
        (devices) => onMediaDeviceInfoListChanged?.call(devices);

    switch (mode) {
      case WhipMode.send:
        stream?.getTracks().forEach((track) async {
          RTCRtpMediaType kind;
          if (track.kind == 'audio') {
            kind = RTCRtpMediaType.RTCRtpMediaTypeAudio;
          } else if (track.kind == 'video') {
            if (Config.isAudioOnly) {
              return;
            }
            kind = RTCRtpMediaType.RTCRtpMediaTypeVideo;
          } else {
            kind = RTCRtpMediaType.RTCRtpMediaTypeData;
          }
          await _pc?.addTransceiver(
              track: track,
              kind: kind,
              init: RTCRtpTransceiverInit(
                  direction: TransceiverDirection.SendOnly, streams: [stream]));
        });
        break;
      case WhipMode.receive:
        await _pc?.addTransceiver(
            kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
            init: RTCRtpTransceiverInit(
                direction: TransceiverDirection.RecvOnly));
        if (Config.isAudioOnly == false) {
          await _pc?.addTransceiver(
              kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
              init: RTCRtpTransceiverInit(
                  direction: TransceiverDirection.RecvOnly));
        }
        break;
    }
    logger.d(
        '[WHIP] Initialize whip connection: mode: $mode, stream = ${stream?.id}');
    _setState(WhipState.initialized);
  }

  /// Connect to room with [roomId]
  Future<void> connect({required String roomId, required String peer}) async {
    try {
      // Ensure initialize is called.
      await initialize(mode: _mode);
      _setState(WhipState.connecting);
      // Create a new whep session
      await _createWhepSession(roomId: roomId, peer: peer);

      final Map<String, dynamic> constraints = {
        'mandatory': {
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': true,
        },
        'optional': [],
      };

      var offer = await _pc!.createOffer(constraints);
      offer = _fixSdp(offer);
      if (_mode == WhipMode.send && _videoCodec != null) {
        _setPreferredCodec(offer, videoCodec: _videoCodec!);
      }
      await _pc!.setLocalDescription(offer);

      final sdp = offer.sdp;
      // Connect to room and send offer.
      final endpoint = WhepEndpoint.connectWhepSession(_token, sdp!);
      var response = await apiClient.request(endpoint);
      // Get answer from response.
      var answer = RTCSessionDescription(response.body, 'answer');
      answer = _fixSdp(answer);
      logger.d('[WHIP] Receive answer: \n ${answer.sdp}');
      await _pc!.setRemoteDescription(answer);
      _setState(WhipState.connected);
      // Get resource path from header to send ICE.
      _resourcePath = response.headers['location'];
      if (_resourcePath == null) {
        logger.e('[WHIP] Resource url not found');
        _resourcePath = 'whep/conn';
      } else {
        _resourcePath = _resourcePath!.substring(1, _resourcePath!.length);
      }
    } catch (e) {
      logger.e('[WHIP] Connect failed with error: $e');
      _setState(WhipState.failure);
      lastError = e;
    }
  }

  /// Get list of available [MediaDeviceInfo] of [MediaDeviceKind],
  /// if kind is null, all media device will get.
  Future<List<MediaDeviceInfo>> getMediaDevices({MediaDeviceKind? kind}) async {
    final devices = await navigator.mediaDevices.enumerateDevices();
    if (kind == null) {
      return devices;
    }
    return List.from(devices.where((e) => e.kind == kind.value));
  }

  /// Select audio output by device id.
  Future<void> selectAudioOutput(String deviceId) async {
    await navigator.mediaDevices
        .selectAudioOutput(AudioOutputOptions(deviceId: deviceId));
  }

  /// Close connection.
  Future<void> close() async {
    if (state == WhipState.disconnected) {
      return;
    }
    logger.d('[WHIP] closing connection');
    await _pc?.close();
    _pc = null;
    try {
      if (_resourcePath != null) {
        final endpoint = WhepEndpoint.deleteConnection(_resourcePath!);
        await apiClient.request(endpoint);
      }
    } catch (e) {
      logger.e('[WHIP] close connection with error: $e');
      _setState(WhipState.failure);
      lastError = e;
      return;
    }
    _setState(WhipState.disconnected);
  }

  //endregion

  //region: Private

  /// Create a whep session, if success access token will saved to [_token] variable.
  Future<void> _createWhepSession(
      {required String roomId, required String peer}) async {
    final body = CreateWhipSessionRequestBody(
        room: roomId, peer: peer, ttl: 7200, record: true, extraData: "string");
    final BaseApiResponse<SessionTokenModel> sessionTokenResponse =
        await apiClient.ermisRequest(TokenEndpoint.createWhepSession(body));
    final whepToken = sessionTokenResponse.data?.token;
    if (whepToken == null) {
      throw Exception('Can not create whep session');
    }
    _token = whepToken;
  }

  /// Send [RTCIceCandidate] to sever.
  void _onIceCandidate(RTCIceCandidate? ice) async {
    if (ice == null || _resourcePath == null) {
      return;
    }
    logger.d('[WHIP] Sending ice candidate: ${ice.toMap().toString()}');

    final endpoint = WhepEndpoint.sendIce(_resourcePath!, ice.candidate);
    try {
      final response = await apiClient.request(endpoint);
      logger.d('[WHIP] Send ice success with response $response');
    } catch (e) {
      logger.d('[WHIP] Send ice failed with error: $e');
    }
  }

  /// Update [WhipState]
  void _setState(WhipState newState) {
    onState?.call(newState);
    state = newState;
  }

  /// Set preferred codec for [RTCSessionDescription].
  void _setPreferredCodec(RTCSessionDescription description,
      {String audioCodec = 'opus', String videoCodec = 'vp8'}) {
    var capSel = CodecCapabilitySelector(description.sdp!);
    var acaps = capSel.getCapabilities('audio');
    if (acaps != null) {
      acaps.codecs = acaps.codecs
          .where((e) => (e['codec'] as String).toLowerCase() == audioCodec)
          .toList();
      acaps.setCodecPreferences('audio', acaps.codecs);
      capSel.setCapabilities(acaps);
    }
    if (Config.isAudioOnly == false) {
      var vcaps = capSel.getCapabilities('video');
      if (vcaps != null) {
        vcaps.codecs = vcaps.codecs
            .where((e) => (e['codec'] as String).toLowerCase() == videoCodec)
            .toList();
        vcaps.setCodecPreferences('video', vcaps.codecs);
        capSel.setCapabilities(vcaps);
      }
    }
    description.sdp = capSel.sdp();
  }

  /// Fix [RTCSessionDescription].
  /// In iOS the unsupported codec will be remove.
  RTCSessionDescription _fixSdp(RTCSessionDescription s) {
    logger.d('FIXING SDP ${s.type}');
    var sdp = s.sdp;

    List<String> components = sdp!.split('\n');
    // components.removeWhere((e) => e.contains('H264'));
    if (s.type == 'offer') {
      // Remove codec don't supported in iOS
      if (Platform.isIOS && !kIsWeb) {
        components = components
            .map((e) => e.contains("m=video")
                ? 'm=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99'
                : e)
            .toList();
        components.removeWhere(
            (e) => e.contains(':35') && !e.contains('fingerprint'));
        components.removeWhere(
            (e) => e.contains(':36') && !e.contains('fingerprint'));
        components.removeWhere(
            (e) => e.contains(':37') && !e.contains('fingerprint'));
        components.removeWhere(
            (e) => e.contains(':100') && !e.contains('fingerprint'));
        components.removeWhere(
            (e) => e.contains(':101') && !e.contains('fingerprint'));
        components.removeWhere(
            (e) => e.contains(':103') && !e.contains('fingerprint'));
        components.removeWhere(
            (e) => e.contains(':104') && !e.contains('fingerprint'));
        components.removeWhere(
            (e) => e.contains(':105') && !e.contains('fingerprint'));
        components.removeWhere(
            (e) => e.contains(':106') && !e.contains('fingerprint'));
        components.removeWhere(
            (e) => e.contains(':127') && !e.contains('fingerprint'));
      }
      // components = components
      //     .map((e) => e.contains("m=video")
      //         ? 'm=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99'
      //         : e)
      //     .toList();

      // components.removeWhere((e) => e.contains(':35'));
      // components.removeWhere((e) => e.contains(':36'));
      // components.removeWhere((e) => e.contains(':37'));
      // components.removeWhere((e) => e.contains(':96'));
      // components.removeWhere((e) => e.contains(':97'));
      // components.removeWhere((e) => e.contains(':98'));
      // components.removeWhere((e) => e.contains(':99'));
      // components.removeWhere((e) => e.contains(':100'));
      // components.removeWhere((e) => e.contains(':101'));
      // components.removeWhere((e) => e.contains(':103'));
      // components.removeWhere((e) => e.contains(':104'));
      // components.removeWhere((e) => e.contains(':105'));
      // components.removeWhere((e) => e.contains(':106'));
      // components.removeWhere((e) => e.contains(':127'));

      // components
      //     .removeWhere((e) => e.contains(':35') && !e.contains('fingerprint'));
      // components
      //     .removeWhere((e) => e.contains(':36') && !e.contains('fingerprint'));
      // components
      //     .removeWhere((e) => e.contains(':37') && !e.contains('fingerprint'));
      // components.removeWhere((e) => e.contains(':96') && !e.contains('fingerprint'));
      // components.removeWhere((e) => e.contains(':97') && !e.contains('fingerprint'));
      // components.removeWhere((e) => e.contains(':98') && !e.contains('fingerprint'));
      // components.removeWhere((e) => e.contains(':99') && !e.contains('fingerprint'));
      // components
      //     .removeWhere((e) => e.contains(':100') && !e.contains('fingerprint'));
      // components
      //     .removeWhere((e) => e.contains(':101') && !e.contains('fingerprint'));
      // components
      //     .removeWhere((e) => e.contains(':103') && !e.contains('fingerprint'));
      // components
      //     .removeWhere((e) => e.contains(':104') && !e.contains('fingerprint'));
      // components
      //     .removeWhere((e) => e.contains(':105') && !e.contains('fingerprint'));
      // components
      //     .removeWhere((e) => e.contains(':106') && !e.contains('fingerprint'));
      // components
      //     .removeWhere((e) => e.contains(':127') && !e.contains('fingerprint'));
      //
      // components = components
      //     .map((e) => e.contains('a=fmtp:96')
      //         ? "a=fmtp:96 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=64001f"
      //         : e)
      //     .toList();
    } else {
      // components = components.map((e) => e.contains("m=video") ? 'm=video 9 UDP/TLS/RTP/SAVPF 100' : e).toList();
      // components.removeWhere((e) => e.contains(':101') && !e.contains('fingerprint'));
      // components.removeWhere((e) => e.contains(':127') && !e.contains('fingerprint'));
      // components.removeWhere((e) => e.contains(':103') && !e.contains('fingerprint'));
    }
    // components.removeWhere((e) => e.contains(':96'));
    // components = components.map((e) => e.contains('VP8') ? 'a=rtpmap:96 H264/90000' : e).toList();
    // components.removeWhere((e) => e.contains('VP9'));

    String newSDPString = components.join('\n');

    logger.d('NEW SDP ${s.type} is: \n $newSDPString}');
    // newSDPString.replaceAll('VP9', 'H264');
    // newSDPString.replaceAll('VP8', 'H264');
    RTCSessionDescription newSDP = RTCSessionDescription(newSDPString, s.type);
    // s.sdp = sdp!.replaceAll('H264', 'h264');

    return newSDP;
  }
//endregion
}
