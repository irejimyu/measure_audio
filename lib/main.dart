import 'package:flutter/material.dart';
import 'package:sample/xxxx/flutter_fft.dart';
import 'package:sample/xxxx/flutter_sound.dart';
import 'package:sample/xxxx/just_audio.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Simple flutter fft example",
      color: Colors.blue,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
      ),
      home: const SampleList(),
    );
  }
}

class SampleList extends StatelessWidget {
  const SampleList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Flutter_Sound'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecordToStreamExample(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Flutter_FFT'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Application(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Just_Audio'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Home(),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
