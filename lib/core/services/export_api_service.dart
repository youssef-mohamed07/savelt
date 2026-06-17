import 'api_service.dart';

class ExportApiService {
  static final ExportApiService instance = ExportApiService._internal();
  ExportApiService._internal();
  factory ExportApiService() => instance;

  final ApiService _api = ApiService();

  Future<ExportResult> exportToPdf({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }
    if (categoryId != null) {
      queryParams['category'] = categoryId;
    }

    final response = await _api.getFile('/export/pdf', queryParams: queryParams);

    if (response.isSuccess && response.fileBytes != null) {
      return ExportResult.success(
        fileBytes: response.fileBytes!,
        fileName: 'expense_report.pdf',
        mimeType: 'application/pdf',
      );
    }

    return ExportResult.failure(message: response.message ?? 'Failed to export PDF');
  }

  Future<ExportResult> exportToExcel({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }
    if (categoryId != null) {
      queryParams['category'] = categoryId;
    }

    final response = await _api.getFile('/export/excel', queryParams: queryParams);

    if (response.isSuccess && response.fileBytes != null) {
      return ExportResult.success(
        fileBytes: response.fileBytes!,
        fileName: 'expense_report.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }

    return ExportResult.failure(message: response.message ?? 'Failed to export Excel');
  }

  Future<ExportResult> exportToCsv({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }
    if (categoryId != null) {
      queryParams['category'] = categoryId;
    }

    final response = await _api.getFile('/export/csv', queryParams: queryParams);

    if (response.isSuccess && response.fileBytes != null) {
      return ExportResult.success(
        fileBytes: response.fileBytes!,
        fileName: 'expense_report.csv',
        mimeType: 'text/csv',
      );
    }

    return ExportResult.failure(message: response.message ?? 'Failed to export CSV');
  }

  Future<ApiResponse> getExportHistory() async {
    final response = await _api.get('/export/history');
    return response;
  }

  Future<ApiResponse> deleteExport(String exportId) async {
    final response = await _api.delete('/export/$exportId');
    return response;
  }
}

class ExportResult {
  final bool isSuccess;
  final List<int>? fileBytes;
  final String? fileName;
  final String? mimeType;
  final String? message;

  ExportResult._({
    required this.isSuccess,
    this.fileBytes,
    this.fileName,
    this.mimeType,
    this.message,
  });

  factory ExportResult.success({
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  }) {
    return ExportResult._(
      isSuccess: true,
      fileBytes: fileBytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  factory ExportResult.failure({required String message}) {
    return ExportResult._(
      isSuccess: false,
      message: message,
    );
  }
}