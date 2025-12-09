package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// Exit codes
const (
	ExitAllow = 0 // Allow operation
	ExitBlock = 2 // Block operation
)

// ANSI color codes
const (
	Red    = "\033[0;31m"
	Yellow = "\033[1;33m"
	NC     = "\033[0m" // No Color
)

// PreToolUseInput represents the JSON input from stdin
type PreToolUseInput struct {
	ToolName  string                 `json:"tool_name"`
	SessionID string                 `json:"session_id"`
	CWD       string                 `json:"cwd"`
	ToolInput map[string]interface{} `json:"tool_input"`
}

// Debug logging
var (
	debugLog *os.File
)

func initDebugLog() {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return
	}

	logDir := filepath.Join(homeDir, ".claude", "logs")
	os.MkdirAll(logDir, 0755)

	logPath := filepath.Join(logDir, "hooks-debug.log")
	debugLog, _ = os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
}

func debugLogf(format string, args ...interface{}) {
	if debugLog != nil {
		timestamp := time.Now().Format("2006-01-02 15:04:05")
		fmt.Fprintf(debugLog, "[%s] %s\n", timestamp, fmt.Sprintf(format, args...))
	}
}

func closeDebugLog() {
	if debugLog != nil {
		debugLog.Close()
	}
}

// validateFilePath validates a file path to prevent traversal attacks
func validateFilePath(path string) (string, bool) {
	// Check for null bytes, newlines, and other dangerous characters
	if strings.ContainsAny(path, "\x00\n\r") {
		debugLogf("ERROR: Invalid path contains forbidden characters: %s", path)
		return "", false
	}

	// Try to get absolute path
	absPath, err := filepath.Abs(path)
	if err != nil {
		debugLogf("ERROR: Failed to get absolute path: %s", path)
		return "", false
	}

	// For new files, validate parent directory
	if _, err := os.Stat(absPath); os.IsNotExist(err) {
		parentDir := filepath.Dir(absPath)
		if _, err := os.Stat(parentDir); err != nil {
			// Walk up to find existing directory
			checkDir := parentDir
			for checkDir != "/" && checkDir != "." {
				if _, err := os.Stat(checkDir); err == nil {
					return path, true
				}
				checkDir = filepath.Dir(checkDir)
			}
		}
	}

	return path, true
}

// validateEnvFile checks if CLAUDE_ENV_FILE is in a safe location
func validateEnvFile(envFile string) bool {
	if envFile == "" {
		return false
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		return false
	}

	safeLocations := []string{
		"/tmp/",
		filepath.Join(homeDir, ".claude") + "/",
		filepath.Join(homeDir, ".config") + "/",
	}

	for _, safeDir := range safeLocations {
		if strings.HasPrefix(envFile, safeDir) {
			return true
		}
	}

	debugLogf("ERROR: CLAUDE_ENV_FILE not in safe location: %s", envFile)
	return false
}

// getFileBranch gets the git branch for a file path (handles worktrees)
func getFileBranch(filePath string) (string, bool) {
	// Get the directory containing the file
	fileDir := filePath
	if info, err := os.Stat(filePath); err == nil && !info.IsDir() {
		fileDir = filepath.Dir(filePath)
	} else if err != nil {
		fileDir = filepath.Dir(filePath)
	}

	// Walk up to find existing directory
	for fileDir != "/" && fileDir != "." {
		if _, err := os.Stat(fileDir); err == nil {
			break
		}
		fileDir = filepath.Dir(fileDir)
	}

	// Check if we're in a git repo
	cmd := exec.Command("git", "-C", fileDir, "rev-parse", "--git-dir")
	if err := cmd.Run(); err != nil {
		return "", false
	}

	// Get branch name
	cmd = exec.Command("git", "-C", fileDir, "rev-parse", "--abbrev-ref", "HEAD")
	output, err := cmd.Output()
	if err != nil {
		return "", false
	}

	branch := strings.TrimSpace(string(output))
	return branch, true
}

// isFileOnProtectedBranch checks if a file is on a protected branch
// Returns: 0 = protected (block), 1 = not protected (allow), 2 = warning (allow with warning)
func isFileOnProtectedBranch(filePath string) int {
	branch, ok := getFileBranch(filePath)
	if !ok {
		return 1 // Not in a git repo, not protected
	}

	// Protected branches - fully blocked
	switch branch {
	case "main", "master", "develop", "production":
		return 0 // Protected - block
	}

	// Release branches
	if strings.HasPrefix(branch, "release/") {
		return 0 // Protected - block
	}

	// Staging branch - warning only
	if branch == "staging" {
		return 2 // Warning only - allow with warning
	}

	return 1 // Not protected - allow
}

// isQualityCycleActive checks if we're in a quality cycle context
func isQualityCycleActive(sessionID string) bool {
	// Check for QC override
	if os.Getenv("CLAUDE_QC_OVERRIDE") == "true" {
		overrideMsg := fmt.Sprintf("[%s] QC_OVERRIDE used - session: %s", time.Now().Format(time.RFC3339), sessionID)
		fmt.Fprintln(os.Stderr, overrideMsg)
		debugLogf("AUDIT: %s", overrideMsg)
		return true
	}

	// Check CLAUDE_ENV_FILE for quality cycle marker
	envFile := os.Getenv("CLAUDE_ENV_FILE")
	if envFile != "" && validateEnvFile(envFile) {
		content, err := os.ReadFile(envFile)
		if err == nil && strings.Contains(string(content), "QUALITY_CYCLE_ACTIVE=true") {
			debugLogf("Quality cycle context detected via CLAUDE_ENV_FILE")
			return true
		}
	}

	// Check if we're in a subagent context via session ID
	validSessionID := regexp.MustCompile(`^[a-zA-Z0-9_-]+$`)
	if validSessionID.MatchString(sessionID) {
		subagentPattern := regexp.MustCompile(`^(code-developer|code-reviewer|code-tester|tech-writer|tech-editor|tech-publisher|prompt-engineer|prompt-reviewer|prompt-tester|plugin-engineer|plugin-reviewer|plugin-tester)-`)
		if subagentPattern.MatchString(sessionID) {
			debugLogf("Subagent context detected via session ID: %s", sessionID)
			return true
		}
	}

	return false
}

// isProtectedPath checks if a path matches protected patterns
func isProtectedPath(path string) bool {
	// Agent definitions
	agentPattern := regexp.MustCompile(`\.claude/agents/.*/AGENT\.md$`)
	if agentPattern.MatchString(path) {
		return true
	}

	// Skills
	if strings.Contains(path, ".claude/skills/") {
		return true
	}

	// Bash scripts
	if strings.HasSuffix(path, ".sh") || strings.Contains(path, "/scripts/") {
		return true
	}

	// Script interpreters
	scriptExtPattern := regexp.MustCompile(`\.(bash|ksh|zsh|fish|py|rb|pl)$`)
	if scriptExtPattern.MatchString(path) {
		return true
	}

	// Hook scripts
	if strings.Contains(path, ".claude/hooks/") {
		return true
	}

	// Production code files
	codeExtPattern := regexp.MustCompile(`\.(go|ts|tsx|js|jsx|rs|java|c|cpp|h|hpp)$`)
	if codeExtPattern.MatchString(path) {
		return true
	}

	// Documentation files (specifications - same rigor as code)
	docsExtPattern := regexp.MustCompile(`\.(md|mdx|rst|adoc)$`)
	if docsExtPattern.MatchString(path) {
		// Exclude tickets and handoff outputs - transient content
		if !strings.Contains(path, "/tickets/") && !regexp.MustCompile(`handoff-.*\.md$`).MatchString(path) {
			return true
		}
	}

	return false
}

// isScriptCommand checks if a command is executing a script
func isScriptCommand(command string) bool {
	// Direct script execution
	scriptPattern := regexp.MustCompile(`\.sh(\s|$|;|&|\|)`)
	if scriptPattern.MatchString(command) {
		return true
	}

	// Script in scripts directory
	if strings.Contains(command, "/scripts/") {
		return true
	}

	// Hook scripts
	if strings.Contains(command, "/hooks/") {
		return true
	}

	// Source or dot commands
	sourcePattern := regexp.MustCompile(`^(source|\.)\s+[^/]*\.sh`)
	if sourcePattern.MatchString(command) {
		return true
	}

	// Interpreter-based execution
	interpreterPattern := regexp.MustCompile(`^(bash|sh|zsh|ksh|python|python3|ruby|perl)\s+`)
	if interpreterPattern.MatchString(command) {
		return true
	}

	// Check for creation of executable files
	if strings.Contains(command, "chmod") && strings.Contains(command, "+x") {
		return true
	}

	return false
}

// generateErrorMessage generates a helpful error message for quality cycle violations
func generateErrorMessage(reason, tool, target string) string {
	return fmt.Sprintf(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
%s❌ QUALITY CYCLE REQUIRED - Operation Blocked%s
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reason: %s
Tool: %s
Target: %s

This operation requires a quality cycle per ~/.claude/CLAUDE.md.

TO PROCEED CORRECTLY:
1. Create a ticket: tickets/queue/TICKET-{session-id}-{seq}.md
2. Use the appropriate agent via Task tool:
   - For code: invoke code-developer agent
   - For docs: invoke tech-writer agent
3. Let the quality cycle run (Creator → Critic → Expediter)

EMERGENCY OVERRIDE (use sparingly - will be logged):
Export CLAUDE_QC_OVERRIDE=true before the operation

Example workflow:
1. Create ticket with requirements
2. Task tool: subagent_type="general-purpose", model="opus"
3. Prompt: "You are code-developer. Read ticket TICKET-xxx and implement..."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`, Red, NC, reason, tool, target)
}

// generateBranchErrorMessage generates an error message for protected branch violations
func generateBranchErrorMessage(tool, branch, target string) string {
	return fmt.Sprintf(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
%s❌ PROTECTED BRANCH - Operation Blocked%s
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You are on protected branch: %s
Tool: %s
Target: %s

Direct modifications to protected branches are not allowed.
This prevents accidental commits that bypass:
  - Pull request review process
  - CI/CD validation checks
  - Branch protection rules

TO PROCEED CORRECTLY:
1. Create a git worktree for your feature:
   git worktree add ../feature-name -b feature/your-feature

2. Switch to the worktree directory:
   cd ../feature-name

3. Make your changes there, then create a PR

WORKTREE COMMANDS:
  List worktrees:   git worktree list
  Create worktree:  git worktree add <path> -b <branch>
  Remove worktree:  git worktree remove <path>

EMERGENCY OVERRIDE (use sparingly - will be audited):
Export CLAUDE_MAIN_OVERRIDE=true before the operation

Note: This is separate from CLAUDE_QC_OVERRIDE (quality cycle bypass).
Branch protection is about WHERE you write, not quality gates.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`, Red, NC, branch, tool, target)
}

// generateStagingWarningMessage generates a warning message for staging branch edits
func generateStagingWarningMessage(tool, target string) string {
	return fmt.Sprintf(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
%s⚠️  STAGING BRANCH - Proceeding with Warning%s
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You're editing on the staging branch.
Tool: %s
Target: %s

Consider creating a feature branch from staging:
  git checkout -b feature/your-feature staging

This helps:
  - Keep staging clean for integration testing
  - Enable easier rollback if needed
  - Follow the team's branching workflow

Proceeding with operation...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`, Yellow, NC, tool, target)
}

func main() {
	// Initialize debug logging
	initDebugLog()
	defer closeDebugLog()

	// Read JSON input from stdin
	inputBytes, err := io.ReadAll(os.Stdin)
	if err != nil {
		debugLogf("ERROR: Failed to read stdin: %v", err)
		os.Exit(ExitAllow)
	}

	var input PreToolUseInput
	if err := json.Unmarshal(inputBytes, &input); err != nil {
		debugLogf("ERROR: Failed to parse JSON: %v", err)
		os.Exit(ExitAllow)
	}

	debugLogf("Hook invoked for tool: %s, session: %s", input.ToolName, input.SessionID)

	// Only check specific tools
	switch input.ToolName {
	case "Bash", "Edit", "Write":
		debugLogf("Checking tool: %s", input.ToolName)
	default:
		os.Exit(ExitAllow)
	}

	// HARD GATE: Protected branch check for destructive tools
	// This runs BEFORE quality cycle checks - branch protection is non-negotiable
	if input.ToolName == "Edit" || input.ToolName == "Write" {
		// Extract file_path
		var targetFilePath string
		if filePathVal, ok := input.ToolInput["file_path"]; ok {
			if fp, ok := filePathVal.(string); ok {
				targetFilePath = fp
			}
		}

		// Check if the FILE is on a protected branch (not CWD's branch)
		if targetFilePath != "" {
			branchCheckResult := isFileOnProtectedBranch(targetFilePath)
			fileBranch, _ := getFileBranch(targetFilePath)

			switch branchCheckResult {
			case 0: // Fully protected - block unless override
				// Check for explicit main branch override
				if os.Getenv("CLAUDE_MAIN_OVERRIDE") == "true" {
					// Log override usage for audit trail
					overrideMsg := fmt.Sprintf("[%s] MAIN_OVERRIDE used - session: %s, tool: %s, file_branch: %s, file: %s, cwd: %s",
						time.Now().Format(time.RFC3339), input.SessionID, input.ToolName, fileBranch, targetFilePath, input.CWD)
					debugLogf("AUDIT: %s", overrideMsg)
					// Allow operation to continue (will still hit QC checks)
				} else {
					debugLogf("Protected branch write blocked: file_branch=%s, tool=%s, target=%s", fileBranch, input.ToolName, targetFilePath)
					fmt.Fprint(os.Stderr, generateBranchErrorMessage(input.ToolName, fileBranch, targetFilePath))
					os.Exit(ExitBlock)
				}
			case 2: // Warning only (staging) - log and allow
				debugLogf("WARNING: Staging branch edit - file_branch=%s, tool=%s, target=%s", fileBranch, input.ToolName, targetFilePath)
				fmt.Fprint(os.Stderr, generateStagingWarningMessage(input.ToolName, targetFilePath))
				// Allow operation to continue (exit 0 at end of hook)
			default: // Not protected - continue normally
			}
		}
	}

	// Check if we're in a quality cycle context
	if isQualityCycleActive(input.SessionID) {
		debugLogf("Quality cycle active - allowing operation")
		os.Exit(ExitAllow)
	}

	// Check if operation requires quality cycle
	switch input.ToolName {
	case "Bash":
		var command string
		if commandVal, ok := input.ToolInput["command"]; ok {
			if cmd, ok := commandVal.(string); ok {
				command = cmd
			}
		}

		if command != "" && isScriptCommand(command) {
			debugLogf("Bash script operation blocked: %s", command)
			cmdPreview := command
			if len(cmdPreview) > 100 {
				cmdPreview = cmdPreview[:100] + "..."
			}
			fmt.Fprint(os.Stderr, generateErrorMessage("Bash script creation/modification requires quality cycle", "Bash", cmdPreview))
			os.Exit(ExitBlock)
		}

	case "Edit", "Write":
		var filePath string
		if filePathVal, ok := input.ToolInput["file_path"]; ok {
			if fp, ok := filePathVal.(string); ok {
				filePath = fp
			}
		}

		if filePath == "" {
			os.Exit(ExitAllow)
		}

		// Validate file path
		validatedPath, valid := validateFilePath(filePath)
		if !valid {
			debugLogf("ERROR: Invalid file path: %s", filePath)
			os.Exit(ExitAllow)
		}

		if isProtectedPath(validatedPath) {
			debugLogf("Protected path modification blocked: %s", validatedPath)
			fmt.Fprint(os.Stderr, generateErrorMessage("Protected file modification requires quality cycle", input.ToolName, validatedPath))
			os.Exit(ExitBlock)
		}
	}

	os.Exit(ExitAllow)
}
