import 'dart:async';
import 'dart:io';

import '../../core/network/api_client.dart';
import '../../models/collateral_model.dart';
import '../../models/loan_model.dart';
import '../interfaces/loan_repository.dart';

/// Triển khai thực tế của LoanRepository kết nối qua RESTful API
class ApiLoanRepository implements LoanRepository {
  final ApiClient client;

  ApiLoanRepository({required this.client});

  /// Phương thức bọc cuộc gọi API để chuẩn hóa và chuyển đổi mã lỗi HTTP sang thông điệp rõ ràng
  Future<T> _handleApiCall<T>(Future<dynamic> Function() request) async {
    try {
      final response = await request();
      return response as T;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw Exception(
          'Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.',
        );
      }
      if (e.statusCode == 404) {
        throw Exception(
          'Không tìm thấy thông tin khoản vay hoặc tài sản được yêu cầu.',
        );
      }
      if (e.statusCode == 400 || e.statusCode == 422) {
        throw Exception(e.message);
      }
      if (e.statusCode >= 500) {
        throw Exception(
          'Máy chủ FinCredit đang bận xử lý. Vui lòng thử lại sau giây lát.',
        );
      }
      throw Exception(e.message);
    } on SocketException catch (_) {
      throw Exception(
        'Không thể kết nối máy chủ. Vui lòng kiểm tra kết nối mạng Wifi/4G.',
      );
    } on TimeoutException catch (_) {
      throw Exception(
        'Yêu cầu đã quá thời gian phản hồi (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<List<LoanModel>> getLoans({
    String? keyword,
    LoanStatus? status,
    String? lender,
  }) async {
    final queryParams = <String, String>{};
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }
    if (status != null && status != LoanStatus.all) {
      queryParams['status'] = status.name.toUpperCase();
    }
    if (lender != null && lender.isNotEmpty) {
      queryParams['lender'] = lender;
    }

    final response = await _handleApiCall<dynamic>(
      () => client.get(
        '/api/loans',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      ),
    );

    final list = response is List
        ? response
        : (response is Map<String, dynamic>
              ? (response['data'] as List? ?? [])
              : []);

    return list
        .map(
          (item) => LoanModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<LoanModel> getLoanDetail(String loanId) async {
    final response = await _handleApiCall<dynamic>(
      () => client.get('/api/loans/$loanId'),
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return LoanModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<LoanModel> createLoan(Map<String, dynamic> loanData) async {
    final response = await _handleApiCall<dynamic>(
      () => client.post('/api/loans', body: loanData),
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return LoanModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<LoanModel> updateLoan(
    String loanId,
    Map<String, dynamic> loanData,
  ) async {
    // RESTful chuẩn sử dụng PUT để cập nhật toàn bộ hoặc một phần hợp đồng
    final response = await _handleApiCall<dynamic>(
      () => client.put('/api/loans/$loanId', body: loanData),
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return LoanModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<void> deleteLoan(String loanId, {bool softDelete = true}) async {
    await _handleApiCall<dynamic>(
      () => client.delete(
        '/api/loans/$loanId',
        body: {'soft_delete': softDelete},
      ),
    );
  }

  @override
  Future<List<CollateralModel>> getCollateralsByLoan(String loanId) async {
    return getCollaterals(loanId: loanId);
  }

  @override
  Future<List<CollateralModel>> getCollaterals({String? loanId}) async {
    final response = await _handleApiCall<dynamic>(
      () => client.get(
        '/api/collaterals',
        queryParams: loanId != null ? {'loan_id': loanId} : null,
      ),
    );
    final list = response is List
        ? response
        : (response is Map<String, dynamic>
              ? (response['data'] as List? ?? [])
              : []);

    return list
        .map(
          (item) =>
              CollateralModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<CollateralModel> addCollateral(
    Map<String, dynamic> collateralData,
  ) async {
    final response = await _handleApiCall<dynamic>(
      () => client.post('/api/collaterals', body: collateralData),
    );
    final data = response is Map<String, dynamic>
        ? (response['data'] ?? response)
        : response;
    return CollateralModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<Map<String, dynamic>> scanDocumentOcr(String imagePath) async {
    final response = await _handleApiCall<dynamic>(
      () => client.post('/api/loans/ocr-scan', body: {'image_path': imagePath}),
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
  }
}
