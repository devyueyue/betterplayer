import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_screenshot/native_screenshot.dart';

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
      Constants.elephantDreamVideoUrl,
      liveStream: false,
      useAsmsSubtitles: true,
      // resolutions: {
      //   "标清":
      //       'https://v.zhijisx.net/1d720c2412ad4b308cdaaf8ee5582443/video/f6d32dedf18046dda9dfc2ed8bfae747-4092e3279e37623b6a9903b86b1452f6-video-ld-encrypt-stream.m3u8?auth_key=1642595465-15bd7de5854249b2b028c34184a24f0d-0-92658a36e49c43649ca245a5addd4754&MtsHlsUriToken=1642599065_00_241247ff484f71a8a4d4',
      //   "高清":
      //       'https://v.zhijisx.net/1d720c2412ad4b308cdaaf8ee5582443/video/f6d32dedf18046dda9dfc2ed8bfae747-2a9d8275702d9194878b7a4bf1dbfad6-video-sd-encrypt-stream.m3u8?auth_key=1642595465-9493b9e7dfb347e18533d7900c7c98ba-0-25c4830d15529c7f75b7fdbad89603f3&MtsHlsUriToken=1642599065_00_241247ff484f71a8a4d4',
      //   "超清":
      //       'https://v.zhijisx.net/1d720c2412ad4b308cdaaf8ee5582443/video/f6d32dedf18046dda9dfc2ed8bfae747-ac001f3a81aa49068b6fee3c8bc0c655-video-hd-encrypt-stream.m3u8?auth_key=1642595465-7f0bfa66312845fa9f3645d590dcd531-0-a28c489c4c938d8789198befa5973c7d&MtsHlsUriToken=1642599065_00_241247ff484f71a8a4d4'
      // },
      // subtitles: [
      //   BetterPlayerSubtitlesSource(
      //     type: BetterPlayerSubtitlesSourceType.network,
      //     name: "英文",
      //     urls: [
      //       "https://v0.zhijisx.net/subtitle/8AC1C88F2ED34E37B03084CD1DA7978F-3-3.vtt"
      //     ],
      //   ),
      //   BetterPlayerSubtitlesSource(
      //     type: BetterPlayerSubtitlesSourceType.network,
      //     name: "中文",
      //     urls: [
      //       "https://v0.zhijisx.net/subtitle/F4625FAAAD39446888317D2443200766-3-3.vtt"
      //     ],
      //   ),
      // ],
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(_betterPlayerDataSource);
    _betterPlayerController.setBetterPlayerControlsConfiguration(
        betterPlayerControlsConfiguration);
    super.initState();
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
              String path = await NativeScreenshot.takeScreenshot() ?? '';
              print('-----hhyyy-截图成功---${path}');
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
