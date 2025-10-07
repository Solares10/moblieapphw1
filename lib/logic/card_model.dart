enum Suit { clubs, diamonds, hearts, spades }

enum Rank { ace, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king }

class CardModel {
  final Suit suit;
  final Rank rank;
  bool faceUp;

  CardModel(this.suit, this.rank, {this.faceUp = true});

  String get rankLabel {
    switch (rank) {
      case Rank.ace: return 'A';
      case Rank.two: return '2';
      case Rank.three: return '3';
      case Rank.four: return '4';
      case Rank.five: return '5';
      case Rank.six: return '6';
      case Rank.seven: return '7';
      case Rank.eight: return '8';
      case Rank.nine: return '9';
      case Rank.ten: return '10';
      case Rank.jack: return 'J';
      case Rank.queen: return 'Q';
      case Rank.king: return 'K';
    }
  }

  String get suitSymbol {
    switch (suit) {
      case Suit.clubs: return '♣';
      case Suit.diamonds: return '♦';
      case Suit.hearts: return '♥';
      case Suit.spades: return '♠';
    }
  }

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;
}
