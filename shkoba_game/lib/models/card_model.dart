class CardModel {
  final String suit; // 'C', 'D', 'H', 'S'
  final int value;   // 1-13

  CardModel(this.suit, this.value);

  // Asset dosya adı formatı: C01, D12, H07, S13 ...
  String get code => '$suit${value.toString().padLeft(2, '0')}';
}
