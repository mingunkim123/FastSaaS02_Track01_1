# Report 저장 & 조회 기능 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Users can save AI-generated reports from Chat and view them in a dedicated Stats tab.

**Architecture:** Backend adds a `reports` table with REST API endpoints; Flutter creates a Report detail page (opened from Chat or Stats) and adds a "저장됨" tab to Stats with list view. Data flows: Chat → AI generates report → Report detail page → User saves → GET /api/reports → Stats displays.

**Tech Stack:** Hono.js + Drizzle ORM (backend), Riverpod + Dio (Flutter), SQLite (Cloudflare D1).

---

## File Structure

### Backend Files
- **`backend/src/db/schema.ts`** — Add `reports` table schema
- **`backend/src/services/reports.ts`** — CRUD logic for reports (new file)
- **`backend/src/routes/reports.ts`** — REST API endpoints (new file)

### Flutter Files
- **`flutter_app/lib/shared/models/report.dart`** — Report data models (new file)
- **`flutter_app/lib/shared/providers/report_provider.dart`** — Riverpod providers (new file)
- **`flutter_app/lib/features/reports/report_detail_page.dart`** — Report detail view (new file)
- **`flutter_app/lib/features/reports/report_list_item.dart`** — Report list item widget (new file)
- **`flutter_app/lib/features/stats/stats_page.dart`** — Add "저장됨" tab (modify existing)
- **`flutter_app/lib/core/api/api_client.dart`** — Add report methods (modify existing)
- **`flutter_app/lib/routes/app_router.dart`** — Add report detail route (modify existing)

---

## Backend Implementation

### Task 1: Add Reports Table Schema

**Files:**
- Modify: `backend/src/db/schema.ts`

- [ ] **Step 1: Read current schema structure**

Read the existing `schema.ts` to understand table patterns.

Run: `head -50 backend/src/db/schema.ts`

Expected: See imports and existing table definitions using `sqliteTable()`.

- [ ] **Step 2: Add reports table definition**

```typescript
export const reports = sqliteTable('reports', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  userId: text('user_id').notNull().references(() => users.id),
  reportType: text('report_type', {
    enum: ['monthly_summary', 'category_detail', 'spending_pattern', 'anomaly', 'suggestion']
  }).notNull(),
  title: text('title').notNull(),
  subtitle: text('subtitle'),
  reportData: text('report_data').notNull(), // JSON string
  params: text('params').notNull(), // JSON string
  createdAt: text('created_at').default(sql`(datetime('now'))`),
  updatedAt: text('updated_at').default(sql`(datetime('now'))`),
});

export type Report = typeof reports.$inferSelect;
export type NewReport = typeof reports.$inferInsert;
```

Add this after the last existing table definition in `schema.ts`.

- [ ] **Step 3: Verify syntax**

Run: `cd backend && npm run build`

Expected: No TypeScript errors related to schema.

- [ ] **Step 4: Commit**

```bash
cd backend
git add src/db/schema.ts
git commit -m "schema: add reports table for persisting ai-generated reports"
```

---

### Task 2: Create Reports Service

**Files:**
- Create: `backend/src/services/reports.ts`

- [ ] **Step 1: Create service file with types**

```typescript
import { db as drizzleDb } from '../db/index';
import { reports } from '../db/schema';
import type { Report, NewReport } from '../db/schema';
import { eq, desc, and, isNull } from 'drizzle-orm';

export interface SaveReportInput {
  reportType: string;
  title: string;
  subtitle?: string;
  reportData: Record<string, unknown>;
  params: Record<string, unknown>;
}

export interface ReportSummary {
  id: number;
  reportType: string;
  title: string;
  subtitle?: string;
  createdAt: string;
}

export class ReportService {
  constructor(private db: any) {}

  async saveReport(userId: string, input: SaveReportInput): Promise<Report> {
    const result = await this.db
      .insert(reports)
      .values({
        userId,
        reportType: input.reportType,
        title: input.title,
        subtitle: input.subtitle || null,
        reportData: JSON.stringify(input.reportData),
        params: JSON.stringify(input.params),
      })
      .returning();

    return result[0];
  }

  async getReports(userId: string, month?: string, limit: number = 50): Promise<ReportSummary[]> {
    let query = this.db
      .select({
        id: reports.id,
        reportType: reports.reportType,
        title: reports.title,
        subtitle: reports.subtitle,
        createdAt: reports.createdAt,
      })
      .from(reports)
      .where(eq(reports.userId, userId))
      .orderBy(desc(reports.createdAt))
      .limit(limit);

    if (month) {
      // Filter by month (YYYY-MM format)
      query = query.where(
        and(
          eq(reports.userId, userId),
          sql`${reports.createdAt} LIKE ${month}%`
        )
      );
    }

    return query;
  }

  async getReportDetail(userId: string, reportId: number): Promise<Report | null> {
    const result = await this.db
      .select()
      .from(reports)
      .where(and(
        eq(reports.id, reportId),
        eq(reports.userId, userId)
      ));

    return result[0] || null;
  }

  async deleteReport(userId: string, reportId: number): Promise<boolean> {
    const result = await this.db
      .delete(reports)
      .where(and(
        eq(reports.id, reportId),
        eq(reports.userId, userId)
      ));

    return result.changes > 0;
  }
}
```

Create `backend/src/services/reports.ts` with the above content.

- [ ] **Step 2: Add sql import**

At the top of `reports.ts`, add:
```typescript
import { sql } from 'drizzle-orm';
```

- [ ] **Step 3: Verify TypeScript compiles**

Run: `cd backend && npm run build`

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
cd backend
git add src/services/reports.ts
git commit -m "feat: add reports service with save, list, detail, and delete operations"
```

---

### Task 3: Create Reports API Routes

**Files:**
- Create: `backend/src/routes/reports.ts`

- [ ] **Step 1: Create routes file**

```typescript
import { Hono } from 'hono';
import { ZodError } from 'zod';
import { z } from 'zod';
import { getDb, Env } from '../db/index';
import type { Variables } from '../middleware/auth';
import { ReportService } from '../services/reports';

const router = new Hono<{ Bindings: Env; Variables: Variables }>();

// Validation schema for save report
const SaveReportSchema = z.object({
  reportType: z.enum(['monthly_summary', 'category_detail', 'spending_pattern', 'anomaly', 'suggestion']),
  title: z.string().min(1).max(200),
  subtitle: z.string().max(100).optional(),
  reportData: z.record(z.unknown()),
  params: z.record(z.unknown()),
});

type SaveReportPayload = z.infer<typeof SaveReportSchema>;

// POST /api/reports - Save a report
router.post('/', async (c) => {
  try {
    const userId = c.get('userId');
    const body = await c.req.json();

    const payload = SaveReportSchema.parse(body);

    const db = getDb(c.env);
    const reportService = new ReportService(db);

    const report = await reportService.saveReport(userId, payload);

    return c.json({
      success: true,
      id: report.id,
      createdAt: report.createdAt,
    }, 201);
  } catch (error) {
    console.error('[Reports API] Save error:', error);

    if (error instanceof ZodError) {
      return c.json(
        { success: false, error: 'Invalid report data', details: error.errors },
        400
      );
    }

    return c.json(
      { success: false, error: 'Failed to save report' },
      500
    );
  }
});

// GET /api/reports - List reports
router.get('/', async (c) => {
  try {
    const userId = c.get('userId');
    const month = c.req.query('month');
    const limitStr = c.req.query('limit') || '50';
    const limit = Math.min(parseInt(limitStr), 100);

    const db = getDb(c.env);
    const reportService = new ReportService(db);

    const reportsList = await reportService.getReports(userId, month, limit);

    return c.json({
      success: true,
      reports: reportsList,
    });
  } catch (error) {
    console.error('[Reports API] List error:', error);
    return c.json(
      { success: false, error: 'Failed to fetch reports' },
      500
    );
  }
});

// GET /api/reports/:id - Get report detail
router.get('/:id', async (c) => {
  try {
    const userId = c.get('userId');
    const reportId = parseInt(c.req.param('id'));

    if (isNaN(reportId)) {
      return c.json(
        { success: false, error: 'Invalid report ID' },
        400
      );
    }

    const db = getDb(c.env);
    const reportService = new ReportService(db);

    const report = await reportService.getReportDetail(userId, reportId);

    if (!report) {
      return c.json(
        { success: false, error: 'Report not found' },
        404
      );
    }

    return c.json({
      success: true,
      report: {
        id: report.id,
        reportType: report.reportType,
        title: report.title,
        subtitle: report.subtitle,
        reportData: JSON.parse(report.reportData),
        params: JSON.parse(report.params),
        createdAt: report.createdAt,
      },
    });
  } catch (error) {
    console.error('[Reports API] Detail error:', error);
    return c.json(
      { success: false, error: 'Failed to fetch report' },
      500
    );
  }
});

// DELETE /api/reports/:id - Delete report
router.delete('/:id', async (c) => {
  try {
    const userId = c.get('userId');
    const reportId = parseInt(c.req.param('id'));

    if (isNaN(reportId)) {
      return c.json(
        { success: false, error: 'Invalid report ID' },
        400
      );
    }

    const db = getDb(c.env);
    const reportService = new ReportService(db);

    const deleted = await reportService.deleteReport(userId, reportId);

    if (!deleted) {
      return c.json(
        { success: false, error: 'Report not found' },
        404
      );
    }

    return c.json({
      success: true,
      message: 'Report deleted',
    });
  } catch (error) {
    console.error('[Reports API] Delete error:', error);
    return c.json(
      { success: false, error: 'Failed to delete report' },
      500
    );
  }
});

export default router;
```

Create `backend/src/routes/reports.ts` with the above content.

- [ ] **Step 2: Register routes in main app**

Open `backend/src/index.ts` and find where other routes are imported (look for `import aiRouter from './routes/ai'`).

Add this import:
```typescript
import reportsRouter from './routes/reports';
```

Find where routes are registered (look for `app.route('/api/ai', aiRouter)`).

Add this line after the ai route:
```typescript
app.route('/api/reports', reportsRouter);
```

- [ ] **Step 3: Verify routes load**

Run: `cd backend && npm run build`

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
cd backend
git add src/routes/reports.ts src/index.ts
git commit -m "feat: add reports REST API endpoints (save, list, detail, delete)"
```

---

## Flutter Implementation

### Task 4: Create Report Models

**Files:**
- Create: `flutter_app/lib/shared/models/report.dart`

- [ ] **Step 1: Create models file**

```dart
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
```

Create `flutter_app/lib/shared/models/report.dart` with the above content.

- [ ] **Step 2: Generate freezed code**

Run: `cd flutter_app && flutter pub run build_runner build --delete-conflicting-outputs`

Expected: `report.freezed.dart` and `report.g.dart` are generated without errors.

- [ ] **Step 3: Commit**

```bash
cd flutter_app
git add lib/shared/models/report.dart
git commit -m "feat: add report data models (ReportSummary, ReportDetail, Report)"
```

---

### Task 5: Add Report Methods to API Client

**Files:**
- Modify: `flutter_app/lib/core/api/api_client.dart`

- [ ] **Step 1: Read current api_client.dart**

Run: `head -100 flutter_app/lib/core/api/api_client.dart`

Expected: See existing methods like `createTransaction()`, understand parameter and return patterns.

- [ ] **Step 2: Add report methods**

Find the last method in the `ApiClient` class. Add these methods before the closing brace:

```dart
  /// Save a report
  Future<int> saveReport({
    required String reportType,
    required String title,
    String? subtitle,
    required Map<String, dynamic> reportData,
    required Map<String, dynamic> params,
  }) async {
    final response = await _dio.post(
      '/api/reports',
      data: {
        'reportType': reportType,
        'title': title,
        'subtitle': subtitle,
        'reportData': reportData,
        'params': params,
      },
    );

    if (response.statusCode != 201) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Failed to save report',
      );
    }

    return response.data['id'] as int;
  }

  /// Get list of reports
  Future<List<ReportSummary>> getReports({
    String? month,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/reports',
      queryParameters: {
        if (month != null) 'month': month,
        'limit': limit,
      },
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Failed to fetch reports',
      );
    }

    final reports = (response.data['reports'] as List)
        .map((r) => ReportSummary.fromJson(r as Map<String, dynamic>))
        .toList();

    return reports;
  }

  /// Get report detail
  Future<ReportDetail> getReportDetail(int reportId) async {
    final response = await _dio.get('/api/reports/$reportId');

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Failed to fetch report',
      );
    }

    return ReportDetail.fromJson(response.data['report'] as Map<String, dynamic>);
  }

  /// Delete a report
  Future<void> deleteReport(int reportId) async {
    final response = await _dio.delete('/api/reports/$reportId');

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Failed to delete report',
      );
    }
  }
```

- [ ] **Step 3: Add imports**

At the top of `api_client.dart`, add:
```dart
import '../models/report.dart';
```

- [ ] **Step 4: Verify imports resolve**

Run: `cd flutter_app && flutter analyze lib/core/api/api_client.dart`

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
cd flutter_app
git add lib/core/api/api_client.dart
git commit -m "feat: add saveReport, getReports, getReportDetail, deleteReport methods to API client"
```

---

### Task 6: Create Report Providers

**Files:**
- Create: `flutter_app/lib/shared/providers/report_provider.dart`

- [ ] **Step 1: Create providers file**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report.dart';
import '../../core/api/api_client.dart';

// Get API client provider
final apiClientProvider = Provider((ref) => ApiClient());

// Get list of saved reports
final getReportsProvider = FutureProvider.family<List<ReportSummary>, ({String? month, int limit})>((ref, params) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getReports(month: params.month, limit: params.limit);
});

// Get report detail
final getReportDetailProvider = FutureProvider.family<ReportDetail, int>((ref, reportId) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getReportDetail(reportId);
});

// Save report
final saveReportProvider = FutureProvider.family<int, Report>((ref, report) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.saveReport(
    reportType: report.reportType,
    title: report.title,
    subtitle: report.subtitle,
    reportData: report.reportData,
    params: report.params,
  );
});

// Delete report
final deleteReportProvider = FutureProvider.family<void, int>((ref, reportId) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.deleteReport(reportId);
});
```

Create `flutter_app/lib/shared/providers/report_provider.dart` with the above content.

- [ ] **Step 2: Verify syntax**

Run: `cd flutter_app && flutter analyze lib/shared/providers/report_provider.dart`

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd flutter_app
git add lib/shared/providers/report_provider.dart
git commit -m "feat: add riverpod providers for report operations (get, save, delete)"
```

---

### Task 7: Create Report List Item Widget

**Files:**
- Create: `flutter_app/lib/features/reports/report_list_item.dart`

- [ ] **Step 1: Create widget file**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/report.dart';
import '../../theme/app_theme.dart';

class ReportListItem extends StatelessWidget {
  final ReportSummary report;

  const ReportListItem({
    Key? key,
    required this.report,
  }) : super(key: key);

  String _formatDate(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }

  String _getReportTypeLabel(String reportType) {
    switch (reportType) {
      case 'monthly_summary':
        return '월간 요약';
      case 'category_detail':
        return '카테고리 분석';
      case 'spending_pattern':
        return '지출 패턴';
      case 'anomaly':
        return '이상 탐지';
      case 'suggestion':
        return '제안';
      default:
        return reportType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(report.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.subtitle != null && report.subtitle!.isNotEmpty)
            Text(report.subtitle!, style: const TextStyle(fontSize: 12)),
          SizedBox(height: 4),
          Text(
            '${_getReportTypeLabel(report.reportType)} • ${_formatDate(report.createdAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.primaryColor),
      onTap: () {
        context.push('/report/${report.id}');
      },
    );
  }
}
```

Create `flutter_app/lib/features/reports/report_list_item.dart` with the above content.

- [ ] **Step 2: Verify widget compiles**

Run: `cd flutter_app && flutter analyze lib/features/reports/report_list_item.dart`

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd flutter_app
git add lib/features/reports/report_list_item.dart
git commit -m "feat: add report list item widget with formatted display"
```

---

### Task 8: Create Report Detail Page

**Files:**
- Create: `flutter_app/lib/features/reports/report_detail_page.dart`

- [ ] **Step 1: Create report detail page**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/report.dart';
import '../../shared/providers/report_provider.dart';
import '../../theme/app_theme.dart';
import '../chat/report_card.dart'; // Assumes report rendering widget exists

class ReportDetailPage extends ConsumerStatefulWidget {
  final int reportId;
  final bool isFromStats; // true if opened from Stats, false if from Chat

  const ReportDetailPage({
    Key? key,
    required this.reportId,
    this.isFromStats = false,
  }) : super(key: key);

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  bool _isSaving = false;
  bool _isDeleting = false;

  Future<void> _handleSaveReport(ReportDetail report) async {
    setState(() => _isSaving = true);

    try {
      final reportData = Report(
        reportType: report.reportType,
        title: report.title,
        subtitle: report.subtitle,
        reportData: report.reportData,
        params: report.params,
      );

      final id = await ref.read(saveReportProvider(reportData).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리포트가 저장되었습니다')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleDeleteReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('리포트 삭제'),
        content: Text('이 리포트를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('삭제', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      await ref.read(deleteReportProvider(widget.reportId).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리포트가 삭제되었습니다')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(getReportDetailProvider(widget.reportId));

    return Scaffold(
      appBar: AppBar(
        title: Text('리포트 상세'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: reportAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('리포트를 불러올 수 없습니다'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(getReportDetailProvider(widget.reportId));
                },
                child: Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (report) => SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (report.subtitle != null && report.subtitle!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          report.subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(),
              Padding(
                padding: EdgeInsets.all(16),
                child: ReportCard(reportData: report.reportData),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: reportAsync.whenData((report) {
        if (widget.isFromStats) {
          // Stats mode: Show delete and regenerate buttons
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.delete_outline),
                    label: Text('삭제'),
                    onPressed: _isDeleting ? null : _handleDeleteReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Chat mode: Show save button
          return Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _handleSaveReport(report),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('저장하기'),
              ),
            ),
          );
        }
      }).data ?? SizedBox.shrink(),
    );
  }
}
```

Create `flutter_app/lib/features/reports/report_detail_page.dart` with the above content.

- [ ] **Step 2: Verify compilation**

Run: `cd flutter_app && flutter analyze lib/features/reports/report_detail_page.dart`

Expected: No errors (ignore any missing ReportCard import warning for now).

- [ ] **Step 3: Commit**

```bash
cd flutter_app
git add lib/features/reports/report_detail_page.dart
git commit -m "feat: add report detail page with save (Chat) and delete (Stats) modes"
```

---

### Task 9: Add Report Route to App Router

**Files:**
- Modify: `flutter_app/lib/routes/app_router.dart`

- [ ] **Step 1: Read current router structure**

Run: `grep -n "GoRoute\|path:" flutter_app/lib/routes/app_router.dart | head -20`

Expected: See route definitions with `path:` and `builder:` patterns.

- [ ] **Step 2: Add report detail route**

Find the `routes: [` array in the `GoRouter` definition. Add this route before the closing bracket of the routes array:

```dart
GoRoute(
  path: '/report/:id',
  builder: (context, state) {
    final id = int.parse(state.pathParameters['id']!);
    final isFromStats = state.extra as bool? ?? false;
    return ReportDetailPage(reportId: id, isFromStats: isFromStats);
  },
),
```

- [ ] **Step 3: Add import**

At the top of `app_router.dart`, add:
```dart
import '../features/reports/report_detail_page.dart';
```

- [ ] **Step 4: Verify router compiles**

Run: `cd flutter_app && flutter analyze lib/routes/app_router.dart`

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
cd flutter_app
git add lib/routes/app_router.dart
git commit -m "feat: add report detail page route to app router"
```

---

### Task 10: Add "저장됨" Tab to Stats Page

**Files:**
- Modify: `flutter_app/lib/features/stats/stats_page.dart`

- [ ] **Step 1: Read current stats page**

Run: `head -100 flutter_app/lib/features/stats/stats_page.dart`

Expected: See existing page structure with tabs or similar navigation.

- [ ] **Step 2: Add SavedReportsTab widget**

Before the `StatsPage` class, add this widget:

```dart
class SavedReportsTab extends ConsumerWidget {
  const SavedReportsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(
      getReportsProvider((month: null, limit: 50)),
    );

    return reportsAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('리포트를 불러올 수 없습니다'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ref.refresh(getReportsProvider((month: null, limit: 50)));
              },
              child: Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '저장된 리포트가 없습니다',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Text(
                  'Chat에서 리포트를 생성하고 저장해보세요.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            return ReportListItem(report: reports[index]);
          },
        );
      },
    );
  }
}
```

- [ ] **Step 3: Add tab to TabBar**

Find the existing `TabBar` or tab structure in the `StatsPage`. Add a new tab for "저장됨":

If using `TabBar` with `Tab`:
```dart
Tab(text: '저장됨'),
```

If using custom tab buttons, add similar button/segment for saved reports.

- [ ] **Step 4: Add SavedReportsTab to TabBarView**

Find the `TabBarView` or equivalent content area. Add this as a new tab:

```dart
SavedReportsTab(),
```

This should correspond to the "저장됨" tab position.

- [ ] **Step 5: Add imports**

At the top of `stats_page.dart`, add:
```dart
import '../../shared/models/report.dart';
import '../../shared/providers/report_provider.dart';
import './report_list_item.dart';
```

Wait, `ReportListItem` was created in reports folder, so adjust import:
```dart
import '../reports/report_list_item.dart';
```

- [ ] **Step 6: Verify page compiles**

Run: `cd flutter_app && flutter analyze lib/features/stats/stats_page.dart`

Expected: No errors.

- [ ] **Step 7: Commit**

```bash
cd flutter_app
git add lib/features/stats/stats_page.dart
git commit -m "feat: add saved reports tab to stats page with list view"
```

---

## Testing Checklist

### Backend Testing

- [ ] **API: Save Report**
  - Manual test: POST to `/api/reports` with valid payload
  - Expected: 201 Created with `id` and `createdAt`
  - Expected payload:
    ```json
    {
      "reportType": "monthly_summary",
      "title": "April 2026 Summary",
      "subtitle": "April 2026",
      "reportData": {...},
      "params": {"month": "2026-04"}
    }
    ```

- [ ] **API: List Reports**
  - Manual test: GET `/api/reports`
  - Expected: 200 with array of ReportSummary objects
  - Test with `?month=2026-04` filter
  - Test with `?limit=10` parameter

- [ ] **API: Get Report Detail**
  - Manual test: GET `/api/reports/1` (use ID from save test)
  - Expected: 200 with full ReportDetail including parsed reportData and params
  - Test with invalid ID: Expected 404

- [ ] **API: Delete Report**
  - Manual test: DELETE `/api/reports/1`
  - Expected: 200 with success message
  - Verify report no longer appears in list
  - Test with invalid ID: Expected 404

### Flutter Testing

- [ ] **Report Models**
  - Run code generation: `flutter pub run build_runner build`
  - Expected: No errors, `.freezed.dart` and `.g.dart` files generated

- [ ] **API Client Methods**
  - Test `saveReport()` integration with actual backend
  - Test `getReports()` returns List<ReportSummary>
  - Test `getReportDetail()` returns full ReportDetail
  - Test `deleteReport()` successfully deletes

- [ ] **Report List Item Widget**
  - Render with sample ReportSummary
  - Verify tap navigation to detail page
  - Verify date and type label formatting

- [ ] **Report Detail Page - Chat Mode**
  - Open from chat message
  - Verify "저장하기" button visible
  - Click save and verify success snackbar
  - Verify report appears in Stats "저장됨" tab

- [ ] **Report Detail Page - Stats Mode**
  - Open from Stats list
  - Verify "삭제" button visible
  - Click delete and verify confirmation dialog
  - Verify report removed after confirmation

- [ ] **Stats Page - 저장됨 Tab**
  - Verify tab appears in stats page
  - Verify empty state shows when no reports
  - Verify list shows saved reports with correct order (newest first)
  - Verify loading state while fetching
  - Verify error state with retry button

---

## Spec Coverage Verification

| Spec Section | Implementation Task | Status |
|--------------|-------------------|--------|
| Database Schema | Task 1: Add reports table | ✓ |
| POST /api/reports | Task 3: Reports routes (POST handler) | ✓ |
| GET /api/reports | Task 3: Reports routes (GET list handler) | ✓ |
| GET /api/reports/:id | Task 3: Reports routes (GET detail handler) | ✓ |
| DELETE /api/reports/:id | Task 3: Reports routes (DELETE handler) | ✓ |
| Flutter Report Models | Task 4: Report models | ✓ |
| API Client Methods | Task 5: API client methods | ✓ |
| Report Providers | Task 6: Riverpod providers | ✓ |
| Report Detail Page (Chat mode) | Task 8: Report detail page with save | ✓ |
| Report Detail Page (Stats mode) | Task 8: Report detail page with delete | ✓ |
| Report List Item | Task 7: Report list item widget | ✓ |
| Stats "저장됨" Tab | Task 10: Add saved reports tab | ✓ |
| App Router Integration | Task 9: Add report route | ✓ |

---

Plan complete and saved. Two execution options:

**1. Subagent-Driven (recommended)** - Fresh subagent per task, fast iteration with reviews between tasks

**2. Inline Execution** - Execute tasks sequentially in this session with checkpoints

Which approach?