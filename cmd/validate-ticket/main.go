package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Exit codes matching shell script
const (
	ExitValid   = 0
	ExitInvalid = 1
	ExitError   = 2
)

type TicketMeta struct {
	TicketID     string
	WorktreePath string
	Status       string
}

func parseTicketFrontmatter(path string) (*TicketMeta, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	meta := &TicketMeta{}
	scanner := bufio.NewScanner(file)
	inFrontmatter := false

	for scanner.Scan() {
		line := scanner.Text()

		if line == "---" {
			if inFrontmatter {
				break // End of frontmatter
			}
			inFrontmatter = true
			continue
		}

		if !inFrontmatter {
			continue
		}

		parts := strings.SplitN(line, ":", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		value := strings.TrimSpace(parts[1])

		switch key {
		case "ticket_id":
			meta.TicketID = value
		case "worktree_path":
			meta.WorktreePath = value
		case "status":
			meta.Status = value
		}
	}

	return meta, scanner.Err()
}

func validateTicket(ticketPath string) ([]string, error) {
	meta, err := parseTicketFrontmatter(ticketPath)
	if err != nil {
		return nil, err
	}

	var errors []string

	// Check 1: worktree_path is set
	if meta.WorktreePath == "null" || meta.WorktreePath == "" {
		errors = append(errors, "worktree_path is null - ticket not activated")
	}

	// Check 2: worktree_path exists
	if meta.WorktreePath != "null" && meta.WorktreePath != "" {
		if _, err := os.Stat(meta.WorktreePath); os.IsNotExist(err) {
			errors = append(errors, fmt.Sprintf("worktree_path does not exist: %s", meta.WorktreePath))
		}
	}

	// Check 3: cwd matches worktree_path
	if meta.WorktreePath != "null" && meta.WorktreePath != "" {
		cwd, _ := os.Getwd()
		if cwd != meta.WorktreePath && !strings.HasPrefix(cwd, meta.WorktreePath+"/") {
			errors = append(errors, "Current directory does not match worktree_path")
			errors = append(errors, fmt.Sprintf("  Expected: %s", meta.WorktreePath))
			errors = append(errors, fmt.Sprintf("  Actual:   %s", cwd))
		}
	}

	// Check 4: status is in_progress
	if meta.Status != "in_progress" {
		errors = append(errors, fmt.Sprintf("Ticket status is '%s', expected 'in_progress'", meta.Status))
	}

	return errors, nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: validate-ticket <ticket-path>")
		os.Exit(ExitError)
	}

	ticketPath := os.Args[1]

	// Resolve to absolute path
	absPath, err := filepath.Abs(ticketPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Invalid path: %s\n", ticketPath)
		os.Exit(ExitError)
	}

	if _, err := os.Stat(absPath); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "Ticket file not found: %s\n", ticketPath)
		os.Exit(ExitError)
	}

	errors, err := validateTicket(absPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading ticket: %v\n", err)
		os.Exit(ExitError)
	}

	if len(errors) > 0 {
		meta, _ := parseTicketFrontmatter(absPath)
		fmt.Fprintf(os.Stderr, "TICKET VALIDATION FAILED: %s\n\n", meta.TicketID)
		for _, e := range errors {
			fmt.Fprintf(os.Stderr, "  - %s\n", e)
		}
		fmt.Fprintln(os.Stderr, "")
		fmt.Fprintln(os.Stderr, "To activate ticket properly:")
		fmt.Fprintf(os.Stderr, "  ./scripts/activate-ticket.sh %s\n", ticketPath)
		os.Exit(ExitInvalid)
	}

	meta, _ := parseTicketFrontmatter(absPath)
	fmt.Printf("Ticket validated: %s\n", meta.TicketID)
	os.Exit(ExitValid)
}
