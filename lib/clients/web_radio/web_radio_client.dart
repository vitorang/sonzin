import 'dart:async';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

abstract class WebRadioClient extends GetxController {
  String get name;
  bool get loading => _searchTimer != null;

  Future<List<RadioEntry>> search(String name);
  Future<RadioEntry> loadStreamUrl(RadioEntry radio);
  List<RadioEntry> radios = [];
  Timer? _searchTimer;
  String _lastSearchText = '';

  void searchAndSet(String text, void Function() onComplete, void Function(Object error) onError) {
    _lastSearchText = text;
    if (_searchTimer != null) {
      return;
    }
    update();

    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      text = _lastSearchText;
      try {
        radios = (text.isEmpty ? [] : await search(text));
        onComplete();
      } catch (e) {
        onError(e);
      } finally {
        _searchTimer = null;
        update();
        if (text != _lastSearchText) {
          searchAndSet(_lastSearchText, onComplete, onError);
        }
      }
    });
  }

  Future<String> streamFromPls(String url) async {
    var response = await http.get(Uri.parse(url), headers: headers({}));
    if (response.statusCode != 200) throw 'Status ${response.statusCode}';
    return response.body
        .split('\n')
        .where((line) => line.toLowerCase().startsWith('file'))
        .first
        .split('=')
        .sublist(1)
        .join('=');
  }
}

Map<String, String> headers(Map<String, String> values) {
  var defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
    'Accept-Language': 'pt-BR',
  };

  return {...defaultHeaders, ...values};
}

class RadioEntry {
  final String? name;
  final String? description;
  final String? streamUrl;
  final String? image;
  final String? url;
  final String? extra;

  RadioEntry({required this.name, this.description, this.streamUrl, this.image, this.url, this.extra});
}
