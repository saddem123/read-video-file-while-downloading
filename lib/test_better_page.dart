import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';


class TestPage extends StatefulWidget {
  const TestPage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {

  late VideoPlayerController _videoPlayerController;
  bool playerInitialized = false;

  final httpClient = http.Client();
  String fileName = "video12.mp4";


  String? taskId;
  late String filePath;
  // String testVideoUrl = 'https://media.w3.org/2010/05/sintel/trailer.mp4';
  String testVideoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4";
  // String testVideoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
  // String testVideoUrl = "https://firebasestorage.googleapis.com/v0/b/public-bucket-t4u/o/testStreamables%2FElephantsDreamStreamable.mp4?alt=media&token=5cd8d177-870d-4128-a6d2-e1d82214dcb9";
  // String testVideoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4';
  // String testVideoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4";
  final ReceivePort _port = ReceivePort();

  void initPlayerSecondTime() async {
    Directory appDocDirectory = await getApplicationSupportDirectory();
    String path = "${appDocDirectory.path}/videos";
    await Directory(path).create(recursive: true);
    print(path);

    filePath =  path + "/" +fileName;
    var file = File(filePath);
    _videoPlayerController = VideoPlayerController.file(
      file,
      // videoPlayerOptions: VideoPlayerOptions(),
    );
    _videoPlayerController.initialize().then((value) => setState(() {

      playerInitialized = true;
      _videoPlayerController.play();
    }));
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    //initPlayerSecondTime();

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) async {
      String id = data[0];
      int status = data[1];
      int progress = data[2];
      print("id $id");
      print("status $status");
      print("progress $progress");

      if(progress > 35 && taskId != null && !playerInitialized){
        print("enter to pause");
        await FlutterDownloader.pause(taskId: taskId!);

        var file = File(filePath);
        print('file $file ${file.absolute.path}');
        _videoPlayerController = VideoPlayerController.network(
          file.absolute.path,
        );
        _videoPlayerController.initialize().then((value) => setState(() => playerInitialized = true));
        // FlutterDownloader.pause(taskId: data[0]);

        // _videoPlayerController.setOverriddenAspectRatio(16/9);

        // _videoPlayerController.play();


        // _videoPlayerController = VlcController()

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
    //String fileName = "video1.mp4";
    FlutterDownloader.enqueue(
      url: testVideoUrl,
      savedDir: path,
      fileName: fileName,
      showNotification: false, // show download progress in status bar (for Android)

      // openFileFromNotification: true, // click on notification to open downloaded file (for Android)
    ).then((value) {
      print("enter file to queue");
      setState(() {
        taskId = value;
        filePath =  path + "/" +fileName;
        // print("videoPath $videosPath");
        print("filePath $filePath");
      });
      print("taskId ::  $taskId");
    }).onError((error, stackTrace) {
      print("error $error");
    });
  }


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    ScreenUtil.init(context);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          children: [
            const SizedBox(height: 20,),
            playerInitialized ?
            VisibilityDetector(
              key: const Key("video"),
              onVisibilityChanged: (visibilityFraction){
                if(visibilityFraction.visibleFraction > 0.5){
                  print("==================> ");
                  // _videoPlayerController.play();
                  print("resumeeeedddd");
                  // FlutterDownloader.resume(taskId: taskId!);
                }
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.width,
                width: MediaQuery.of(context).size.width * 16/9,
                child: Container(),
              ),
            ) :
            Container()
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

/*@override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    print("playerInitialized $playerInitialized");
    ScreenUtil.init(context);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          children: [
            const SizedBox(height: 20,),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width * 9/16,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: IgnorePointer(
                    ignoring: true,
                    child: playerInitialized  ? VlcPlayer(
                       controller: _videoPlayerController,
                      aspectRatio: 16 / 9,
                      virtualDisplay: false,
                      placeholder: const Center(
                          child: CircularProgressIndicator()),
                    ) :  Container(),
                  )),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }*/


  @override
  void dispose() async {
    _videoPlayerController.dispose();
    // await _videoViewController.dispose();
    // IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }
}


Future<String> downloadFile(String url, {required String fullPath}) async {
  var request = http.Request('GET', Uri.parse(url));
  var response = request.send();

  List<List<int>> chunks = List.empty(growable: true);
  int downloaded = 0;
  File file = File(fullPath);

  response.asStream().listen((http.StreamedResponse r) {
    //Utils.printf('Listen to http.StreamedResponse');
    r.stream.listen((List<int> chunk) {
      // Display percentage of completion
      //Utils.printf('downloadPercentage: ${downloaded / r.contentLength! * 100}');

      chunks.add(chunk);
      downloaded += chunk.length;

      final Uint8List bytes = Uint8List(r.contentLength!);
      int offset = 0;
      for (List<int> chunk in chunks) {
        bytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      file.writeAsBytes(bytes, mode: FileMode.write);
    }, onDone: () async {
      // // Display percentage of completion
      //Utils.printf('download Completed: ${downloaded / r.contentLength! * 100}');
      // // Save the file
      // File file = new File('$dir/$filename');
      // final Uint8List bytes = Uint8List(r.contentLength);
      // int offset = 0;
      // for (List<int> chunk in chunks) {
      //   bytes.setRange(offset, offset + chunk.length, chunk);
      //   offset += chunk.length;
      // }
      // await file.writeAsBytes(bytes);
      // return;
    });
  });

  return file.path;
}

