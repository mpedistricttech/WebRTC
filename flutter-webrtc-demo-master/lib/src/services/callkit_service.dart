import 'package:flutter/services.dart';
import 'dart:async';

class CallKitService {
  static const MethodChannel _channel = MethodChannel('callkit');
  static const EventChannel _eventChannel = EventChannel('callkit_events');
  
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();

  StreamSubscription? _eventSubscription;
  Function(String)? _onCallStarted;
  Function()? _onCallEnded;
  Function()? _onCallAnswered;
  Function()? _onCallDeclined;

  /// Initialize CallKit service and listen for events
  Future<void> initialize({
    Function(String)? onCallStarted,
    Function()? onCallEnded,
    Function()? onCallAnswered,
    Function()? onCallDeclined,
  }) async {
    _onCallStarted = onCallStarted;
    _onCallEnded = onCallEnded;
    _onCallAnswered = onCallAnswered;
    _onCallDeclined = onCallDeclined;

    try {
      // Listen for CallKit events
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          _handleCallKitEvent(event);
        },
        onError: (error) {
          print('CallKit event error: $error');
        },
      );
    } catch (e) {
      print('Error initializing CallKit: $e');
    }
  }

  /// Start a call using CallKit
  Future<void> startCall({
    required String handle,
    bool isVideo = true,
  }) async {
    try {
      await _channel.invokeMethod('startCall', {
        'handle': handle,
        'isVideo': isVideo,
      });
    } catch (e) {
      print('Error starting call: $e');
      rethrow;
    }
  }

  /// End the current call
  Future<void> endCall() async {
    try {
      await _channel.invokeMethod('endCall');
    } catch (e) {
      print('Error ending call: $e');
      rethrow;
    }
  }

  /// Update call state
  Future<void> updateCall({required String state}) async {
    try {
      await _channel.invokeMethod('updateCall', {
        'state': state,
      });
    } catch (e) {
      print('Error updating call: $e');
      rethrow;
    }
  }

  /// Report incoming call
  Future<void> reportIncomingCall({
    required String handle,
    bool isVideo = true,
  }) async {
    try {
      await _channel.invokeMethod('reportIncomingCall', {
        'handle': handle,
        'isVideo': isVideo,
      });
    } catch (e) {
      print('Error reporting incoming call: $e');
      rethrow;
    }
  }

  /// Handle CallKit events
  void _handleCallKitEvent(dynamic event) {
    if (event is Map) {
      final String? type = event['type'];
      
      switch (type) {
        case 'callStarted':
          final String? handle = event['handle'];
          if (handle != null && _onCallStarted != null) {
            _onCallStarted!(handle);
          }
          break;
        case 'callEnded':
          if (_onCallEnded != null) {
            _onCallEnded!();
          }
          break;
        case 'callAnswered':
          if (_onCallAnswered != null) {
            _onCallAnswered!();
          }
          break;
        case 'callDeclined':
          if (_onCallDeclined != null) {
            _onCallDeclined!();
          }
          break;
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }
}

/// Call states
enum CallState {
  idle,
  connecting,
  connected,
  disconnected,
  failed,
}

/// Call types
enum CallType {
  audio,
  video,
} 