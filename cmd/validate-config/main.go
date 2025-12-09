package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// Exit codes matching shell script
const (
	ExitPass    = 0
	ExitWarning = 1
	ExitFail    = 2
)

// ANSI color codes
const (
	Red    = "\033[0;31m"
	Green  = "\033[0;32m"
	Yellow = "\033[1;33m"
	Blue   = "\033[0;34m"
	NC     = "\033[0m" // No Color
)

// Counters
var (
	passCount int
	warnCount int
	failCount int
)

// Settings structures
type Settings struct {
	AlwaysThinkingEnabled *bool                  `json:"alwaysThinkingEnabled"`
	DisableAllHooks       *bool                  `json:"disableAllHooks"`
	Env                   map[string]interface{} `json:"env"`
	Hooks                 *HooksConfig           `json:"hooks"`
}

type HooksConfig struct {
	SessionStart []HookEntry `json:"SessionStart"`
	PreToolUse   []HookEntry `json:"PreToolUse"`
	PostToolUse  []HookEntry `json:"PostToolUse"`
}

type HookEntry struct {
	Matcher *string      `json:"matcher"`
	Hooks   []HookDetail `json:"hooks"`
}

type HookDetail struct {
	Type    string  `json:"type"`
	Command string  `json:"command"`
	Timeout *int    `json:"timeout"`
}

// Print functions
func printPass(msg string) {
	fmt.Printf("%s[PASS]%s %s\n", Green, NC, msg)
	passCount++
}

func printWarn(msg string) {
	fmt.Printf("%s[WARN]%s %s\n", Yellow, NC, msg)
	warnCount++
}

func printFail(msg string) {
	fmt.Printf("%s[FAIL]%s %s\n", Red, NC, msg)
	failCount++
}

func printInfo(msg string) {
	fmt.Printf("%s[INFO]%s %s\n", Blue, NC, msg)
}

func printSection(title string) {
	fmt.Printf("\n%s═══ %s ═══%s\n", Blue, title, NC)
}

// Check if file exists
func checkFileExists(path, description string) bool {
	if _, err := os.Stat(path); err == nil {
		printPass(fmt.Sprintf("%s exists: %s", description, path))
		return true
	}
	printFail(fmt.Sprintf("%s not found: %s", description, path))
	return false
}

// Validate JSON syntax
func validateJSONSyntax(path string) ([]byte, bool) {
	data, err := os.ReadFile(path)
	if err != nil {
		printFail("Failed to read file")
		return nil, false
	}

	var js json.RawMessage
	if err := json.Unmarshal(data, &js); err != nil {
		printFail("JSON syntax invalid")
		fmt.Printf("  %v\n", err)
		return nil, false
	}

	printPass("JSON syntax valid")
	return data, true
}

// Check JSON field
func checkJSONField(settings *Settings, field, description string) {
	switch field {
	case ".alwaysThinkingEnabled":
		if settings.AlwaysThinkingEnabled != nil {
			printPass(fmt.Sprintf("%s: %t", description, *settings.AlwaysThinkingEnabled))
		} else {
			printWarn(fmt.Sprintf("%s not found", description))
		}
	case ".disableAllHooks":
		if settings.DisableAllHooks != nil {
			printPass(fmt.Sprintf("%s: %t", description, *settings.DisableAllHooks))
		} else {
			printWarn(fmt.Sprintf("%s not found", description))
		}
	case ".env.CLAUDE_QC_OVERRIDE":
		if settings.Env != nil {
			if val, ok := settings.Env["CLAUDE_QC_OVERRIDE"]; ok {
				printPass(fmt.Sprintf("%s: %v", description, val))
			} else {
				printWarn(fmt.Sprintf("%s not found", description))
			}
		} else {
			printWarn(fmt.Sprintf("%s not found", description))
		}
	}
}

// Validate hook structure
func validateHookStructure(hookType string, entries []HookEntry, requireMatcher bool) {
	if entries == nil {
		printInfo(fmt.Sprintf("Hook type '%s' not configured (optional)", hookType))
		return
	}

	printInfo(fmt.Sprintf("Validating %s hook structure...", hookType))
	printInfo(fmt.Sprintf("Found %d hook configuration(s) for %s", len(entries), hookType))

	for i, entry := range entries {
		// Check nested hooks array
		if len(entry.Hooks) > 0 {
			printPass(fmt.Sprintf("Hook config %d has nested hooks array (%d hook(s))", i, len(entry.Hooks)))

			// Validate each nested hook
			for j, hook := range entry.Hooks {
				// Check type field
				if hook.Type != "" {
					printPass(fmt.Sprintf("  Hook %d.%d: type = '%s'", i, j, hook.Type))
				} else {
					printFail(fmt.Sprintf("  Hook %d.%d: missing 'type' field", i, j))
				}

				// Check command field
				if hook.Command != "" {
					cmdPreview := hook.Command
					if len(cmdPreview) > 50 {
						cmdPreview = cmdPreview[:50] + "..."
					}
					printPass(fmt.Sprintf("  Hook %d.%d: command = '%s'", i, j, cmdPreview))
				} else {
					printFail(fmt.Sprintf("  Hook %d.%d: missing 'command' field", i, j))
				}

				// Check timeout field
				if hook.Timeout != nil {
					if *hook.Timeout >= 0 {
						printPass(fmt.Sprintf("  Hook %d.%d: timeout = %ds", i, j, *hook.Timeout))
					} else {
						printWarn(fmt.Sprintf("  Hook %d.%d: timeout value negative: %d", i, j, *hook.Timeout))
					}
				} else {
					printWarn(fmt.Sprintf("  Hook %d.%d: no timeout specified (may use default)", i, j))
				}
			}
		} else {
			printWarn(fmt.Sprintf("Hook config %d missing nested 'hooks' array", i))
		}

		// Check matcher (required for PreToolUse/PostToolUse)
		if requireMatcher {
			if entry.Matcher != nil && *entry.Matcher != "" {
				printPass(fmt.Sprintf("Hook config %d has matcher: '%s'", i, *entry.Matcher))
			} else {
				printFail(fmt.Sprintf("Hook config %d missing 'matcher' (required for %s)", i, hookType))
			}
		}
	}
}

// Check hooks debug log
func checkHooksLog(logPath string) {
	if _, err := os.Stat(logPath); os.IsNotExist(err) {
		printWarn("Hooks debug log not found (no hooks executed yet?)")
		return
	}

	file, err := os.Open(logPath)
	if err != nil {
		printWarn(fmt.Sprintf("Failed to read hooks log: %v", err))
		return
	}
	defer file.Close()

	// Read file and find session ID
	var sessionID string
	scanner := bufio.NewScanner(file)
	sessionPattern := regexp.MustCompile(`session: ([a-f0-9-]+)`)

	var lines []string
	for scanner.Scan() {
		line := scanner.Text()
		lines = append(lines, line)
		if matches := sessionPattern.FindStringSubmatch(line); len(matches) > 1 {
			sessionID = matches[1]
		}
	}

	if sessionID == "" {
		printWarn("No session ID found in hooks log")
		return
	}

	printInfo(fmt.Sprintf("Current session: %s", sessionID))

	// Count executions and errors for current session
	execCount := 0
	errorCount := 0
	errorPattern := regexp.MustCompile(`(?i)error|fail|timeout`)
	var errorLines []string

	for _, line := range lines {
		if strings.Contains(line, "session: "+sessionID) {
			execCount++
			if errorPattern.MatchString(line) {
				errorCount++
				errorLines = append(errorLines, line)
			}
		}
	}

	printInfo(fmt.Sprintf("Hook executions this session: %d", execCount))

	if errorCount == 0 {
		printPass("No errors found in hooks log for current session")
	} else {
		printFail(fmt.Sprintf("Found %d potential error(s) in hooks log", errorCount))
		fmt.Println("Recent errors:")
		// Show last 5 errors
		start := len(errorLines) - 5
		if start < 0 {
			start = 0
		}
		for _, line := range errorLines[start:] {
			fmt.Printf("  %s\n", line)
		}
	}
}

// Check SessionStart hook execution
func checkSessionStartExecution(logPath string) {
	if _, err := os.Stat(logPath); os.IsNotExist(err) {
		printWarn("Session test log not found (SessionStart hook not configured or not executed)")
		return
	}

	file, err := os.Open(logPath)
	if err != nil {
		printWarn(fmt.Sprintf("Failed to read session log: %v", err))
		return
	}
	defer file.Close()

	// Get last line
	var lastLine string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lastLine = scanner.Text()
	}

	if lastLine != "" {
		printPass(fmt.Sprintf("SessionStart hook executed: %s", lastLine))
	} else {
		printWarn("Session test log exists but is empty")
	}
}

func main() {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error getting home directory: %v\n", err)
		os.Exit(ExitFail)
	}

	settingsFile := filepath.Join(homeDir, ".claude", "settings.json")
	hooksLog := filepath.Join(homeDir, ".claude", "logs", "hooks-debug.log")
	sessionLog := filepath.Join(homeDir, ".claude", "logs", "session-test.log")

	// Print header
	fmt.Printf("%s╔═══════════════════════════════════════════════════════════╗%s\n", Blue, NC)
	fmt.Printf("%s║  Claude Code Hooks Configuration Validator               ║%s\n", Blue, NC)
	fmt.Printf("%s╚═══════════════════════════════════════════════════════════╝%s\n", Blue, NC)

	// Phase 1: File existence
	printSection("File Existence Checks")
	settingsExists := checkFileExists(settingsFile, "Settings file")

	if !settingsExists {
		printSection("Validation Summary")
		fmt.Printf("%sPassed:  %d%s\n", Green, passCount, NC)
		fmt.Printf("%sWarnings: %d%s\n", Yellow, warnCount, NC)
		fmt.Printf("%sFailed:   %d%s\n", Red, failCount, NC)
		fmt.Println()
		fmt.Printf("%sValidation FAILED with critical errors%s\n", Red, NC)
		os.Exit(ExitFail)
	}

	// Phase 2: JSON syntax
	printSection("JSON Syntax Validation")
	data, jsonValid := validateJSONSyntax(settingsFile)
	if !jsonValid {
		printSection("Validation Summary")
		fmt.Printf("%sPassed:  %d%s\n", Green, passCount, NC)
		fmt.Printf("%sWarnings: %d%s\n", Yellow, warnCount, NC)
		fmt.Printf("%sFailed:   %d%s\n", Red, failCount, NC)
		fmt.Println()
		fmt.Printf("%sValidation FAILED with critical errors%s\n", Red, NC)
		os.Exit(ExitFail)
	}

	// Parse settings
	var settings Settings
	if err := json.Unmarshal(data, &settings); err != nil {
		printFail(fmt.Sprintf("Failed to parse settings: %v", err))
		os.Exit(ExitFail)
	}

	// Phase 3: Basic configuration
	printSection("Basic Configuration")
	checkJSONField(&settings, ".alwaysThinkingEnabled", "Always thinking enabled")
	checkJSONField(&settings, ".disableAllHooks", "Hooks disabled")

	// Phase 4: Environment variables
	printSection("Environment Variables")
	checkJSONField(&settings, ".env.CLAUDE_QC_OVERRIDE", "QC Override")

	// Phase 5: Hook structure validation
	printSection("Hook Structure Validation")
	if settings.Hooks != nil {
		printPass("Hooks configuration exists")
		validateHookStructure("SessionStart", settings.Hooks.SessionStart, false)
		validateHookStructure("PreToolUse", settings.Hooks.PreToolUse, true)
		validateHookStructure("PostToolUse", settings.Hooks.PostToolUse, true)
	} else {
		printInfo("No hooks configured (optional)")
	}

	// Phase 6: Log file analysis
	printSection("Log File Analysis")
	checkHooksLog(hooksLog)
	checkSessionStartExecution(sessionLog)

	// Summary
	printSection("Validation Summary")
	fmt.Printf("%sPassed:  %d%s\n", Green, passCount, NC)
	fmt.Printf("%sWarnings: %d%s\n", Yellow, warnCount, NC)
	fmt.Printf("%sFailed:   %d%s\n", Red, failCount, NC)
	fmt.Println()

	// Exit code
	if failCount > 0 {
		fmt.Printf("%sValidation FAILED with critical errors%s\n", Red, NC)
		os.Exit(ExitFail)
	} else if warnCount > 0 {
		fmt.Printf("%sValidation completed with warnings%s\n", Yellow, NC)
		os.Exit(ExitWarning)
	} else {
		fmt.Printf("%sAll validation checks PASSED%s\n", Green, NC)
		os.Exit(ExitPass)
	}
}
