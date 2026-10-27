/// Counts only completed runs with meaningful active play time.
class AdPacing {
  Duration activePlay = Duration.zero;
  int eligibleRuns = 0;
  int shown = 0;
  DateTime? lastShown;
  DateTime? rewardAt;
  final List<DateTime> impressions = [];

  void completeRun(Duration active) {
    activePlay += active;
    if (active >= const Duration(seconds: 15)) eligibleRuns++;
  }

  bool eligible(DateTime now) =>
      activePlay >= const Duration(minutes: 2) &&
      eligibleRuns >= 3 &&
      shown < 3 &&
      (lastShown == null ||
          now.difference(lastShown!) >= const Duration(minutes: 3)) &&
      (rewardAt == null ||
          now.difference(rewardAt!) >= const Duration(minutes: 5)) &&
      impressions
              .where((t) => now.difference(t) < const Duration(hours: 1))
              .length <
          2;

  void record(DateTime now) {
    shown++;
    eligibleRuns = 0;
    lastShown = now;
    impressions.add(now);
  }
}
