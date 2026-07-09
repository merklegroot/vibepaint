import 'package:vibepaint/models/stroke.dart';

class HistoryAction {
  const HistoryAction({
    required this.label,
    required this.strokes,
  });

  final String label;
  final List<Stroke> strokes;
}
