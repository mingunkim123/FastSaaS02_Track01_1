# Chat Clarification Feature Design

**Date:** 2026-04-07  
**Status:** Approved  
**Goal:** Enable in-chat clarification questions when user input is ambiguous (missing category, amount, etc.)

---

## Overview

When users provide incomplete or ambiguous transaction data (e.g., "커피" without amount or category), the AI assistant asks clarifying questions **directly in the chat interface** rather than rejecting the input or silently guessing. Users answer in chat, and transactions are created immediately once sufficient information is gathered.

**Core principle:** Pure chat conversation flow with no separate UI components.

---

## User Flow

### Example: Ambiguous Input
```
User Message: "커피"
↓
AI detects low confidence (< 70%)
↓
AI asks in chat: "커피를 찾았어요! 얼마를 썼나요?"
↓
User responds: "5000"
↓
[Transaction created: Expense, Food, ₩5,000, today]
↓
AI confirms in chat: "비용 ₩5,000, 음식으로 기록했어요. (오늘)"
```

### Multi-Step Clarification
If multiple fields are missing or ambiguous:

```
User: "음식 샀어"
↓
AI: "음식 구매를 기록할게요. 얼마를 썼나요?"
↓
User: "15000"
↓
[Check again: category needs confirmation]
↓
AI: "₩15,000이 맞나요? 어떤 카테고리인가요? (음식, 교통, 쇼핑, 엔터테인먼트, 유틸리티, 의료, 일, 기타)"
↓
User: "음식"
↓
[Transaction created: Expense, Food, ₩15,000, today]
↓
AI: "비용 ₩15,000, 음식으로 기록했어요. (오늘)"
```

---

## Technical Architecture

### 1. AI Response Format

Update `SYSTEM_PROMPT` to recognize a new action type: `clarify`

**New Response Schema:**
```json
{
  "type": "clarify",
  "payload": {
    "message": "커피를 찾았어요! 얼마를 썼나요?",
    "missingFields": ["amount"],
    "partialData": {
      "transactionType": "expense",
      "category": "food",
      "memo": "커피"
    },
    "confidence": 0.65
  }
}
```

**When to return `clarify`:**
- Confidence score < 70%
- User input is missing critical fields (amount, category, transaction type)
- User input is ambiguous (could be multiple categories)

### 2. Chat State Management

Track ongoing clarifications at the **session level** using a new field in the database:

**New table: `clarification_sessions`**
```sql
CREATE TABLE clarification_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  chat_session_id TEXT NOT NULL,
  state JSON NOT NULL, -- { missingFields: [], partialData: {}, messageId: }
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (chat_session_id) REFERENCES sessions(id)
);
```

**State structure:**
```typescript
interface ClarificationState {
  missingFields: string[]; // ['amount', 'category']
  partialData: Partial<Transaction>; // { transactionType, category, memo, ... }
  messageId: string; // AI's clarification message ID for reference
}
```

### 3. Backend Logic Flow

**Endpoint:** `POST /api/ai/action` (existing, modified)

**Flow:**
1. User sends message
2. AI processes and returns response (could be `clarify`, `create`, `plain_text`, etc.)
3. **If `clarify`:**
   - Save clarification state to `clarification_sessions`
   - Add AI message to chat (with `actionType: 'clarify'`)
   - Wait for user's next message
4. **If user's next message replies to clarification:**
   - Merge user's answer with `partialData`
   - Re-evaluate confidence
   - If still ambiguous, ask another clarification
   - If confident enough (≥ 70%), proceed with transaction creation
5. **Transaction created:**
   - Save to `transactions` table
   - Delete clarification session
   - Add confirmation message to chat

### 4. Frontend (Flutter) Changes

**Minimal changes — leverage existing chat UI:**

- **ChatMessage widget:** Add support for `actionType: 'clarify'` (display as normal AI message)
- **Message input:** No changes (user replies in chat normally)
- **Message parsing:** When processing responses, check for clarification state in `MessageProvider`

**New logic in `message_provider.dart`:**
```dart
// After user sends message, check if it's a reply to a clarification
// If so, the backend will merge with partialData and process
// No explicit UI changes needed — conversation flows naturally
```

---

## Implementation Plan Outline

### Phase 1: Backend Setup
- [ ] Add `clarification_sessions` table and migration
- [ ] Update `SYSTEM_PROMPT` to support `clarify` action type
- [ ] Implement clarification state management in `messages.ts` or new `clarifications.ts` service

### Phase 2: AI Integration
- [ ] Modify AI response handler in `/api/ai/action` to recognize and store `clarify` responses
- [ ] Implement clarification merging logic (combine user's answer with `partialData`)

### Phase 3: Frontend Integration
- [ ] Update `MessageProvider` to handle clarification flow
- [ ] Test end-to-end in Flutter app

### Phase 4: Testing
- [ ] Write tests for clarification state management
- [ ] Write tests for multi-step clarification scenarios
- [ ] Test edge cases (user changes their mind, timeout handling)

---

## Data Flow Diagram

```
┌──────────────┐
│ User Message │ "커피"
└──────┬───────┘
       │
       ▼
┌──────────────────────────┐
│ AI Processing            │
│ - Extract data           │
│ - Calculate confidence   │
└──────┬───────────────────┘
       │
       ├─ Confidence ≥ 70%?
       │
       ├─ YES: Return `create`
       │  └─► [Transaction created]
       │      └─► AI: "비용 ₩15,000, 음식으로..."
       │
       └─ NO: Return `clarify`
          └─► Save clarification_sessions
              └─► AI: "얼마를 썼나요?"
                  └─ User replies in chat
                     └─ Merge with partialData
                        └─ Re-evaluate confidence
                           └─ Either ask more or create transaction
```

---

## Error Handling & Edge Cases

**Case 1: User cancels mid-clarification**
- User says "never mind" → Delete clarification_sessions entry
- Continue normal chat conversation

**Case 2: Clarification timeout**
- If > 5 minutes without user response, auto-clear clarification state
- Next user message treated as new input

**Case 3: User provides conflicting info**
- Example: "Actually, it was ₩20,000, not 5000"
- Accept the latest info and re-process

**Case 4: Multiple concurrent clarifications**
- Only one active clarification per session (no parallel clarifications)
- If new ambiguous input arrives, clear previous and start fresh

---

## Success Criteria

- ✅ Users with ambiguous input get helpful clarifying questions in chat
- ✅ No separate UI components required (pure chat flow)
- ✅ Transactions created immediately after clarification complete
- ✅ Conversation feels natural (AI asks, user answers, AI confirms)
- ✅ Confidence threshold (70%) prevents over-asking for confident cases
- ✅ Multi-step clarifications work smoothly (asking multiple questions)

---

## Future Enhancements

- Pattern learning: Remember user's typical categories and amounts for faster inference
- Smart defaults: "Last time you spent on coffee, it was ₩5,000. Same amount?"
- Undo within time window: "Oops, that was actually ₩6,000"
