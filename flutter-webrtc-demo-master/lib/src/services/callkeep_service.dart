import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

class CallKeepService {
  static const MethodChannel _channel = MethodChannel('callkeep');
  static const EventChannel _eventChannel = EventChannel('callkeep_events');
  
  static final CallKeepService _instance = CallKeepService._internal();
  factory CallKeepService() => _instance;
  CallKeepService._internal();

  StreamSubscription? _eventSubscription;
  Function(String, String)? _onCallStarted;
  Function(String)? _onCallEnded;
  Function(String)? _onCallAnswered;
  Function(String)? _onCallDeclined;

  /// Initialize CallKeep service
  Future<bool> initialize({
    Function(String, String)? onCallStarted,
    Function(String)? onCallEnded,
    Function(String)? onCallAnswered,
    Function(String)? onCallDeclined,
  }) async {
    try {
      _onCallStarted = onCallStarted;
      _onCallEnded = onCallEnded;
      _onCallAnswered = onCallAnswered;
      _onCallDeclined = onCallDeclined;

      // Listen to CallKeep events
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(_handleCallKeepEvent);

      // Initialize native CallKeep
      final bool result = await _channel.invokeMethod('initialize');
      
      if (result) {
        print('CallKeep initialized successfully');
      } else {
        print('Failed to initialize CallKeep');
      }
      
      return result;
    } catch (e) {
      print('Error initializing CallKeep: $e');
      return false;
    }
  }

  /// Start an outgoing call
  Future<String?> startCall({
    required String handle,
    bool isVideo = true,
  }) async {
    try {
      final String? callId = await _channel.invokeMethod('startCall', {
        'handle': handle,
        'isVideo': isVideo,
      });
      
      print('Started call: $callId with handle: $handle');
      return callId;
    } catch (e) {
      print('Error starting call: $e');
      return null;
    }
  }

  /// End a call
  Future<bool> endCall({String? callId}) async {
    try {
      await _channel.invokeMethod('endCall', {
        'callId': callId,
      });
      
      print('Ended call: $callId');
      return true;
    } catch (e) {
      print('Error ending call: $e');
      return false;
    }
  }

  /// Update call state
  Future<bool> updateCall({
    required String callId,
    required String state,
  }) async {
    try {
      await _channel.invokeMethod('updateCall', {
        'callId': callId,
        'state': state,
      });
      
      print('Updated call state: $callId to $state');
      return true;
    } catch (e) {
      print('Error updating call: $e');
      return false;
    }
  }

  /// Report an incoming call
  Future<String?> reportIncomingCall({
    required String handle,
    bool isVideo = true,
  }) async {
    try {
      final String? callId = await _channel.invokeMethod('reportIncomingCall', {
        'handle': handle,
        'isVideo': isVideo,
      });
      
      print('Reported incoming call: $callId with handle: $handle');
      return callId;
    } catch (e) {
      print('Error reporting incoming call: $e');
      return null;
    }
  }

  /// Handle CallKeep events from native side
  void _handleCallKeepEvent(dynamic event) {
    if (event is Map) {
      final String type = event['type'] ?? '';
      final String callId = event['callId'] ?? '';
      final String handle = event['handle'] ?? '';

      switch (type) {
        case 'callStarted':
          _onCallStarted?.call(callId, handle);
          break;
        case 'callEnded':
          _onCallEnded?.call(callId);
          break;
        case 'callAnswered':
          _onCallAnswered?.call(callId);
          break;
        case 'callDeclined':
          _onCallDeclined?.call(callId);
          break;
      }
    }
  }

  /// Check if CallKeep is available on this platform
  bool get isAvailable {
    return Platform.isIOS || (Platform.isAndroid && _isAndroidOreoOrHigher());
  }

  /// Check Android API level for CallKeep support
  bool _isAndroidOreoOrHigher() {
    if (Platform.isAndroid) {
      // Android CallKeep requires API level 26 (Android 8.0 Oreo) or higher
      // This is a simplified check - in a real app you'd get the actual API level
      return true; // Assume modern Android for demo purposes
    }
    return false;
  }

  /// Dispose resources
  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _onCallStarted = null;
    _onCallEnded = null;
    _onCallAnswered = null;
    _onCallDeclined = null;
  }
}

/// Call states for CallKeep
enum CallKeepState {
  idle,
  connecting,
  connected,
  disconnected,
  failed,
  holding,
}

/// Call types for CallKeep
enum CallKeepType {
  audio,
  video,
} 