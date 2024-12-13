import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:acumacum/ui/HomePage.dart';
import 'package:acumacum/ui/story_model.dart';
import 'package:acumacum/ui/viewProfile.dart';
import 'package:video_player/video_player.dart';

class StoryScreen extends StatefulWidget {
  final List<Story> stories;
  final String uid;
  final String currentUserID;

  const StoryScreen({
    super.key,
    required this.stories,
    required this.uid,
    required this.currentUserID,
  });

  @override
  State<StoryScreen> createState() => StoryScreenState();
}

class StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  PageController? _pageController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(vsync: this);
    try {
      for (int i = 0; i < widget.stories.length; i++) {
        _videoController = VideoPlayerController.network(widget.stories[i].url)
          ..initialize().then((value) => setState(() {}));
        _videoController?.play();
        _videoController?.setVolume(0.0);
      }
    } on PlatformException catch (e) {
      logger.e("Error $e");
    }

    final Story firstStory = widget.stories.first;
    _loadStory(story: firstStory, animateToPage: false);

    _animController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController?.stop();
        _animController?.reset();
        setState(() {
          if (_currentIndex + 1 < widget.stories.length) {
            _currentIndex += 1;
            _loadStory(story: widget.stories[_currentIndex]);
          } else {
            // Out of bounds - loop story
            // You can also Navigator.of(context).pop() here
            _currentIndex = 0;
            _loadStory(story: widget.stories[_currentIndex]);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _animController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Story story = widget.stories[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _onTapDown(details, story),
        child: Stack(children: <Widget>[
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.stories.length,
            itemBuilder: (context, i) {
              final Story story = widget.stories[i];
              switch (story.media) {
                case "image":
                  return CachedNetworkImage(
                      imageUrl: story.url, fit: BoxFit.cover);
                case "video":
                  if (_videoController != null &&
                      _videoController!.value.isInitialized) {
                    return FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    );
                  }
              }
              return const SizedBox.shrink();
            },
          ),
          widget.currentUserID != widget.uid
              ? Padding(
                  padding: const EdgeInsets.only(top: 50, right: 10),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0),
                                side: const BorderSide(color: Colors.white)),
                            backgroundColor: Colors.blue,
                            disabledBackgroundColor: Colors.blue,
                          ),
                          onPressed: () {
                            setState(() {
                              _videoController?.setVolume(1.0);
                            });
                          },
                          child: Icon(
                            _videoController?.value.isPlaying == true
                                ? Icons.volume_up
                                : Icons.volume_off,
                            color: Colors.white,
                            size: 30.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 50, right: 10),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0),
                                side: const BorderSide(color: Colors.white)),
                          ),
                          onPressed: () {
                            setState(() {
                              _videoController?.setVolume(1.0);
                            });
                          },
                          child: Icon(
                            _videoController?.value.isPlaying == true
                                ? Icons.volume_up
                                : Icons.volume_off,
                            color: Colors.white,
                            size: 30.0,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            DocumentReference reference = FirebaseFirestore
                                .instance
                                .collection('Users')
                                .doc(widget.uid)
                                .collection('Story')
                                .doc(widget.stories[_currentIndex].id);

                            Reference storageReference = FirebaseStorage
                                .instance
                                .refFromURL(widget.stories[_currentIndex].url);
                            await storageReference.delete();
                            await reference.delete();
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) {
                              return StoryProfile(
                                  uid: widget.uid,
                                  currentUserID: widget.currentUserID);
                            }));
                          },
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0),
                                side: const BorderSide(color: Colors.white)),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          Positioned(
            top: 40.0,
            left: 10.0,
            right: 10.0,
            child: Row(
              children: widget.stories
                  .asMap()
                  .map((i, e) {
                    return MapEntry(
                      i,
                      AnimatedBar(
                        animController: _animController!,
                        position: i,
                        currentIndex: _currentIndex,
                      ),
                    );
                  })
                  .values
                  .toList(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 1.5,
              vertical: 10.0,
            ),
          )
        ]),
      ),
    );
  }

  void _onTapDown(TapDownDetails details, Story story) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;
    if (dx < screenWidth / 3) {
      setState(() {
        if (_currentIndex - 1 >= 0) {
          _currentIndex -= 1;
          _loadStory(story: widget.stories[_currentIndex]);
        }
      });
    } else if (dx > 2 * screenWidth / 3) {
      setState(() {
        if (_currentIndex + 1 < widget.stories.length) {
          _currentIndex += 1;
          _loadStory(story: widget.stories[_currentIndex]);
        } else {
          // Out of bounds - loop story
          // You can also Navigator.of(context).pop() here
          _currentIndex = 0;
          _loadStory(story: widget.stories[_currentIndex]);
        }
      });
    } else {
      if (story.media == "video") {
        if (_videoController?.value.isPlaying == true) {
          _videoController?.pause();
          _animController?.stop();
        } else {
          _videoController?.play();

          _animController?.forward();
        }
      }
    }
  }

  void _loadStory({required Story story, bool animateToPage = true}) {
    _animController?.stop();
    _animController?.reset();
    switch (story.media) {
      case "image":
        _animController?.duration = const Duration(seconds: 10);
        _animController?.forward();
        break;
      case "video":
        _videoController?.dispose();
        _videoController =
            VideoPlayerController.networkUrl(Uri.parse(story.url))
              ..initialize().then((_) {
                setState(() {});
                if (_videoController?.value.isInitialized == true) {
                  _animController?.duration = _videoController?.value.duration;
                  _videoController?.play();
                  _videoController?.setVolume(0.0);
                  _animController?.forward();
                }
              });
        break;
    }
    if (animateToPage) {
      _pageController!.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }
}

class AnimatedBar extends StatelessWidget {
  final AnimationController animController;
  final int position;
  final int currentIndex;

  const AnimatedBar({
    super.key,
    required this.animController,
    required this.position,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: <Widget>[
                _buildContainer(
                  double.infinity,
                  position < currentIndex
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
                position == currentIndex
                    ? AnimatedBuilder(
                        animation: animController,
                        builder: (context, child) {
                          return _buildContainer(
                            constraints.maxWidth * animController.value,
                            Colors.white,
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ],
            );
          },
        ),
      ),
    );
  }

  Container _buildContainer(double width, Color color) {
    return Container(
      height: 5.0,
      width: width,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black26,
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(3.0),
      ),
    );
  }
}
