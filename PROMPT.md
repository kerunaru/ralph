# Ralph Agent Instructions

## Your task

1. Read `{{PRD_PATH}}`
2. Read `{{PROGRESS_PATH}}` (check Codebase Patterns first)
3. Pick **THE HIGHEST PRIORITY UNCOMPLETED TASK** (the first unchecked [ ] item)
4. Implement **ONLY THAT ONE SINGLE TASK**
5. Run typecheck and tests (if applicable)
6. Commit: `feat: [ID] - [Title]` (if in git repo)
7. Update `{{PRD_PATH}}` to mark **ONLY THAT ONE TASK** as completed [x]
8. Append learnings to `{{PROGRESS_PATH}}`

## CRITICAL RULES

**YOU MUST ONLY COMPLETE ONE TASK PER ITERATION:**
- DO NOT complete multiple tasks in a single iteration
- DO NOT mark multiple checkboxes as [x] in the PRD
- Even if tasks are small or related, do ONLY ONE
- Ralph will call you again for the next task
- This ensures proper tracking and allows user to review progress

**STOP IMMEDIATELY after completing ONE task**

## Progress Format

APPEND to `{{PROGRESS_PATH}}`:

## [Date] - [Story ID]

- What was implemented
- Files changed
- **Learnings:**
  - Patterns discovered
  - Gotchas encountered

---

## Codebase Patterns

Add reusable patterns to the TOP of progress.md:

## Stop Condition

**Check the PRD after completing your ONE task:**

- If ALL checkboxes [ ] are now [x]: Output `<promise>COMPLETE</promise>` to signal completion
- If ANY checkboxes [ ] remain unchecked: End normally (Ralph will iterate again)

**DO NOT output `<promise>COMPLETE</promise>` unless EVERY SINGLE task in the PRD is marked [x]**

## Workflow Summary

1. Find first unchecked [ ] task in PRD
2. Implement ONLY that task
3. Mark ONLY that task as [x]
4. Update progress.md
5. Stop (Ralph will call you again for next task)
