// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReportSummaryImpl _$$ReportSummaryImplFromJson(Map<String, dynamic> json) =>
    _$ReportSummaryImpl(
      id: (json['id'] as num).toInt(),
      reportType: json['reportType'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$ReportSummaryImplToJson(_$ReportSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reportType': instance.reportType,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'createdAt': instance.createdAt,
    };

_$ReportDetailImpl _$$ReportDetailImplFromJson(Map<String, dynamic> json) =>
    _$ReportDetailImpl(
      id: (json['id'] as num).toInt(),
      reportType: json['reportType'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      reportData: json['reportData'] as Map<String, dynamic>,
      params: json['params'] as Map<String, dynamic>,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$ReportDetailImplToJson(_$ReportDetailImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reportType': instance.reportType,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'reportData': instance.reportData,
      'params': instance.params,
      'createdAt': instance.createdAt,
    };

_$ReportImpl _$$ReportImplFromJson(Map<String, dynamic> json) => _$ReportImpl(
  reportType: json['reportType'] as String,
  title: json['title'] as String,
  subtitle: json['subtitle'] as String?,
  reportData: json['reportData'] as Map<String, dynamic>,
  params: json['params'] as Map<String, dynamic>,
);

Map<String, dynamic> _$$ReportImplToJson(_$ReportImpl instance) =>
    <String, dynamic>{
      'reportType': instance.reportType,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'reportData': instance.reportData,
      'params': instance.params,
    };
