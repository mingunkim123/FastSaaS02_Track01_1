import { clarificationSessions } from '../db/schema';
import { eq, and, lt } from 'drizzle-orm';
import crypto from 'crypto';

// Valid transaction categories (must match validation.ts)
const VALID_CATEGORIES = ['food', 'transport', 'work', 'shopping', 'entertainment', 'utilities', 'medicine', 'other'] as const;

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
   * Only one clarification can be active per user+session combination
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

    try {
      return JSON.parse(result[0].state) as ClarificationState;
    } catch (error) {
      console.error(`Failed to parse clarification state for user ${userId}, session ${chatSessionId}:`, error);
      return null;
    }
  }

  /**
   * Merge user's clarification response with partial data
   * Extracts missing fields (amount, category, transactionType) from user input
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
    const lowerResponse = userResponse.toLowerCase().trim();

    // Try to extract amount if it's missing
    if (missingFields.includes('amount')) {
      const amountMatch = lowerResponse.match(/(\d+)/);
      if (amountMatch) {
        const amount = parseInt(amountMatch[1], 10);
        // Validate amount is positive
        if (amount > 0 && amount <= 1000000000) {
          mergedData.amount = amount;
        }
      }
    }

    // Try to extract category if it's missing
    if (missingFields.includes('category')) {
      for (const cat of VALID_CATEGORIES) {
        if (lowerResponse.includes(cat)) {
          mergedData.category = cat;
          break;
        }
      }
    }

    // Try to extract transactionType if it's missing
    if (missingFields.includes('transactionType')) {
      if (lowerResponse.includes('expense') || lowerResponse.includes('지출') || lowerResponse.includes('썼')) {
        mergedData.transactionType = 'expense';
      } else if (lowerResponse.includes('income') || lowerResponse.includes('수입') || lowerResponse.includes('받')) {
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
   * Should be called periodically (e.g., every 10 minutes) to prevent stale sessions
   * Prevents users being stuck in a clarification state if they abandon the chat
   */
  async cleanupExpired(db: any): Promise<void> {
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
    await db
      .delete(clarificationSessions)
      .where(lt(clarificationSessions.createdAt, fiveMinutesAgo));
  }
}

export const clarificationService = new ClarificationService();
