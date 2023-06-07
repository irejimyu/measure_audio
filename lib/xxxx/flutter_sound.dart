import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const int tSampleRate = 44100;
typedef _Fn = void Function();

/// Example app.
class RecordToStreamExample extends StatefulWidget {
  @override
  _RecordToStreamExampleState createState() => _RecordToStreamExampleState();
}

class _RecordToStreamExampleState extends State<RecordToStreamExample> {
  final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  final FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();

  bool _mplaybackReady = false;
  late String _mPath;
  StreamSubscription? _mRecordingDataSubscription;

  Future<void> _initialize() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    _mPlayer.openPlayer();
    _mRecorder.openRecorder();

    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    stopPlayer();
    _mPlayer.closePlayer();

    stopRecorder();
    _mRecorder.closeRecorder();
    super.dispose();
  }

  Future<IOSink> createFile() async {
    var tempDir = await getApplicationDocumentsDirectory();
    _mPath = '${tempDir.path}/flutter_sound_example.wav';
    print('path $_mPath');
    var outputFile = File(_mPath);
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }
    return outputFile.openWrite();
  }

  // ----------------------  Here is the code to record to a Stream ------------

  Future<void> record() async {
    assert(_mPlayer.isStopped);
    var sink = await createFile();
    var recordingDataController = StreamController<Food>();
    _mRecordingDataSubscription =
        recordingDataController.stream.listen((buffer) {
      if (buffer is FoodData) {
        sink.add(buffer.data!);
      }
    });
    await _mRecorder.startRecorder(
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: tSampleRate,
    );
    setState(() {});
  }
  // --------------------- (it was very simple, wasn't it ?) -------------------

  Future<void> stopRecorder() async {
    await _mRecorder.stopRecorder();
    if (_mRecordingDataSubscription != null) {
      await _mRecordingDataSubscription!.cancel();
      _mRecordingDataSubscription = null;
    }
    _mplaybackReady = true;
  }

  _Fn? getRecorderFn() {
    if (!_mPlayer.isStopped) {
      return null;
    }
    return _mRecorder.isStopped
        ? record
        : () {
            stopRecorder().then((value) => setState(() {}));
          };
  }

  void play() async {
    assert(_mplaybackReady && _mRecorder.isStopped && _mPlayer.isStopped);
    await _mPlayer.startPlayer(
      fromURI: _mPath,
      sampleRate: tSampleRate,
      codec: Codec.pcm16,
      numChannels: 1,
    );
  }

  Future<void> stopPlayer() async {
    await _mPlayer.stopPlayer();
  }

  _Fn? getReadPlaybackFn() {
    if (!_mplaybackReady || !_mRecorder.isStopped) {
      return null;
    }
    return () async {
      var outputFile = File(_mPath);
      if (outputFile.existsSync()) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('WaveForm'),
              content: SingleChildScrollView(
                child: Center(
                  child: WaveForm(
                    path: _mPath,
                  ),
                ),
              ),
            );
          },
        );
      }
    };
  }

  _Fn? getPlaybackFn() {
    if (!_mplaybackReady || !_mRecorder.isStopped) {
      return null;
    }
    return _mPlayer.isStopped
        ? play
        : () {
            _mPlayer.stopPlayer();
          };
  }
  // ----------------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record to Stream ex.'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton.icon(
            onPressed: getRecorderFn(),
            icon: Icon(
              _mRecorder.isRecording ? Icons.stop_circle : Icons.circle,
            ),
            label: Text(_mRecorder.isRecording
                ? 'Recording in progress'
                : 'Recorder is stopped'),
          ),
          ElevatedButton.icon(
            onPressed: getPlaybackFn(),
            icon: Icon(
              _mPlayer.isPlaying ? Icons.stop_circle : Icons.play_circle,
            ),
            label: Text(_mPlayer.isPlaying
                ? 'Recording in progress'
                : 'Recorder is stopped'),
          ),
          ElevatedButton.icon(
            onPressed: getReadPlaybackFn(),
            icon: const Icon(Icons.remove_red_eye),
            label: const Text('Read recorded data'),
          ),
        ],
      ),
    );
  }
}

class WaveForm extends StatefulWidget {
  const WaveForm({
    Key? key,
    required this.path,
  }) : super(key: key);

  final String path;

  @override
  State<WaveForm> createState() => _WaveFormState();
}

class _WaveFormState extends State<WaveForm> {
  final PlayerController playerController = PlayerController();
  late File soundFile;
  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    soundFile = File(widget.path);
    if (soundFile.existsSync()) {
      await soundFile.writeAsBytes(
        (await rootBundle.load('assets/sa.wav')).buffer.asUint8List(),
      );
      playerController.preparePlayer(
        path: soundFile.path,
        shouldExtractWaveform: true,
      );
    }
  }

  final playerWaveStyle = const PlayerWaveStyle(
    fixedWaveColor: Colors.white54,
    liveWaveColor: Colors.white,
    spacing: 6,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () async {
            playerController.playerState.isPlaying
                ? await playerController.pausePlayer()
                : await playerController.startPlayer();
          },
          icon: Icon(
            playerController.playerState.isPlaying
                ? Icons.stop
                : Icons.play_arrow,
          ),
          color: Colors.white,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        AudioFileWaveforms(
          size: Size(MediaQuery.of(context).size.width / 2, 70),
          playerController: playerController,
          waveformType: WaveformType.long,
          playerWaveStyle: const PlayerWaveStyle(
            showBottom: false,
            fixedWaveColor: Colors.white54,
            liveWaveColor: Colors.white,
            spacing: 6,
          ),
        ),
      ],
    );
  }
}
