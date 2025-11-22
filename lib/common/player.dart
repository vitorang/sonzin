import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sonzin/common/util.dart';

class PlayerArguments {
  final String title;
  final String album;
  final String url;
  final String? image;
  final bool canSeek;
  final bool compact;
  final void Function()? nextMusic;

  PlayerArguments({
    required this.title,
    required this.album,
    required this.url,
    this.image,
    this.canSeek = false,
    this.compact = false,
    this.nextMusic,
  });
}

class PlayerPlaceholder extends StatelessWidget {
  const PlayerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(onPressed: null, icon: Icon(Icons.play_arrow)),
          Expanded(child: Slider(value: 0, onChanged: null)),
        ],
      ),
    );
  }
}

class Player extends StatefulWidget {
  final PlayerArguments arguments;

  const Player({super.key, required this.arguments});

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  final player = AudioPlayer();
  Duration? duration;
  bool playing = false;
  bool loading = false;
  bool error = false;
  double audioPosition = 0.0;
  double? sliderPosition;
  final imageSize = Size(12 * 16, 12 * 9);

  PlayerArguments get arguments => widget.arguments;

  @override
  void initState() {
    super.initState();

    player.playerStateStream.listen((state) {
      if (!mounted) return;

      var pState = state.processingState;

      setState(() {
        if (pState == ProcessingState.completed) {
          player.seek(Duration());
          player.stop();
          playing = false;
          loading = false;
          arguments.nextMusic?.call();
        } else if (state.playing) {
          playing = true;
          loading = false;
        } else {
          playing = false;
          loading = pState == ProcessingState.loading || pState == ProcessingState.buffering;
        }
      });
    });

    if (arguments.canSeek) {
      player.positionStream.listen((position) {
        if (!mounted) return;
        setState(() {
          audioPosition = position.inSeconds.toDouble();
        });
      });
    }

    _autoplay();
  }

  void _autoplay() async {
    await setSource(url: arguments.url, title: arguments.title, album: arguments.album, artUrl: arguments.image);
    player.play();
  }

  @override
  void dispose() {
    super.dispose();

    player.stop();
  }

  @override
  Widget build(BuildContext context) {
    return arguments.compact ? buildCompact(context) : buildNormal(context);
  }

  Widget buildCompact(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          PlayPauseButton(
            error: error,
            loading: loading,
            player: player,
            playing: playing,
            canSeek: arguments.canSeek,
            compact: arguments.compact,
          ),
          Expanded(
            child: PlayerProgress(
              audioPosition: audioPosition,
              canSeek: arguments.canSeek,
              onChangeEnd: onChangeEnd,
              onChangeStart: onChangeStart,
              onChanged: onChanged,
              player: player,
              sliderPosition: sliderPosition,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNormal(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    var backgroundColor = (brightness == Brightness.dark ? Colors.black : Colors.white);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            () {
              if ((arguments.image ?? '').isEmpty) return Container();

              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Image.network(arguments.image!, fit: BoxFit.cover),
              );
            }(),
            () {
              if ((arguments.image ?? '').isEmpty) return Container();

              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  color: backgroundColor.withAlpha(127),
                ),
              );
            }(),
            Padding(
              padding: EdgeInsetsGeometry.only(top: 0, left: 16, right: 16, bottom: 8),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(arguments.title, style: TextStyle(fontSize: 24), textAlign: TextAlign.center),
                          SizedBox(height: 8),
                          Text(arguments.album, style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
                          const SizedBox(height: 32),
                          PlayPauseButton(
                            error: error,
                            loading: loading,
                            player: player,
                            playing: playing,
                            canSeek: arguments.canSeek,
                            compact: arguments.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                  PlayerProgress(
                    audioPosition: audioPosition,
                    canSeek: arguments.canSeek,
                    onChangeEnd: onChangeEnd,
                    onChangeStart: onChangeStart,
                    onChanged: onChanged,
                    player: player,
                    sliderPosition: sliderPosition,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> load(String url) async {
    duration = await player.setUrl(url);
  }

  Future<void> setSource({required String url, required String title, required String album, String? artUrl}) async {
    url = url.replaceAll(RegExp('^http:'), 'https:');
    Uri? artUri = (artUrl ?? '').isNotEmpty ? Uri.parse(artUrl!) : null;

    var audioSource = AudioSource.uri(
      Uri.parse(url),
      tag: MediaItem(id: url, album: album, title: title, artUri: artUri),
    );

    try {
      duration = await player.setAudioSource(audioSource);
    } catch (e) {
      //Get.snackbar('Erro', error.toString());
      duration = Duration();
      error = true;
    } finally {
      if (mounted) setState(() {});
    }
  }

  void onChangeStart(double value) {
    if (mounted) {
      setState(() {
        sliderPosition = value;
      });
    }
  }

  void onChangeEnd(double value) {
    player.seek(Duration(seconds: value.toInt()));
    if (mounted) {
      setState(() {
        sliderPosition = null;
      });
    }
  }

  void onChanged(double value) {
    if (mounted) {
      setState(() {
        sliderPosition = value;
      });
    }
  }
}

class PlayPauseButton extends StatelessWidget {
  final bool loading;
  final bool error;
  final bool playing;
  final bool canSeek;
  final bool compact;
  final AudioPlayer player;

  const PlayPauseButton({
    super.key,
    required this.loading,
    required this.error,
    required this.playing,
    required this.player,
    required this.canSeek,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    double iconSize = compact ? 24 : 48;

    Future<void> Function()? onPressed;
    late Widget icon;

    if (loading) {
      icon = SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(color: IconTheme.of(context).color?.withAlpha(180)),
      );
    } else if (error) {
      icon = Icon(Icons.error_outline);
    } else if (!playing) {
      onPressed = player.play;
      icon = Icon(Icons.play_arrow);
    } else if (canSeek) {
      onPressed = player.pause;
      icon = Icon(Icons.pause);
    } else {
      onPressed = player.stop;
      icon = Icon(Icons.stop);
    }

    if (compact) {
      return IconButton(onPressed: onPressed, icon: icon, iconSize: iconSize);
    } else {
      return IconButton.outlined(onPressed: onPressed, icon: icon, iconSize: iconSize);
    }
  }
}

class PlayerProgress extends StatelessWidget {
  final bool canSeek;
  final AudioPlayer player;
  final double? sliderPosition;
  final double audioPosition;
  final void Function(double value) onChangeStart;
  final void Function(double value) onChangeEnd;
  final void Function(double value) onChanged;

  const PlayerProgress({
    super.key,
    required this.canSeek,
    required this.player,
    this.sliderPosition,
    required this.audioPosition,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!canSeek) return Container();

    var maxDuration = player.duration ?? Duration();
    var sliderPosition = this.sliderPosition ?? audioPosition;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        showValueIndicator: ShowValueIndicator.always,
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
      ),
      child: Slider(
        min: 0,
        max: maxDuration.inSeconds.toDouble(),
        value: sliderPosition,
        label: formatTime(sliderPosition),
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        onChanged: onChanged,
      ),
    );
  }
}
