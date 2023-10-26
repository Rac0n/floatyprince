import 'dart:convert';
import 'dart:io';

import 'package:floatyprince/my_hud.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as my_ui;

import 'dart:developer';
import 'package:screenshot/screenshot.dart';

import 'dart:async';
import 'package:flutter/services.dart';

Map<String, dynamic> allAssets={};
bool assetsLoading = true;
Size gameSize = const Size(1280.0, 720.0);
int currentFra=0;

int currentTime=0;
int pausedTime=0;

late StreamController<String> streamController;
late Stream stream;

bool music=true;
bool sound=true;

String currentStage="play";

late dynamic results;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  
  streamController = StreamController<String>();
  stream = streamController.stream.asBroadcastStream();
  
  assetsLoading = true;
  loadAssets();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floaty Prince',
      theme: ThemeData(
        primarySwatch:Colors.teal,
        fontFamily: "Gamlangdee"
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin,WidgetsBindingObserver {
  late Animation<double> animation;
  late AnimationController controller;
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
          if(currentStage=="play"){
          pausedTime=pausedTime+(Timeline.now-currentTime)~/1000;
          currentStage="pause";
          streamController.add("PAUSEGAME");
          }
    }
    else {

    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    stream.listen((event) {
      if (event == "LOADED") {
        assetsLoading = false;
        setState(() {
          
        });
      }
      else
      if(event=="TAKESCREENSHOT" && assetsLoading==false){
        try{
        screenshotController.capture().then((Uint8List? image) async {
          if(image!=null){
            String first=results["frames"].keys.elementAt(currentFra);
            final myImagePath = "imgs/$first.png";
            File imageFile = File(myImagePath);
            if(! await imageFile.exists()){   imageFile.create(recursive: true); }
            imageFile.writeAsBytes(image);

            if(currentFra<results["frames"].keys.length-1){
              currentFra+=1;
            }
            else {
              currentFra=0;
            }

            setState(() {
              
            });
          }
          else {
            throw Exception("IMAGE WAS NULL");
          }
        });
        }
        catch (onError){
          throw Exception("THERE WAS AN ERROR: $onError");
        }
      }
    });

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );

    Tween<double> animationTween = Tween(begin: 0, end: 1.0);

    animation = animationTween.animate(controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.repeat();
        } else if (status == AnimationStatus.dismissed) {
          controller.forward();
        }
      });

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(color: Colors.amber.shade300, width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height,),
        assetsLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white,))
            : SingleChildScrollView(
              child: Center(
                                        child: AspectRatio(
                                            aspectRatio: gameSize.width /
                                                gameSize.height,
                                            child: Transform.scale(
                                                alignment: Alignment.topLeft,
                                                scale: MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            gameSize.width <
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height /
                                                            gameSize.height
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        gameSize.width
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .height /
                                                        gameSize.height,
                                                child: SizedBox(
                                                    width: gameSize.width,
                                                    height: gameSize.height,
                                                    child: Screenshot(
                                                    controller: screenshotController,
                                                    child: AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return CustomPaint(
                                                      painter: MyPaintOne(
                                                          animation.value),
                                                      child: Container(),
                                                    );}))))))
                            
                        /*))))*/),
        MyHUD(context.widget.key),
      ]),
    );
  }
}

Future<dynamic> fetchJson(String jsonPath) async {
  final String response = await rootBundle.loadString(jsonPath);
  dynamic data = json.decode(response);

  return data;
}

Future<void> loadAssets() async {
  allAssets["Alls"] = await loadImage("assets/alls.png");
  results = await fetchJson("assets/alls.json");
  String first=results["frames"].keys.elementAt(0);

  gameSize=Size(results["frames"][first]["sourceSize"]["w"].toDouble(),
  results["frames"][first]["sourceSize"]["h"].toDouble());

  print(gameSize);
  streamController.add("LOADED");
  return;
}

Future<my_ui.Image> loadImage(String imagepath) async {
  var img = ExactAssetImage(imagepath);
  AssetBundleImageKey key = await img.obtainKey(const ImageConfiguration());
  final ByteData data = await key.bundle.load(key.name).catchError( (e){
    throw 'Unable to read data';
  });
  var codec = await my_ui.instantiateImageCodec(data.buffer.asUint8List());
  var frame = await codec.getNextFrame();
  return frame.image;
}

class MyPaintOne extends CustomPainter {
  bool once=false;
  MyPaintOne(this.minut){
    _paint.color=Colors.amber.shade300;
  }

  final double minut;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if(once==false){
    canvas.clipRect(const Rect.fromLTWH(0, 0, 1280.0, 720.0));
    once=true;
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1280.0, 720.0), _paint);
    }

    if (assetsLoading == false) {
      String first=results["frames"].keys.elementAt(currentFra);
      
      canvas.drawImageRect (allAssets["Alls"],
      Rect.fromLTWH(results["frames"][first]["frame"]["x"].toDouble(),
      results["frames"][first]["frame"]["y"].toDouble(),
      results["frames"][first]["frame"]["w"].toDouble(),
      results["frames"][first]["frame"]["h"].toDouble()),
      Rect.fromLTWH(results["frames"][first]["spriteSourceSize"]["x"].toDouble(),
      results["frames"][first]["spriteSourceSize"]["y"].toDouble(),
      results["frames"][first]["spriteSourceSize"]["w"].toDouble(),
      results["frames"][first]["spriteSourceSize"]["h"].toDouble()), _paint);
      stage.checkChildren(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}