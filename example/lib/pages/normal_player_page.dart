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
            deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown
        ]);
    BetterPlayerControlsConfiguration betterPlayerControlsConfiguration =
        const BetterPlayerControlsConfiguration(
      enableSkips: false,
      controlBarColor: Colors.transparent,
    );
    _betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        // Constants.forBiggerBlazesUrl,   设置Url hhy
        "https://v.zhijisx.net/1d720c2412ad4b308cdaaf8ee5582443/video/f6d32dedf18046dda9dfc2ed8bfae747-4092e3279e37623b6a9903b86b1452f6-video-ld-encrypt-stream.m3u8?auth_key=1642576029-7c3b1e2622394d95bb88fc59e9acf3cc-0-2d2bcb99b36d8518d76d88bc46584ec8&MtsHlsUriToken=1642579629_00_246c4622e72bbae70c37");

    dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      "https://v.zhijisx.net/1d720c2412ad4b308cdaaf8ee5582443/video/f6d32dedf18046dda9dfc2ed8bfae747-4092e3279e37623b6a9903b86b1452f6-video-ld-encrypt-stream.m3u8?auth_key=1642574714-10fdae40dec94b1fa16d88e3c098c005-0-287d5ef85bd1589a3bbcd7f7e7ec12c2&MtsHlsUriToken=1642578314_00_bff1a80f9f8f857aeced",
      liveStream: false,
      useAsmsSubtitles: true,
      // resolutions: {
      //   "MEDIUM":
      //       "https://v.zhijisx.net/1d720c2412ad4b308cdaaf8ee5582443/video/f6d32dedf18046dda9dfc2ed8bfae747-4092e3279e37623b6a9903b86b1452f6-video-ld-encrypt-stream.m3u8?auth_key=1642574714-10fdae40dec94b1fa16d88e3c098c005-0-287d5ef85bd1589a3bbcd7f7e7ec12c2&MtsHlsUriToken=1642578314_00_bff1a80f9f8f857aeced",
      //   "LARGE":
      //       "https://v.zhijisx.net/1d720c2412ad4b308cdaaf8ee5582443/video/f6d32dedf18046dda9dfc2ed8bfae747-4092e3279e37623b6a9903b86b1452f6-video-ld-encrypt-stream.m3u8?auth_key=1642574714-10fdae40dec94b1fa16d88e3c098c005-0-287d5ef85bd1589a3bbcd7f7e7ec12c2&MtsHlsUriToken=1642578314_00_bff1a80f9f8f857aeced",
      //   "EXTRA_LARGE":
      //       "https://v.zhijisx.net/1d720c2412ad4b308cdaaf8ee5582443/video/f6d32dedf18046dda9dfc2ed8bfae747-4092e3279e37623b6a9903b86b1452f6-video-ld-encrypt-stream.m3u8?auth_key=1642574714-10fdae40dec94b1fa16d88e3c098c005-0-287d5ef85bd1589a3bbcd7f7e7ec12c2&MtsHlsUriToken=1642578314_00_bff1a80f9f8f857aeced",
      // },
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
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
        ],
      ),
    );
  }
}
