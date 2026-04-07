import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report.dart';
import '../../core/api/api_client.dart';

// Get list of reports with optional month filter
final getReportsProvider = FutureProvider.family<List<ReportSummary>, ({String? month, int limit})>(
  (ref, params) async {
    final apiClient = ref.watch(apiClientProvider);
    return apiClient.getReports(
      month: params.month,
      limit: params.limit,
    );
  },
);

// Get single report detail
final getReportDetailProvider = FutureProvider.family<ReportDetail, int>(
  (ref, reportId) async {
    final apiClient = ref.watch(apiClientProvider);
    return apiClient.getReportDetail(reportId);
  },
);

// Save a new report
final saveReportProvider = FutureProvider.family<int, Report>(
  (ref, report) async {
    final apiClient = ref.watch(apiClientProvider);
    return apiClient.saveReport(
      reportType: report.reportType,
      title: report.title,
      subtitle: report.subtitle,
      reportData: report.reportData,
      params: report.params,
    );
  },
);

// Delete a report
final deleteReportProvider = FutureProvider.family<void, int>(
  (ref, reportId) async {
    final apiClient = ref.watch(apiClientProvider);
    return apiClient.deleteReport(reportId);
  },
);
