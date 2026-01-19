# Ralph - AI Agent Workflow System

Ralph is an iterative AI agent system for implementing features and requirements with automated progress tracking.

**Ralph is designed to be used as a git submodule**, keeping the tool separate from your project-specific requirements.

## Directory Structure

```
project-root/
├── ralph/                    # Git submodule (Ralph tool)
│   ├── ralph.sh              # Main execution script
│   ├── PROMPT.md             # Shared prompt template
│   ├── CLAUDE.md             # Developer guidance
│   ├── README.md             # This file
│   └── templates/            # Template files
│       └── 000-sample.md     # Example PRD structure
└── ralph-reference/          # Project-specific requirements (NOT in submodule)
    ├── 20260114-kickoff/
    │   ├── idea.md           # Initial rough idea/concept
    │   ├── PRD_PROMPT.md     # Prompt used to generate PRD.md
    │   ├── PRD.md            # Product Requirements Document
    │   ├── progress.md       # Progress log with learnings (auto-generated)
    │   ├── .run-id           # Current run identifier (auto-generated)
    │   └── archive/          # Completed/incomplete run archives
    └── 20260116-feat-palette-selector-to-footer/
        ├── PRD_PROMPT.md
        └── PRD.md
```

## Getting Started

### Adding Ralph to Your Project

```bash
# From your project root
git submodule add <ralph-repo-url> ralph
git submodule update --init

# Run the wizard to create your first requirement
./ralph/ralph.sh
```

The `ralph-reference/` directory will be automatically created in your project root when you create your first requirement.

## Usage

### Wizard Mode (Recommended)

Run Ralph without arguments to enter interactive wizard mode:

```bash
./ralph/ralph.sh
```

The wizard will guide you through:
1. Creating a new requirement or running an existing one
2. **Visual status indicators** show which requirements are completed:
   - ✓ Green checkmark = Completed (has completed archive)
   - • Cyan dot = In progress or not started
   - Summary count shows "X of Y completed" at the top
3. For new requirements:
   - Enter requirement name (automatically prefixed with date and time)
   - Provide idea/description (multi-line, end with Ctrl+D)
   - Automatically generate PRD.md using Claude
   - Option to run immediately or later
   - Choose interactive or auto-continue mode
4. For existing requirements:
   - Select from available requirements (with completion status)
   - Choose interactive or auto-continue mode

### Command-Line Mode

You can also run Ralph directly with command-line arguments:

```bash
# Run existing requirement (interactive mode)
./ralph/ralph.sh <requirement-folder>

# Run with auto-continue (skip confirmation prompts)
./ralph/ralph.sh <requirement-folder> --yes

# Examples
./ralph/ralph.sh 20260114-kickoff
./ralph/ralph.sh 20260116-feat-palette-selector-to-footer -y
```

### Execution Modes

**Interactive Mode (default):**
- Ralph pauses after each iteration
- Prompts to continue, quit, or enable auto-continue
- Press Enter to continue, 'q' to quit, 's' to skip future prompts
- Gives you control over the execution flow

**Auto-continue Mode:**
- Ralph runs continuously until all tasks are complete
- No confirmation prompts between iterations
- Enable with `--yes` or `-y` flag, or press 's' during interactive mode
- Ideal for unattended execution

### Manual Requirement Creation

If you prefer manual setup instead of the wizard:

1. Create a new folder in `ralph-reference/` with a descriptive name:
   ```bash
   mkdir -p ralph-reference/YYYYMMDD-HHMM-feature-name
   ```

2. Create an `idea.md` with your initial concept:
   ```bash
   echo "# Feature Name\n\nBrief description of what you want to build..." > ralph-reference/YYYYMMDD-HHMM-feature-name/idea.md
   ```

3. Create a `PRD_PROMPT.md` with instructions for generating the PRD:
   ```bash
   cat > ralph-reference/YYYYMMDD-HHMM-feature-name/PRD_PROMPT.md << 'EOF'
   Write a PRD document called `PRD.md` in this directory based on `idea.md`.

   Think about how to implement the feature step-by-step. Break it down into smaller tasks.
   Follow the `ralph/templates/000-sample.md` as structure reference.
   EOF
   ```

4. Generate the `PRD.md` using Claude or write it manually

5. Run Ralph for this requirement:
   ```bash
   ./ralph/ralph.sh YYYYMMDD-HHMM-feature-name
   ```

Ralph will automatically:
- Create `progress.md` if it doesn't exist
- Track the run with a `.run-id` file
- Archive completed/incomplete runs in `archive/`

## File Descriptions

### ralph.sh
Main script that:
- Provides interactive wizard mode for creating new requirements
- Guides user through requirement name and idea input
- Auto-generates folder structure, idea.md, PRD_PROMPT.md, and PRD.md
- Validates requirement folder exists
- Prepares the prompt with requirement-specific paths
- Runs Claude iteratively until completion (with optional confirmation prompts)
- Shows Claude's output in real-time during each iteration
- Supports interactive mode (with confirmations) or auto-continue mode (--yes flag)
- Archives results on completion or user stop

### PROMPT.md
Shared prompt template used for all requirements. Contains:
- Task instructions for the AI agent (ONE task per iteration)
- Critical rules emphasizing single-task execution
- Progress format guidelines
- Stop condition for completion (only when ALL tasks done)
- Workflow summary for clarity
- Uses `{{PRD_PATH}}` and `{{PROGRESS_PATH}}` placeholders

### idea.md (per requirement, optional)
Initial rough concept or feature description. Used as input for creating the PRD_PROMPT.md.

### PRD_PROMPT.md (per requirement)
The prompt that was used to generate the PRD.md. Documents:
- Instructions for creating the PRD
- References to idea.md and sample structure
- What to include in the PRD
- Maintains a record of how the PRD was created

### PRD.md (per requirement, required)
Product Requirements Document generated from PRD_PROMPT.md. Contains:
- Progress summary with checkboxes
- Overview and goals
- Implementation steps
- Acceptance criteria
- Technical specifications

### progress.md (per requirement, auto-generated)
Progress log created and updated by Ralph with:
- Run ID and timestamp
- Codebase patterns (at the top)
- Dated entries for each implementation step
- Learnings and gotchas discovered

### .run-id (per requirement, auto-generated)
Tracks the current run identifier for the requirement. Deleted on completion.

### archive/ (per requirement, auto-generated)
Contains timestamped snapshots of completed or incomplete runs.

## Complete Workflow

### Phase 1: Planning (Wizard-Assisted)

Using the wizard (recommended):

1. **Launch**: Run `./ralph/ralph.sh` without arguments
2. **Select**: Choose "Create new requirement"
3. **Name**: Enter descriptive requirement name (auto-prefixed with date and time)
4. **Ideation**: Enter your idea/description (multi-line, Ctrl+D to finish)
5. **Auto-Generate**: Wizard creates folder structure, idea.md, PRD_PROMPT.md, and generates PRD.md with Claude
6. **Review**: Review the generated PRD.md (optional: edit before running)
7. **Run**: Choose to run immediately or later

Or manually:

1. **Ideation**: Create `idea.md` with rough concept
2. **PRD Prompt**: Create `PRD_PROMPT.md` with instructions for generating the PRD
3. **PRD Generation**: Use Claude to generate `PRD.md` from `PRD_PROMPT.md` and `idea.md`
4. **Review**: Review and refine the PRD before implementation

### Phase 2: Implementation (Automated via Ralph)

Ralph works in **one-task-per-iteration** cycles:

1. **Initialize**: Ralph reads the PRD and existing progress
2. **Select**: Picks the first unchecked [ ] task in the PRD
3. **Implement**: Completes ONLY that ONE task (no batching)
4. **Test**: Runs tests and type checks if applicable
5. **Commit**: Creates focused git commit with task ID
6. **Update**: Marks ONLY that task as [x] in PRD
7. **Document**: Appends learnings to progress.md
8. **Display**: Shows Claude's output in real-time for transparency
9. **Confirm**: (Interactive mode) Prompts user before next iteration
10. **Iterate**: Repeats until ALL tasks are complete
11. **Archive**: Saves PRD, PRD_PROMPT, and progress to timestamped archive folder

**Why one task per iteration?**
- Enables granular progress tracking
- Allows user review between tasks in interactive mode
- Creates focused, meaningful git commits
- Makes it easy to stop and resume work
- Provides clear visibility into what's being done

The key insight: `PRD_PROMPT.md` documents **how** the PRD was created, maintaining a record of the original intent and generation process.

## Stop Condition

Ralph completes when the AI agent outputs:
```
<promise>COMPLETE</promise>
```

This should only happen when ALL tasks in the PRD are completed.

## Naming Convention

Requirement folders should follow the pattern:
```
YYYYMMDD-HHMM-brief-descriptive-name
```

Examples:
- `20260114-0930-kickoff` - Initial project setup
- `20260116-1104-feat-palette-selector-to-footer` - Add palette selector feature
- `20260120-1530-fix-responsive-mobile` - Fix mobile responsiveness

The date and time prefix ensures unique folder names even when multiple features are created on the same day.

## Tips

### Planning

- Keep PRDs focused on a single feature or requirement
- Break tasks into small, atomic steps (5-10 minimum)
- Each task should have a clear, testable outcome
- Use `idea.md` for initial brainstorming before creating the PRD

### Execution

- Ralph processes ONE task per iteration (by design)
- This creates focused commits and enables granular progress tracking
- Use interactive mode when you want to review each iteration's output
- Use auto-continue mode (`--yes`) for unattended execution
- Press 's' during interactive mode to dynamically switch to auto-continue
- Watch Claude's real-time output to understand what changes are being made
- Press 'q' to gracefully stop execution and archive progress

### Tracking

- Update progress.md with learnings as you discover patterns
- Archive folders preserve the state at completion/stop
- Check the wizard menu for a quick overview of which requirements are complete
- Green checkmarks indicate requirements with completed archives
- The summary count helps track overall progress across all requirements

### Technical

- The script runs Claude from the project root for full codebase access
- Each iteration marks exactly ONE checkbox in the PRD
- Completion only triggers when ALL tasks are checked
