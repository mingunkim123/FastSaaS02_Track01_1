import { clarificationSessions } from '../db/schema';
import { eq, and, lt } from 'drizzle-orm';
import crypto from 'crypto';

export interface ClarificationState {
  missingFields: string[];
  partialData: {
    transactionType?: 'income' | 'expense';
    amount?: number;
    category?: string;
    memo?: string;
    date?: string;
  };
  messageId: string;
}

export class ClarificationService {
  /**
   * Save a new clarification session
   */
  async saveClarification(
    db: any,
    userId: string,
    chatSessionId: number,
    state: ClarificationState
  ): Promise<string> {
    const id = crypto.randomUUID();
    await db.insert(clarificationSessions).values({
      id,
      userId,
      chatSessionId,
      state: JSON.stringify(state),
      createdAt: new Date().toISOString(),
    });
    return id;
  }

  /**
   * Get active clarification for a chat session
   */
  async getClarification(
    db: any,
    userId: string,
    chatSessionId: number
  ): Promise<ClarificationState | null> {
    const result = await db
      .select()
      .from(clarificationSessions)
      .where(
        and(
          eq(clarificationSessions.userId, userId),
          eq(clarificationSessions.chatSessionId, chatSessionId)
        )
      )
      .limit(1);

    if (result.length === 0) return null;
    return JSON.parse(result[0].state) as ClarificationState;
  }

  /**
   * Merge user's clarification response with partial data
   * Returns updated partial data and remaining missing fields
   */
  async mergeClarificationResponse(
    userResponse: string,
    currentState: ClarificationState
  ): Promise<{
    mergedData: ClarificationState['partialData'];
    stillMissingFields: string[];
  }> {
    const { missingFields, partialData } = currentState;
    const mergedData = { ...partialData };

    // Try to extract amount if it's missing
    if (missingFields.includes('amount')) {
      const amountMatch = userResponse.match(/(\d+)/);
      if (amountMatch) {
        mergedData.amount = parseInt(amountMatch[1], 10);
      }
    }

    // Try to extract category if it's missing
    if (missingFields.includes('category')) {
      const categories = ['food', 'transport', 'work', 'shopping', 'entertainment', 'utilities', 'medicine', 'other'];
      for (const cat of categories) {
        if (userResponse.toLowerCase().includes(cat)) {
          mergedData.category = cat as any;
          break;
        }
      }
    }

    // Try to extract transactionType if it's missing
    if (missingFields.includes('transactionType')) {
      if (userResponse.toLowerCase().includes('expense') || userResponse.toLowerCase().includes('지출') || userResponse.toLowerCase().includes('썼')) {
        mergedData.transactionType = 'expense';
      } else if (userResponse.toLowerCase().includes('income') || userResponse.toLowerCase().includes('수입') || userResponse.toLowerCase().includes('받')) {
        mergedData.transactionType = 'income';
      }
    }

    // Determine still-missing fields
    const stillMissing = [];
    if (missingFields.includes('amount') && !mergedData.amount) stillMissing.push('amount');
    if (missingFields.includes('category') && !mergedData.category) stillMissing.push('category');
    if (missingFields.includes('transactionType') && !mergedData.transactionType) stillMissing.push('transactionType');

    return {
      mergedData,
      stillMissingFields: stillMissing,
    };
  }

  /**
   * Delete clarification session (when done or cancelled)
   */
  async deleteClarification(db: any, userId: string, chatSessionId: number): Promise<void> {
    await db
      .delete(clarificationSessions)
      .where(
        and(
          eq(clarificationSessions.userId, userId),
          eq(clarificationSessions.chatSessionId, chatSessionId)
        )
      );
  }

  /**
   * Clean up expired clarifications (> 5 minutes old)
   */
  async cleanupExpired(db: any): Promise<void> {
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
    await db
      .delete(clarificationSessions)
      .where(lt(clarificationSessions.createdAt, fiveMinutesAgo));
  }
}

export const clarificationService = new ClarificationService();
