# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Ralph is an iterative AI agent workflow system designed to implement features and requirements with automated progress tracking. It uses Claude to execute Product Requirements Documents (PRDs) one task at a time, creating focused git commits and maintaining detailed progress logs.

Ralph is designed to be used as a **git submodule**, keeping the tool separate from project-specific requirements. The `ralph/` directory contains the reusable tool, while `ralph-reference/` in your project root stores project-specific PRDs and progress logs.

## Key Architecture Concepts

### One-Task-Per-Iteration Design

Ralph's core architecture enforces **strict single-task execution**:

- Each iteration completes exactly ONE task from the PRD
- The agent marks exactly ONE checkbox [x] in the PRD per iteration
- This creates focused, reviewable git commits with clear task IDs
- Never batch multiple tasks in a single iteration
- Stop immediately after completing one task

This design enables:
- Granular progress tracking
- User review between tasks (in interactive mode)
- Easy resumption if work is interrupted
- Clear git history with task-specific commits

### Directory Structure

```
project-root/
├── ralph/                    # Git submodule containing Ralph tool
│   ├── ralph.sh              # Main orchestration script
│   ├── PROMPT.md             # Shared agent instructions template
│   ├── CLAUDE.md             # This file
│   ├── README.md             # Documentation
│   └── templates/            # Template files
│       ├── 000-sample.md     # PRD structure reference
│       └── PRD_PROMPT.md     # Template for PRD generation instructions
└── ralph-reference/          # Project-specific requirements (NOT in submodule)
    └── YYYYMMDD-HHMM-feature-name/
        ├── idea.md           # Initial concept (optional)
        ├── PRD.md            # Product Requirements Document
        ├── progress.md       # Progress log (auto-generated)
        ├── .run-id           # Current run identifier (auto-generated)
        └── archive/          # Completed/stopped run snapshots
```

### File Responsibilities

**ralph.sh**: Orchestrator that runs Claude in a loop until all PRD tasks complete. Handles:
- Interactive wizard for creating new requirements
- Prompt preparation with requirement-specific paths
- Iteration loop with user confirmation (interactive mode) or auto-continue
- Archiving completed/stopped runs
- Visual status indicators for requirement completion

**PROMPT.md**: Template containing agent instructions. Uses placeholders:
- `{{PRD_PATH}}` - Path to requirement's PRD.md
- `{{PROGRESS_PATH}}` - Path to requirement's progress.md

**PRD.md**: Product Requirements Document with two key sections:
- **Progress Summary**: Implementation steps with [ ] checkboxes that the agent tracks and marks [x] as completed
- **Acceptance Criteria**: Validation requirements without checkboxes (informational only, not tracked)

**PRD_PROMPT.md** (in templates/): Standard instructions for generating PRD.md files from idea.md.

**progress.md**: Progress log with:
- Run ID and timestamp at top
- Codebase Patterns section (for reusable learnings)
- Dated entries for each task with learnings and gotchas

### Workflow Phases

**Phase 1 - Planning**: Create requirement folder, write idea.md, generate PRD.md using ralph/templates/PRD_PROMPT.md

**Phase 2 - Implementation**: Ralph runs Claude iteratively:
1. Read PRD and progress
2. Pick first unchecked [ ] task from Progress Summary section
3. Implement ONLY that task
4. Run tests/typechecks if applicable
5. Commit with format: `feat: [ID] - [Title]`
6. Mark ONLY that task as [x] in Progress Summary
7. Append learnings to progress.md
8. Stop (Ralph calls again for next task)

**Phase 3 - Completion**: When ALL implementation tasks in the Progress Summary section are marked [x], agent outputs `<promise>COMPLETE</promise>` and Ralph archives the run.

## Commands

### Running Ralph

```bash
# Wizard mode (recommended) - interactive menu
./ralph/ralph.sh

# Run existing requirement (interactive mode)
./ralph/ralph.sh YYYYMMDD-HHMM-feature-name

# Run with auto-continue (no confirmation prompts)
./ralph/ralph.sh YYYYMMDD-HHMM-feature-name --yes
./ralph/ralph.sh YYYYMMDD-HHMM-feature-name -y
```

### Execution Modes

**Interactive Mode** (default): Pauses after each iteration for user review
- Press Enter to continue
- Press 'q' to quit and archive
- Press 's' to enable auto-continue mode

**Auto-continue Mode**: Runs until all tasks complete without prompts
- Enable with `--yes` or `-y` flag
- Or press 's' during interactive mode

### Creating Requirements

The wizard (`./ralph/ralph.sh` with no arguments) automates:
1. Requirement name input (auto-prefixed with date/time)
2. Multi-line idea description (Ctrl+D to finish)
3. Auto-generation of folder structure and idea.md
4. Claude-generated PRD.md (using ralph/templates/PRD_PROMPT.md)
5. Option to run immediately or later

### Naming Convention

Requirement folders must follow: `YYYYMMDD-HHMM-brief-descriptive-name`

Examples:
- `20260114-0930-kickoff`
- `20260116-1104-feat-palette-selector-to-footer`

## Critical Rules for Working with Ralph

### When Acting as the Ralph Agent

If you are invoked BY ralph.sh (you'll see `{{PRD_PATH}}` or `{{PROGRESS_PATH}}` in the prompt, paths will reference `ralph-reference/` folder):

1. **Read PRD and progress first** - Check "Codebase Patterns" section in progress.md
2. **Pick ONLY the first unchecked [ ] task from Progress Summary** - Never skip ahead
3. **Implement ONLY that ONE task** - No batching, no combining
4. **Test if applicable** - Run relevant tests/typechecks
5. **Commit with task ID** - Format: `feat: [ID] - [Title]`
6. **Mark ONLY that ONE task as [x] in Progress Summary** - Update PRD.md
7. **Document learnings** - Append to progress.md with date and task ID
8. **Check completion** - If ALL Progress Summary tasks now [x], output `<promise>COMPLETE</promise>`
9. **Stop immediately** - Ralph will call you again for next task

Note: Acceptance Criteria items do not have checkboxes and are not tracked for completion.

### When Modifying Ralph Itself

If you need to modify ralph.sh, PROMPT.md, or the Ralph system:

- Understand the one-task-per-iteration contract
- Preserve the placeholder system ({{PRD_PATH}}, {{PROGRESS_PATH}})
- Maintain the `<promise>COMPLETE</promise>` completion signal
- Don't break the archiving system
- Test both interactive and auto-continue modes

## Progress Tracking

### Codebase Patterns Section

Add reusable patterns discovered during implementation to the **TOP** of progress.md under "## Codebase Patterns". This section should grow over time as you discover how the target codebase works.

### Task Entries

Append dated entries for each completed task:

```markdown
## [Date] - [Story ID]

- What was implemented
- Files changed
- **Learnings:**
  - Patterns discovered
  - Gotchas encountered

---
```

## Project Context

This repository contains Ralph itself - it's a meta-tool for managing AI-driven development workflows. When working on Ralph:

- Ralph is designed to be used as a **git submodule** in client projects
- The `ralph/` directory contains the tool itself (submodule)
- The `ralph-reference/` directory in the project root stores project-specific requirements
- The target codebase is whatever project Ralph is being run FROM
- Ralph operates from the project root via `cd "$PROJECT_ROOT"`
- Paths in PROMPT.md are relative to project root (e.g., `ralph-reference/YYYYMMDD-HHMM-feature/PRD.md`)
- Ralph itself has no build/test commands (it's a bash script)

### Adding Ralph to a New Project

```bash
# Add Ralph as a submodule
git submodule add <ralph-repo-url> ralph

# Initialize the ralph-reference directory (automatically created when you create your first requirement)
./ralph/ralph.sh
```
