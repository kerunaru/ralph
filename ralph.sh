#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph/ralph.sh [requirement-folder] [-y|--yes]
# Example: ./ralph/ralph.sh 20260116-feat-palette-selector-to-footer
# Example: ./ralph/ralph.sh 20260116-feat-palette-selector-to-footer --yes
# Or run without arguments to use wizard mode

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REFERENCE_DIR="$PROJECT_ROOT/ralph-reference"

# Parse command-line flags
AUTO_CONTINUE=false
REQUIREMENT_FOLDER=""
for arg in "$@"; do
  case "$arg" in
    -y|--yes)
      AUTO_CONTINUE=true
      ;;
    *)
      if [ -z "$REQUIREMENT_FOLDER" ]; then
        REQUIREMENT_FOLDER="$arg"
      fi
      ;;
  esac
done

# Color codes for fancy output
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
GRAY='\033[0;90m'

# Symbols
CHECK="✓"
CROSS="✗"
ARROW="→"
STAR="★"
DOT="•"

# Function to print a header box
print_header() {
  local title="$1"
  echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${RESET}"
  echo -e "${CYAN} ${RESET}  ${BOLD}${MAGENTA}$title${RESET}"
  echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"
}

# Function to print info message
print_info() {
  echo -e "${BLUE}${DOT}${RESET} $1"
}

# Function to print success message
print_success() {
  echo -e "${GREEN}${CHECK}${RESET} ${GREEN}$1${RESET}"
}

# Function to print error message
print_error() {
  echo -e "${RED}${CROSS}${RESET} ${RED}$1${RESET}"
}

# Function to print warning message
print_warning() {
  echo -e "${YELLOW}${ARROW}${RESET} ${YELLOW}$1${RESET}"
}

# Function to print step
print_step() {
  echo -e "${CYAN}${ARROW}${RESET} ${BOLD}$1${RESET}"
}

# Function to get current task from PRD
get_current_task() {
  local prd_file="$1"
  # Find first unchecked task in Progress Summary section
  awk '/^## Progress Summary/,/^## [^P]/ {
    if (/^- \[ \]/) {
      sub(/^- \[ \] /, "")
      print
      exit
    }
  }' "$prd_file"
}

# Function to count tasks in PRD
count_tasks() {
  local prd_file="$1"
  local total=0
  local completed=0

  # Count tasks in Progress Summary section
  while IFS= read -r line; do
    if [[ "$line" =~ ^-\ \[x\] ]]; then
      ((completed++))
      ((total++))
    elif [[ "$line" =~ ^-\ \[\ \] ]]; then
      ((total++))
    fi
  done < <(awk '/^## Progress Summary/,/^## [^P]/' "$prd_file")

  echo "$completed $total"
}

# Function to check if requirement is completed
is_requirement_completed() {
  local req_folder="$1"
  local completed_file="$REFERENCE_DIR/$req_folder/completed"

  # Check if completed marker file exists
  [ -f "$completed_file" ] && return 0
  return 1
}

# Function to list available requirements
list_requirements() {
  local reqs=$(ls -1 "$REFERENCE_DIR" 2>/dev/null | grep -v "\.md$" || true)
  if [ -z "$reqs" ]; then
    echo -e "  ${DIM}(none found)${RESET}"
  else
    echo "$reqs" | while read req; do
      if is_requirement_completed "$req"; then
        echo -e "  ${GREEN}${CHECK}${RESET} ${BOLD}$req${RESET} ${DIM}(completed)${RESET}"
      else
        echo -e "  ${CYAN}${DOT}${RESET} ${BOLD}$req${RESET}"
      fi
    done
  fi
}

# Function to create new requirement
create_new_requirement() {
  print_header "Create New Requirement"

  # Get requirement name
  echo -e "${BOLD}Requirement Name${RESET}"
  echo -e "${DIM}Example: feat-dark-mode-toggle, fix-mobile-layout${RESET}"
  read -p "$(echo -e ${CYAN}${ARROW}${RESET}) " REQ_NAME
  if [ -z "$REQ_NAME" ]; then
    print_error "Requirement name cannot be empty"
    exit 1
  fi

  # Generate folder name with date and time prefix
  DATE_PREFIX=$(date +%Y%m%d-%H%M)
  REQUIREMENT_FOLDER="$DATE_PREFIX-$REQ_NAME"
  REQ_DIR="$REFERENCE_DIR/$REQUIREMENT_FOLDER"

  # Check if folder already exists
  if [ -d "$REQ_DIR" ]; then
    print_error "Requirement folder already exists: $REQUIREMENT_FOLDER"
    exit 1
  fi

  echo ""
  print_info "Creating ${BOLD}$REQUIREMENT_FOLDER${RESET}"
  echo ""

  # Get idea content (multi-line)
  echo -e "${BOLD}Idea / Requirement Description${RESET}"
  echo -e "${DIM}Enter your description below (press Ctrl+D when finished)${RESET}"
  echo -e "${GRAY}────────────────────────────────────────────────────────────${RESET}"
  IDEA_CONTENT=$(cat)

  if [ -z "$IDEA_CONTENT" ]; then
    echo ""
    print_error "Idea content cannot be empty"
    exit 1
  fi

  echo -e "${GRAY}────────────────────────────────────────────────────────────${RESET}"
  echo ""

  # Create requirement folder
  mkdir -p "$REFERENCE_DIR"  # Ensure ralph-reference directory exists
  mkdir -p "$REQ_DIR"
  print_step "Setting up requirement structure..."

  # Create idea.md
  echo "$IDEA_CONTENT" > "$REQ_DIR/idea.md"
  print_success "Created idea.md"

  # Generate PRD.md using Claude
  echo ""
  print_step "Generating PRD.md with Claude..."
  cd "$REQ_DIR"

  GENERATE_PROMPT="Read idea.md in the current directory and ../../ralph/templates/PRD_PROMPT.md, then generate PRD.md following the instructions in ../../ralph/templates/PRD_PROMPT.md. Use ../../ralph/templates/000-sample.md as a structure reference. Generate PRD.md directly in the current directory."

  echo "$GENERATE_PROMPT" | claude --dangerously-skip-permissions > /dev/null

  if [ ! -f "$REQ_DIR/PRD.md" ]; then
    echo ""
    print_error "Failed to generate PRD.md"
    exit 1
  fi

  print_success "Generated PRD.md"
  echo ""
  echo -e "${GREEN}${STAR}${RESET} ${GREEN}${BOLD}Requirement created successfully!${RESET}"
  echo -e "${DIM}   Folder: $REQUIREMENT_FOLDER${RESET}"
  echo ""

  # Return to project root
  cd "$PROJECT_ROOT"
}

# Wizard mode - no arguments provided
if [ $# -eq 0 ]; then
  print_header "Ralph Wizard ${STAR}"

  # Count requirements
  WIZARD_REQS=$(ls -1 "$REFERENCE_DIR" 2>/dev/null | grep -v "\.md$" || true)
  if [ -z "$WIZARD_REQS" ]; then
    WIZARD_TOTAL_COUNT=0
  else
    WIZARD_TOTAL_COUNT=$(echo "$WIZARD_REQS" | grep -c .)
  fi
  WIZARD_COMPLETED_COUNT=0

  if [ -n "$WIZARD_REQS" ]; then
    while read req; do
      if is_requirement_completed "$req"; then
        WIZARD_COMPLETED_COUNT=$((WIZARD_COMPLETED_COUNT + 1))
      fi
    done <<< "$WIZARD_REQS"
  fi

  # If no requirements exist, automatically create the first one
  if [ "$WIZARD_TOTAL_COUNT" -eq 0 ]; then
    echo -e "${BOLD}No requirements found!${RESET}"
    echo -e "${DIM}Let's create your first requirement...${RESET}"
    echo ""
    OPTION="1"
  else
    echo -e "${BOLD}Available Requirements:${RESET} ${DIM}($WIZARD_COMPLETED_COUNT of $WIZARD_TOTAL_COUNT completed)${RESET}"
    list_requirements
    echo ""

    echo -e "${BOLD}What would you like to do?${RESET}"
    echo -e "  ${CYAN}1${RESET}) ${BOLD}Create new requirement${RESET}"
    echo -e "  ${CYAN}2${RESET}) ${BOLD}Run existing requirement${RESET}"
    echo -e "  ${CYAN}q${RESET}) ${DIM}Quit${RESET}"
    echo ""
    read -p "$(echo -e ${CYAN}${ARROW}${RESET}) Select option: " OPTION
  fi

  case "$OPTION" in
    1)
      create_new_requirement
      # After creation, prompt to run it
      echo ""
      echo -e "${BOLD}Ready to run?${RESET}"
      read -p "$(echo -e ${CYAN}${ARROW}${RESET}) Run this requirement now? (y/n): " RUN_NOW
      if [ "$RUN_NOW" != "y" ] && [ "$RUN_NOW" != "Y" ]; then
        echo ""
        print_info "You can run it later with:"
        echo -e "  ${DIM}./ralph/ralph.sh $REQUIREMENT_FOLDER${RESET}"
        exit 0
      fi
      echo ""
      echo -e "${BOLD}Auto-continue mode?${RESET}"
      echo -e "${DIM}Skip confirmation prompts between iterations (or use --yes flag)${RESET}"
      read -p "$(echo -e ${CYAN}${ARROW}${RESET}) Auto-continue? (y/n, default: n): " AUTO_CHOICE
      if [ "$AUTO_CHOICE" = "y" ] || [ "$AUTO_CHOICE" = "Y" ]; then
        AUTO_CONTINUE=true
      fi
      ;;
    2)
      print_header "Run Existing Requirement"
      echo -e "${BOLD}Available Requirements:${RESET}"
      list_requirements
      echo ""
      read -p "$(echo -e ${CYAN}${ARROW}${RESET}) Enter requirement folder name: " REQUIREMENT_FOLDER
      if [ -z "$REQUIREMENT_FOLDER" ]; then
        print_error "Requirement folder name required"
        exit 1
      fi
      echo ""
      echo -e "${BOLD}Auto-continue mode?${RESET}"
      echo -e "${DIM}Skip confirmation prompts between iterations (or use --yes flag)${RESET}"
      read -p "$(echo -e ${CYAN}${ARROW}${RESET}) Auto-continue? (y/n, default: n): " AUTO_CHOICE
      if [ "$AUTO_CHOICE" = "y" ] || [ "$AUTO_CHOICE" = "Y" ]; then
        AUTO_CONTINUE=true
      fi
      REQ_DIR="$REFERENCE_DIR/$REQUIREMENT_FOLDER"
      ;;
    q|Q)
      echo ""
      print_info "Goodbye!"
      exit 0
      ;;
    *)
      print_error "Invalid option"
      exit 1
      ;;
  esac
else
  # Command-line arguments provided (already parsed above)
  REQ_DIR="$REFERENCE_DIR/$REQUIREMENT_FOLDER"
fi

# Validate requirement folder exists
if [ ! -d "$REQ_DIR" ]; then
  echo ""
  print_error "Requirement folder not found: $REQ_DIR"
  echo ""
  echo -e "${BOLD}Available requirements:${RESET}"
  list_requirements
  exit 1
fi

# Set paths for this requirement
PRD_FILE="$REQ_DIR/PRD.md"
PROMPT_FILE="$SCRIPT_DIR/PROMPT.md"
PROGRESS_FILE="$REQ_DIR/progress.md"
COMPLETED_FILE="$REQ_DIR/completed"
RUN_ID_FILE="$REQ_DIR/.run-id"

# Validate PRD file exists
if [ ! -f "$PRD_FILE" ]; then
  echo ""
  print_error "PRD.md not found in requirement folder"
  echo -e "  ${DIM}$PRD_FILE${RESET}"
  echo ""
  print_info "Each requirement folder must contain a PRD.md file"
  exit 1
fi

# Generate or load run ID
if [ ! -f "$RUN_ID_FILE" ]; then
  RUN_ID=$(date +%Y%m%d-%H%M%S)
  echo "$RUN_ID" > "$RUN_ID_FILE"
else
  RUN_ID=$(cat "$RUN_ID_FILE")
fi

# Initialize progress file if it doesn't exist or is empty
if [ ! -f "$PROGRESS_FILE" ] || [ ! -s "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "" >> "$PROGRESS_FILE"
  echo "**Run ID:** $RUN_ID" >> "$PROGRESS_FILE"
  echo "**Started:** $(date)" >> "$PROGRESS_FILE"
  echo "" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
  echo "" >> "$PROGRESS_FILE"
fi

print_header "Ralph Agent Loop"

echo -e "${BOLD}Configuration:${RESET}"
echo -e "  ${CYAN}${DOT}${RESET} Requirement:  ${BOLD}$REQUIREMENT_FOLDER${RESET}"
echo -e "  ${CYAN}${DOT}${RESET} Mode: ${BOLD}$([ "$AUTO_CONTINUE" = true ] && echo "Auto-continue" || echo "Interactive")${RESET}"
echo -e "  ${CYAN}${DOT}${RESET} Run ID: ${DIM}$RUN_ID${RESET}"
echo ""
echo -e "${DIM}Project root: $PROJECT_ROOT${RESET}"
echo -e "${DIM}PRD: $PRD_FILE${RESET}"
echo -e "${DIM}Progress: $PROGRESS_FILE${RESET}"
echo ""

# Infinite loop until completion
ITERATION=1
while true; do
  echo ""
  echo -e "${MAGENTA} ${RESET}  ${BOLD}${WHITE}Iteration $ITERATION${RESET}"
  echo -e "${MAGENTA}══════════════════════════════════════════════════════════════${RESET}"
  echo ""

  # Get current task and count
  CURRENT_TASK=$(get_current_task "$PRD_FILE")
  read COMPLETED_COUNT TOTAL_COUNT <<< $(count_tasks "$PRD_FILE")
  REMAINING_COUNT=$((TOTAL_COUNT - COMPLETED_COUNT))

  # Display progress
  if [ -n "$CURRENT_TASK" ]; then
    echo -e "${BOLD}Current Step:${RESET} ${CYAN}$CURRENT_TASK${RESET}"
  fi
  echo -e "${BOLD}Progress:${RESET} ${GREEN}$COMPLETED_COUNT${RESET}/${CYAN}$TOTAL_COUNT${RESET} completed ${DIM}($REMAINING_COUNT remaining)${RESET}"
  echo ""

  # Prepare prompt with requirement-specific paths
  # Paths are relative to PROJECT_ROOT where claude will run
  REL_PRD_PATH="ralph-reference/$REQUIREMENT_FOLDER/PRD.md"
  REL_PROGRESS_PATH="ralph-reference/$REQUIREMENT_FOLDER/progress.md"

  PREPARED_PROMPT=$(cat "$PROMPT_FILE" | \
    sed "s|{{PRD_PATH}}|$REL_PRD_PATH|g" | \
    sed "s|{{PROGRESS_PATH}}|$REL_PROGRESS_PATH|g")

  # Run claude from project root with the prepared prompt
  cd "$PROJECT_ROOT"

  print_step "Running Claude agent..."
  echo ""
  echo -e "${GRAY}────────────────────────────────────────────────────────────${RESET}"

  # Run and capture exit code
  set +e  # Temporarily disable exit on error
  OUTPUT=$(echo "$PREPARED_PROMPT" | claude --dangerously-skip-permissions 2>&1 | tee /dev/tty)
  CLAUDE_EXIT_CODE=$?
  set -e  # Re-enable exit on error

  echo -e "${GRAY}────────────────────────────────────────────────────────────${RESET}"
  echo ""

  # Check if Claude command failed
  if [ $CLAUDE_EXIT_CODE -ne 0 ]; then
    echo ""
    print_error "Claude Code execution failed with exit code $CLAUDE_EXIT_CODE"
    echo ""
    print_warning "Stopping execution at iteration $ITERATION"
    echo ""
    print_info "Check PRD and progress files for current state:"
    echo -e "  ${DIM}PRD: $PRD_FILE${RESET}"
    echo -e "  ${DIM}Progress: $PROGRESS_FILE${RESET}"

    rm -f "$RUN_ID_FILE"
    exit 1
  fi

  # Check for completion signal (must be on a line by itself)
  if echo "$OUTPUT" | grep -Fxq "<promise>COMPLETE</promise>"; then
    echo ""
    echo -e "${GREEN} ${RESET}  ${BOLD}${GREEN}${STAR} All tasks completed successfully! ${STAR}${RESET}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}"
    echo ""
    print_success "Completed at iteration $ITERATION"

    # Mark requirement as completed
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    echo "Completed: $TIMESTAMP" > "$COMPLETED_FILE"

    echo ""
    print_success "Requirement marked as completed"
    echo -e "  ${DIM}$COMPLETED_FILE${RESET}"

    # Clean up run ID for next run
    rm -f "$RUN_ID_FILE"

    exit 0
  fi

  print_success "Iteration $ITERATION complete"

  # Ask for confirmation before next iteration (unless auto-continue)
  if [ "$AUTO_CONTINUE" = false ]; then
    echo ""
    echo -e "${BOLD}Continue to next iteration?${RESET}"
    echo -e "${DIM}Press Enter to continue, 'q' to quit, 's' to skip confirmations${RESET}"
    read -p "$(echo -e ${CYAN}${ARROW}${RESET}) " CONTINUE_CHOICE

    case "$CONTINUE_CHOICE" in
      q|Q)
        echo ""
        print_warning "Stopped by user at iteration $ITERATION"
        echo ""
        print_info "Resume later by running:"
        echo -e "  ${DIM}./ralph/ralph.sh $REQUIREMENT_FOLDER${RESET}"

        exit 0
        ;;
      s|S)
        AUTO_CONTINUE=true
        print_info "Auto-continue enabled"
        ;;
      *)
        # Continue (default)
        ;;
    esac
  else
    sleep 1
  fi

  ITERATION=$((ITERATION + 1))
done
