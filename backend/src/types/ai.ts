// AI Action types
export type ActionType = 'create' | 'update' | 'read' | 'delete';

export interface TransactionAction {
  type: ActionType;
  payload: CreatePayload | UpdatePayload | ReadPayload | DeletePayload;
  confidence: number;
}

export interface CreatePayload {
  transactionType: 'income' | 'expense';
  amount: number;
  category: string;
  memo?: string;
  date: string;  // YYYY-MM-DD
}

export interface UpdatePayload {
  id: number;
  transactionType?: 'income' | 'expense';
  amount?: number;
  category?: string;
  memo?: string;
  date?: string;
}

export interface ReadPayload {
  month?: string;  // YYYY-MM
  category?: string;
  type?: 'income' | 'expense';
}

export interface DeletePayload {
  id: number;
  reason?: string;
}

// Response types
export interface AIActionResponse {
  success: boolean;
  type?: ActionType;
  result?: any;
  message?: string;
  error?: string;
}
