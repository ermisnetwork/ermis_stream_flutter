class CodecCapability {
  String kind;
  List<dynamic> rtcpFb;
  List<dynamic> fmtp;
  List<String> payloads;
  List<dynamic> codecs;

  CodecCapability(
      this.kind, this.payloads, this.codecs, this.fmtp, this.rtcpFb) {
    codecs.forEach((element) {
      element['origin_payload'] = element['payload'];
    });
  }

  bool setCodecPreferences(String kind, List<dynamic>? newCodecs) {
    if (newCodecs == null) {
      return false;
    }
    var newRtcpFb = <dynamic>[];
    var newFmtp = <dynamic>[];
    var newPayloads = <String>[];
    newCodecs.forEach((element) {
      var originPayload = element['origin_payload'] as int;
      var payload = element['payload'] as int;
      // Change payload type
      if (payload != originPayload) {
        newRtcpFb.addAll(rtcpFb.where((element) {
          if (element['payload'] == originPayload) {
            element['payload'] = payload;
            return true;
          }
          return false;
        }).toList());

        newFmtp.addAll(rtcpFb.where((element) {
          if (element['payload'] == originPayload) {
            element['payload'] = payload;
            return true;
          }
          return false;
        }).toList());

        if (payloads.contains('$originPayload')) {
          newPayloads.add('$payload');
        }
      } else {
        newRtcpFb.addAll(rtcpFb.where((element) => element['payload'] == payload).toList());
        newFmtp.addAll(fmtp.where((element) => element['payload'] == payload).toList());
        newPayloads.addAll(payloads.where((element) => element == '$payload').toList());
      }
    });

    rtcpFb = newRtcpFb;
    fmtp = newFmtp;
    payloads = newPayloads;
    codecs = newCodecs;
    return true;
  }
}
