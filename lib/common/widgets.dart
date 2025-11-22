import 'package:flutter/material.dart';

class EmptyList extends StatelessWidget {
  const EmptyList({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(opacity: 0.25, child: Icon(Icons.playlist_remove, size: 24 * 8)),
    );
  }
}

class LinearLoaderIndicator extends StatelessWidget {
  final bool loading;

  const LinearLoaderIndicator({super.key, required this.loading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: Offstage(offstage: !loading, child: LinearProgressIndicator()),
    );
  }
}
