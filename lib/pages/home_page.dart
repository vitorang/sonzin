import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonzin/pages/web_radio_page.dart';
import 'package:sonzin/pages/youtube/youtube_search.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            _listView('Youtube', [
              _Option(
                name: 'Vídeos',
                color: Colors.red,
                icon: Icons.play_arrow,
                page: () => YoutubeSearchPage(),
                arguments: YoutubeSearchArguments(filter: TypeFilters.video),
              ),
              _Option(
                name: 'Playlists',
                color: Colors.red,
                icon: Icons.playlist_play,
                page: () => YoutubeSearchPage(),
                arguments: YoutubeSearchArguments(filter: TypeFilters.playlist),
              ),

              _Option(
                name: 'Canais',
                color: Colors.red,
                icon: Icons.subscriptions,
                page: () => YoutubeSearchPage(),
                arguments: YoutubeSearchArguments(filter: TypeFilters.channel),
                disabled: true,
              ),
            ]),
            _listView('Outros', [
              _Option(name: 'Rádios Online', color: Colors.green, icon: Icons.radio, page: () => WebRadioPage()),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _listView(String title, Iterable<_Option> options) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title, textScaler: TextScaler.linear(2)),
          ),
          Card(
            child: ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                for (var option in options)
                  Opacity(
                    opacity: option.disabled ? 0.6 : 1.0,
                    child: ListTile(
                      leading: Container(
                        decoration: BoxDecoration(color: option.color, shape: BoxShape.circle),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(option.icon, color: Colors.white),
                        ),
                      ),
                      title: Text(option.name, textScaler: TextScaler.linear(1.25)),
                      onTap: option.disabled
                          ? null
                          : () async {
                              Get.to(option.page, arguments: option.arguments);
                            },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Option {
  final String name;
  final Widget Function() page;
  final Color color;
  final IconData icon;
  final dynamic arguments;
  final bool disabled;

  _Option({
    required this.name,
    required this.page,
    required this.color,
    required this.icon,
    this.arguments,
    this.disabled = false,
  });
}
