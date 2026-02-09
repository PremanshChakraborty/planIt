import 'package:travel_app/pages/day_planner/models/day_plan.dart';

class ProcessedDayPlan {
  final DayPlan dayPlan;
  final DateTime absoluteDate;
  final String? creatorImageUrl;

  ProcessedDayPlan({
    required this.dayPlan,
    required this.absoluteDate,
    this.creatorImageUrl,
  });
}
