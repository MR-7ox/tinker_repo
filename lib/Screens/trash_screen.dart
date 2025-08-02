import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

enum Sender { human, ai }

class Message {
  final String text;
  final Sender sender;

  Message({required this.text, required this.sender});
}

class TrollChatScreen extends StatefulWidget {
  const TrollChatScreen({super.key});

  @override
  State<TrollChatScreen> createState() => _TrollChatScreenState();
}

class _TrollChatScreenState extends State<TrollChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = []; // Change from String? _response
  bool _loading = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _micAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _micAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        // _response = null; // Clear previous response - removed
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_image == null && _controller.text.trim().isEmpty) {
      setState(() {
        // _response = 'Please select an image or enter text first.'; // Removed
        _messages.add(
          Message(
            text: 'Please select an image or enter text first.',
            sender: Sender.ai,
          ),
        );
      });
      return;
    }

    final userMessageText =
        _controller.text.trim().isEmpty
            ? 'Describing image...' // Or a placeholder for image-only messages
            : _controller.text.trim();

    setState(() {
      _messages.add(Message(text: userMessageText, sender: Sender.human));
      _controller.clear();
      _loading = true;
      // _response = null; // Removed
    });

    try {
      // 1. Read the image as bytes
      final bytes = await _image!.readAsBytes();
      // 2. Convert the bytes to a Base64-encoded string
      final base64Image = base64Encode(bytes);

      // 3. Create the JSON payload
      final Map<String, dynamic> body = {
        'image_data':
            'data:image/jpeg;base64,$base64Image', // Add the MIME type header
        'prompt':
            _controller.text.trim().isEmpty
                ? 'Describe this image.'
                : _controller.text.trim(),
      };

      // 4. Send the JSON payload to the correct Flask endpoint
      final response = await http.post(
        Uri.parse(
          'http://10.220.44.36:5000/analyze_image',
        ), // Use the correct endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _messages.add(
            Message(
              text: data['comment'] ?? 'No response from server.',
              sender: Sender.ai,
            ),
          );
        });
      } else {
        setState(() {
          _messages.add(
            Message(
              text: data['error'] ?? 'Server error: ${response.statusCode}',
              sender: Sender.ai,
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          Message(text: 'Failed to connect to server: $e', sender: Sender.ai),
        );
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Troll Chat')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Button to pick an image
            ElevatedButton.icon(
              onPressed: _loading ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
            ),
            const SizedBox(height: 12),
            // Display the selected image thumbnail
            if (_image != null)
              Image.file(_image!, height: 150, fit: BoxFit.cover),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                reverse: true, // Show latest messages at the bottom
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message =
                      _messages[_messages.length -
                          1 -
                          index]; // Display in reverse order
                  return Align(
                    alignment:
                        message.sender == Sender.human
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            message.sender == Sender.human
                                ? Color(0xFF00C8F8).withOpacity(
                                  0.2,
                                ) // Neon blue for human messages (lighter glassy)
                                : Color(0xFF2A2A3A).withOpacity(
                                  0.7,
                                ), // Darker glassy grey for AI messages
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              message.sender == Sender.human
                                  ? Color(0xFF00C8F8).withOpacity(0.5)
                                  : Color(0xFF9B59B6).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              style: TextStyle(
                color: Colors.white,
              ), // Set text color to white for dark theme
              decoration: InputDecoration(
                labelText: 'Say something...',
                labelStyle: TextStyle(color: Colors.white70), // Hint text color
                filled: true,
                fillColor: Color(
                  0xFF1A1A2A,
                ).withOpacity(0.5), // Dark glassy grey for input area
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ), // Rounded corners for glassy look
                  borderSide: BorderSide(
                    color: Color(0xFF00C8F8).withOpacity(0.5),
                  ), // Neon blue border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Color(0xFF00C8F8).withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Color(0xFF00C8F8),
                  ), // Brighter neon blue when focused
                ),
                suffixIcon: AnimatedBuilder(
                  animation: _micAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _micAnimation.value,
                      child: IconButton(
                        icon: Icon(
                          Icons.mic,
                          color: Color(0xFF00C8F8),
                        ), // Mic icon
                        onPressed: () {
                          // TODO: Implement mic functionality
                        },
                      ),
                    );
                  },
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(
                  0xFF1A1A2A,
                ).withOpacity(0.5), // Glassy background for send button
                foregroundColor: Color(0xFF00C8F8), // Neon blue text/icon color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Color(0xFF00C8F8).withOpacity(0.5)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ), // Adjust padding for better look
              ),
              onPressed: _loading ? null : _sendMessage,
              child:
                  _loading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00C8F8),
                          ),
                        ), // Neon blue loading indicator
                      )
                      : const Text('Send', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            // if (_response != null) // Removed
            //   Expanded( // Removed
            //     child: SingleChildScrollView( // Removed
            //       child: Container( // Removed
            //         padding: const EdgeInsets.all(12), // Removed
            //         decoration: BoxDecoration( // Removed
            //           color: Colors.white.withOpacity( // Removed
            //             0.08, // Removed
            //           ), // Dark, glassy background for chat area // Removed
            //           borderRadius: BorderRadius.circular( // Removed
            //             12, // Removed
            //           ), // Consistent rounded corners // Removed
            //           border: Border.all( // Removed
            //             color: Color( // Removed
            //               0xFF9B59B6, // Removed
            //             ).withOpacity(0.5), // Purple border for chat area // Removed
            //           ), // Removed
            //         ), // Removed
            //         child: Text( // Removed
            //           _response!, // Removed
            //           style: const TextStyle( // Removed
            //             fontSize: 16, // Removed
            //             color: Colors.white, // Removed
            //           ), // White text for readability // Removed
            //         ), // Removed
            //       ), // Removed
            //     ), // Removed
            //   ), // Removed
          ],
        ),
      ),
    );
  }
}
