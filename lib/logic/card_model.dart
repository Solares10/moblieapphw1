/// Suits used in a standard deck.
enum Suit { clubs, diamonds, hearts, spades }

/// Ranks from Ace (low) to King (high).
enum Rank { ace, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king }

/// Lightweight data model for a single playing card.
class CardModel {
  final Suit suit;     // Card suit (♣ ♦ ♥ ♠)
  final Rank rank;     // Card rank (A–K)
  bool faceUp;         // Whether the card is currently face-up

  CardModel(this.suit, this.rank, {this.faceUp = true});

  /// Short label for the rank (e.g., 'A', '10', 'Q').
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

  /// Unicode symbol for the suit (e.g., '♥', '♣').
  String get suitSymbol {
    switch (suit) {
      case Suit.clubs: return '♣';
      case Suit.diamonds: return '♦';
      case Suit.hearts: return '♥';
      case Suit.spades: return '♠';
    }
  }

  /// Red cards are Hearts or Diamonds.
  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;
}
