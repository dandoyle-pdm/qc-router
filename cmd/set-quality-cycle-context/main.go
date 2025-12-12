package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// SessionStartInput represents the JSON input from stdin
type SessionStartInput struct {
	SessionID string `json:"session_id"`
	CWD       string `json:"cwd"`
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
		fmt.Fprintf(debugLog, "[%s] [SessionStart] %s\n", timestamp, fmt.Sprintf(format, args...))
	}
}

func closeDebugLog() {
	if debugLog != nil {
		debugLog.Close()
	}
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

// validateSessionID checks if session ID has valid format
func validateSessionID(sessionID string) bool {
	matched, _ := regexp.MatchString(`^[a-zA-Z0-9_-]+$`, sessionID)
	if !matched {
		debugLogf("Invalid session ID format: %s", sessionID)
	}
	return matched
}

// detectSubagentContext detects if this is a subagent session
func detectSubagentContext(sessionID, cwd string) (string, bool) {
	// Validate session ID first
	if !validateSessionID(sessionID) {
		return "", false
	}

	// Check session ID patterns for known agents
	agentPattern := regexp.MustCompile(`^(code-developer|code-reviewer|code-tester|tech-writer|tech-editor|tech-publisher|prompt-engineer|prompt-reviewer|prompt-tester|plugin-engineer|plugin-reviewer|plugin-tester)-[a-zA-Z0-9_-]+$`)
	if matches := agentPattern.FindStringSubmatch(sessionID); len(matches) > 1 {
		agentType := matches[1]
		debugLogf("Detected subagent via session ID: %s", sessionID)
		return agentType, true
	}

	// Check if we're in a worktree
	worktreePattern := regexp.MustCompile(`/workspace/worktrees/([^/]+)/([^/]+)`)
	if worktreePattern.MatchString(cwd) {
		debugLogf("Detected worktree context: %s", cwd)
		return "worktree", true
	}

	// Check for ticket-based work indicators
	ticketPattern := regexp.MustCompile(`^TICKET-[a-zA-Z0-9]+-[0-9]+$`)
	if ticketPattern.MatchString(sessionID) {
		debugLogf("Detected ticket-based work: %s", sessionID)
		return "ticket", true
	}

	// Check environment for explicit quality cycle indicators
	if os.Getenv("QUALITY_CYCLE_MODE") == "true" {
		debugLogf("Detected explicit quality cycle mode")
		return "explicit", true
	}

	return "", false
}

// isMainThread detects if this is likely a main thread session
func isMainThread(sessionID, cwd string) bool {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return false
	}

	// Main thread indicators based on CWD
	mainLocations := []string{
		homeDir,
		filepath.Join(homeDir, "docs"),
		filepath.Join(homeDir, ".claude"),
	}

	for _, mainLoc := range mainLocations {
		if cwd == mainLoc {
			// Ensure session ID is not a subagent pattern
			agentPattern := regexp.MustCompile(`^(code-developer|code-reviewer|code-tester|tech-writer|tech-editor|tech-publisher|prompt-engineer|prompt-reviewer|prompt-tester|plugin-engineer|plugin-reviewer|plugin-tester)-[a-zA-Z0-9_-]+$`)
			if !agentPattern.MatchString(sessionID) {
				return true
			}
		}
	}

	return false
}

// setQualityCycleContext writes quality cycle markers to CLAUDE_ENV_FILE
func setQualityCycleContext(agentType, sessionID string) error {
	envFile := os.Getenv("CLAUDE_ENV_FILE")
	if envFile == "" {
		debugLogf("Warning: CLAUDE_ENV_FILE not set, cannot persist context")
		return fmt.Errorf("CLAUDE_ENV_FILE not set")
	}

	// Validate env file path
	if !validateEnvFile(envFile) {
		debugLogf("ERROR: CLAUDE_ENV_FILE path validation failed")
		return fmt.Errorf("invalid CLAUDE_ENV_FILE path")
	}

	// Create env file if it doesn't exist
	if _, err := os.Stat(envFile); os.IsNotExist(err) {
		if err := os.WriteFile(envFile, []byte{}, 0644); err != nil {
			debugLogf("ERROR: Failed to create CLAUDE_ENV_FILE: %v", err)
			return err
		}
		debugLogf("Created CLAUDE_ENV_FILE: %s", envFile)
	}

	// Read existing content (excluding old quality cycle markers)
	content, err := os.ReadFile(envFile)
	if err != nil {
		debugLogf("ERROR: Failed to read CLAUDE_ENV_FILE: %v", err)
		return err
	}

	// Filter out old quality cycle markers and comment
	var filteredLines []string
	for _, line := range strings.Split(string(content), "\n") {
		if !strings.HasPrefix(line, "QUALITY_CYCLE_") && !strings.Contains(line, "Quality Cycle Context") {
			filteredLines = append(filteredLines, line)
		}
	}

	// Create temp file for atomic write
	tempFile, err := os.CreateTemp(filepath.Dir(envFile), filepath.Base(envFile)+".*.tmp")
	if err != nil {
		debugLogf("ERROR: Failed to create temp file: %v", err)
		return err
	}
	tempPath := tempFile.Name()
	defer os.Remove(tempPath) // Clean up if we fail

	// Write filtered content
	for _, line := range filteredLines {
		if line != "" {
			fmt.Fprintln(tempFile, line)
		}
	}

	// Write new quality cycle markers
	fmt.Fprintln(tempFile, "# Quality Cycle Context - Set by SessionStart hook")
	fmt.Fprintln(tempFile, "QUALITY_CYCLE_ACTIVE=true")
	fmt.Fprintf(tempFile, "QUALITY_CYCLE_AGENT=%s\n", agentType)
	fmt.Fprintf(tempFile, "QUALITY_CYCLE_SESSION=%s\n", sessionID)
	fmt.Fprintf(tempFile, "QUALITY_CYCLE_STARTED=%s\n", time.Now().Format("2006-01-02 15:04:05"))

	tempFile.Close()

	// Atomic rename
	if err := os.Rename(tempPath, envFile); err != nil {
		debugLogf("ERROR: Failed to rename temp file: %v", err)
		return err
	}

	debugLogf("Set quality cycle context: agent=%s, session=%s", agentType, sessionID)
	return nil
}

// clearStaleContext removes quality cycle markers from CLAUDE_ENV_FILE
func clearStaleContext() error {
	envFile := os.Getenv("CLAUDE_ENV_FILE")
	if envFile == "" || !validateEnvFile(envFile) {
		return nil
	}

	if _, err := os.Stat(envFile); os.IsNotExist(err) {
		return nil
	}

	// Read existing content
	content, err := os.ReadFile(envFile)
	if err != nil {
		return err
	}

	// Check if there are any quality cycle markers
	if !strings.Contains(string(content), "QUALITY_CYCLE_ACTIVE=") {
		return nil
	}

	// Filter out quality cycle markers
	var filteredLines []string
	for _, line := range strings.Split(string(content), "\n") {
		if !strings.HasPrefix(line, "QUALITY_CYCLE_") && !strings.Contains(line, "Quality Cycle Context") {
			filteredLines = append(filteredLines, line)
		}
	}

	// Create temp file for atomic write
	tempFile, err := os.CreateTemp(filepath.Dir(envFile), filepath.Base(envFile)+".*.tmp")
	if err != nil {
		debugLogf("ERROR: Failed to create temp file for clearing context: %v", err)
		return err
	}
	tempPath := tempFile.Name()
	defer os.Remove(tempPath)

	// Write filtered content
	for _, line := range filteredLines {
		if line != "" {
			fmt.Fprintln(tempFile, line)
		}
	}
	tempFile.Close()

	// Atomic rename
	if err := os.Rename(tempPath, envFile); err != nil {
		debugLogf("ERROR: Failed to rename temp file: %v", err)
		return err
	}

	debugLogf("Cleared stale quality cycle context")
	return nil
}

func main() {
	// Initialize debug logging
	initDebugLog()
	defer closeDebugLog()

	// Read JSON input from stdin
	inputBytes, err := io.ReadAll(os.Stdin)
	if err != nil {
		debugLogf("ERROR: Failed to read stdin: %v", err)
		os.Exit(0) // Always exit 0 for SessionStart
	}

	var input SessionStartInput
	if err := json.Unmarshal(inputBytes, &input); err != nil {
		debugLogf("ERROR: Failed to parse JSON: %v", err)
		os.Exit(0)
	}

	debugLogf("SessionStart hook invoked: session=%s, cwd=%s", input.SessionID, input.CWD)

	// Check if this is main thread (clear any stale context)
	if isMainThread(input.SessionID, input.CWD) {
		debugLogf("Main thread detected - clearing any stale context")
		clearStaleContext()
		os.Exit(0)
	}

	// Try to detect subagent context
	agentType, isSubagent := detectSubagentContext(input.SessionID, input.CWD)
	if isSubagent {
		debugLogf("Subagent context detected: %s", agentType)

		// Set the quality cycle context
		if err := setQualityCycleContext(agentType, input.SessionID); err != nil {
			debugLogf("Warning: Failed to set quality cycle context: %v", err)
			os.Exit(0) // Still exit 0 to not block session
		}

		debugLogf("Successfully set quality cycle context")

		// Output success message to stdout (informational)
		fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		fmt.Println("✅ Quality Cycle Context Activated")
		fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		fmt.Println()
		fmt.Printf("Agent Type: %s\n", agentType)
		fmt.Printf("Session ID: %s\n", input.SessionID)
		fmt.Printf("Working Directory: %s\n", input.CWD)
		fmt.Println()
		fmt.Println("Quality cycle operations are now permitted in this session.")
		fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	} else {
		debugLogf("No subagent context detected - normal session")
	}

	// Exit successfully to not block session
	os.Exit(0)
}
