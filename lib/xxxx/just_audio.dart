import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.filter_tilt_shift),
        onPressed: () {
          retrieveAudioData();
        },
      ),
    );
  }

  void retrieveAudioData() async {
    final audioPlayer = AudioPlayer();

    const filePath = 'assets/sample.wav';

    await audioPlayer.setAsset(filePath);
    final duration = audioPlayer.duration;
    final sampleRate = await audioPlayer.icyMetadata;

    print('adsfasdf ${sampleRate}');
  }
}
