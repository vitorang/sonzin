import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sonzin/clients/web_radio/web_radio_client.dart';

class RadioGardenClient extends WebRadioClient {
  @override
  String get name => 'R. Garden';

  @override
  Future<List<RadioEntry>> search(String name) async {
    if (name == '') return [];

    var url = 'https://radio.garden/api/search/secure?q=${Uri.encodeComponent(name)}';
    var response = await http.get(Uri.parse(url), headers: headers({}));
    if (response.statusCode != 200) throw 'Status ${response.statusCode}';
    var data = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    var radios = (data['hits']['hits'] as List<dynamic>)
        .map((hit) => hit['_source']! as Map<String, dynamic>)
        .where((hit) => hit['type'] == 'channel')
        .map((hit) => hit['page']! as Map<String, dynamic>)
        .map(
          (page) => RadioEntry(
            streamUrl: 'https://radio.garden/api/ara/content/listen/${parseId(page['url'])}/channel.mp3',
            name: page['title'],
            description: page['subtitle'],
          ),
        )
        .toList();

    return radios;
  }

  String parseId(String url) {
    return url.split('/').last;
  }

  @override
  Future<RadioEntry> loadStreamUrl(RadioEntry radio) {
    throw UnimplementedError();
  }
}
