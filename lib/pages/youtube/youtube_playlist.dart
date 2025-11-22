import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonzin/common/player.dart';
import 'package:sonzin/common/widgets.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubePlaylistArguments {
  final String title;
  final PlaylistId playlistId;

  YoutubePlaylistArguments({required this.title, required this.playlistId});
}

class YoutubePlaylistController extends GetxController {
  late YoutubePlaylistArguments arguments;
  final yt = YoutubeExplode();
  late Stream<Video> videoStream;
  List<Video> videos = [];
  Video? currentVideo;
  PlayerArguments? playerArguments;

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value) {
    _loading = value;
    update();
  }

  @override
  void onInit() {
    super.onInit();

    arguments = Get.arguments;
    videoStream = yt.playlists.getVideos(arguments.playlistId);
    search();
  }

  @override
  void dispose() {
    super.dispose();

    yt.close();
  }

  Future<void> search() async {
    if (loading) return;
    loading = true;

    try {
      videos.addAll(await videoStream.toList());
    } catch (e) {
      Get.snackbar('Erro', e.toString());
    } finally {
      loading = false;
    }
  }

  void nextMusic() {
    if (currentVideo == null || currentVideo == videos.last) return;
    var index = videos.indexOf(currentVideo!);
    setVideo(videos[index + 1]);
  }

  setVideo(Video video) async {
    if (loading || video == currentVideo) return;

    currentVideo = null;
    loading = true;

    try {
      var manifest = await yt.videos.streams.getManifest(video.id);
      var audio = manifest.audioOnly.sortByBitrate().first;

      playerArguments = PlayerArguments(
        title: video.title,
        album: video.author,
        url: audio.url.toString(),
        image: video.thumbnails.lowResUrl,
        canSeek: true,
        compact: true,
        nextMusic: nextMusic,
      );

      currentVideo = video;
    } finally {
      loading = false;
    }
  }
}

class YoutubePlaylistPage extends GetView<YoutubePlaylistController> {
  const YoutubePlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(YoutubePlaylistController());

    return Builder(
      builder: (context) {
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(title: Text(controller.arguments.title)),
            body: GetBuilder<YoutubePlaylistController>(
              builder: (controller) {
                return Column(
                  children: [
                    LinearLoaderIndicator(loading: controller.loading),
                    Expanded(child: buildList()),
                    buildPlayer(),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildList() {
    final thumbnailSize = Size(24 * 2, 24 * 3);

    if (controller.videos.isEmpty) return EmptyList();

    return ListView(
      children: [
        ...controller.videos.map((video) {
          var selected = video == controller.currentVideo;

          return ListTile(
            selected: selected,
            leading: SizedBox(
              width: thumbnailSize.width,
              height: thumbnailSize.height,
              child: Image.network(video.thumbnails.lowResUrl, fit: BoxFit.cover),
            ),
            title: Text(video.title, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text(video.author),
            onTap: () => controller.setVideo(video),
          );
        }),
      ],
    );
  }

  Widget buildPlayer() {
    if (controller.currentVideo == null) return Card(child: PlayerPlaceholder());

    return Card(
      child: Player(key: Key(controller.playerArguments!.url), arguments: controller.playerArguments!),
    );
  }
}
