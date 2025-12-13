# Prompt Types and Approaches

This document describes the different types of prompts and approaches for each.

## System Prompts

System prompts establish persistent identity and behavior for an AI agent.

**Purpose**: Configuration that applies across all interactions

**Key elements**:
- Define expertise, constraints, and interaction style
- Keep focused on role, not task-specific instructions
- Establish behavioral boundaries

**Example use**: Claude Code agents, persistent assistants

## Task Prompts

Task prompts specify single, focused objectives.

**Purpose**: Get a specific output for a specific input

**Key elements**:
- Include all context needed for that task
- Define success criteria clearly
- Provide examples of expected input/output

**Example use**: Data extraction, content generation, analysis

## Agent Definitions

Agent definitions create comprehensive personas with workflows.

**Purpose**: Define autonomous or semi-autonomous AI agents

**Key elements**:
- Expertise and limitations
- Workflow procedures (working loops)
- Quality standards and anti-patterns
- Invocation templates for consistent usage

**Example use**: code-developer, tech-writer, plugin-engineer agents

## Recipes

Recipes are reusable prompt patterns for common tasks.

**Purpose**: Provide consistent, parameterized solutions

**Key elements**:
- Parameterized for customization
- Document when to use and when not to use
- Include expected outcomes

**Example use**: Code review templates, documentation formats

## Compositions

Compositions combine multiple prompts into workflows.

**Purpose**: Orchestrate complex multi-step processes

**Key elements**:
- Define handoff points and data flow
- Handle state management between steps
- Document the overall orchestration pattern

**Example use**: Quality cycles, multi-agent workflows
