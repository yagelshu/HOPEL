# AI Development Rules

This document outlines the strict operational guidelines for AI-assisted development in this project. The goal is to eliminate the "ping-pong" cycle of bug fixing and ensure a stable, scalable architecture.

## The Core Development Loop
For every reported bug or new feature, the AI MUST follow this strict sequence:

1. **Reproduce & Diagnose:**
   - Mentally or programmatically reproduce the state that caused the bug.
   - Do NOT apply a patch until the exact **Root Cause** is identified.
   - Example: If a list is empty, do not just hardcode a default list. Trace *why* the fetch failed.

2. **Plan & Audit:**
   - Before writing code, review dependencies. Will fixing this bug break another flow?
   - Update `implementation_plan.md` with the proposed fix and its impact radius.
   - Await user approval for architectural changes.

3. **Fix & Propagate:**
   - Implement the fix.
   - Search the codebase for similar anti-patterns or identical root causes in other files, and fix those too. (e.g., if one Riverpod provider is missing a database filter, check the other providers).

4. **Verify & Regression Test:**
   - Cross-reference the fix against `GOLDEN_PATHS.md`.
   - Ensure that the primary user journeys (Authentication, Dashboard, Isolation) are not compromised.
   - Do not ask the user to test until this verification is complete.

## Architectural Guidelines

### 1. Single Source of Truth
- **Supabase is King.** The production app will rely on Supabase as the single source of truth.
- Local abstractions (`mock_database_repository`, `SyncEngine`) must be phased out or strictly isolated to prevent split-brain state bugs.

### 2. State Management
- Use `flutter_riverpod` providers strictly for reading and caching data from Supabase.
- Mutations (Insert, Update, Delete) must await the Supabase network call *before* invalidating the local Riverpod provider.
- No optimistic UI updates unless specifically architected with a robust rollback mechanism.

### 3. Data Isolation (RLS)
- Supabase Row Level Security (RLS) is mandatory.
- Code must always assume users can only read/write their own unit's data. Do not rely solely on client-side filtering (`where('unit_id', ...)`).

### 4. No Unrelated Refactoring
- Stick to the scope of the bug. If a file is messy but works, and is unrelated to the current fix, leave it alone. Add it to a tech-debt backlog instead.
