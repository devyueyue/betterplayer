import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NormalPlayerPage extends StatefulWidget {
  @override
  _NormalPlayerPageState createState() => _NormalPlayerPageState();
}

class _NormalPlayerPageState extends State<NormalPlayerPage> {
  late BetterPlayerController _betterPlayerController;
  late BetterPlayerDataSource _betterPlayerDataSource;
  late BetterPlayerDataSource dataSource;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        const BetterPlayerConfiguration(
            aspectRatio: 16 / 9,
            fit: BoxFit.contain,
            fullScreenByDefault: false,
            autoPlay: true,
            deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown
        ]);
    BetterPlayerControlsConfiguration betterPlayerControlsConfiguration =
        BetterPlayerControlsConfiguration(
            enableSkips: false,
            controlBarColor: Colors.transparent,
            enableOverflowMenu: false,
            enableMute: false,
            progressBarBackgroundColor: Colors.white.withOpacity(0.18),
            progressBarBufferedColor: Colors.white.withOpacity(0.18),
            progressBarHandleColor: Colors.white.withOpacity(0.99),
            progressBarPlayedColor: Color(0xff3470DD));

    _betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      // Constants.elephantDreamVideoUrl,
      // Constants.exampleResolutionsUrls['LOW']!,
      // Constants.elephantDreamStreamUrl,
      'https://v.botaoyouxue.com/050dc5db8f0549f992b337117c5ce205/video/5c7e7dad5a384306aa1b6db274ea6896-b8bf685e4b7b331e6483a3d3f6aa52a8-video-ld-encrypt-stream.m3u8?auth_key=1646100130-04b0947ceb734279b75cf68c81eab4e2-0-4187cfdc290056bf6a442554f3ad88b2&MtsHlsUriToken=1646103729_00_f40874c3acdf9aadbd2d',
      liveStream: false,
      useAsmsSubtitles: true,
      resolutions: {
        "标清":
            'https://v.botaoyouxue.com/050dc5db8f0549f992b337117c5ce205/video/5c7e7dad5a384306aa1b6db274ea6896-b8bf685e4b7b331e6483a3d3f6aa52a8-video-ld-encrypt-stream.m3u8?auth_key=1646100130-04b0947ceb734279b75cf68c81eab4e2-0-4187cfdc290056bf6a442554f3ad88b2&MtsHlsUriToken=1646103729_00_f40874c3acdf9aadbd2d',
        "高清":
            'https://v.botaoyouxue.com/050dc5db8f0549f992b337117c5ce205/video/5c7e7dad5a384306aa1b6db274ea6896-6f435e42b8c5191b63ec3c0c9b8c004d-video-sd-encrypt-stream.m3u8?auth_key=1646100130-c949a1e2b8f8410da46c67e79e7f9bf5-0-bae3a6b5ce6672b733d25674e052d61f&MtsHlsUriToken=1646103729_00_f40874c3acdf9aadbd2d',
        "超清":
            'https://v.zhijisx.net/1d720c2412ad4b308cdaaf8ee5582443/video/f6d32dedf18046dda9dfc2ed8bfae747-ac001f3a81aa49068b6fee3c8bc0c655-video-hd-encrypt-stream.m3u8?auth_key=1642595465-7f0bfa66312845fa9f3645d590dcd531-0-a28c489c4c938d8789198befa5973c7d&MtsHlsUriToken=1642599065_00_241247ff484f71a8a4d4'
      },
      subtitles: [
        BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.network,
          name: "英文",
          urls: [
            "https://v0.zhijisx.net/subtitle/8AC1C88F2ED34E37B03084CD1DA7978F-3-3.vtt"
          ],
        ),
        BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.network,
          name: "中文",
          urls: [
            "https://v0.zhijisx.net/subtitle/F4625FAAAD39446888317D2443200766-3-3.vtt"
          ],
        ),
      ],
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(_betterPlayerDataSource);
    _betterPlayerController.setBetterPlayerControlsConfiguration(
        betterPlayerControlsConfiguration);
    _betterPlayerController.addEventsListener((data) {
      // print(
      //     '--------hhhy---listener==${data}-----path==${_betterPlayerController.screenImagePath}');
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _betterPlayerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Normal player page"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Memory player with plays video from bytes list. In this example"
              "file bytes are read to list and then used in player.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
          GestureDetector(
            onTap: () async {
              // String path = await NativeScreenshot.takeScreenshot() ?? '';
              // print('-----hhyyy-截图成功---${path}');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Memory player with plays video from bytes list. In this example"
                "file bytes are read to list and then used in player.",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
