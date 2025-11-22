import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonzin/clients/web_radio/radio_garden_client.dart';
import 'package:sonzin/clients/web_radio/radio_pt_client.dart';
import 'package:sonzin/clients/web_radio/tunein_client.dart';
import 'package:sonzin/clients/web_radio/web_radio_client.dart';
import 'package:sonzin/common/player.dart';
import 'package:sonzin/common/widgets.dart';
import 'package:sonzin/pages/player_page.dart';

class WebRadioController extends GetxController {
  final textController = TextEditingController(text: '');
  final textFocus = FocusNode();
  bool loadingRadio = false;

  void search(String text, List<WebRadioClient> clients) {
    for (var client in clients) {
      client.searchAndSet(text, () {}, (error) {
        Get.snackbar('Erro', error.toString());
      });
    }
  }

  void goToRadio(RadioEntry radio, WebRadioClient client) async {
    textFocus.unfocus();
    if (loadingRadio) return;

    try {
      if (radio.streamUrl == null) {
        radio = await client.loadStreamUrl(radio);
      }

      Get.to(
        () => PlayerPage(),
        arguments: PlayerArguments(
          title: radio.name ?? radio.description ?? 'Rádio',
          album: client.name,
          url: radio.streamUrl!,
          image: radio.image,
        ),
      );
    } catch (error) {
      Get.snackbar('Erro', error.toString());
    } finally {
      loadingRadio = false;
    }
  }
}

class WebRadioPage extends GetView<WebRadioController> {
  const WebRadioPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(WebRadioController());
    var clients = [Get.put(RadioGardenClient()), Get.put(RadioPtClient()), Get.put(TuneInClient())];

    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: controller.textController,
              focusNode: controller.textFocus,
              decoration: InputDecoration(hintText: 'Pesquisar...'),
              onChanged: (String text) => controller.search(text, clients),
            ),
            bottom: TabBar(
              onTap: (_) {
                controller.textFocus.unfocus();
              },
              tabs: [tab<RadioPtClient>(), tab<TuneInClient>(), tab<RadioGardenClient>()],
            ),
          ),
          body: TabBarView(children: [list<RadioPtClient>(), list<TuneInClient>(), list<RadioGardenClient>()]),
        ),
      ),
    );
  }

  Widget tab<T extends WebRadioClient>() {
    return GetBuilder<T>(
      builder: (client) {
        const iconSize = 24.0;
        Widget icon = SizedBox(width: iconSize, child: const CircularProgressIndicator());
        if (!client.loading) {
          icon = Text(client.radios.length.toString(), style: TextStyle(fontSize: 16));
        }

        return Tab(
          text: client.name,
          icon: SizedBox(
            width: 50,
            height: iconSize,
            child: Center(child: icon),
          ),
        );
      },
    );
  }

  Widget list<T extends WebRadioClient>() {
    return GetBuilder<T>(
      builder: (client) {
        if (client.radios.isEmpty) return EmptyList();

        return ListView(
          children: [
            for (var radio in client.radios)
              ListTile(
                onTap: () => controller.goToRadio(radio, client),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: SizedBox(width: 48, height: 48, child: radioLogo(radio)),
                ),
                title: Text(radioName(radio)),
              ),
          ],
        );
      },
    );
  }

  Widget radioLogo(RadioEntry? radio) {
    String? imageUrl = radio?.image;
    if (imageUrl == null || imageUrl.isEmpty) return Container(color: Colors.grey.withAlpha(30));
    return Image.network(imageUrl);
  }

  String radioName(RadioEntry? radio) {
    String name = radio?.name ?? '';
    if (name.isEmpty) name = radio?.description ?? '';
    return name;
  }
}
