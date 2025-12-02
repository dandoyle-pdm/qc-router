# Code Review Checklists

Detailed checklists for Reviewer and Judge phases of quality cycles.

**Part of**: [Git Worktree Management](../SKILL.md)

## Purpose

This guide provides comprehensive checklists for reviewing code (Reviewer role) and validating changes (Judge role) during quality cycles. Use these checklists systematically to ensure thorough, consistent reviews.

**When to use**: During Reviewer and Judge phases of code quality workflows.

**See**: [Code Quality Workflows](code-quality-workflows.md) for workflow overview and [Code Workflow Procedures](code-workflow-procedures.md) for detailed step-by-step procedures.

## Reviewer Checklist

Use this checklist when reviewing code changes during the Reviewer phase.

### Security Vulnerabilities

Check for common security issues (OWASP Top 10):
- [ ] **Injection**: SQL, NoSQL, command, LDAP injection vulnerabilities
- [ ] **Authentication**: Broken authentication, session management issues
- [ ] **Sensitive Data**: Exposure of sensitive data (passwords, tokens, PII)
- [ ] **XML/XXE**: XML external entities vulnerabilities
- [ ] **Access Control**: Broken access control, privilege escalation
- [ ] **Security Misconfiguration**: Default credentials, verbose errors, open S3 buckets
- [ ] **XSS**: Cross-site scripting in user inputs or outputs
- [ ] **Deserialization**: Insecure deserialization of untrusted data
- [ ] **Dependencies**: Known vulnerabilities in dependencies
- [ ] **Logging**: Insufficient logging, monitoring, or audit trails

### Test Coverage

Verify adequate testing:
- [ ] **Unit tests** exist for new functions/methods
- [ ] **Integration tests** cover cross-component interactions
- [ ] **Edge cases** tested (empty inputs, null, boundary values, max sizes)
- [ ] **Error paths** tested (what happens when things fail)
- [ ] **Happy path** tested (expected successful flow)
- [ ] **Test quality**: Tests are clear, maintainable, and actually test behavior

### Error Handling

Check error handling completeness:
- [ ] **All errors caught** and handled appropriately
- [ ] **Error messages** are clear and actionable (for developers and users)
- [ ] **No silent failures** (errors logged or surfaced)
- [ ] **Graceful degradation** where appropriate
- [ ] **Resource cleanup** in error paths (close files, connections, etc.)

### Performance Implications

Consider performance impact:
- [ ] **No N+1 queries** or obvious performance bottlenecks
- [ ] **Efficient algorithms** used for data processing
- [ ] **Caching** considered where appropriate
- [ ] **Database indexes** exist for common queries
- [ ] **Memory usage** reasonable (no memory leaks, large allocations handled)

### Pattern Consistency

Verify consistency with codebase:
- [ ] **Follows existing patterns** for similar functionality
- [ ] **Naming conventions** match codebase style
- [ ] **Code organization** consistent with project structure
- [ ] **Abstractions** align with existing architectural patterns
- [ ] **Dependencies** managed consistently (same versions, similar libraries)

### Backwards Compatibility

For maintenance work, check compatibility:
- [ ] **No breaking API changes** without deprecation period
- [ ] **Migration paths** provided for breaking changes
- [ ] **Existing functionality** still works as expected
- [ ] **Database migrations** reversible or provide rollback
- [ ] **Configuration changes** documented and backwards compatible

### Edge Cases and Validation

Verify edge case handling:
- [ ] **Input validation** on all user-provided data
- [ ] **Boundary conditions** handled (min/max, empty, null)
- [ ] **Concurrency** issues considered (race conditions, deadlocks)
- [ ] **Timeout handling** for external calls
- [ ] **Resource limits** respected (file sizes, request limits, memory)

### Code Quality and Maintainability

Assess general code quality:
- [ ] **Clear and readable** code with appropriate comments
- [ ] **Well-named** variables, functions, and classes
- [ ] **Appropriate complexity** (not over-engineered, not too simplistic)
- [ ] **Documentation** exists for non-obvious behavior
- [ ] **No dead code** or commented-out code blocks

## Judge Validation Checklist

Use this checklist when validating changes during the Judge phase.

### Automated Test Validation

Run and verify test suites:
- [ ] **All unit tests pass**
```bash
npm test  # or pytest, cargo test, go test, etc.
```
- [ ] **All integration tests pass**
```bash
npm run test:integration
```
- [ ] **Test coverage** meets project requirements (if enforced)
```bash
npm run test:coverage
```

### Code Quality Checks

Run linting and formatting:
- [ ] **Linting passes** with no errors
```bash
npm run lint
```
- [ ] **Formatting** consistent with project style
```bash
npm run format:check
```

### Type Safety Validation

Run type checking (if applicable):
- [ ] **Type checking passes** with no errors
```bash
npm run typecheck  # or mypy, cargo check, etc.
```

### Security Validation

Run security scans:
- [ ] **No known vulnerabilities** in dependencies
```bash
npm audit  # or pip-audit, cargo audit, etc.
```
- [ ] **Security scans** pass (if project uses SAST tools)

### Build Validation

Verify build succeeds:
- [ ] **Build completes** successfully
```bash
npm run build
```
- [ ] **No build warnings** (or acceptable warnings documented)

### Regression Validation

Check for regressions:
- [ ] **No tests broken** that previously passed
- [ ] **Performance benchmarks** within tolerance (if applicable)
- [ ] **No new errors** in logs during test runs

### Reviewer Approval

Verify review status:
- [ ] **Reviewer has approved** (check REVIEWER_FEEDBACK.md status)
- [ ] **All required changes** addressed by Creator
- [ ] **No unresolved discussion** points remain

### Merge Readiness

Final merge checks:
- [ ] **No merge conflicts** with main branch
```bash
git fetch origin main
git merge origin/main  # Should merge cleanly
```
- [ ] **Branch is up to date** with main
- [ ] **All commits** properly formatted and descriptive

## Related Concepts

- [Code Quality Workflows](code-quality-workflows.md) - Workflow overview and role definitions
- [Code Workflow Procedures](code-workflow-procedures.md) - Detailed step-by-step procedures using these checklists
- [Integration Workflows](integration-workflows.md) - Merging to main after Judge approval
- [Git Worktree Management](../SKILL.md) - Overall skill documentation

## See Also

**Back to**: [Git Worktree Management](../SKILL.md)
