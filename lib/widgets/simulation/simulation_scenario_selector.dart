import 'package:flutter/material.dart';

import '../../models/simulation_model.dart';
import '../common/app_colors.dart';

/// Bộ lựa chọn 4 kịch bản mô phỏng trả nợ (Mục 6 Bước 4)
class SimulationScenarioSelector extends StatelessWidget {
  final SimulationScenarioType selectedScenario;
  final ValueChanged<SimulationScenarioType> onScenarioChanged;

  const SimulationScenarioSelector({
    super.key,
    required this.selectedScenario,
    required this.onScenarioChanged,
  });

  IconData _getScenarioIcon(SimulationScenarioType type) {
    switch (type) {
      case SimulationScenarioType.extraPayment:
        return Icons.add_card_rounded;
      case SimulationScenarioType.changePayment:
        return Icons.tune_rounded;
      case SimulationScenarioType.changeInterestRate:
        return Icons.percent_rounded;
      case SimulationScenarioType.earlyPayoff:
        return Icons.verified_user_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LỰA CHỌN KỊCH BẢN GIẢ ĐỊNH (MỤC 6)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: SimulationScenarioType.values.map((scenario) {
            final isSelected = scenario == selectedScenario;
            return InkWell(
              onTap: () => onScenarioChanged(scenario),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getScenarioIcon(scenario),
                        size: 18,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scenario.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            scenario.description,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isSelected
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
