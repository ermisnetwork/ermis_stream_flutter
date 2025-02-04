class CreateWhipSessionRequestBody {
  String room;
  String peer;
  int ttl;
  bool record;
  String extraData;

  CreateWhipSessionRequestBody({required this.room, required this.peer, required this.ttl, required this.record, required this.extraData});

  Map<String, dynamic> endCode() {
    return {
      'room': room,
      'peer': peer,
      'ttl': ttl,
      'record': record,
      'extra_data': extraData
    };
  }
}