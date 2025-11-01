// lib/features/tracking/widgets/voice_input_widget.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

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

  Future<void> _listen() async {
    if (!_isListening) {
      // Check microphone permission first
      final micStatus = await Permission.microphone.status;
      
      if (!micStatus.isGranted) {
        if (micStatus.isPermanentlyDenied) {
          _showPermissionDialog();
          return;
        }
        
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          _showPermissionDeniedSnackbar();
          return;
        }
      }
      
      // Initialize speech recognition
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('Speech status: $val');
          if (val == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          print('Speech error: $val');
          setState(() => _isListening = false);
          
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
          localeId: 'en_US',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available on this device'),
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

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'This app needs microphone access to use voice input. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Microphone permission is required for voice input'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }
}