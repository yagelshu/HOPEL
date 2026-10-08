# Golden Paths (Core User Journeys)

These are the critical usage scenarios that the app MUST pass successfully after any major refactor.

## 1. Authentication & Onboarding
- **Path:** Launch App -> Register new user -> Create new unit -> Land on Dashboard.
- **Verification:** User is assigned to the newly created unit as `COMPANY_MEDIC` (חופ"ל). The dashboard displays 0 medics on standby, and the default equipment catalog is populated.
- **Regression Check:** No "unit_id = null" errors. Dashboard metrics do not crash.

## 2. Cross-User Data Isolation (No Bleed)
- **Path:** Login User A -> Add a medic to standby / update equipment -> Logout -> Login User B (different unit).
- **Verification:** User B sees exactly their unit's data. Zero overlap with User A's standby medics or equipment changes.
- **Regression Check:** `db.clear()` or Supabase queries are strictly enforcing RLS and clearing local cache.

## 3. Medical Case Management
- **Path:** Dashboard -> Open Medical Cases -> Create new case -> Fill details -> Save -> Re-open case.
- **Verification:** The case appears in the list. Details remain exactly as entered. The dashboard metric for active cases increments by 1.
- **Regression Check:** The case saves to Supabase instantly. Re-fetching pulls the identical state.

## 4. Equipment Catalog & Updates
- **Path:** Dashboard -> Open Equipment -> Mark 5 items as "MISSING" -> Save -> Reload App.
- **Verification:** The 5 items remain "MISSING". The dashboard metric for missing equipment shows `5`.
- **Regression Check:** Updates are persisted to Supabase and correctly re-fetched on initialization.

## 5. Joining an Existing Unit
- **Path:** Register new user -> Choose "Join Unit" -> Enter valid 6-char code -> Land on Dashboard.
- **Verification:** User is assigned to the unit as `COMBAT_MEDIC`. User sees the exact same dashboard metrics and medics list as the `COMPANY_MEDIC` who created the unit.
- **Regression Check:** Read permissions (RLS) on Supabase allow the new user to read the unit's shared tables (equipment, cases, users).
