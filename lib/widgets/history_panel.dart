import 'package:flutter/material.dart';
import 'package:vibepaint/models/history_action.dart';
import 'package:vibepaint/theme/app_colors.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({
    super.key,
    required this.layerName,
    required this.actions,
    required this.currentIndex,
    required this.onGoToIndex,
  });

  static const double width = 220;
  static const double height = 180;

  final String layerName;
  final List<HistoryAction> actions;
  final int currentIndex;
  final ValueChanged<int> onGoToIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.palettePanel,
        border: Border(
          left: BorderSide(color: AppColors.paletteBorder),
          top: BorderSide(color: AppColors.paletteBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'History',
                  style: TextStyle(
                    color: AppColors.statusText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  layerName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.paletteLabel,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: actions.isEmpty
                ? const Center(
                    child: Text(
                      'No actions yet',
                      style: TextStyle(
                        color: AppColors.paletteLabel,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: actions.length,
                    itemBuilder: (context, index) {
                      final action = actions[index];
                      final isCurrent = index == currentIndex;
                      final isUndone = currentIndex >= 0 && index > currentIndex;

                      return _HistoryRow(
                        label: action.label,
                        isCurrent: isCurrent,
                        isUndone: isUndone,
                        onTap: () => onGoToIndex(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.label,
    required this.isCurrent,
    required this.isUndone,
    required this.onTap,
  });

  final String label;
  final bool isCurrent;
  final bool isUndone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isUndone
        ? AppColors.paletteBorder
        : isCurrent
            ? AppColors.statusText
            : AppColors.paletteLabel;

    return Material(
      color: isCurrent ? AppColors.workspace : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
