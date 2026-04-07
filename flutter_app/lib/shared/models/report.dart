import 'package:freezed_annotation/freezed_annotation.dart';

part 'report.freezed.dart';
part 'report.g.dart';

@freezed
class ReportSummary with _$ReportSummary {
  const factory ReportSummary({
    required int id,
    required String reportType,
    required String title,
    String? subtitle,
    required String createdAt,
  }) = _ReportSummary;

  factory ReportSummary.fromJson(Map<String, dynamic> json) =>
      _$ReportSummaryFromJson(json);
}

@freezed
class ReportDetail with _$ReportDetail {
  const factory ReportDetail({
    required int id,
    required String reportType,
    required String title,
    String? subtitle,
    required Map<String, dynamic> reportData,
    required Map<String, dynamic> params,
    required String createdAt,
  }) = _ReportDetail;

  factory ReportDetail.fromJson(Map<String, dynamic> json) =>
      _$ReportDetailFromJson(json);
}

@freezed
class Report with _$Report {
  const factory Report({
    required String reportType,
    required String title,
    String? subtitle,
    required Map<String, dynamic> reportData,
    required Map<String, dynamic> params,
  }) = _Report;

  factory Report.fromJson(Map<String, dynamic> json) =>
      _$ReportFromJson(json);
}
