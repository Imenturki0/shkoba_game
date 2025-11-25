// Shows table cards, player hand, captured cards, Shkobba counts.

// Sends actions (play card, draw cards) to the server.

// Listens for updates (initial_state and update_state) from the server.

import 'dart:math';

import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../widgets/card_widget.dart';
import '../utils/socket_service.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  final String roomName;
  final SocketService socketService;

  const GameScreen({
    super.key,
    required this.playerName,
    required this.roomName,
    required this.socketService,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<CardModel> tableCards = [];
  List<CardModel> hand = [];
  List<CardModel> eatenCards = [];
  int chkobbaCount = 0;
  String currentTurn = "";

  @override
  void initState() {
    super.initState();

    widget.socketService.connect();
    widget.socketService.joinRoom(widget.roomName, widget.playerName);

  


    // Initial state
    widget.socketService.onInitialState((data) {
      if (!mounted) return;
      setState(() {
        if (data != null) {
          hand = (data['hand'] as List)
              .map((c) => CardModel(c['suit'], c['value']))
              .toList();
          tableCards = (data['tableCards'] as List)
              .map((c) => CardModel(c['suit'], c['value']))
              .toList();
          // eatenCards = (data['eatenCards'] as List)
          //     .map((c) => CardModel(c['suit'], c['value']))
          //     .toList();
          // chkobbaCount = data['chkobba'] ?? 0;
          currentTurn = data['currentTurn'] ?? "";
        }
      });
    });

    // Updates after any player move
    widget.socketService.onUpdateState((data) {
      if (!mounted) return;
      setState(() {
        tableCards = (data['tableCards'] as List)
            .map((c) => CardModel(c['suit'], c['value']))
            .toList();
        hand = (data['hands'][widget.playerName] as List)
            .map((c) => CardModel(c['suit'], c['value']))
            .toList();
        eatenCards = (data['eatenCards'][widget.playerName] as List)
            .map((c) => CardModel(c['suit'], c['value']))
            .toList();
        chkobbaCount = data['chkobba'][widget.playerName] ?? 0;
        currentTurn = data['currentTurn'] ?? "";
      });
    });

    widget.socketService.onGameOver((data) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Game Over'),
          content: Text(
            data.entries
                .map((e) => '${e.key}: ${e.value} captured cards')
                .join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                restartGame(); // Your restart function
              },
              child: const Text("Restart"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  void restartGame() {
    widget.socketService.restartGame(
      room: widget.roomName,
      player: widget.playerName,
    );
  }

  void playCard(CardModel card) {
    if (currentTurn != widget.playerName) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Not yout turn!")));
      return;
    }
    widget.socketService.playCard(
      room: widget.roomName,
      player: widget.playerName,
      card: card,
    );
  }

  void drawNewCards() {
    widget.socketService.onDrawNotAllowed((message) {
    if (!mounted) return; // <-- check mounted here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  });
    widget.socketService.drawCards(
      room: widget.roomName,
      player: widget.playerName,
    );
  }

  Widget buildTableRow(List<CardModel> cards) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CardWidget(card: c),
                ))
            .toList(),
      ),
    );
  }

  Widget buildFannedHandRow(List<CardModel> cards) {
    // if (cards.isEmpty) return const SizedBox.shrink();
    final double angleStep = 0.12;
    final double offsetStep = 50;
    final double curveHeight = 30;

    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(cards.length, (i) {
          final card = cards[i];
          final centerIndex = (cards.length - 1) / 2;
          final angle = (i - centerIndex) * angleStep;
          final offsetX = (i - centerIndex) * offsetStep;
          final offsetY = -curveHeight * (1 - cos(angle.abs()));

          return Positioned(
            bottom: offsetY,
            left: MediaQuery.of(context).size.width / 2 + offsetX - 40,
            child: Transform.rotate(
              angle: angle,
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () => playCard(card),
                child: CardWidget(card: card),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shkoba Multiplayer'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child:
                Image.asset('assets/background/table.jpg', fit: BoxFit.cover),
          ),
          Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Table Cards:',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          buildTableRow(tableCards),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currentTurn == widget.playerName
                    ? "Your turn!"
                    : "$currentTurn is playing...",
                style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const Text(
                'Your Hand:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              buildFannedHandRow(hand),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: drawNewCards,
                child: const Text('Draw New Cards'),
              ),
              const SizedBox(height: 10),
              Text('Captured Cards: ${eatenCards.length}',
                  style: const TextStyle(color: Colors.white)),
              Text('Shkobas: $chkobbaCount',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
