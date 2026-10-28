import '../../models/credit_profile_model.dart';

/// Hợp đồng giao diện cho Kho lưu trữ Hồ sơ Sức khỏe Tín dụng (CreditProfileRepository)
abstract class CreditProfileRepository {
  /// Lấy hồ sơ sức khỏe tín dụng hiện tại của người dùng
  Future<CreditProfileModel?> getCreditProfile({int? userId});

  /// Yêu cầu Backend tính toán lại và cập nhật hồ sơ tín dụng khi có biến động dữ liệu
  Future<CreditProfileModel> recalculateCreditProfile({int? userId});
}
