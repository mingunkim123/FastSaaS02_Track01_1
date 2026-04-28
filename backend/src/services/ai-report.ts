import { eq, gte, lte, and, isNull } from 'drizzle-orm';
import type { ReportPayload, Report, ReportSection } from '../types/ai';
import { transactions } from '../db/schema';
import type { LLMConfig } from './llm';

export class AIReportService {
  constructor(_config: LLMConfig, _ai?: any) {}

  /**
   * Main method: Generate a financial report
   * 2-stage process after the chat parser has selected the report intent:
   * 1. Aggregate transaction data based on the parsed report filters
   * 2. Generate deterministic report sections from the aggregate
   * @param db - Database instance
   * @param userId - User ID to generate report for
   * @param reportPayload - Parsed report request with type and params
   * @returns Structured Report object with title and sections
   */
  async generateReport(
    db: any,
    userId: string,
    reportPayload: ReportPayload
  ): Promise<Report> {
    // Stage 1: Determine report type and filters
    const { reportType, params } = reportPayload;

    // Stage 2: Aggregate data based on params
    const transactionData = await this.aggregateTransactionData(
      db,
      userId,
      reportType,
      params
    );

    // Generate report sections from aggregated data without another LLM call.
    const reportSections = this.generateReportSections(
      reportType,
      transactionData
    );

    return {
      reportType,
      title: this.getReportTitle(reportType, params),
      subtitle: this.getReportSubtitle(reportType, params),
      sections: reportSections,
      generatedAt: new Date().toISOString(),
    };
  }

  /**
   * Aggregates transaction data for report generation
   * @param db - Database instance
   * @param userId - User ID
   * @param reportType - Type of report being generated
   * @param params - Optional filters (month, category)
   * @returns Aggregated transaction data as JSON string
   */
  private async aggregateTransactionData(
    db: any,
    userId: string,
    reportType: string,
    params?: Record<string, unknown>
  ): Promise<string> {
    // Build query filters
    const filters = [eq(transactions.userId, userId), isNull(transactions.deletedAt)];

    if (params?.month) {
      const month = params.month as string;
      const [year, monthNum] = month.split('-');
      const startDate = `${year}-${monthNum}-01`;
      const endDate = new Date(parseInt(year), parseInt(monthNum), 1);
      endDate.setDate(endDate.getDate() - 1);
      const endDateStr = endDate.toISOString().split('T')[0];

      filters.push(gte(transactions.date, startDate));
      filters.push(lte(transactions.date, endDateStr));
    }

    if (params?.category) {
      filters.push(eq(transactions.category, params.category as string));
    }

    // Fetch transactions
    const txns = await db
      .select()
      .from(transactions)
      .where(and(...filters))
      .all();

    // Aggregate by type and category
    const aggregated = {
      totalIncome: 0,
      totalExpense: 0,
      byCategory: {} as Record<string, { income: number; expense: number }>,
      transactionCount: txns.length,
      dateRange: params?.month || 'all time',
    };

    txns.forEach((txn: any) => {
      if (txn.type === 'income') aggregated.totalIncome += txn.amount;
      else aggregated.totalExpense += txn.amount;

      if (!aggregated.byCategory[txn.category]) {
        aggregated.byCategory[txn.category] = { income: 0, expense: 0 };
      }
      if (txn.type === 'income') aggregated.byCategory[txn.category].income += txn.amount;
      else aggregated.byCategory[txn.category].expense += txn.amount;
    });

    return JSON.stringify(aggregated);
  }

  private generateReportSections(
    reportType: string,
    transactionData: string
  ): ReportSection[] {
    const data = JSON.parse(transactionData) as {
      totalIncome: number;
      totalExpense: number;
      byCategory: Record<string, { income: number; expense: number }>;
      transactionCount: number;
      dateRange: string;
    };

    const expenseByCategory = Object.entries(data.byCategory)
      .map(([category, totals]) => ({ category, amount: totals.expense }))
      .filter((item) => item.amount > 0)
      .sort((a, b) => b.amount - a.amount);

    const labels = expenseByCategory.map((item) => item.category);
    const values = expenseByCategory.map((item) => item.amount);
    const net = data.totalIncome - data.totalExpense;
    const topCategory = expenseByCategory[0];

    const sections: ReportSection[] = [
      {
        type: 'card',
        title: '총 지출',
        subtitle: `${data.dateRange} 기준`,
        metric: this.formatAmount(data.totalExpense),
        trend: 'stable',
        data: { value: data.totalExpense, transactionCount: data.transactionCount },
      },
      {
        type: 'pie',
        title: '카테고리별 지출',
        data: {
          labels: labels.length > 0 ? labels : ['데이터 없음'],
          values: values.length > 0 ? values : [0],
        },
      },
      {
        type: 'bar',
        title: '수입/지출 비교',
        data: { labels: ['수입', '지출'], values: [data.totalIncome, data.totalExpense] },
      },
      {
        type: 'line',
        title: '순현금흐름',
        data: { labels: [String(data.dateRange)], values: [net] },
      },
      {
        type: 'alert',
        title: '상태 점검',
        data: { message: this.buildAlert(data.totalIncome, data.totalExpense, data.transactionCount) },
      },
    ];

    sections.push({
      type: 'suggestion',
      title: this.getSuggestionTitle(reportType),
      data: {
        message: this.buildSuggestion(data.totalIncome, data.totalExpense, topCategory?.category),
      },
    });

    return sections;
  }

  private formatAmount(amount: number): string {
    return `₩${amount.toLocaleString('ko-KR')}`;
  }

  private getSuggestionTitle(reportType: string): string {
    if (reportType === 'anomaly') return '확인할 항목';
    if (reportType === 'suggestion') return '추천 액션';
    return '다음에 해볼 일';
  }

  private buildSuggestion(totalIncome: number, totalExpense: number, topCategory?: string): string {
    if (totalExpense === 0) {
      return '아직 지출 데이터가 적습니다. 거래를 더 기록하면 더 의미 있는 분석을 볼 수 있습니다.';
    }
    if (totalIncome > 0 && totalExpense > totalIncome) {
      return '지출이 수입을 초과했습니다. 고정비와 반복 지출을 먼저 점검해 보세요.';
    }
    if (topCategory) {
      return `${topCategory} 지출 비중이 가장 큽니다. 이번 주에는 이 카테고리 예산을 먼저 확인해 보세요.`;
    }
    return '최근 거래를 꾸준히 기록하면 소비 패턴을 더 정확하게 추적할 수 있습니다.';
  }

  private buildAlert(totalIncome: number, totalExpense: number, transactionCount: number): string {
    if (transactionCount === 0) {
      return '선택한 조건에 해당하는 거래가 없습니다.';
    }
    if (totalIncome > 0 && totalExpense > totalIncome) {
      return '지출이 수입보다 큽니다.';
    }
    return '특이한 위험 신호는 없습니다.';
  }

  /**
   * Gets report title based on type and params
   */
  private getReportTitle(reportType: string, params?: Record<string, unknown>): string {
    const titles = {
      'monthly_summary': `Monthly Summary`,
      'category_detail': `Category Analysis`,
      'spending_pattern': `Spending Pattern Analysis`,
      'anomaly': `Anomaly Detection`,
      'suggestion': `Smart Recommendations`,
    };
    return titles[reportType as keyof typeof titles] || reportType;
  }

  /**
   * Gets report subtitle based on type and params
   */
  private getReportSubtitle(reportType: string, params?: Record<string, unknown>): string | undefined {
    if (params?.month) {
      return `for ${params.month}`;
    }
    return undefined;
  }
}

export function createAIReportService(config: LLMConfig): AIReportService {
  return new AIReportService(config);
}
