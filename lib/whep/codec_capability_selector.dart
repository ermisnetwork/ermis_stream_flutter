import 'package:ermis_stream/whep/codec_capability.dart';
import 'package:sdp_transform/sdp_transform.dart' as sdp_transform;

class CodecCapabilitySelector {
  late String _sdp;
  late Map<String, dynamic> _session;

  Map<String, dynamic> get session => _session;

  String sdp() => sdp_transform.write(_session, null);

  CodecCapabilitySelector(String sdp) {
    _sdp = sdp;
    _session = sdp_transform.parse(sdp);
  }

  CodecCapability? getCapabilities(String kind) {
    var mline = _mline(kind);
    if (mline == null) {
      return null;
    }
    var rtcpFb = mline['rtcpFb'] as List<dynamic>;
    var fmtp = mline['fmtp'] as List<dynamic>;
    var payloads = (mline['payloads'] as String).split(' ');
    var codecs = mline['rtp'] as List<dynamic>;
    return CodecCapability(kind, payloads, codecs, fmtp, rtcpFb);
  }

  bool setCapabilities(CodecCapability? caps) {
    if (caps == null) {
      return false;
    }

    var mline = _mline(caps.kind);
    if (mline == null) {
      return false;
    }
    mline['payloads'] = caps.payloads.join(' ');
    mline['rtp'] = caps.codecs;
    mline['fmtp'] = caps.fmtp;
    mline['rtcpFb'] = caps.rtcpFb;

    var mlines = _session['media'] as List<dynamic>;
    mlines.forEach((element) {
      element.remove('ssrcGroups');
      var ssrcs = element['ssrcs'];
      if (ssrcs != null && ssrcs.length >= 4) {
        element['ssrcs'] = ssrcs.sublist(0,3);
      }
    });
    return true;
  }

  Map<String, dynamic>? _mline(String kind) {
    var mlist = _session['media'] as List<dynamic>;
    return mlist.firstWhere((element) => element['type'] == kind,
        orElse: () => null);
  }
}
