// SocketService to match the new server/client architecture:

// Listen for initial_state when joining a room.

// Listen for update_state for all game updates (table, hands, captured cards, Shkobbas).

// Send play_card and draw_cards events to server.

import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/card_model.dart';

class SocketService {
  late IO.Socket _socket;

  void connect() {
    _socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      print('Connected to server');
    });

    _socket.onDisconnect((_) {
      print('Disconnected from server');
    });
  }

  void joinRoom(String roomName, String playerName) {
    _socket.emit('join_room', {'room': roomName, 'player': playerName});
  }

  void playCard({
    required String room,
    required String player,
    required CardModel card,
  }) {
    _socket.emit('play_card', {
      'room': room,
      'player': player,
      'cardSuit': card.suit,
      'cardValue': card.value,
    });
  }

  void drawCards({
    required String room,
    required String player,
  }) {
    _socket.emit('draw_cards', {
      'room': room,
      'player': player,
    });
  }

  void onInitialState(Function(Map<String, dynamic>?) callback) {
    _socket.on('initial_state', (data) {
      if (data == null) {
        callback(null);
      } else {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onUpdateState(Function(Map<String, dynamic>) callback) {
    _socket.on('update_state', (data) {
      print('Update received from server: $data'); // <- prints raw data
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onGameOver(Function(Map<String, dynamic>) callback) {
    _socket.on('game_over', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void restartGame({required String room, required String player}) {
    _socket.emit('restart_game', {
      'room': room,
      'player': player,
    });
  }

  void onDrawNotAllowed(Function(String) callback) {
    _socket.on('draw_not_allowed', (data) {
      callback(data['message'] ?? 'Draw not allowed');
    });
  }
}
