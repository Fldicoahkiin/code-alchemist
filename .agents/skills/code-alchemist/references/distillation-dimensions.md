# Distillation Dimensions

Only capture repeatable engineering habits. Do not capture private tone, mood, or one-off background details.

## 1. Naming And Vocabulary

Look for:

- stable domain terms
- short versus explicit variable names
- repeated conventions for types, functions, and directories
- preferred suffixes such as `Service`, `Store`, `Client`, or `Repository`

Evidence priority:

1. high-touch files that still exist
2. names preserved across multiple edits
3. newly added code in representative commits

## 2. Structure And Boundaries

Look for:

- whether files stay focused on a single responsibility
- whether logic is kept inline or extracted into helpers
- how interfaces, DTOs, components, and modules are split
- whether the author prefers shallow or layered directory structures

## 3. Data And Control Flow

Look for:

- where state enters, changes, and persists
- whether the author leans toward pure functions, immutable updates, or pipeline-style composition
- whether validation is usually pushed to the edge of the flow

## 4. Error Handling And Observability

Look for:

- whether errors are thrown directly, wrapped, or converted into return values
- whether context is preserved in error paths
- whether logging, metrics, or tracing hooks appear consistently

## 5. Testing Habits

Look for:

- whether tests move with logic changes
- whether the author leans toward unit, integration, or smoke coverage
- whether test naming and layout are stable
- whether regression coverage appears before or during refactors

## 6. Comments And Documentation

Look for:

- whether comments are sparse but precise
- whether comments explain "what" or "why"
- whether magic numbers, protocol bits, or edge conditions are turned into named constants with context

## 7. Change Granularity And Commit Shape

Look for:

- whether commits are small and focused or wide and batch-oriented
- whether refactors are mixed with feature work
- which commit verbs and subject lengths repeat

## 8. Explicit Anti-Patterns

Prefer to identify what the author repeatedly avoids:

- naming styles they do not use
- abstraction depth they avoid
- testing structures they do not keep
- error-handling styles they consistently replace

## Confidence Template

Record each rule in this shape:

```markdown
- Rule:
- Evidence:
  - Files:
  - Commits:
- Confidence: high | medium | low
- Counterexamples:
- Applicability:
```

## Down-Weight These Cases

Reduce the weight of:

- mechanical formatting passes
- bulk dependency updates
- generated files
- pure asset changes
- comment-only or copy-only edits
- merge commits
