import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:core';
import '../widgets/screen_select_dialog.dart';
import '../services/callkit_service.dart' as callkit;
import 'signaling.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class CallSampleWithCallKit extends StatefulWidget {
  static String tag = 'call_sample_with_callkit';
  final String host;
  CallSampleWithCallKit({required this.host});

  @override
  _CallSampleWithCallKitState createState() => _CallSampleWithCallKitState();
}

class _CallSampleWithCallKitState extends State<CallSampleWithCallKit> {
  final GlobalKey _captureKey = GlobalKey();
  Signaling? _signaling;
  List<dynamic> _peers = [];
  String? _selfId;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  Session? _session;
  DesktopCapturerSource? selected_source_;
  bool _waitAccept = false;

  // CallKit integration
  final callkit.CallKitService _callKitService = callkit.CallKitService();
  bool _isCallKitAvailable = false;

  @override
  initState() {
    super.initState();
    initRenderers();
    _initializeCallKit();
    _connect(context);
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  /// Initialize CallKit service
  Future<void> _initializeCallKit() async {
    try {
      await _callKitService.initialize(
        onCallStarted: (String handle) {
          print('CallKit: Call started with handle: $handle');
          // Handle call start from CallKit
        },
        onCallEnded: () {
          print('CallKit: Call ended');
          _hangUp();
        },
        onCallAnswered: () {
          print('CallKit: Call answered');
          _accept();
        },
        onCallDeclined: () {
          print('CallKit: Call declined');
          _reject();
        },
      );
      _isCallKitAvailable = true;
    } catch (e) {
      print('CallKit not available: $e');
      _isCallKitAvailable = false;
    }
  }

  @override
  deactivate() {
    super.deactivate();
    _signaling?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _callKitService.dispose();
  }

  void _connect(BuildContext context) async {
    _signaling ??= Signaling(widget.host, context)..connect();
    _signaling?.onSignalingStateChange = (SignalingState state) {
      switch (state) {
        case SignalingState.ConnectionClosed:
        case SignalingState.ConnectionError:
        case SignalingState.ConnectionOpen:
          break;
      }
    };

    _signaling?.onCallStateChange = (Session session, CallState state) async {
      switch (state) {
        case CallState.CallStateNew:
          setState(() {
            _session = session;
          });
          break;
        case CallState.CallStateRinging:
          // Use CallKit for incoming call if available
          if (_isCallKitAvailable && Platform.isIOS) {
            await _callKitService.reportIncomingCall(
              handle: session.pid,
              isVideo: true,
            );
          } else {
            // Fallback to dialog
            bool? accept = await _showAcceptDialog();
            if (accept!) {
              _accept();
              setState(() {
                _inCalling = true;
              });
            } else {
              _reject();
            }
          }
          break;
        case CallState.CallStateBye:
          if (_waitAccept) {
            print('peer reject');
            _waitAccept = false;
            Navigator.of(context).pop(false);
          }
          setState(() {
            _localRenderer.srcObject = null;
            _remoteRenderer.srcObject = null;
            _inCalling = false;
            _session = null;
          });
          // End CallKit call
          if (_isCallKitAvailable && Platform.isIOS) {
            await _callKitService.endCall();
          }
          break;
        case CallState.CallStateInvite:
          _waitAccept = true;
          _showInvateDialog();
          break;
        case CallState.CallStateConnected:
          if (_waitAccept) {
            _waitAccept = false;
            Navigator.of(context).pop(false);
          }
          setState(() {
            _inCalling = true;
          });
          // Update CallKit call state
          if (_isCallKitAvailable && Platform.isIOS) {
            await _callKitService.updateCall(state: 'connected');
          }
          break;
        case CallState.CallStateRinging:
          break;
      }
    };

    _signaling?.onPeersUpdate = ((event) {
      setState(() {
        _selfId = event['self'];
        _peers = event['peers'];
      });
    });

    _signaling?.onLocalStream = ((stream) {
      _localRenderer.srcObject = stream;
      setState(() {});
    });

    _signaling?.onAddRemoteStream = ((_, stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    _signaling?.onRemoveRemoteStream = ((_, stream) {
      _remoteRenderer.srcObject = null;
    });
  }

  Future<bool?> _showAcceptDialog() {
    return showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Incoming Call"),
          content: Text("Accept video call?"),
          actions: <Widget>[
            MaterialButton(
              child: Text(
                'Reject',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            MaterialButton(
              child: Text(
                'Accept',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showInvateDialog() {
    return showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Calling"),
          content: Text("Waiting for answer..."),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false);
                _hangUp();
              },
            ),
          ],
        );
      },
    );
  }

  _invitePeer(BuildContext context, String peerId, bool useScreen) async {
    if (_signaling != null && peerId != _selfId) {
      // Start CallKit call if available
      if (_isCallKitAvailable && Platform.isIOS) {
        await _callKitService.startCall(
          handle: peerId,
          isVideo: true,
        );
      }
      _signaling?.invite(peerId, 'video', useScreen);
    }
  }

  _accept() {
    if (_session != null) {
      _signaling?.accept(_session!.sid, 'video');
    }
  }

  _reject() {
    if (_session != null) {
      _signaling?.reject(_session!.sid);
    }
  }

  _hangUp() {
    if (_session != null) {
      _signaling?.bye(_session!.sid);
    }
    // End CallKit call
    if (_isCallKitAvailable && Platform.isIOS) {
      _callKitService.endCall();
    }
  }

  _switchCamera() {
    _signaling?.switchCamera();
  }

  _muteMic() {
    _signaling?.muteMic();
  }

  _buildRow(context, peer) {
    var self = (peer['id'] == _selfId);
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(self ? peer['name'] + '[Yourself]' : peer['name']),
        onTap: () => _invitePeer(context, peer['id'], false),
        trailing: SizedBox(
            width: 100.0,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () => _invitePeer(context, peer['id'], false),
                    tooltip: 'Video call',
                  ),
                  IconButton(
                    icon: const Icon(Icons.screen_share),
                    onPressed: () => _invitePeer(context, peer['id'], true),
                    tooltip: 'Screen sharing',
                  ),
                ])),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connected to: ${widget.host}'),
        actions: <Widget>[
          IconButton(
            icon:
                Icon(_isCallKitAvailable ? Icons.phone : Icons.phone_disabled),
            onPressed: null,
            tooltip: _isCallKitAvailable
                ? 'CallKit Available'
                : 'CallKit Not Available',
          ),
        ],
      ),
      body: _inCalling ? _buildCallView() : _buildPeerList(),
    );
  }

  Widget _buildCallView() {
    return OrientationBuilder(builder: (context, orientation) {
      return Container(
        child: Stack(children: <Widget>[
          Center(
            child: Container(
              margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: RTCVideoView(_remoteRenderer),
              decoration: BoxDecoration(color: Colors.black54),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 100.0,
              height: 150.0,
              child: Center(
                child: RTCVideoView(_localRenderer),
              ),
              decoration: BoxDecoration(color: Colors.black54),
            ),
          ),
          _buildControlPanel(),
        ]),
      );
    });
  }

  Widget _buildControlPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(bottom: 30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FloatingActionButton(
              onPressed: _switchCamera,
              tooltip: 'Switch camera',
              child: Icon(Icons.switch_camera),
            ),
            FloatingActionButton(
              onPressed: _muteMic,
              tooltip: 'Mute mic',
              child: Icon(Icons.mic_off),
            ),
            FloatingActionButton(
              onPressed: _hangUp,
              tooltip: 'Hangup',
              child: Icon(Icons.call_end),
              backgroundColor: Colors.pink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerList() {
    return ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(0.0),
        itemCount: (_peers.length),
        itemBuilder: (context, i) {
          return _buildRow(context, _peers[i]);
        });
  }
}
