import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;
  final VoidCallback? onTap;


  const CardWidget({required this.card, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final cardImagePath = 'assets/cards/${card.code}.png';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: ClipRRect(
       borderRadius: BorderRadius.circular(6),
          
         child: Image.asset(
          cardImagePath,
          width: 80, // optional, can make flexible
          height: 110, // optional
          // fit: BoxFit.cover,
        
      
          ),
        ),
      ),
    );
  }
}
