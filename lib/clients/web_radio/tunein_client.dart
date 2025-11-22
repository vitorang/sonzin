import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sonzin/clients/web_radio/web_radio_client.dart';

class TuneInClient extends WebRadioClient {
  static final Map<String, String> streamUrlCache = {};

  @override
  String get name => 'TuneIn';

  @override
  Future<RadioEntry> loadStreamUrl(RadioEntry radio) async {
    String url = 'https://opml.radiotime.com/Tune.ashx?id=${radio.extra}';
    var response = await http.get(Uri.parse(url), headers: headers({}));
    if (response.statusCode != 200) throw 'Status ${response.statusCode}';
    if (!response.body.startsWith(RegExp('https?://'))) throw response.body;

    var urls = response.body.split('\n').where((line) => line.isNotEmpty);
    var pls = urls.where((url) => url.endsWith('.pls'));
    var others = urls.where((url) => !url.endsWith('.pls'));

    var streamUrl = '';
    if (others.isNotEmpty) {
      streamUrl = others.first;
    } else if (pls.isNotEmpty) {
      streamUrl = await streamFromPls(pls.first);
    } else {
      throw 'Nenhum stream encontrado em $url';
    }

    streamUrlCache[radio.extra!] = streamUrl;

    return RadioEntry(
      name: radio.name,
      extra: radio.extra,
      image: radio.image,
      description: radio.description,
      streamUrl: streamUrl,
    );
  }

  @override
  Future<List<RadioEntry>> search(String name) async {
    String url =
        'https://api.tunein.com/profiles?fullTextSearch=true&query=${Uri.encodeComponent(name)}&formats=mp3,aac,ogg,flash,html,hls,wma&serial=9f3fca1a-af70-47e5-9d6f-278b4ebe8608&partnerId=RadioTime&version=6.7701&itemUrlScheme=secure&reqAttempt=1';
    var response = await http.get(Uri.parse(url), headers: headers({}));
    if (response.statusCode != 200) throw 'Status ${response.statusCode}';
    var data = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    List<RadioEntry> radios = [];
    for (var item in data['Items']) {
      for (var child in item['Children'] ?? []) {
        if (child['Type'] != 'Station') continue;

        var extra = child['GuideId'];
        if (radios.any((radio) => radio.extra == child['GuideId'])) continue;

        radios.add(
          RadioEntry(
            name: child['Title'],
            image: child['Image'],
            description: child['Subtitle'],
            extra: extra,
            streamUrl: streamUrlCache[extra],
          ),
        );
      }
    }

    return radios;
  }
}
