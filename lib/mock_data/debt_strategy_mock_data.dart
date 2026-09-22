import '../models/debt_strategy_model.dart';

class DebtStrategyMockData {
  static final List<DebtStrategyModel> debtStrategiesDatabase = [
    DebtStrategyModel(
      id: 1,
      userId: 1,
      strategyType: 'AVALANCHE',
      extraPayment: 2000000.0,
      estimatedInterestSaved: 3250000.0,
      estimatedMonthsSaved: 4,
      createdAt: DateTime(2026, 9, 1, 9),
    ),
  ];
}
