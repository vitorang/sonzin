import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonzin/common/player.dart';

class PlayerController extends GetxController {
  late PlayerArguments arguments;

  @override
  void onInit() {
    super.onInit();

    arguments = Get.arguments;
  }
}

class PlayerPage extends GetView<PlayerController> {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(PlayerController());

    return SafeArea(
      child: Scaffold(body: Player(arguments: controller.arguments)),
    );
  }
}
