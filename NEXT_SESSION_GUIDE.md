# Next Session Guide: RAG Context Enhancement Implementation

**Date Started:** 2026-04-08  
**Status:** Design & Planning Complete → Ready for Implementation  
**Current Branch:** main

## What's Been Completed ✅

### Session 1: Chat Clarification Feature (COMPLETE)
- ✅ Feature brainstormed and designed
- ✅ Implementation plan created
- ✅ All 7 tasks implemented via subagent-driven approach
- ✅ 41/41 tests passing
- ✅ All commits merged to main
- **Commits:** 9 commits from `771c62f` to `9c353df`

### Session 2: RAG Context Enhancement (Design & Planning COMPLETE)
- ✅ Feature brainstormed and designed (interactive questions → clear requirements)
- ✅ Design spec written: `docs/superpowers/specs/2026-04-08-rag-context-enhancement-design.md`
- ✅ Implementation plan written: `docs/superpowers/plans/2026-04-08-rag-context-enhancement-implementation.md`
- ✅ All design docs committed
- **Commits:** 2 commits (`da9fd4e`, `5f9335c`)

## What's Ready to Implement 🚀

The RAG context enhancement plan includes **12 bite-sized tasks**:

1. **Database Tables** — Migration + schema (user_notes, knowledge_base)
2. **RAG Types** — Type definitions for vectorization + context
3. **VectorizeService** — Cloudflare Vectorize API wrapper
4. **UserNotesService** — User notes CRUD + vectorization
5. **ContextService** — Context orchestration + formatting
6. **User Notes Routes** — API endpoints (POST/GET/PATCH/DELETE)
7. **AI Service Integration** — Inject context into parseUserInput()
8. **AI Route Integration** — Pass context service to route handler
9. **VectorizeService Tests** — Unit tests with mocked API
10. **ContextService Tests** — Selective retrieval tests
11. **UserNotesService Tests** — CRUD + vectorization tests
12. **User Notes Routes Tests** — Endpoint tests

**All code samples included in:** `docs/superpowers/plans/2026-04-08-rag-context-enhancement-implementation.md`

## How to Execute in Next Session

### Option A: Subagent-Driven (Recommended)
```bash
# In next session:
1. Open the plan: docs/superpowers/plans/2026-04-08-rag-context-enhancement-implementation.md
2. Use /superpowers:subagent-driven-development skill
3. System will:
   - Extract all 12 tasks
   - Dispatch fresh subagent per task
   - Two-stage review (spec compliance + code quality)
   - Manage review loops automatically
```

### Option B: Inline Execution
```bash
# In next session:
1. Use /superpowers:executing-plans skill
2. System will batch tasks with checkpoints
3. Execute in this session with reviews between batches
```

## Key Implementation Details

### Architecture
- **Three data sources:** Knowledge base (static), Transactions (request-time), User notes (on-write)
- **Selective retrieval:** 3 items for CREATE/UPDATE/DELETE, 5 for CLARIFY, 15 for READ/REPORT
- **Context injection:** Separate "context" role message in LLM call (not system prompt)
- **Graceful fallback:** Continue without context if Vectorize API fails

### Technology Stack
- TypeScript, Hono, Drizzle ORM, SQLite (Turso)
- Cloudflare Vectorize for embeddings
- User isolation: All queries scoped to userId

### Files to Create (6)
- `src/services/vectorize.ts` (Cloudflare API wrapper)
- `src/services/context.ts` (Context orchestration)
- `src/services/user-notes.ts` (CRUD + vectorization)
- `src/routes/user-notes.ts` (API endpoints)
- `src/types/rag.ts` (Type definitions)
- `src/db/migrations/005_*.sql` (Database schema)

### Files to Modify (4)
- `src/db/schema.ts` (Add table types)
- `src/services/ai.ts` (Inject context)
- `src/routes/ai.ts` (Call context service)
- `src/types/ai.ts` (Export ActionType if needed)

### Tests to Create (4)
- `tests/services/vectorize.test.ts`
- `tests/services/context.test.ts`
- `tests/services/user-notes.test.ts`
- `tests/routes/user-notes.test.ts`

## Before Starting Implementation

### Prerequisites
1. ✅ All design docs are committed
2. ✅ Plan is comprehensive with complete code samples
3. ✅ Current tests passing (chat clarification feature)
4. ⚠️ TODO: Ensure Cloudflare API credentials will be available in env:
   - `CLOUDFLARE_ACCOUNT_ID`
   - `CLOUDFLARE_API_TOKEN`

### Optional: Create Worktree
```bash
# To keep implementation isolated:
git worktree add .claude/worktrees/rag-context main
cd .claude/worktrees/rag-context
```

## Success Criteria

When implementation is complete:
- ✅ All 12 tasks implemented
- ✅ All tests passing (vectorize, context, user-notes, routes)
- ✅ Context retrieves from all three sources (knowledge base, transactions, notes)
- ✅ Selective retrieval works per action type
- ✅ Context injected into LLM call as separate message
- ✅ User privacy maintained (data isolated by userId)
- ✅ Error handling + fallbacks working
- ✅ Commits cleaned up and ready to merge

## Quick Reference

**Plan Location:** `docs/superpowers/plans/2026-04-08-rag-context-enhancement-implementation.md`  
**Design Location:** `docs/superpowers/specs/2026-04-08-rag-context-enhancement-design.md`  
**Current Commits:** 42 commits ahead of origin/main  
**Last Commit:** `5f9335c` - docs: add RAG context enhancement implementation plan

## Notes for Next Session

- Both features (chat clarification + RAG context) are independent and can be merged separately
- Chat clarification is complete and tested; can be pushed to production
- RAG context is ready to implement but requires Cloudflare credentials
- Estimated effort: 4-6 hours with subagent-driven approach (including reviews)
- Token efficiency: Subagent-driven approach will dispatch fresh agents per task

---

**Ready to implement? Start with Option A (Subagent-Driven) for best results! 🚀**
