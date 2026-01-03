import '/core/core.dart';

final class Level4 {
  static const int levelNumber = 4;

  // 11x18 (0..197)
  // Bariyer olmayan hücrelere yerleştirildi:
  static const int playerStartPosition =
      AppConstants.numberInRow * 16 + 1; // 177
  static const int ghost1StartPosition = AppConstants.numberInRow * 2 + 1; // 23
  static const int ghost2StartPosition = AppConstants.numberInRow * 8 + 5; // 93
  static const int ghost3StartPosition =
      AppConstants.numberInRow * 12 + 9; // 141

  // Portal (örnekteki gibi bariyer üstünden açılacak)
  static const int portalPosition = 21;

  static const List<int> barriers = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    21,
    22,
    25,
    26,
    27,
    30,
    32,
    33,
    38,
    41,
    43,
    44,
    47,
    54,
    55,
    58,
    65,
    66,
    69,
    72,
    73,
    76,
    77,
    79,
    80,
    81,
    82,
    83,
    84,
    87,
    88,
    98,
    99,
    106,
    109,
    110,
    113,
    114,
    117,
    120,
    121,
    131,
    132,
    137,
    140,
    142,
    143,
    148,
    151,
    153,
    154,
    162,
    164,
    165,
    168,
    169,
    170,
    173,
    175,
    176,
    186,
    187,
    188,
    189,
    190,
    191,
    192,
    193,
    194,
    195,
    196,
    197,
  ];
}
