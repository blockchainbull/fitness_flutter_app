import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputWidget extends StatefulWidget {
  final Function(String) onTextReceived;
  
  const VoiceInputWidget({
    Key? key,
    required this.onTextReceived,
  }) : super(key: key);

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _isListening 
              ? [Colors.red.shade400, Colors.red.shade600]
              : [Colors.green.shade400, Colors.green.shade600],
        ),
      ),
      child: IconButton(
        icon: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 30,
        ),
        onPressed: _listen,
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('onStatus: $val');
          if (val == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          print('onError: $val');
          setState(() => _isListening = false);
          // Show error to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice recognition error: ${val.errorMsg}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
      
      if (available) {
        setState(() => _isListening = true);
        
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.finalResult) {
              widget.onTextReceived(_text);
              _isListening = false;
            }
          }),
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: 'en_US', // or user's preferred language
        );
      } else {
        // Microphone not available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_text.isNotEmpty) {
        widget.onTextReceived(_text);
      }
    }
  }
}