import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:better_player/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_cupertino_progress_bar.dart';
import 'package:better_player/src/controls/better_player_multiple_gesture_detector.dart';
import 'package:better_player/src/controls/better_player_progress_colors.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_source.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_source_type.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_screenshot/flutter_native_screenshot.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:native_screenshot/native_screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

class BetterPlayerCupertinoControls extends StatefulWidget {
  ///Callback used to send information if player bar is hidden or not
  final Function(bool visbility) onControlsVisibilityChanged;

  ///Controls config
  final BetterPlayerControlsConfiguration controlsConfiguration;

  const BetterPlayerCupertinoControls({
    required this.onControlsVisibilityChanged,
    required this.controlsConfiguration,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BetterPlayerCupertinoControlsState();
  }
}

class _BetterPlayerCupertinoControlsState
    extends BetterPlayerControlsState<BetterPlayerCupertinoControls> {
  final marginSize = 5.0;
  VideoPlayerValue? _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _expandCollapseTimer;
  Timer? _initTimer;
  bool _wasLoading = false;

  VideoPlayerController? _controller;
  BetterPlayerController? _betterPlayerController;
  StreamSubscription? _controlsVisibilityStreamSubscription;

  BetterPlayerControlsConfiguration get _controlsConfiguration =>
      widget.controlsConfiguration;

  @override
  VideoPlayerValue? get latestValue => _latestValue;

  @override
  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  @override
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _controlsConfiguration;
  var _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, String>> dataList = [];

  List<Map<String, String>> fontList = [];

  List<Map<String, String>> speedList = [
    {'title': '1.25X', 'is_select': 'false', 'type': 'speed'},
    {'title': '1.0X', 'is_select': 'true', 'type': 'speed'},
    {'title': '0.75X', 'is_select': 'false', 'type': 'speed'},
  ];

  List<Map<String, String>> qualityList = [];

  String qualityValue = '标清';

  late List<BetterPlayerSubtitlesSource> subtitleList;

  late Map<String, String> resolutionMap;

  final courseButtonController = StreamController<bool>();
  Stream<bool> get courseStream => courseButtonController.stream;

  ///  todo  流暂时不关闭
  final screenImageController = StreamController<String?>();
  Stream<String?> get screenImageStream => screenImageController.stream;

  ///收藏流
  final saveController = StreamController<bool?>();
  Stream<bool?> get saveStream => saveController.stream;
  int fontSelectIndex = -1;

  ///  设置字幕
  // betterPlayerController!.setupSubtitleSource(subtitlesSource);

  /// 设置分辨率
  // betterPlayerController!.setResolution(url);

  final String CHANGE_BRIGHTNESS = 'change_brightness';
  final String CHANGE_VOLUME = 'change_volume';

  /// 手势拖动播放进度
  bool _controllerWasPlaying = false;
  bool shouldPlayAfterDragEnd = false;
  Duration? lastSeek;
  Timer? _updateBlockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      Future.delayed(Duration(milliseconds: 100), () {
        setResolutionConfig(isInit: true);
      });
      setFontConfig(isInit: true);
    });
  }

  void setResolutionConfig({bool isInit = false}) {
    resolutionMap =
        betterPlayerController!.betterPlayerDataSource!.resolutions ?? {};
    if (resolutionMap.isEmpty) {
      return;
    }
    if (qualityList.isEmpty) {
      resolutionMap.forEach((key, value) {
        bool isSelect =
            (betterPlayerController!.betterPlayerDataSource?.url ?? '') ==
                value;
        if (isSelect) {
          qualityValue = key;
        }
        qualityList.add({
          'title': key,
          'is_select': isSelect ? 'true' : 'false',
          'type': 'quality',
          'url': value
        });
      });
    }
    dataList = qualityList;
    if (!isInit) {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  void setFontConfig({bool isInit = false}) {
    ///字幕点击事件
    subtitleList = betterPlayerController!.betterPlayerSubtitlesSourceList;
    if (subtitleList.isEmpty || subtitleList.length == 1) {
      return;
    }
    if (fontList.isEmpty) {
      for (int i = 0; i < subtitleList.length; i++) {
        BetterPlayerSubtitlesSource betterItem = subtitleList[i];
        fontList.add({
          'title':
              (i == subtitleList.length - 1) ? '关闭字幕' : betterItem.name ?? '',
          'is_select': (i == subtitleList.length - 1) ? 'true' : 'false',
          'type': 'font'
        });
      }
    }
    dataList = fontList;
    if (!isInit) {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: handleHorizontalDragStart,
      onHorizontalDragUpdate: handleHorizontalDragUpdate,
      onHorizontalDragEnd: handleHorizontalDragEnd,
      child: Scaffold(
          appBar: null,
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          drawer: _betterPlayerController!.isFullScreen ? _buildDrawer() : null,
          body: StreamBuilder<bool?>(
              stream: saveStream,
              builder: (context, snapshot) {
                bool isSave =
                    snapshot.data ?? _betterPlayerController!.chapterIsSave;
                return Stack(
                  children: [
                    buildLTRDirectionality(_buildMainWidget(isSave)),
                    StreamBuilder<String?>(
                        stream: screenImageStream,
                        builder: (context, snapshot) {
                          String imageUrl = snapshot.data ?? '';
                          return imageUrl.isEmpty
                              ? SizedBox()
                              : imageUrl == CHANGE_BRIGHTNESS
                                  ? Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(3)),
                                        width: 174,
                                        height: 32,
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10),
                                              child: Icon(
                                                Icons.wb_sunny_rounded,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                            Expanded(
                                              child: LinearProgressIndicator(
                                                value: _setBrightnessValue(),
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Color(0xff3470DD)),
                                                minHeight: 3,
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.4),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 12,
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.black87,
                                      height: double.infinity,
                                      width: double.infinity,
                                      padding:
                                          EdgeInsets.fromLTRB(190, 30, 180, 40),
                                      child: Column(
                                        children: [
                                          Expanded(
                                              child: Stack(
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.fromLTRB(
                                                    0, 10, 10, 0),
                                                child:
                                                    Image.file(File(imageUrl)),
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () {
                                                    if (!(_betterPlayerController!
                                                            .isPlaying() ??
                                                        false)) {
                                                      _onPlayPause();
                                                    }
                                                    _betterPlayerController!
                                                        .screenImagePath = '';
                                                    screenImageController.sink
                                                        .add('');
                                                  },
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    180)),
                                                        color: Colors.black
                                                            .withOpacity(0.3)),
                                                    child: Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          )),
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              _onExpandCollapse();
                                            },
                                            child: Container(
                                              height: 38,
                                              width: 127,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(90)),
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                              ),
                                              child: Text(
                                                '截图写笔记',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                        })
                  ],
                );
              })),
    );
  }

  /// 设置按钮样式
  Widget _buildTextStytle(
      {required int index,
      required String value,
      required String isSelect,
      required String type,
      required String url}) {
    return InkWell(
      onTap: () {
        dataList.forEach((element) {
          element['is_select'] = 'false';
        });
        dataList[index]['is_select'] = 'true';
        switch (type) {

          ///  字幕设置
          case 'font':
            fontList = dataList;
            fontSelectIndex = index;
            if (index > subtitleList.length) {
              betterPlayerController!.setupSubtitleSource(
                  BetterPlayerSubtitlesSource(
                      type: BetterPlayerSubtitlesSourceType.none));
            } else {
              betterPlayerController!.setupSubtitleSource(subtitleList[index]);
            }

            break;

          ///  倍速设置
          case 'speed':
            speedList = dataList;
            double speedValue = 1.0;
            try {
              String subString = value.replaceAll('X', '');

              speedValue = double.parse(subString);
            } catch (e) {
              print('--log----倍速这只异常=e=${e}');
            }
            betterPlayerController!.setSpeed(speedValue);
            break;

          /// 分辨率设置
          case 'quality':
            qualityList = dataList;
            qualityValue = value;
            betterPlayerController!.setResolution(url);
            Future.delayed(Duration(milliseconds: 5000), () {
              if (fontSelectIndex != -1) {
                betterPlayerController!
                    .setupSubtitleSource(subtitleList[fontSelectIndex]);
              }
            });

            print('-------选择的分辨率---${qualityValue}-----url=${url}');
            break;
          default:
            break;
        }
        setState(() {});
      },
      child: Container(
        width: 152,
        height: 45,
        alignment: Alignment.center,
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            border: Border.all(
              color:
                  isSelect == 'true' ? Color(0xff3470DD) : Colors.transparent,
            ),
            color: isSelect == 'true'
                ? Color(0xff9EC1FF).withOpacity(0.1)
                : Colors.white.withOpacity(0.2)),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isSelect == 'true' ? Color(0xff3470DD) : Colors.white),
        ),
      ),
    );
  }

  ///  全屏显示侧滑栏，  TODO  需要改为右侧弹出
  Widget _buildDrawer() {
    return SizedBox(
      width: 250,
      child: Drawer(
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.black54, Colors.black12],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: dataList
                  .asMap()
                  .keys
                  .map(
                    (i) => _buildTextStytle(
                        index: i,
                        value: dataList[i]['title']!,
                        isSelect: dataList[i]['is_select']!,
                        type: dataList[i]['type']!,
                        url: dataList[i]['url'] ?? ''),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  ///Builds main widget of the controls.
  Widget _buildMainWidget(bool isCollectSave) {
    _betterPlayerController = BetterPlayerController.of(context);

    if (_latestValue?.hasError == true) {
      return Container(
        color: Colors.black,
        child: _buildErrorWidget(),
      );
    }

    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController!.videoPlayerController;
    final backgroundColor = _controlsConfiguration.controlBarColor;
    final iconColor = _controlsConfiguration.iconsColor;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait
        ? _controlsConfiguration.controlBarHeight
        : _controlsConfiguration.controlBarHeight + 10;
    const buttonPadding = 10.0;
    final isFullScreen = _betterPlayerController?.isFullScreen == true;

    _wasLoading = isLoading(_latestValue);
    final controlsColumn = Column(children: <Widget>[
      _buildTopBar(
        backgroundColor,
        iconColor,
        barHeight,
        buttonPadding,
      ),
      if (_wasLoading)
        Expanded(child: Center(child: _buildLoadingWidget()))
      else
        _buildHitArea(isCollectSave),
      _buildNextVideoWidget(),
      _buildBottomBar(
        backgroundColor,
        iconColor,
        barHeight,
      ),
    ]);
    return GestureDetector(
      onTap: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onTap?.call();
        }
        controlsNotVisible
            ? cancelAndRestartTimer()
            : changePlayerControlsNotVisible(true);
      },
      onDoubleTap: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onDoubleTap?.call();
        }
        cancelAndRestartTimer();
        _onPlayPause();
      },
      onLongPress: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onLongPress?.call();
        }
      },
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onHorizontalDragStart: handleHorizontalDragStart,
      onHorizontalDragUpdate: handleHorizontalDragUpdate,
      onHorizontalDragEnd: handleHorizontalDragEnd,
      child:
          AbsorbPointer(absorbing: controlsNotVisible, child: controlsColumn),
    );
  }

  /// 拖动开始
  void handleHorizontalDragStart(DragStartDetails playerValue) async {
    final bool enableProgressBarDrag = betterPlayerController!
        .betterPlayerControlsConfiguration.enableProgressBarDrag;
    if (!_controller!.value.initialized || !enableProgressBarDrag) {
      return;
    }
    changePlayerControlsNotVisible(false);
    _controllerWasPlaying = _controller!.value.isPlaying;
    if (_controllerWasPlaying) {
      _controller!.pause();
    }

    _hideTimer?.cancel();
  }

  /// 更新拖动
  void handleHorizontalDragUpdate(DragUpdateDetails details) async {
    final bool enableProgressBarDrag = betterPlayerController!
        .betterPlayerControlsConfiguration.enableProgressBarDrag;
    if (!_controller!.value.initialized || !enableProgressBarDrag) {
      return;
    }
    int newTime =
        (details.delta.dx).toInt() + _controller!.value.position.inSeconds;
    if (newTime > _controller!.value.duration!.inSeconds) {
      newTime = _controller!.value.duration!.inSeconds;
    } else if (newTime < 0) {
      newTime = 0;
    }
    await betterPlayerController!.seekTo(Duration(seconds: newTime));
    onFinishedLastSeek();
  }

  void onFinishedLastSeek() {
    if (shouldPlayAfterDragEnd) {
      shouldPlayAfterDragEnd = false;
      betterPlayerController?.play();
    }
  }

  /// 拖动结束
  void handleHorizontalDragEnd(DragEndDetails playerValue) async {
    final bool enableProgressBarDrag = betterPlayerController!
        .betterPlayerControlsConfiguration.enableProgressBarDrag;
    if (!enableProgressBarDrag) {
      return;
    }
    if (_controllerWasPlaying) {
      betterPlayerController?.play();
      shouldPlayAfterDragEnd = true;
    }
    _setupUpdateBlockTimer();

    _startHideTimer();
  }

  void _setupUpdateBlockTimer() {
    _updateBlockTimer = Timer(const Duration(milliseconds: 1000), () {
      lastSeek = null;
      _cancelUpdateBlockTimer();
    });
  }

  void _cancelUpdateBlockTimer() {
    _updateBlockTimer?.cancel();
    _updateBlockTimer = null;
  }

  String verticalDragArea = 'left';
  Offset startPosition = Offset(0, 0); // 起始位置
  double movePan = 0; // 偏移量累计总和
  double layoutWidth = 0; // 组件宽度
  double layoutHeight = 0; // 组件高度
  double brightness = 0.0; //亮度
  double volumeness = 0.0; //音量

  void _onVerticalDragStart(DragStartDetails details) async {
    if (_betterPlayerController!.isFullScreen) {
      if (details.localPosition.dx <= MediaQuery.of(context).size.width / 2) {
        verticalDragArea = 'left';
      } else {
        verticalDragArea = 'right';
      }
      print(
          '垂直拖动开始 =====${details.localPosition}----value=${verticalDragArea}');
      _reset(context);
      startPosition = details.globalPosition;

      if (startPosition.dx < (layoutWidth / 2)) {
        /// 左边触摸
        brightness = await ScreenBrightness().current;
      } else {
        ///右边触摸
        volumeness = await VolumeController().getVolume();
      }
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (_betterPlayerController!.isFullScreen) {
      /// 累计计算偏移量(下滑减少百分比，上滑增加百分比)
      movePan += (-details.delta.dy);

      if (startPosition.dx < (layoutWidth / 2)) {
        /// 左边触摸
        await ScreenBrightness().setScreenBrightness(_setBrightnessValue());
        screenImageController.sink.add(CHANGE_BRIGHTNESS);
        setState(() {
          print('---------亮度：${(_setBrightnessValue() * 100).toInt()}%');
        });
      } else {
        /// 右边触摸
        VolumeController().setVolume(_setVolumeValue());
      }
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) async {
    if (_betterPlayerController!.isFullScreen) {
      if (startPosition.dx < (layoutWidth / 2)) {
        await ScreenBrightness().setScreenBrightness(_setBrightnessValue());
        screenImageController.sink.add('');
        // 左边触摸
        setState(() {});
      }
    }
  }

  /// 调节亮度
  double _setBrightnessValue() {
    // 亮度百分控制
    double value = double.parse(
        ((movePan * 1.4) / layoutHeight + brightness).toStringAsFixed(2));
    if (value >= 1.00) {
      value = 1.00;
    } else if (value <= 0.00) {
      value = 0.00;
    }
    return value;
  }

  /// 调节声音
  double _setVolumeValue({int num = 1}) {
    // 声音亮度百分控制
    double value = double.parse(
        ((movePan * 1.4) / layoutHeight + volumeness).toStringAsFixed(num));
    if (value >= 1.0) {
      value = 1.0;
    } else if (value <= 0.0) {
      value = 0.0;
    }
    return value;
  }

  void _reset(BuildContext context) async {
    startPosition = Offset(0, 0);
    movePan = 0;
    layoutHeight = context.size?.height ?? 0;
    layoutWidth = context.size?.width ?? 0;
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _controller!.removeListener(_updateState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
    _controlsVisibilityStreamSubscription?.cancel();
    courseButtonController.close();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController!.videoPlayerController;

    if (_oldController != _betterPlayerController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildBottomBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
  ) {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }
    final barHeightValue = barHeight * 0.8;
    final iconSize = barHeight * 0.4;
    return AnimatedOpacity(
      opacity: controlsNotVisible ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: Container(
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.only(top: 10),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Color(0xff000000).withOpacity(0.6),
            Color(0xff000000).withOpacity(0)
          ], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
          child: _betterPlayerController!.isLiveStream()
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const SizedBox(width: 8),
                    if (_controlsConfiguration.enablePlayPause)
                      _buildPlayPause(_controller!, iconColor, barHeight)
                    else
                      const SizedBox(),
                    const SizedBox(width: 8),
                    _buildLiveWidget(),
                  ],
                )
              : Padding(
                  padding: EdgeInsets.fromLTRB(
                      _betterPlayerController!.isFullScreen
                          ? Platform.isAndroid
                              ? 70
                              : 90
                          : 0,
                      0,
                      _betterPlayerController!.isFullScreen
                          ? Platform.isAndroid
                              ? 66
                              : 86
                          : 0,
                      _betterPlayerController!.isFullScreen
                          ? marginSize + 18
                          : 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            if (_controlsConfiguration.enableSkips)
                              _buildSkipBack(iconColor, barHeight)
                            else
                              const SizedBox(),
                            if (_controlsConfiguration.enablePlayPause &&
                                !_betterPlayerController!.isFullScreen)
                              _buildPlayPause(
                                  _controller!, iconColor, barHeight)
                            else
                              const SizedBox(),
                            if (_controlsConfiguration.enableSkips)
                              _buildSkipForward(iconColor, barHeight)
                            else
                              const SizedBox(),
                            if (_controlsConfiguration.enableProgressText)
                              _buildPosition()
                            else
                              const SizedBox(),
                            if (_controlsConfiguration.enableProgressBar)
                              _buildProgressBar()
                            else
                              const SizedBox(),
                            if (_controlsConfiguration.enableProgressText)
                              _buildRemaining()
                            else
                              const SizedBox(),
                            if (!(_betterPlayerController?.isFullScreen ??
                                false))
                              _buildExpandButton(
                                backgroundColor,
                                iconColor,
                                barHeightValue,
                                iconSize,
                                10,
                              )
                            else
                              const SizedBox(),
                          ],
                        ),
                      ),
                      (_controlsConfiguration.enablePlayPause &&
                              _betterPlayerController!.isFullScreen)
                          ? Container(
                              height: 20,
                              child: Row(
                                children: [
                                  if (_controlsConfiguration.enablePlayPause &&
                                      _betterPlayerController!.isFullScreen)
                                    _buildPlayPause(
                                        _controller!, iconColor, barHeight),
                                  Expanded(child: SizedBox()),
                                  betterPlayerController!
                                              .betterPlayerSubtitlesSourceList
                                              .length <
                                          2
                                      ? SizedBox()
                                      : InkWell(
                                          onTap: () {
                                            setFontConfig();
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Text(
                                              '字幕',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ),
                                  (betterPlayerController!
                                                  .betterPlayerDataSource!
                                                  .resolutions ??
                                              {})
                                          .isEmpty
                                      ? SizedBox()
                                      : InkWell(
                                          onTap: () {
                                            setResolutionConfig();
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Text(
                                              qualityValue,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ),
                                  InkWell(
                                    onTap: () {
                                      /// 倍速点击事件
                                      dataList = speedList;
                                      setState(() {});
                                      _scaffoldKey.currentState?.openDrawer();
                                    },
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        '倍速',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  // InkWell(
                                  //   onTap: () {},
                                  //   child: Padding(
                                  //     padding:
                                  //         EdgeInsets.symmetric(horizontal: 12),
                                  //     child: Text(
                                  //       '目录',
                                  //       style: TextStyle(
                                  //           color: Colors.red, fontSize: 13),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ))
                          : SizedBox()
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLiveWidget() {
    return Expanded(
      child: Text(
        _betterPlayerController!.translations.controlsLive,
        style: TextStyle(
            color: _controlsConfiguration.liveTextColor,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  GestureDetector _buildExpandButton(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double iconSize,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: controlsNotVisible ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: barHeight,
            margin: EdgeInsets.only(
                left: _betterPlayerController!.isFullScreen
                    ? Platform.isAndroid
                        ? 66
                        : 86
                    : 0),
            padding: EdgeInsets.symmetric(
              horizontal: buttonPadding,
            ),
            decoration: BoxDecoration(color: backgroundColor),
            child: Center(
              child: Icon(
                _betterPlayerController!.isFullScreen
                    ? Icons.arrow_back_ios
                    : _controlsConfiguration.fullscreenEnableIcon,
                color: iconColor,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea(bool isCollectSave) {
    return Expanded(
      child: GestureDetector(
        onTap: _latestValue != null && _latestValue!.isPlaying
            ? () {
                if (controlsNotVisible == true) {
                  cancelAndRestartTimer();
                } else {
                  _hideTimer?.cancel();
                  changePlayerControlsNotVisible(true);
                }
              }
            : () {
                _hideTimer?.cancel();
                changePlayerControlsNotVisible(false);
              },
        child: Container(
          color: Colors.transparent,
          child: _betterPlayerController!.isFullScreen
              ? AnimatedOpacity(
                  opacity: controlsNotVisible ? 0.0 : 1.0,
                  duration: _controlsConfiguration.controlsHideTime,
                  onEnd: _onPlayerHide,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                PermissionStatus permission =
                                    await Permission.storage.request();
                                if (permission.isGranted) {
                                  if (Platform.isIOS) {
                                    String path = await _betterPlayerController!
                                            .videoPlayerController
                                            ?.takeScreenshot(
                                                _betterPlayerController!
                                                    .videoPlayerController!
                                                    .textureId) ??
                                        '';
                                    if (path.isNotEmpty &&
                                        (_betterPlayerController!.isPlaying() ??
                                            false)) {
                                      _onPlayPause();
                                    }
                                    _betterPlayerController!.screenImagePath =
                                        path;
                                    screenImageController.sink.add(path);
                                    print(
                                        '-----player---点击了截图===value==${path}');
                                  } else {
                                    _hideTimer?.cancel();
                                    changePlayerControlsNotVisible(true);
                                    Future.delayed(Duration(milliseconds: 400),
                                        () async {
                                      String path =
                                          await FlutterNativeScreenshot
                                                  .takeScreenshot() ??
                                              '';
                                      if (path.isNotEmpty &&
                                          (_betterPlayerController!
                                                  .isPlaying() ??
                                              false)) {
                                        _onPlayPause();
                                      }
                                      _betterPlayerController!.screenImagePath =
                                          path;
                                      screenImageController.sink.add(path);
                                      print(
                                          '-----player---点击了截图--path==${path}');
                                    });
                                  }
                                } else {
                                  Fluttertoast.showToast(msg: '请在设置中允许保存到相册');
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                  colors: [
                                    Color(0xff000000).withOpacity(0.1),
                                    Color(0xff000000).withOpacity(0)
                                  ],
                                )),
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (!_betterPlayerController!.saveBtnCanClick) {
                                  return;
                                }
                                _betterPlayerController!.saveBtnCanClick =
                                    false;
                                if (_betterPlayerController!.onCollect !=
                                    null) {
                                  _betterPlayerController!.onCollect!();
                                }
                                saveController.sink.add(!isCollectSave);
                                _betterPlayerController!.chapterIsSave =
                                    !isCollectSave;
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                  colors: [
                                    Color(0xff000000).withOpacity(0.1),
                                    Color(0xff000000).withOpacity(0)
                                  ],
                                )),
                                child: Icon(
                                  Icons.star_border,
                                  size: 22,
                                  color: isCollectSave
                                      ? Color(0xffFFB600)
                                      : Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        width: _betterPlayerController!.isFullScreen
                            ? Platform.isAndroid
                                ? 70
                                : 90
                            : 0,
                      )
                    ],
                  ),
                )
              : SizedBox(),
        ),
      ),
    );
  }

  GestureDetector _buildMoreButton(
    VideoPlayerController? controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double iconSize,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: () {
        onShowMoreClicked();
      },
      child: AnimatedOpacity(
        opacity: controlsNotVisible ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
            ),
            child: Container(
              height: barHeight,
              padding: EdgeInsets.symmetric(
                horizontal: buttonPadding,
              ),
              child: Icon(
                _controlsConfiguration.overflowMenuIcon,
                color: iconColor,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController? controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double iconSize,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: () {
        cancelAndRestartTimer();

        if (_latestValue!.volume == 0) {
          controller!.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller!.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: controlsNotVisible ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
            ),
            child: Container(
              height: barHeight,
              padding: EdgeInsets.symmetric(
                horizontal: buttonPadding,
              ),
              child: Icon(
                (_latestValue != null && _latestValue!.volume > 0)
                    ? _controlsConfiguration.muteIcon
                    : _controlsConfiguration.unMuteIcon,
                color: iconColor,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(
    VideoPlayerController controller,
    Color iconColor,
    double barHeight,
  ) {
    return GestureDetector(
      onTap: _onPlayPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(
          controller.value.isPlaying
              ? _controlsConfiguration.pauseIcon
              : Icons.play_arrow,
          color: iconColor,
          size: barHeight * 0.6,
        ),
      ),
    );
  }

  Widget _buildPosition() {
    final position =
        _latestValue != null ? _latestValue!.position : const Duration();

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        BetterPlayerUtils.formatDuration(position),
        style: TextStyle(
          color: _controlsConfiguration.textColor,
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _buildRemaining() {
    final position = _latestValue != null && _latestValue!.duration != null
        ? _latestValue!.duration!
        : const Duration();

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        '${BetterPlayerUtils.formatDuration(position)}',
        style:
            TextStyle(color: _controlsConfiguration.textColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildSkipBack(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: skipBack,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 10.0),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        child: Icon(
          _controlsConfiguration.skipBackIcon,
          color: iconColor,
          size: barHeight * 0.4,
        ),
      ),
    );
  }

  GestureDetector _buildSkipForward(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: skipForward,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        margin: const EdgeInsets.only(right: 8.0),
        child: Icon(
          _controlsConfiguration.skipForwardIcon,
          color: iconColor,
          size: barHeight * 0.4,
        ),
      ),
    );
  }

  Widget _buildTopBar(
    Color backgroundColor,
    Color iconColor,
    double topBarHeight,
    double buttonPadding,
  ) {
    if (!betterPlayerController!.controlsEnabled ||
        !(_betterPlayerController?.isFullScreen ?? false)) {
      return const SizedBox();
    }
    final barHeight = topBarHeight * 0.8;
    final iconSize = topBarHeight * 0.4;
    return AnimatedOpacity(
      opacity: controlsNotVisible ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          Color(0xff000000).withOpacity(0),
          Color(0xff000000).withOpacity(0.6)
        ], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
        margin: EdgeInsets.only(
          top: 0,
          right: marginSize,
          left: marginSize,
        ),
        child: Row(
          children: <Widget>[
            if (_betterPlayerController?.isFullScreen ?? false)
              _buildExpandButton(
                backgroundColor,
                iconColor,
                barHeight,
                iconSize,
                buttonPadding,
              )
            else
              const SizedBox(),
            const SizedBox(
              width: 4,
            ),
            if (_controlsConfiguration.enablePip)
              _buildPipButton(
                backgroundColor,
                iconColor,
                barHeight,
                iconSize,
                buttonPadding,
              )
            else
              const SizedBox(),
            const Spacer(),
            if (_controlsConfiguration.enableMute)
              _buildMuteButton(
                _controller,
                backgroundColor,
                iconColor,
                barHeight,
                iconSize,
                buttonPadding,
              )
            else
              const SizedBox(),
            const SizedBox(
              width: 4,
            ),
            if (_controlsConfiguration.enableOverflowMenu)
              _buildMoreButton(
                _controller,
                backgroundColor,
                iconColor,
                barHeight,
                iconSize,
                buttonPadding,
              )
            else
              const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildNextVideoWidget() {
    return StreamBuilder<int?>(
      stream: _betterPlayerController!.nextVideoTimeStream,
      builder: (context, snapshot) {
        final time = snapshot.data;
        if (time != null && time > 0) {
          return InkWell(
            onTap: () {
              _betterPlayerController!.playNextVideo();
            },
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4, right: 8),
                decoration: BoxDecoration(
                  color: _controlsConfiguration.controlBarColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "${_betterPlayerController!.translations.controlsNextVideoIn} $time ...",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    changePlayerControlsNotVisible(false);
    _startHideTimer();
  }

  Future<void> _initialize() async {
    _controller!.addListener(_updateState);

    _updateState();

    if ((_controller!.value.isPlaying) ||
        _betterPlayerController!.betterPlayerConfiguration.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        changePlayerControlsNotVisible(false);
      });
    }
    _controlsVisibilityStreamSubscription =
        _betterPlayerController!.controlsVisibilityStream.listen((state) {
      changePlayerControlsNotVisible(!state);

      if (!controlsNotVisible) {
        cancelAndRestartTimer();
      }
    });
  }

  void _onExpandCollapse() {
    if (!_betterPlayerController!.isFullScreen) {
      _betterPlayerController!.screenImagePath = '';
    }
    changePlayerControlsNotVisible(true);
    _betterPlayerController!.toggleFullScreen();
    _expandCollapseTimer = Timer(_controlsConfiguration.controlsHideTime, () {
      setState(() {
        cancelAndRestartTimer();
      });
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: BetterPlayerCupertinoVideoProgressBar(
          _controller,
          _betterPlayerController,
          onDragStart: () {
            _hideTimer?.cancel();
          },
          onDragEnd: () {
            _startHideTimer();
          },
          onTapDown: () {
            cancelAndRestartTimer();
          },
          colors: BetterPlayerProgressColors(
              playedColor: _controlsConfiguration.progressBarPlayedColor,
              handleColor: _controlsConfiguration.progressBarHandleColor,
              bufferedColor: _controlsConfiguration.progressBarBufferedColor,
              backgroundColor:
                  _controlsConfiguration.progressBarBackgroundColor),
        ),
      ),
    );
  }

  void _onPlayPause() {
    bool isFinished = false;

    if (_latestValue?.position != null && _latestValue?.duration != null) {
      isFinished = _latestValue!.position >= _latestValue!.duration!;
    }

    if (_controller!.value.isPlaying) {
      changePlayerControlsNotVisible(false);
      _hideTimer?.cancel();
      _betterPlayerController!.pause();
    } else {
      cancelAndRestartTimer();

      if (!_controller!.value.initialized) {
        if (_betterPlayerController!.betterPlayerDataSource?.liveStream ==
            true) {
          _betterPlayerController!.play();
          _betterPlayerController!.cancelNextVideoTimer();
        }
      } else {
        if (isFinished) {
          _betterPlayerController!.seekTo(const Duration());
        }
        _betterPlayerController!.play();
        _betterPlayerController!.cancelNextVideoTimer();
      }
    }
  }

  void _startHideTimer() {
    if (_betterPlayerController!.controlsAlwaysVisible) {
      return;
    }
    _hideTimer = Timer(const Duration(seconds: 3), () {
      changePlayerControlsNotVisible(true);
    });
  }

  void _updateState() {
    if (mounted) {
      if (!controlsNotVisible ||
          isVideoFinished(_controller!.value) ||
          _wasLoading ||
          isLoading(_controller!.value)) {
        setState(() {
          _latestValue = _controller!.value;
          if (isVideoFinished(_latestValue)) {
            changePlayerControlsNotVisible(false);
          }
        });
      }
    }
  }

  void _onPlayerHide() {
    _betterPlayerController!.toggleControlsVisibility(!controlsNotVisible);
    widget.onControlsVisibilityChanged(!controlsNotVisible);
  }

  Widget _buildErrorWidget() {
    final errorBuilder =
        _betterPlayerController!.betterPlayerConfiguration.errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(
          context,
          _betterPlayerController!
              .videoPlayerController!.value.errorDescription);
    } else {
      final textStyle = TextStyle(color: _controlsConfiguration.textColor);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: _controlsConfiguration.iconsColor,
              size: 42,
            ),
            Text(
              _betterPlayerController!.translations.generalDefaultError,
              style: textStyle,
            ),
            if (_controlsConfiguration.enableRetry)
              TextButton(
                onPressed: () {
                  _betterPlayerController!.retryDataSource();
                },
                child: Text(
                  _betterPlayerController!.translations.generalRetry,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              )
          ],
        ),
      );
    }
  }

  Widget? _buildLoadingWidget() {
    if (_controlsConfiguration.loadingWidget != null) {
      return _controlsConfiguration.loadingWidget;
    }

    return CircularProgressIndicator(
      valueColor:
          AlwaysStoppedAnimation<Color>(_controlsConfiguration.loadingColor),
    );
  }

  Widget _buildPipButton(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double iconSize,
    double buttonPadding,
  ) {
    return FutureBuilder<bool>(
      future: _betterPlayerController!.isPictureInPictureSupported(),
      builder: (context, snapshot) {
        final isPipSupported = snapshot.data ?? false;
        if (isPipSupported &&
            _betterPlayerController!.betterPlayerGlobalKey != null) {
          return GestureDetector(
            onTap: () {
              betterPlayerController!.enablePictureInPicture(
                  betterPlayerController!.betterPlayerGlobalKey!);
            },
            child: AnimatedOpacity(
              opacity: controlsNotVisible ? 0.0 : 1.0,
              duration: _controlsConfiguration.controlsHideTime,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: barHeight,
                  padding: EdgeInsets.only(
                    left: buttonPadding,
                    right: buttonPadding,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Icon(
                      _controlsConfiguration.pipMenuIcon,
                      color: iconColor,
                      size: iconSize,
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
