import '../models/simulation_model.dart';

class SimulationMockData {
  static final List<SimulationModel> simulationsDatabase = [
    SimulationModel(
      id: 1,
      userId: 1,
      loanId: 1,
      extraPayment: 2000000.0,
      earlyPaymentFee: 87500.0,
      estimatedInterest: 8250000.0,
      estimatedInterestSaved: 3250000.0,
      monthsReduced: 4,
      totalSaving: 3162500.0,
      createdAt: DateTime(2026, 9, 1, 9, 30),
    ),
  ];
}
