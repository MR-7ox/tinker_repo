import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// Data class for chat messages
class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 3D & Speech Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Home_Screen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Home_Screen extends StatefulWidget {
  const Home_Screen({Key? key}) : super(key: key);

  @override
  State<Home_Screen> createState() {
    return _HomeScreenState();
  }
}

// Added TickerProviderStateMixin for animations
class _HomeScreenState extends State<Home_Screen>
    with TickerProviderStateMixin {
  late SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentRecognizedText = "Swipe right to speak...";

  // State management for chat history
  final List<Message> _messages = [Message(text: "Hehe?", isUser: false)];
  final ScrollController _scrollController = ScrollController();

  // Controllers for the 3D models to enable animation
  late Flutter3DController _robotController;
  late Flutter3DController _luffyController;
  // late AnimationController _animationController; // Removed

  // Gauge state variables
  double _humanGaugeValue = 1.0; // Start at full health/sentiment
  double _aiGaugeValue = 1.0; // Start at full health/sentiment
  bool _humanKeepGoing = true;
  bool _aiKeepGoing = true;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    // Initialize controllers
    _robotController = Flutter3DController();
    _luffyController = Flutter3DController();

    // Setup the continuous rotation animation // Removed
    // _animationController = AnimationController( // Removed
    //   vsync: this, // Removed
    //   duration: const Duration(seconds: 30), // Speed of one full rotation // Removed
    // )..repeat(); // Removed

    // _animationController.addListener(() { // Removed
    //   if (mounted) { // Removed
    //     final double angle = _animationController.value * 360; // Removed
    //     _robotController.setCameraOrbit(20, angle, 5); // Removed
    //     _luffyController.setCameraOrbit(20, angle, 5); // Removed
    //   } // Removed
    // }); // Removed
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    // _animationController.dispose(); // Removed
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _updateGauges() {
    setState(() {
      // Simulate gauge changes based on interaction, for now just a decrement
      _humanGaugeValue -= 0.05; // Example decrement
      _aiGaugeValue -= 0.02; // Example decrement

      if (_humanGaugeValue <= 0 && _humanKeepGoing) {
        _humanKeepGoing = false;
        _playVideoPopup(
          'assets/rob_dance.mp4',
          isHuman: true,
        ); // Use rob_dance.mp4 for human
      }
      if (_aiGaugeValue <= 0 && _aiKeepGoing) {
        _aiKeepGoing = false;
        _playVideoPopup(
          'assets/luffy1.mp4',
          isHuman: false,
        ); // Use luffy1.mp4 for AI
      }
    });
  }

  Future<void> _playVideoPopup(String videoUrl, {required bool isHuman}) async {
    late VideoPlayerController _videoPlayerController;
    late ChewieController _chewieController;

    _videoPlayerController = VideoPlayerController.asset(
      videoUrl,
    ); // Changed to .asset

    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      showControls: false,
      fullScreenByDefault: true,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(child: Chewie(controller: _chewieController)),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    _chewieController.pause();
                    _chewieController.dispose();
                    _videoPlayerController.dispose();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _chewieController.dispose();
      _videoPlayerController.dispose();
    });
  }

  // Helper to scroll to the bottom of the chat list
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initSpeech() async {
    _speech = SpeechToText();
    _speechAvailable = await _speech.initialize(
      onError: (errorNotification) => print('onError: $errorNotification'),
      onStatus: (status) {
        if (mounted) setState(() => _isListening = _speech.isListening);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _sendPrompt(String prompt) async {
    if (prompt.isEmpty) return;

    if (mounted) {
      setState(() => _messages.add(Message(text: prompt, isUser: true)));
      _scrollToBottom();
    }

    setState(() {
      _messages.add(Message(text: "...", isUser: false));
      _scrollToBottom();
    });

    final url = Uri.parse('http://10.220.44.36:5000/recieve');
    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'text/plain'}, body: prompt)
          .timeout(const Duration(seconds: 20));

      setState(() => _messages.removeLast());

      if (response.statusCode == 200) {
        final String reply = response.body;
        if (mounted) {
          setState(() => _messages.add(Message(text: reply, isUser: false)));
        }
      } else {
        if (mounted) {
          setState(
            () => _messages.add(
              Message(text: "Error: Connection failed.", isUser: false),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(
          Message(text: "Error: Could not reach server.", isUser: false),
        );
      });
    }
    _updateGauges(); // Call update gauges after sending a message
    _scrollToBottom();
  }

  void _toggleListening() {
    if (!_speechAvailable) return;

    if (_speech.isListening) {
      _speech.stop();
    } else {
      setState(() => _currentRecognizedText = "Listening...");
      _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() => _currentRecognizedText = result.recognizedWords);
            if (result.finalResult) {
              _sendPrompt(result.recognizedWords);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3D AI Assistant')),
      body: Column(
        // Main layout is now a Column (top-to-bottom)
        children: [
          // Top Half: Chat Interface
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return message.isUser
                          ? UserMessageBubble(message: message)
                          : AiMessageBubble(message: message);
                    },
                  ),
                ),
                // Gauges for Human and AI
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Human Gauge: ${_humanGaugeValue.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Status: ${_humanKeepGoing ? 'Keep Going' : 'Die'}',
                            style: TextStyle(
                              color:
                                  _humanKeepGoing
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'AI Gauge: ${_aiGaugeValue.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Status: ${_aiKeepGoing ? 'Keep Going' : 'Die'}',
                            style: TextStyle(
                              color:
                                  _aiKeepGoing
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _speech.isListening
                        ? _currentRecognizedText
                        : "Swipe right on the mic to speak",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                DraggableMic(
                  isListening: _isListening,
                  swipeCallback: _toggleListening,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const Divider(thickness: 2, height: 2),
          // Bottom Half: 3D Models
          Expanded(
            flex: 1,
            child: Row(
              // Models are now in a Row (side-by-side)
              children: [
                Expanded(
                  child: Managed3DViewer(
                    key: const ValueKey('robot'),
                    src: 'assets/models/robot.glb',
                    controller: _robotController,
                  ),
                ),
                const VerticalDivider(thickness: 2, width: 2),
                Expanded(
                  child: Managed3DViewer(
                    key: const ValueKey('luffy'),
                    src: 'assets/models/luffy.glb',
                    controller: _luffyController,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// No changes were needed for the widgets below this line.

class Managed3DViewer extends StatefulWidget {
  final String src;
  final Flutter3DController controller;

  const Managed3DViewer({required this.src, required this.controller, Key? key})
    : super(key: key);

  @override
  State<Managed3DViewer> createState() => _Managed3DViewerState();
}

class _Managed3DViewerState extends State<Managed3DViewer> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller.onModelLoaded.addListener(_onModelLoaded);
  }

  void _onModelLoaded() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.onModelLoaded.removeListener(_onModelLoaded);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Flutter3DViewer(
          controller: widget.controller,
          src: widget.src,
          onError: (details) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _error = details.toString();
              });
            }
          },
        ),
        if (_isLoading) const CircularProgressIndicator(),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Failed to load model.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class DraggableMic extends StatefulWidget {
  final VoidCallback swipeCallback;
  final bool isListening;

  const DraggableMic({
    required this.swipeCallback,
    required this.isListening,
    Key? key,
  }) : super(key: key);

  @override
  State<DraggableMic> createState() => _DraggableMicState();
}

class _DraggableMicState extends State<DraggableMic> {
  double _dragPosition = 0.0;
  final double _swipeThreshold = 50.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragPosition += details.delta.dx;
          _dragPosition = _dragPosition.clamp(-100, 100);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragPosition > _swipeThreshold) {
          widget.swipeCallback();
        }
        setState(() => _dragPosition = 0.0);
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(_dragPosition, 0),
              child: Icon(
                Icons.mic,
                size: 36,
                color: widget.isListening ? Colors.redAccent : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({Key? key, required this.message}) : super(key: key);
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Color(
            0xFF2A2A3A,
          ).withOpacity(0.7), // Darker glassy grey for AI messages
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class UserMessageBubble extends StatelessWidget {
  const UserMessageBubble({Key? key, required this.message}) : super(key: key);
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Color(
            0xFF00C8F8,
          ).withOpacity(0.2), // Neon blue for human messages (lighter glassy)
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
