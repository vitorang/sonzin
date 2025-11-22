import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonzin/common/player.dart';
import 'package:sonzin/common/util.dart';
import 'package:sonzin/common/widgets.dart';
import 'package:sonzin/pages/player_page.dart';
import 'package:sonzin/pages/youtube/youtube_playlist.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeSearchArguments {
  final SearchFilter filter;

  YoutubeSearchArguments({required this.filter});
}

class YoutubeSearchController extends GetxController {
  late YoutubeSearchArguments arguments;
  final yt = YoutubeExplode();
  final textController = TextEditingController(text: '');
  final textFocus = FocusNode();
  final resultScroller = ScrollController();
  SearchList? searchResult;
  List<SearchResult> results = [];

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
    resultScroller.addListener(onResultScroll);
  }

  Future<void> search() async {
    if (textController.text.removeAllWhitespace.isEmpty) return;
    if (loading) return;

    loading = true;
    try {
      searchResult = await yt.search.searchContent(textController.text, filter: arguments.filter);
      results = searchResult!.map((r) => r).toList();
      if (resultScroller.hasClients) resultScroller.jumpTo(0.0);
    } catch (e) {
      Get.snackbar('Erro', e.toString());
    } finally {
      loading = false;
    }
  }

  Future<void> nextPage() async {
    loading = true;
    try {
      searchResult = await searchResult!.nextPage();
      if (searchResult != null) {
        results.addAll(searchResult!.map((v) => v));
      }
    } catch (e) {
      Get.snackbar('Erro', e.toString());
    } finally {
      loading = false;
    }
  }

  void onResultScroll() async {
    if (searchResult == null || loading) return;

    if (resultScroller.position.pixels >= resultScroller.position.maxScrollExtent - 200) {
      nextPage();
    }
  }

  goToPlaylist(SearchPlaylist playlist) async {
    if (loading) return;
    textFocus.unfocus();

    Get.to(
      () => YoutubePlaylistPage(),
      arguments: YoutubePlaylistArguments(playlistId: playlist.id, title: playlist.title),
    );
  }

  goToVideo(SearchVideo video) async {
    if (loading) return;

    textFocus.unfocus();
    loading = true;

    try {
      var manifest = await yt.videos.streams.getManifest(video.id);
      var audio = manifest.audioOnly.sortByBitrate().first;
      Get.to(
        () => PlayerPage(),
        arguments: PlayerArguments(
          title: video.title,
          album: video.author,
          url: audio.url.toString(),
          image: video.thumbnails.first.url.toString(),
          canSeek: true,
        ),
      );
    } finally {
      loading = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    yt.close();
    textFocus.dispose();
  }
}

class YoutubeSearchPage extends GetView<YoutubeSearchController> {
  YoutubeSearchPage({super.key});
  final thumbnailSize = Size(24 * 2, 24 * 3);

  String get searchHintText {
    var filter = controller.arguments.filter;
    if (filter == TypeFilters.video) return 'Vídeo...';
    if (filter == TypeFilters.playlist) return 'Playlist...';
    if (filter == TypeFilters.channel) return 'Canais...';
    return 'Pesquisar...';
  }

  @override
  Widget build(BuildContext context) {
    Get.put(YoutubeSearchController());

    return GetBuilder<YoutubeSearchController>(
      builder: (controller) {
        return SafeArea(
          child: Scaffold(
            appBar: buildAppBar(controller),
            body: Column(
              children: [
                LinearLoaderIndicator(loading: controller.loading),
                Expanded(child: controller.results.isNotEmpty ? buildList(controller) : EmptyList()),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar buildAppBar(YoutubeSearchController controller) {
    return AppBar(
      title: TextField(
        focusNode: controller.textFocus,
        onSubmitted: (_) => controller.search(),
        controller: controller.textController,
        decoration: InputDecoration(hintText: searchHintText),
      ),
      actions: [
        IconButton(
          onPressed: () {
            controller.textFocus.unfocus();
            controller.search();
          },
          icon: Icon(Icons.search),
        ),
      ],
    );
  }

  Widget buildList(YoutubeSearchController controller) {
    return ListView(
      controller: controller.resultScroller,

      children: [
        ...controller.results.map((result) {
          if (result is SearchChannel) return buildChannelTile(result);
          if (result is SearchPlaylist) return buildPlaylistTile(result);
          if (result is SearchVideo) return buildVideoTile(result);
          return buildUnknownTile();
        }),
      ],
    );
  }

  Widget buildChannelTile(SearchChannel channel) {
    return ListTile(
      leading: SizedBox(
        width: thumbnailSize.width,
        height: thumbnailSize.height,
        child: Image.network(channel.thumbnails.first.url.toString(), fit: BoxFit.cover),
      ),
      title: Text(channel.name),
    );
  }

  Widget buildPlaylistTile(SearchPlaylist playlist) {
    return ListTile(
      leading: SizedBox(
        width: thumbnailSize.width,
        height: thumbnailSize.height,
        child: Image.network(playlist.thumbnails.first.url.toString(), fit: BoxFit.cover),
      ),
      title: Text(playlist.title),
      subtitle: Text('${playlist.videoCount} ${plural(playlist.videoCount, 'vídeo', 'vídeos')}'),
      onTap: () => controller.goToPlaylist(playlist),
    );
  }

  Widget buildVideoTile(SearchVideo video) {
    return ListTile(
      leading: SizedBox(
        width: thumbnailSize.width,
        height: thumbnailSize.height,
        child: Image.network(video.thumbnails.first.url.toString(), fit: BoxFit.cover),
      ),
      title: Text(video.title),
      subtitle: Text(video.author),
      onTap: () => controller.goToVideo(video),
    );
  }

  Widget buildUnknownTile() {
    return ListTile(title: Text('Tipo desconhecido'));
  }
}

class YoutubeVideo extends StatelessWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final String title;
  final String channel;

  const YoutubeVideo({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
