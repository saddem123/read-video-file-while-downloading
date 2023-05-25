import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';


class TestPage extends StatefulWidget {
  const TestPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {

  late VideoPlayerController _videoPlayerController;
  bool playerInitialized = false;


  String fileName = "video12.mp4";


  String? taskId;

  late String filePath;

  String testVideoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4";

  final ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) async {
      String id = data[0];
      int status = data[1];
      int progress = data[2];

      if(progress > 35 && taskId != null && !playerInitialized){
        await FlutterDownloader.pause(taskId: taskId!);

        var file = File(filePath);
        // you can modify it to VideoPlayerController.file but it don't work for me
        _videoPlayerController = VideoPlayerController.network(
          file.absolute.path,
        );
        _videoPlayerController.initialize().then((value) => setState(() => playerInitialized = true));
      }
    });
    FlutterDownloader.registerCallback(downloadCallback);
    initPlayer();


  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  Future<void> initPlayer() async {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    String path = "${appDocDirectory.path}/videos";
    await Directory(path).create(recursive: true);
    FlutterDownloader.enqueue(
      url: testVideoUrl,
      savedDir: path,
      fileName: fileName,
      showNotification: false, // show download progress in status bar (for Android)
    ).then((value) {
      setState(() {
        taskId = value;
        filePath =  path + "/" +fileName;
      });
    }).onError((error, stackTrace) {
    });
  }


  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20,),
            playerInitialized ?
            VisibilityDetector(
              key: const Key("video"),
              onVisibilityChanged: (visibilityFraction){
                if(visibilityFraction.visibleFraction > 0.5){
                  _videoPlayerController.play();
                }
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.width,
                width: MediaQuery.of(context).size.width * 16/9,
                child: VideoPlayer(
                    _videoPlayerController
                ),
              ),
            ) :
            Container()
          ],
        ),
      ),
    );
  }


  @override
  void dispose() async {
    _videoPlayerController.dispose();
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }
}


