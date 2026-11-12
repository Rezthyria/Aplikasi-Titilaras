class AdaptiveState {
  final int level;
  final int streak;
  final int missStreak;

  const AdaptiveState({
    required this.level,
    required this.streak,
    required this.missStreak,
  });
}

class AdaptivePolicy {
  final int minLevel;
  final int maxLevel;
  final int passScore;
  final int failScore;
  final int streakToLevelUp;
  final int missToLevelDown;

  const AdaptivePolicy({
    required this.minLevel,
    required this.maxLevel,
    this.passScore = 85,
    this.failScore = 50,
    this.streakToLevelUp = 5,
    this.missToLevelDown = 2,
  });

  AdaptiveState apply({
    required int level,
    required int streak,
    required int missStreak,
    required int score,
    required bool adaptif,
  }) {
    if (!adaptif) {
      return AdaptiveState(
        level: level.clamp(minLevel, maxLevel),
        streak: score >= passScore ? streak + 1 : 0,
        missStreak: score < failScore ? missStreak + 1 : 0,
      );
    }

    var nextLevel = level.clamp(minLevel, maxLevel);
    var nextStreak = streak;
    var nextMiss = missStreak;

    if (score >= passScore) {
      nextStreak += 1;
      nextMiss = 0;
      if (nextStreak >= streakToLevelUp && nextLevel < maxLevel) {
        nextLevel += 1;
        nextStreak = 0;
      }
    } else if (score < failScore) {
      nextStreak = 0;
      nextMiss += 1;
      if (nextMiss >= missToLevelDown && nextLevel > minLevel) {
        nextLevel -= 1;
        nextMiss = 0;
      }
    } else {
      nextStreak = 0;
      nextMiss = 0;
    }

    return AdaptiveState(
      level: nextLevel,
      streak: nextStreak,
      missStreak: nextMiss,
    );
  }
}
