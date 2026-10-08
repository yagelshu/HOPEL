# Project Specific Rules (HOPEL)

These rules dictate the workflow and architectural guidelines for this project:

1. **Web Preview Environment (Fast Iteration):**
   - Do NOT build an APK for every change.
   - Use Flutter's Web or Simulator environment for rapid testing (Hot Reload).
   - Only build an APK when explicitly requested and after the user approves the web/simulator preview.

2. **Batching Tasks:**
   - Expect features and bug fixes to arrive in batches of 5-10 small tasks.
   - Process the entire batch in one go, providing a single consolidated update/version for review to minimize build cycles.

3. **Test-Driven Development (TDD) via Acceptance Criteria:**
   - Every requested feature will come with clear acceptance criteria (e.g., "Button is green", "Updates inventory on click", "Shows confirmation popup").
   - Before presenting the final result, self-verify that all specified acceptance criteria have been successfully met.

4. **Version Control and Refactoring:**
   - Pause periodically to refactor and clean up the codebase.
   - Maintain clear separation of stable states. Ensure the codebase remains clean and extensible before layering new small features on top.

5. **Separation of UI and Logic:**
   - Keep visual configurations (colors, sizes, typography, layouts) strictly separated from medical/business logic.
   - Centralize design configurations (e.g., in a theme or constants file) so that visual tweaks can be applied quickly without risking bugs in the core logic.
