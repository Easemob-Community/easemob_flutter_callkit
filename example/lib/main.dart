 import 'dart:async';

import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easemob_flutter_callkit/easemob_flutter_callkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  String _platformVersion = 'Unknown';
  String _status = 'Not initialized';
  final List<String> _events = [];
  StreamSubscription? _eventSubscription;

  final _appKeyController = TextEditingController();
  final _usernameController = TextEditingController();
  final _pwdController = TextEditingController();
  final _userIdController = TextEditingController();
  final _groupIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await EasemobFlutterCallkit.getPlatformVersion() ?? 'Unknown platform version';
    } catch (e) {
      platformVersion = 'Failed to get platform version: $e';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void _listenEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = EasemobFlutterCallkit.callEvents.listen((event) {
      setState(() {
        _events.insert(0, event.toString());
        if (_events.length > 50) {
          _events.removeLast();
        }
      });
    });
  }

  Future<void> _initIM() async {
    final appKey = _appKeyController.text.trim();
    if (appKey.isEmpty) {
      _showSnackBar('Please enter appKey');
      return;
    }
    try {
      EMOptions options = EMOptions.withAppKey(appKey,autoLogin: false);
      await EMClient.getInstance.init(options);
      setState(() {
        _status = 'IM initialized: success';
      });
    } catch (e) {
      _showSnackBar('initIM error: $e');
    }
  }

  Future<void> _initCallKit() async {
    try {
      final config = CallKitConfig(callTimeout: 30);
      final success = await EasemobFlutterCallkit.initCallKit(config);
      _listenEvents();
      setState(() {
        _status = 'CallKit initialized: $success';
      });
    } catch (e) {
      _showSnackBar('initCallKit error: $e');
    }
  }


  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final token = _pwdController.text.trim();
    if (username.isEmpty || token.isEmpty) {
      _showSnackBar('Please enter username and token');
      return;
    }
    try {
      await EMClient.getInstance.login(username, token,  true);
      setState(() {
        _status = 'Logged in: success';
      });
    } catch (e) {
      _showSnackBar('login error: $e');
    }
  }

  Future<void> _logout() async {
    try {
      final success = await EasemobFlutterCallkit.logout();
      setState(() {
        _status = 'Logged out: $success';
      });
    } catch (e) {
      _showSnackBar('logout error: $e');
    }
  }

  Future<void> _startVoiceCall() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showSnackBar('Please enter userId');
      return;
    }
    try {
      final success = await EasemobFlutterCallkit.startSingleCall(userId, callType: CallType.voice);
      _showSnackBar('Voice call started: $success');
    } catch (e) {
      _showSnackBar('startVoiceCall error: $e');
    }
  }

  Future<void> _startVideoCall() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showSnackBar('Please enter userId');
      return;
    }
    try {
      final success = await EasemobFlutterCallkit.startSingleCall(userId, callType: CallType.video);
      _showSnackBar('Video call started: $success');
    } catch (e) {
      _showSnackBar('startVideoCall error: $e');
    }
  }

  Future<void> _startGroupCall() async {
    final groupId = _groupIdController.text.trim();
    if (groupId.isEmpty) {
      _showSnackBar('Please enter groupId');
      return;
    }
    try {
      final success = await EasemobFlutterCallkit.startGroupCall(groupId);
      _showSnackBar('Group call started: $success');
    } catch (e) {
      _showSnackBar('startGroupCall error: $e');
    }
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _appKeyController.dispose();
    _usernameController.dispose();
    _pwdController.dispose();
    _userIdController.dispose();
    _groupIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Easemob CallKit Example'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Platform version: $_platformVersion'),
              const SizedBox(height: 8),
              Text('Status: $_status', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              TextField(
                controller: _appKeyController,
                decoration: const InputDecoration(
                  labelText: 'App Key',
                  hintText: 'Enter your Easemob app key',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _initIM,
                child: const Text('Init IM SDK'),
              ),
              ElevatedButton(
                onPressed: _initCallKit,
                child: const Text('Init CallKit'),
              ),
              const Divider(height: 24),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
              ),
              TextField(
                controller: _pwdController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Logout'),
                  ),
                ],
              ),
              const Divider(height: 24),
              TextField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: 'Callee User ID',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _startVoiceCall,
                    child: const Text('Voice Call'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _startVideoCall,
                    child: const Text('Video Call'),
                  ),
                ],
              ),
              const Divider(height: 24),
              TextField(
                controller: _groupIdController,
                decoration: const InputDecoration(
                  labelText: 'Group ID',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _startGroupCall,
                child: const Text('Group Call'),
              ),
              const Divider(height: 24),
              const Text('Events:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._events.map((e) => Text(e, style: const TextStyle(fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }
}
