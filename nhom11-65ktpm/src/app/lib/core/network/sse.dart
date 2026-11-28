import 'dart:async';
import 'dart:convert';

/// Một sự kiện Server-Sent Events (`event: <tên>` + `data: <json>`).
class SseEvent {
  final String event;
  final String data;

  const SseEvent(this.event, this.data);

  Map<String, dynamic> get json => jsonDecode(data) as Map<String, dynamic>;

  @override
  String toString() => 'SseEvent($event, $data)';
}

/// Chuyển luồng byte của response `text/event-stream` thành các [SseEvent].
///
/// Giải mã UTF-8 theo luồng nên chữ Hán bị cắt giữa hai gói mạng vẫn đúng.
Stream<SseEvent> parseSse(Stream<List<int>> bytes) async* {
  var event = 'message';
  final data = <String>[];

  await for (final line in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) {
        yield SseEvent(event, data.join('\n'));
      }
      event = 'message';
      data.clear();
      continue;
    }
    if (line.startsWith(':')) continue; // comment / keep-alive
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    if (field == 'event') {
      event = value;
    } else if (field == 'data') {
      data.add(value);
    }
  }
  if (data.isNotEmpty) {
    yield SseEvent(event, data.join('\n'));
  }
}
