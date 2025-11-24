import '../models/card_model.dart';
import '../models/player_model.dart';

List<CardModel> findSubsetSum(List<CardModel> cards, int targetValue) {
  List<CardModel> result = [];

  bool backtrack(int start, int currentSum, List<CardModel> path) {
    if (currentSum == targetValue) {
      result = List.from(path);
      return true;
    }
    if (currentSum > targetValue) return false;

    for (int i = start; i < cards.length; i++) {
      path.add(cards[i]);
      if (backtrack(i + 1, currentSum + cards[i].value, path)) {
        return true;
      }
      path.removeLast();
    }
    return false;
  }

  backtrack(0, 0, []);
  return result;
}

int calculatePoints({
  required Player player,
  required Player opponent,
}) {
  int points = 0;

  points += player.chkobbaCount;

  bool hasSevenOfDiamonds =
      player.eatenCards.any((c) => c.suit == '♦' && c.value == 7);
  if (hasSevenOfDiamonds) points += 1;

  if (player.eatenCards.length > opponent.eatenCards.length) points += 1;

  int playerDiamonds = player.eatenCards.where((c) => c.suit == '♦').length;
  int opponentDiamonds = opponent.eatenCards.where((c) => c.suit == '♦').length;
  if (playerDiamonds > opponentDiamonds) points += 1;

  return points;
}
