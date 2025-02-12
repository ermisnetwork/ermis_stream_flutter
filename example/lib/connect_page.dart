import 'dart:isolate';

import 'package:ermis_stream/config/config.dart';
import 'package:ermis_stream/ermis_stream.dart';
import 'package:ermis_stream/utilities/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ConnectPageState();
  }
}

class _ConnectPageState extends State<ConnectPage> {
  final roomIdTextEditingController = TextEditingController();
  final WHIP whip = WHIP();
  String roomId = "";
  bool isConnect = false;
  bool isLoading = false;
  static const platform = MethodChannel("network.ermis.test_stream");

  bool get isButtonEnable {
    return roomIdTextEditingController.text.isNotEmpty;
  }

  String state = 'Connecting';
  final remoteVideoRenderer = RTCVideoRenderer();
  bool isReady = false;
  List<MediaDeviceInfo> deviceInfos = [];

  @override
  void initState() {
    _configWebRTC();
    Config.appEnviroment = AppEnviroment.dev;
    initRenderers();
    whip.initialize(mode: WhipMode.receive);
    whip.onState = (WhipState state) {
      var stateValue = "Connecting";
      switch (state) {
        case WhipState.connecting:
          stateValue = "Connecting";
        case WhipState.disconnected:
          stateValue = "Disconnected";
        case WhipState.connected:
          stateValue = "Connected";
        case WhipState.failure:
          stateValue = "Failure";
        case WhipState.initialized:
          stateValue = "Initialized";
        case WhipState.idle:
          stateValue = "Idle";
      }
      logger.d("State changed to: $stateValue");
      setState(() {
        this.state = stateValue;
      });
    };

    whip.onTrack = (event) {
      logger.d("WHIP ON VIDEO TRACK: ${event.track.kind}");
      if (event.track.kind == 'video') {
        setVideoSource(event.streams[0]);
      }
    };

    whip.onAddTrack = (stream, track) {
      logger.d('ON ADD TRACK ${track.kind}');
    };

    whip.onAddStream = (stream) {
      logger.d('ON ADD STREAM');
      final videoStream =
          stream.getTracks().where((e) => e.kind == 'video' && e.enabled);
      if (videoStream.isNotEmpty) {
        logger.d('TTTTTTTT SET VIDEO SOURCE');
        setVideoSource(stream);
      }
    };

    whip.onMediaDeviceInfoListChanged = (dynamic devices) {
      getDeviceInfos();
    };

    getDeviceInfos();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Ermis stream'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: ListView(
            children: [
              Builder(builder: (context) {
                if (!isConnect) {
                  return TextField(
                    controller: roomIdTextEditingController,
                    onChanged: (value) {
                      setState(() {});
                    },
                  );
                } else {
                  return Container(
                    height: 200,
                    width: 150,
                    decoration: BoxDecoration(color: Colors.black54),
                    child: Stack(
                      children: [
                        Container(
                          height: 200,
                          width: 150,
                          decoration: BoxDecoration(color: Colors.yellow),
                          child: RTCVideoView(
                            remoteVideoRenderer,
                            mirror: false,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitContain,
                          ),
                        ),
                        Container(
                          alignment: Alignment(1, 1),
                          child: createSpeakerOutputMenu(deviceInfos),
                        ),
                        Center(
                          child: Text(
                            state,
                            style: TextStyle(
                                color: state != 'Connected'
                                    ? Colors.white
                                    : Colors.transparent),
                          ),
                        )
                      ],
                    ),
                  );
                }
              }),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: ElevatedButton(
                    onPressed: isButtonEnable ? onConnectButtonTapped : null,
                    child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(isConnect ? 'Disconnect' : 'Connect'))),
              )
            ],
          ),
        ));
  }

  @override
  void dispose() {
    roomIdTextEditingController.dispose();
    remoteVideoRenderer.dispose();
    super.dispose();
  }

  void onConnectButtonTapped() {
    isConnect ? disConnect() : connect();
  }

  Future<void> connect() async {
    setState(() {
      roomId = roomIdTextEditingController.text;
      isLoading = true;
    });

    await initRenderers();

    final peer = "Viewer 1";
    try {
      await whip.connect(roomId: roomId, peer: peer);
      setState(() {
        isConnect = true;
      });
    } catch (e) {
      logger.e('Connect to room ${roomId} failed with error: $e');
    } finally {
      isLoading = true;
      setState(() {});
    }
  }

  Future<void> disConnect() async {
    remoteVideoRenderer.srcObject = null;
    await whip.close();
    setState(() {
      isConnect = false;
    });
  }
  
  void _configWebRTC() {
    try {
      platform.invokeMethod('setUpWebRTC');
    } on PlatformException catch (e) {
      logger.e('Fail to invoke method setupWebRTC on platform');
    }
  }

//region Create UI
  Future<void> initRenderers() async {
    await remoteVideoRenderer.initialize();
  }

  Future<void> setVideoSource(MediaStream? stream) async {
    remoteVideoRenderer.srcObject = stream;
    isReady = true;
    stream?.getTracks().forEach((track) {
      // logger.d('TTTT TRACK CONSTRAINT ${track.getConstraints()}');
    });
    setState(() {});
  }

  Future<void> getDeviceInfos() async {
    final audioDevicesInfo =
        await whip.getMediaDevices(kind: MediaDeviceKind.audioOutput);
    logger.d("TTTT auido devices: $audioDevicesInfo");
    setState(() {
      deviceInfos = audioDevicesInfo;
    });
  }

  MenuAnchor createSpeakerOutputMenu(List<MediaDeviceInfo> mediaDeviceInfos) {
    return MenuAnchor(
        builder:
            (BuildContext context, MenuController controller, Widget? child) {
          return IconButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(CupertinoIcons.speaker_2_fill),
            tooltip: 'Select audio output',
          );
        },
        menuChildren: List<MenuItemButton>.from(
            mediaDeviceInfos.map((deviceInfo) => MenuItemButton(
                  onPressed: () => whip.selectAudioOutput(deviceInfo.deviceId),
                  child: Text(deviceInfo.label),
                ))));
  }
//endregion
}
