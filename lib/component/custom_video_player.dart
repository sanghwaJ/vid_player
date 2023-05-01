import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  final XFile video;
  final VoidCallback onNewVideoPressed;

  const CustomVideoPlayer({
    required this.video,
    required this.onNewVideoPressed,
    Key? key,
  }) : super(key: key);

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  VideoPlayerController? videoController;
  Duration currentPosition = Duration();
  bool showControlls = false;

  @override
  void initState() {
    super.initState();
    // initState는 state가 생성될 때 딱 한 번만 실행 (주의!)
    initializeController();
  }

  @override
  void didUpdateWidget(covariant CustomVideoPlayer oldWidget) {
    // state가 이미 생성된 후, 파라미터를 변경하려면 didUpdateWidget를 통해야 함
    super.didUpdateWidget(oldWidget);

    // 기존 video path와 추가된 video path가 다르면 initializeController 실행
    if (oldWidget.video.path != widget.video.path) {
      initializeController();
    }
  }

  void initializeController() async {
    // initializeController를 실행할 때마다 currentPosition 리셋
    currentPosition = Duration();

    videoController = VideoPlayerController.file(
      // dart:io의 File 사용
      File(widget.video.path), // XFile => File
    );

    await videoController!.initialize();

    // addListener => videoController가 값이 변경될 때마다 실행
    videoController!.addListener(() {
      final currentPosition = videoController!.value.position;

      setState(() {
        // videoController가 업데이트 될 때마다 currentPosition도 업데이트
        this.currentPosition = currentPosition;
      });
    });

    // videoController에 맞게 UI 재빌드
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (videoController == null) {
      // videoController가 아직 null인 경우(비동기 처리를 하기 때문에 null일 수 있음), 로딩바 출력
      return CircularProgressIndicator();
    }

    return AspectRatio(
      // 원래 비디오의 비율대로 출력
      aspectRatio: videoController!.value.aspectRatio,
      // 이미지나 비디오 위에 버튼 등을 올리기 위해 사용
      child: GestureDetector(
        onTap: (){
          setState(() {
            // true일 땐 false로, false일 땐 true로 변경
            showControlls =!showControlls;
          });
        },
        child: Stack(
          children: [
            VideoPlayer(
              videoController!,
            ),
            if (showControlls)
              _Controls(
                onReversePressed: onReversePressed,
                onPlayPressed: onPlayPressed,
                onForwardPressed: onForwardPressed,
                isPlaying: videoController!.value.isPlaying,
              ),
            if (showControlls)
              _NewVideo(
                onPressed: widget.onNewVideoPressed,
              ),
            _SlideBottom(
              currentPosition: currentPosition,
              maxPosition: videoController!.value.duration,
              onSliderChanged: onSliderChanged,
            )
          ],
        ),
      ),
    );
  }

  void onReversePressed() {
    // 현재 영상의 위치
    final currentPosition = videoController!.value.position;

    Duration position = Duration(); // 0초
    // 현재 영상의 위치가 3초 이상일 때만 -3초 처리
    if (currentPosition.inSeconds > 3) {
      position = currentPosition - Duration(seconds: 3);
    }

    // 어떤 위치로 이동할 지 지정
    videoController!.seekTo(position);
  }

  void onPlayPressed() {
    // 이미 실행 중이면 중지, 실행 중이 아니면 실행
    // setState를 통해 빌드를 재실행시켜, videoController 값을 바꿔줌
    setState(() {
      if (videoController!.value.isPlaying) {
        videoController!.pause();
      } else {
        videoController!.play();
      }
    });
  }

  void onForwardPressed() {
    // 영상의 최대 길이
    final maxPosition = videoController!.value.duration;
    // 현재 영상의 위치
    final currentPosition = videoController!.value.position;

    // 영상의 최대 길이에서 3초만큼 뺀게 현재 위치보다 크다면 3초 뒤로 이동, 아니라면 최대 위치로 이동
    Duration position = maxPosition;
    if ((maxPosition - Duration(seconds: 3)).inSeconds >
        currentPosition.inSeconds) {
      position = currentPosition + Duration(seconds: 3);
    }

    // 어떤 위치로 이동할 지 지정
    videoController!.seekTo(position);
  }

  void onSliderChanged(double val) {
    // slider가 변경될 때마다, 영상을 해당 위치로 이동
    videoController!.seekTo(
      Duration(
        seconds: val.toInt(),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final VoidCallback onReversePressed;
  final VoidCallback onPlayPressed;
  final VoidCallback onForwardPressed;
  final bool isPlaying;

  const _Controls({
    required this.onReversePressed,
    required this.onPlayPressed,
    required this.onForwardPressed,
    required this.isPlaying,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Icon들이 올라오면 눈에 잘 띄이도록 배경색을 어둡게 처리
      color: Colors.black.withOpacity(0.5),
      // crossAxisAlignment 대체
      height: MediaQuery.of(context).size.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        // stretch로 하면 아이콘이 아닌 겉을 눌러도 버튼이 작동함 => height로 대체
        // crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          renderIconButton(
            onPressed: onReversePressed,
            iconData: Icons.rotate_left,
          ),
          renderIconButton(
            onPressed: onPlayPressed,
            iconData: isPlaying ? Icons.pause : Icons.play_arrow,
          ),
          renderIconButton(
            onPressed: onForwardPressed,
            iconData: Icons.rotate_right,
          ),
        ],
      ),
    );
  }

  Widget renderIconButton({
    required VoidCallback onPressed,
    required IconData iconData,
  }) {
    return IconButton(
      onPressed: onPressed,
      iconSize: 30.0,
      color: Colors.white,
      icon: Icon(
        iconData,
      ),
    );
  }
}

class _NewVideo extends StatelessWidget {
  final VoidCallback onPressed;

  const _NewVideo({
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return // position만 지정하는 경우 사용하는 widget
        Positioned(
      right: 0, // 오른쪽 끝부터 0 pixel만큼 이동
      child: IconButton(
        onPressed: onPressed,
        color: Colors.white,
        iconSize: 30.0,
        icon: Icon(
          Icons.photo_camera_back,
        ),
      ),
    );
  }
}

class _SlideBottom extends StatelessWidget {
  final Duration currentPosition;
  final Duration maxPosition;
  final ValueChanged<double> onSliderChanged;

  const _SlideBottom({
    required this.currentPosition,
    required this.maxPosition,
    required this.onSliderChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      // 오른쪽, 왼쪽 끝과 끝에 붙게 지정
      right: 0,
      left: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: Row(
          children: [
            Text(
              // 8:02 형태로 나오게 지정 (%60을 해준 이유는 안해주면 61초가 나오게 됨)
              '${currentPosition.inMinutes}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Slider(
                value: currentPosition.inSeconds.toDouble(),
                onChanged: onSliderChanged,
                max: maxPosition.inSeconds.toDouble(),
                min: 0,
              ),
            ),
            Text(
              // 8:02 형태로 나오게 지정 (%60을 해준 이유는 안해주면 61초가 나오게 됨)
              '${maxPosition.inMinutes}:${(maxPosition.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}