import 'package:flutter/material.dart';
import 'package:shkoba_game/utils/socket_service.dart';
import 'shkoba_game.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _nameController = TextEditingController();
  final _roomController = TextEditingController();
  final socketService = SocketService();

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _joinRoom() {
    final name = _nameController.text.trim();
    final room = _roomController.text.trim();

    if (name.isEmpty || room.isEmpty) return;

    // Connect and join room
    socketService.connect();
    socketService.joinRoom(room, name);

    // Navigate to GameScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          playerName: name,
          roomName: room,
          socketService: socketService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _joinRoom,
              child: const Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }
}
