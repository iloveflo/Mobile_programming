import '../models/debt_strategy_model.dart';

class DebtStrategyMockData {
  static final List<DebtStrategyModel> _initialDatabase = [
    DebtStrategyModel(
      id: 1,
      userId: 1,
      strategyType: 'AVALANCHE',
      extraPayment: 2000000.0,
      estimatedInterestSaved: 3250000.0,
      estimatedMonthsSaved: 4,
      status: 'ACTIVE',
      createdAt: DateTime(2026, 9, 1, 9),
    ),
  ];

  static final List<DebtStrategyModel> debtStrategiesDatabase = List.from(
    _initialDatabase,
  );

  static void reset() {
    debtStrategiesDatabase.clear();
    debtStrategiesDatabase.addAll(_initialDatabase);
  }
}
