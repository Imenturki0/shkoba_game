import 'card_model.dart';

class Player {
  final String name;
  List<CardModel> hand = [];
  List<CardModel> eatenCards = [];
  int chkobbaCount = 0;
  Player({required this.name});
}
