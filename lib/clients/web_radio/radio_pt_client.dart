import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sonzin/clients/web_radio/web_radio_client.dart';

class RadioPtClient extends WebRadioClient {
  @override
  String get name => 'radio.pt';

  @override
  Future<RadioEntry> loadStreamUrl(RadioEntry radio) {
    throw UnimplementedError();
  }

  @override
  Future<List<RadioEntry>> search(String name) async {
    var url = 'https://prod.radio-api.net/stations/search?query=${Uri.encodeComponent(name)}&count=50&offset=0';
    var response = await http.get(Uri.parse(url), headers: headers({}));
    if (response.statusCode != 200) throw 'Status ${response.statusCode}';
    var data = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    var radios = ((data['playables'] ?? []) as List<dynamic>).where((playable) => playable['hasValidStreams']).map((
      playable,
    ) {
      var description = ([
        playable['city'] ?? '',
        playable['country'] ?? '',
      ]).map((s) => s.toString()).where((s) => s.isNotEmpty);
      var streams = (playable['streams'] as List<dynamic>).where((stream) => stream['status'] == 'VALID');
      String? image = playable['logo100x100'] ?? playable['logo175x175'] ?? playable['logo44x44'];

      return RadioEntry(
        name: playable['name'],
        description: description.join(' - '),
        image: image,
        streamUrl: streams.first['url'],
      );
    });

    return radios.toList();
  }
}
