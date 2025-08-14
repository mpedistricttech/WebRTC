import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/services.dart';
import '../services/callkeep_service.dart';
import 'signaling.dart';
import '../theme/app_theme.dart';

class CallSampleUnified extends StatefulWidget {
  final String? ip;
  final String? port;
  final bool useScreen;

  const CallSampleUnified({
    Key? key,
    this.ip,
    this.port,
    this.useScreen = false,
  }) : super(key: key);

  @override
  _CallSampleUnifiedState createState() => _CallSampleUnifiedState();
}

class _CallSampleUnifiedState extends State<CallSampleUnified> {
  Signaling? _signaling;
  List<dynamic> _peers = [];
  String? _selfId;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  Session? _session;
  bool _isCallKeepAvailable = false;
  String? _currentCallId;
  final CallKeepService _callKeepService = CallKeepService();

  @override
  void initState() {
    super.initState();
    initRenderers();
    _initializeCallKeep();
  }

  @override
  void deactivate() {
    super.deactivate();
    _signaling?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _callKeepService.dispose();
  }

  void initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _initializeCallKeep() async {
    if (_callKeepService.isAvailable) {
      final bool initialized = await _callKeepService.initialize(
        onCallStarted: (callId, handle) {
          print('CallKeep: Call started - $callId with $handle');
          setState(() {
            _currentCallId = callId;
          });
        },
        onCallEnded: (callId) {
          print('CallKeep: Call ended - $callId');
          setState(() {
            _currentCallId = null;
            _inCalling = false;
          });
          _hangUp();
        },
        onCallAnswered: (callId) {
          print('CallKeep: Call answered - $callId');
          _accept();
        },
        onCallDeclined: (callId) {
          print('CallKeep: Call declined - $callId');
          _reject();
        },
      );

      setState(() {
        _isCallKeepAvailable = initialized;
      });
    }
  }

  void _connect(BuildContext context) async {
    if (widget.ip == null || widget.port == null) {
      return;
    }

    final constraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    try {
      var stream = await navigator.mediaDevices.getUserMedia(constraints);
      _localRenderer.srcObject = stream;

      _signaling = Signaling(widget.ip!, context)..connect();

      _signaling!.onCallStateChange = (Session session, CallState state) async {
        switch (state) {
          case CallState.CallStateNew:
            setState(() {
              _session = session;
              _inCalling = true;
            });
            break;
          case CallState.CallStateRinging:
            setState(() {
              _session = session;
              _inCalling = true;
            });

            // Report incoming call to CallKeep
            if (_isCallKeepAvailable) {
              final String? callId = await _callKeepService.reportIncomingCall(
                handle: session.pid,
                isVideo: true,
              );
              setState(() {
                _currentCallId = callId;
              });
            } else {
              // Fallback to dialog for platforms without CallKeep
              _showAcceptDialog(context, session);
            }
            break;
          case CallState.CallStateBye:
            setState(() {
              _inCalling = false;
              _session = null;
            });
            _localRenderer.srcObject = null;
            _remoteRenderer.srcObject = null;

            // End call in CallKeep
            if (_isCallKeepAvailable && _currentCallId != null) {
              await _callKeepService.endCall(callId: _currentCallId);
            }
            break;
          case CallState.CallStateInvite:
            setState(() {
              _session = session;
              _inCalling = true;
            });
            break;
          case CallState.CallStateConnected:
            setState(() {
              _session = session;
              _inCalling = true;
            });

            // Update call state in CallKeep
            if (_isCallKeepAvailable && _currentCallId != null) {
              await _callKeepService.updateCall(
                callId: _currentCallId!,
                state: 'connected',
              );
            }
            break;
          case CallState.CallStateRinging:
            break;
        }
      };

      _signaling!.onLocalStream = ((stream) {
        _localRenderer.srcObject = stream;
      });

      _signaling!.onAddRemoteStream = ((_, stream) {
        _remoteRenderer.srcObject = stream;
        setState(() {});
      });

      _signaling!.onRemoveRemoteStream = ((_, stream) {
        _remoteRenderer.srcObject = null;
        setState(() {});
      });

      _signaling!.onPeersUpdate = ((event) {
        setState(() {
          _selfId = event['self'];
          _peers = event['peers'];
        });
      });

      _signaling!.onSignalingStateChange = (SignalingState state) {
        print(state);
      };
    } catch (e) {
      print(e.toString());
    }
  }

  void _showAcceptDialog(BuildContext context, Session session) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Text(
          'Incoming Call',
          style: AppTheme.heading3,
        ),
        content: Text(
          'Incoming call from ${session.pid}',
          style: AppTheme.body1,
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'DECLINE',
              style: TextStyle(color: AppTheme.accentRed),
            ),
            onPressed: () {
              Navigator.pop(context);
              _reject();
            },
          ),
          ElevatedButton(
            child: Text(
              'ACCEPT',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            onPressed: () {
              Navigator.pop(context);
              _accept();
            },
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context, String peerId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Text(
          'Start Call',
          style: AppTheme.heading3,
        ),
        content: Text(
          'Call $peerId?',
          style: AppTheme.body1,
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            child: Text(
              'CALL',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            onPressed: () {
              Navigator.pop(context);
              _invitePeer(context, peerId, widget.useScreen);
            },
          ),
        ],
      ),
    );
  }

  void _invitePeer(BuildContext context, String peerId, bool useScreen) async {
    if (_signaling != null && peerId != _selfId) {
      // Start call in CallKeep
      if (_isCallKeepAvailable) {
        final String? callId = await _callKeepService.startCall(
          handle: peerId,
          isVideo: true,
        );
        setState(() {
          _currentCallId = callId;
        });
      }
      _signaling!.invite(peerId, 'video', useScreen);
    }
  }

  void _accept() {
    if (_session != null) {
      _signaling?.accept(_session!.sid, 'video');
    }
  }

  void _reject() {
    if (_session != null) {
      _signaling?.reject(_session!.sid);
    }
  }

  void _hangUp() {
    if (_session != null) {
      _signaling!.bye(_session!.sid);
    }
    if (_isCallKeepAvailable && _currentCallId != null) {
      _callKeepService.endCall(callId: _currentCallId);
    }
  }

  void _switchCamera() {
    _signaling?.switchCamera();
  }

  void _muteMic() {
    _signaling?.muteMic();
  }

  Widget _buildRow(context, peer) {
    var self = (peer['id'] == _selfId);
    return ListBody(
      children: <Widget>[
        ListTile(
          title: Text(
              self ? '${peer['name']} [Yourself]' : peer['name'] ?? peer['id']),
          onTap: () => _showInviteDialog(context, peer['id']),
          trailing: SizedBox(
            width: 100.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => _invitePeer(context, peer['id'], false),
                  tooltip: 'Voice Call',
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: () => _invitePeer(context, peer['id'], false),
                  tooltip: 'Video Call',
                ),
                IconButton(
                  icon: const Icon(Icons.screen_share),
                  onPressed: () => _invitePeer(context, peer['id'], true),
                  tooltip: 'Screen Share',
                ),
              ],
            ),
          ),
        ),
        Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CM Relief Fund'),
        backgroundColor: AppTheme.darkSurface,
        foregroundColor: AppTheme.textPrimary,
        actions: <Widget>[
          IconButton(
            icon:
                Icon(_isCallKeepAvailable ? Icons.phone : Icons.phone_disabled),
            onPressed: null,
            tooltip: _isCallKeepAvailable
                ? 'CallKeep Available'
                : 'CallKeep Not Available',
          ),
        ],
      ),
      body: _inCalling ? _buildCallView() : _buildPeerList(),
    );
  }

  Widget _buildCallView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.darkGradient,
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: AppTheme.shadowMedium,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
          Container(
            height: 120,
            margin: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              boxShadow: AppTheme.shadowMedium,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              child: RTCVideoView(
                _localRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: _switchCamera,
            backgroundColor: AppTheme.primaryBlue,
            child: const Icon(Icons.switch_camera),
          ),
          FloatingActionButton(
            onPressed: _muteMic,
            backgroundColor: AppTheme.secondaryPurple,
            child: const Icon(Icons.mic_off),
          ),
          FloatingActionButton(
            onPressed: _hangUp,
            backgroundColor: AppTheme.accentRed,
            child: const Icon(Icons.call_end),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerList() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.darkGradient,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppTheme.spacingM),
              itemCount: _peers.length,
              itemBuilder: (context, i) {
                return _buildRow(context, _peers[i]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: AnimatedGradientButton(
              text: 'Connect to Server',
              icon: Icons.wifi,
              onPressed: () => _connect(context),
            ),
          ),
        ],
      ),
    );
  }
}
