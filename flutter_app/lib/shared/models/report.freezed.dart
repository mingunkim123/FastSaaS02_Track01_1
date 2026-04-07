// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReportSummary _$ReportSummaryFromJson(Map<String, dynamic> json) {
  return _ReportSummary.fromJson(json);
}

/// @nodoc
mixin _$ReportSummary {
  int get id => throw _privateConstructorUsedError;
  String get reportType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get subtitle => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ReportSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReportSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReportSummaryCopyWith<ReportSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportSummaryCopyWith<$Res> {
  factory $ReportSummaryCopyWith(
    ReportSummary value,
    $Res Function(ReportSummary) then,
  ) = _$ReportSummaryCopyWithImpl<$Res, ReportSummary>;
  @useResult
  $Res call({
    int id,
    String reportType,
    String title,
    String? subtitle,
    String createdAt,
  });
}

/// @nodoc
class _$ReportSummaryCopyWithImpl<$Res, $Val extends ReportSummary>
    implements $ReportSummaryCopyWith<$Res> {
  _$ReportSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReportSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reportType = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            reportType: null == reportType
                ? _value.reportType
                : reportType // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            subtitle: freezed == subtitle
                ? _value.subtitle
                : subtitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReportSummaryImplCopyWith<$Res>
    implements $ReportSummaryCopyWith<$Res> {
  factory _$$ReportSummaryImplCopyWith(
    _$ReportSummaryImpl value,
    $Res Function(_$ReportSummaryImpl) then,
  ) = __$$ReportSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String reportType,
    String title,
    String? subtitle,
    String createdAt,
  });
}

/// @nodoc
class __$$ReportSummaryImplCopyWithImpl<$Res>
    extends _$ReportSummaryCopyWithImpl<$Res, _$ReportSummaryImpl>
    implements _$$ReportSummaryImplCopyWith<$Res> {
  __$$ReportSummaryImplCopyWithImpl(
    _$ReportSummaryImpl _value,
    $Res Function(_$ReportSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReportSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reportType = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$ReportSummaryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        reportType: null == reportType
            ? _value.reportType
            : reportType // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        subtitle: freezed == subtitle
            ? _value.subtitle
            : subtitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReportSummaryImpl implements _ReportSummary {
  const _$ReportSummaryImpl({
    required this.id,
    required this.reportType,
    required this.title,
    this.subtitle,
    required this.createdAt,
  });

  factory _$ReportSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReportSummaryImplFromJson(json);

  @override
  final int id;
  @override
  final String reportType;
  @override
  final String title;
  @override
  final String? subtitle;
  @override
  final String createdAt;

  @override
  String toString() {
    return 'ReportSummary(id: $id, reportType: $reportType, title: $title, subtitle: $subtitle, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reportType, reportType) ||
                other.reportType == reportType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, reportType, title, subtitle, createdAt);

  /// Create a copy of ReportSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportSummaryImplCopyWith<_$ReportSummaryImpl> get copyWith =>
      __$$ReportSummaryImplCopyWithImpl<_$ReportSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReportSummaryImplToJson(this);
  }
}

abstract class _ReportSummary implements ReportSummary {
  const factory _ReportSummary({
    required final int id,
    required final String reportType,
    required final String title,
    final String? subtitle,
    required final String createdAt,
  }) = _$ReportSummaryImpl;

  factory _ReportSummary.fromJson(Map<String, dynamic> json) =
      _$ReportSummaryImpl.fromJson;

  @override
  int get id;
  @override
  String get reportType;
  @override
  String get title;
  @override
  String? get subtitle;
  @override
  String get createdAt;

  /// Create a copy of ReportSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReportSummaryImplCopyWith<_$ReportSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReportDetail _$ReportDetailFromJson(Map<String, dynamic> json) {
  return _ReportDetail.fromJson(json);
}

/// @nodoc
mixin _$ReportDetail {
  int get id => throw _privateConstructorUsedError;
  String get reportType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get subtitle => throw _privateConstructorUsedError;
  Map<String, dynamic> get reportData => throw _privateConstructorUsedError;
  Map<String, dynamic> get params => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ReportDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReportDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReportDetailCopyWith<ReportDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportDetailCopyWith<$Res> {
  factory $ReportDetailCopyWith(
    ReportDetail value,
    $Res Function(ReportDetail) then,
  ) = _$ReportDetailCopyWithImpl<$Res, ReportDetail>;
  @useResult
  $Res call({
    int id,
    String reportType,
    String title,
    String? subtitle,
    Map<String, dynamic> reportData,
    Map<String, dynamic> params,
    String createdAt,
  });
}

/// @nodoc
class _$ReportDetailCopyWithImpl<$Res, $Val extends ReportDetail>
    implements $ReportDetailCopyWith<$Res> {
  _$ReportDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReportDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reportType = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? reportData = null,
    Object? params = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            reportType: null == reportType
                ? _value.reportType
                : reportType // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            subtitle: freezed == subtitle
                ? _value.subtitle
                : subtitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            reportData: null == reportData
                ? _value.reportData
                : reportData // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            params: null == params
                ? _value.params
                : params // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReportDetailImplCopyWith<$Res>
    implements $ReportDetailCopyWith<$Res> {
  factory _$$ReportDetailImplCopyWith(
    _$ReportDetailImpl value,
    $Res Function(_$ReportDetailImpl) then,
  ) = __$$ReportDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String reportType,
    String title,
    String? subtitle,
    Map<String, dynamic> reportData,
    Map<String, dynamic> params,
    String createdAt,
  });
}

/// @nodoc
class __$$ReportDetailImplCopyWithImpl<$Res>
    extends _$ReportDetailCopyWithImpl<$Res, _$ReportDetailImpl>
    implements _$$ReportDetailImplCopyWith<$Res> {
  __$$ReportDetailImplCopyWithImpl(
    _$ReportDetailImpl _value,
    $Res Function(_$ReportDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReportDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reportType = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? reportData = null,
    Object? params = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$ReportDetailImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        reportType: null == reportType
            ? _value.reportType
            : reportType // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        subtitle: freezed == subtitle
            ? _value.subtitle
            : subtitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        reportData: null == reportData
            ? _value._reportData
            : reportData // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        params: null == params
            ? _value._params
            : params // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReportDetailImpl implements _ReportDetail {
  const _$ReportDetailImpl({
    required this.id,
    required this.reportType,
    required this.title,
    this.subtitle,
    required final Map<String, dynamic> reportData,
    required final Map<String, dynamic> params,
    required this.createdAt,
  }) : _reportData = reportData,
       _params = params;

  factory _$ReportDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReportDetailImplFromJson(json);

  @override
  final int id;
  @override
  final String reportType;
  @override
  final String title;
  @override
  final String? subtitle;
  final Map<String, dynamic> _reportData;
  @override
  Map<String, dynamic> get reportData {
    if (_reportData is EqualUnmodifiableMapView) return _reportData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_reportData);
  }

  final Map<String, dynamic> _params;
  @override
  Map<String, dynamic> get params {
    if (_params is EqualUnmodifiableMapView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_params);
  }

  @override
  final String createdAt;

  @override
  String toString() {
    return 'ReportDetail(id: $id, reportType: $reportType, title: $title, subtitle: $subtitle, reportData: $reportData, params: $params, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reportType, reportType) ||
                other.reportType == reportType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            const DeepCollectionEquality().equals(
              other._reportData,
              _reportData,
            ) &&
            const DeepCollectionEquality().equals(other._params, _params) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    reportType,
    title,
    subtitle,
    const DeepCollectionEquality().hash(_reportData),
    const DeepCollectionEquality().hash(_params),
    createdAt,
  );

  /// Create a copy of ReportDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportDetailImplCopyWith<_$ReportDetailImpl> get copyWith =>
      __$$ReportDetailImplCopyWithImpl<_$ReportDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReportDetailImplToJson(this);
  }
}

abstract class _ReportDetail implements ReportDetail {
  const factory _ReportDetail({
    required final int id,
    required final String reportType,
    required final String title,
    final String? subtitle,
    required final Map<String, dynamic> reportData,
    required final Map<String, dynamic> params,
    required final String createdAt,
  }) = _$ReportDetailImpl;

  factory _ReportDetail.fromJson(Map<String, dynamic> json) =
      _$ReportDetailImpl.fromJson;

  @override
  int get id;
  @override
  String get reportType;
  @override
  String get title;
  @override
  String? get subtitle;
  @override
  Map<String, dynamic> get reportData;
  @override
  Map<String, dynamic> get params;
  @override
  String get createdAt;

  /// Create a copy of ReportDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReportDetailImplCopyWith<_$ReportDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Report _$ReportFromJson(Map<String, dynamic> json) {
  return _Report.fromJson(json);
}

/// @nodoc
mixin _$Report {
  String get reportType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get subtitle => throw _privateConstructorUsedError;
  Map<String, dynamic> get reportData => throw _privateConstructorUsedError;
  Map<String, dynamic> get params => throw _privateConstructorUsedError;

  /// Serializes this Report to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Report
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReportCopyWith<Report> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportCopyWith<$Res> {
  factory $ReportCopyWith(Report value, $Res Function(Report) then) =
      _$ReportCopyWithImpl<$Res, Report>;
  @useResult
  $Res call({
    String reportType,
    String title,
    String? subtitle,
    Map<String, dynamic> reportData,
    Map<String, dynamic> params,
  });
}

/// @nodoc
class _$ReportCopyWithImpl<$Res, $Val extends Report>
    implements $ReportCopyWith<$Res> {
  _$ReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Report
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reportType = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? reportData = null,
    Object? params = null,
  }) {
    return _then(
      _value.copyWith(
            reportType: null == reportType
                ? _value.reportType
                : reportType // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            subtitle: freezed == subtitle
                ? _value.subtitle
                : subtitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            reportData: null == reportData
                ? _value.reportData
                : reportData // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            params: null == params
                ? _value.params
                : params // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReportImplCopyWith<$Res> implements $ReportCopyWith<$Res> {
  factory _$$ReportImplCopyWith(
    _$ReportImpl value,
    $Res Function(_$ReportImpl) then,
  ) = __$$ReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String reportType,
    String title,
    String? subtitle,
    Map<String, dynamic> reportData,
    Map<String, dynamic> params,
  });
}

/// @nodoc
class __$$ReportImplCopyWithImpl<$Res>
    extends _$ReportCopyWithImpl<$Res, _$ReportImpl>
    implements _$$ReportImplCopyWith<$Res> {
  __$$ReportImplCopyWithImpl(
    _$ReportImpl _value,
    $Res Function(_$ReportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Report
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reportType = null,
    Object? title = null,
    Object? subtitle = freezed,
    Object? reportData = null,
    Object? params = null,
  }) {
    return _then(
      _$ReportImpl(
        reportType: null == reportType
            ? _value.reportType
            : reportType // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        subtitle: freezed == subtitle
            ? _value.subtitle
            : subtitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        reportData: null == reportData
            ? _value._reportData
            : reportData // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        params: null == params
            ? _value._params
            : params // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReportImpl implements _Report {
  const _$ReportImpl({
    required this.reportType,
    required this.title,
    this.subtitle,
    required final Map<String, dynamic> reportData,
    required final Map<String, dynamic> params,
  }) : _reportData = reportData,
       _params = params;

  factory _$ReportImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReportImplFromJson(json);

  @override
  final String reportType;
  @override
  final String title;
  @override
  final String? subtitle;
  final Map<String, dynamic> _reportData;
  @override
  Map<String, dynamic> get reportData {
    if (_reportData is EqualUnmodifiableMapView) return _reportData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_reportData);
  }

  final Map<String, dynamic> _params;
  @override
  Map<String, dynamic> get params {
    if (_params is EqualUnmodifiableMapView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_params);
  }

  @override
  String toString() {
    return 'Report(reportType: $reportType, title: $title, subtitle: $subtitle, reportData: $reportData, params: $params)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportImpl &&
            (identical(other.reportType, reportType) ||
                other.reportType == reportType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            const DeepCollectionEquality().equals(
              other._reportData,
              _reportData,
            ) &&
            const DeepCollectionEquality().equals(other._params, _params));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    reportType,
    title,
    subtitle,
    const DeepCollectionEquality().hash(_reportData),
    const DeepCollectionEquality().hash(_params),
  );

  /// Create a copy of Report
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportImplCopyWith<_$ReportImpl> get copyWith =>
      __$$ReportImplCopyWithImpl<_$ReportImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReportImplToJson(this);
  }
}

abstract class _Report implements Report {
  const factory _Report({
    required final String reportType,
    required final String title,
    final String? subtitle,
    required final Map<String, dynamic> reportData,
    required final Map<String, dynamic> params,
  }) = _$ReportImpl;

  factory _Report.fromJson(Map<String, dynamic> json) = _$ReportImpl.fromJson;

  @override
  String get reportType;
  @override
  String get title;
  @override
  String? get subtitle;
  @override
  Map<String, dynamic> get reportData;
  @override
  Map<String, dynamic> get params;

  /// Create a copy of Report
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReportImplCopyWith<_$ReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
