class HomeStatsModel {
  final Map<String, dynamic> tenantStats;
  final Map<String, dynamic> ownerStats;
  final Map<String, dynamic> techStats;
  final Map<String, dynamic> adminStats;

  HomeStatsModel({
    required this.tenantStats,
    required this.ownerStats,
    required this.techStats,
    required this.adminStats,
  });

  factory HomeStatsModel.empty() {
    return HomeStatsModel(
      tenantStats: {},
      ownerStats: {},
      techStats: {},
      adminStats: {},
    );
  }
}
