---
name: cr
description: Performs a high-confidence code review using a validate-then-present approach. Every finding is verified as a real issue with a concrete fix before being shown. Triggered by: /cr, /cr pr [number], /cr diff, /cr staged, /cr unpushed, /cr path/to/file. Also triggered when user says "review this", "review the PR", "review staged changes", "review my changes", "code review", or similar review requests.
---

# Code Review Skill (`/cr`)

## Arguments

| Usage              | Mode        | Description                                             |
| ------------------ | ----------- | ------------------------------------------------------- |
| `/cr`              | auto-detect | Staged → unstaged → unpushed → error                    |
| `/cr pr [N]`       | PR          | Review PR #N (or current branch's open PR if N omitted) |
| `/cr diff`         | diff        | Review all local changes (staged + unstaged)            |
| `/cr staged`       | staged      | Review only staged changes                              |
| `/cr unstaged`     | unstaged    | Review only unstaged changes                            |
| `/cr unpushed`     | unpushed    | Review commits not yet pushed to remote                 |
| `/cr path/to/file` | file        | Review a specific file or glob pattern                  |

## Workflow

### Step 1 — Parse arguments & detect mode

Determine review mode from argument:

- No argument → check `git diff --cached --stat` (staged?), then `git diff --stat` (unstaged?), then `git log @{u}.. --oneline 2>/dev/null` (unpushed?). Use first non-empty. If all empty, report nothing to review.
- `pr [N]` → resolve PR number (if N omitted, use `gh pr view --json number -q .number`)
- `diff` → `git diff HEAD`
- `staged` → `git diff --cached`
- `unstaged` → `git diff`
- `unpushed` → `git log @{u}.. -p` (or `git log HEAD...origin/$(git branch --show-current) -p` if no upstream)
- `path/to/file` → read file(s) directly

### Step 2 — Gather code

Collect the full diff or file content. For PR mode: use `gh pr diff [N]` for the diff and `gh pr view [N] --json title,body,headRefName` for context. Note the programming language(s) involved.

For diffs: also read surrounding context with Read tool for any changed files — understand what the code is doing before generating candidates.

### Step 3 — Generate candidate findings

Scan the gathered code using the checklist in `references/review-checklist.md`. Generate a list of **candidate findings** — potential issues noticed. Do NOT output this list. This is an internal working step.

For each candidate record:

- Location (file:line)
- Category (bug, security, edge-case, performance, design, overengineering)
- Hypothesis: what you think might be wrong and why
- Evidence needed to confirm

### Step 4 — Validate each candidate (CRITICAL)

**This step separates real issues from hallucinations. Do NOT skip it.**

For each candidate finding, use Read, Grep, and LSP tools to verify:

**Validation checklist:**

1. **Is it actually a bug?** Read the code around the flagged location. Is the behavior intentional? Is there a comment explaining it? Is it handled elsewhere in the call chain?
2. **Does this pattern work elsewhere?** Grep for similar patterns in the codebase. If the pattern is used in 10 places and works fine, your hypothesis is likely wrong.
3. **Is tooling already catching this?** If a linter, compiler, or type-checker would catch it, drop it — the build process handles it.
4. **Is there a concrete failure scenario?** Can you describe exactly what input or state would trigger the bug? If you can only say "this _might_ cause issues", drop it.
5. **Can you propose a specific fix?** If you can only say "consider improving this", drop it. A valid finding has a specific, actionable fix with example code.

**Confidence scoring (0–100):**

- Start at 50
- +30 if you can reproduce the failure scenario concretely (specific input → specific bad output)
- +20 if grep/LSP confirms the issue isn't handled elsewhere
- +10 if the consequence is severe (data loss, crash, security breach)
- -20 if the pattern appears elsewhere in the codebase without issues
- -20 if it's purely theoretical ("could happen if...")
- -30 if you can't write a concrete fix (only vague suggestions)

**Drop policy — drop findings that are:**

- Confidence < 80
- Cosmetic or stylistic (formatting, naming preferences)
- Speculative ("might cause issues", "could potentially")
- Already caught by linter/compiler/type-checker
- Intentional patterns (documented, consistent, or explained by context)
- Redundant with other findings
- "Consider" suggestions with no concrete fix

### Step 5 — Present validated findings

Show only findings that survived Step 4 (confidence ≥ 80).

**If zero findings survived:** Say "No issues found" with one sentence on what you checked. Do NOT invent findings to seem useful.

**Format for each finding:**

```
## [SEVERITY] Finding N: <short title>

**File:** `path/to/file.go:42`
**Category:** Bug / Security / Edge Case / Performance / Design
**Confidence:** 87/100

**Problem:** Clear description of what is wrong and why it matters.
Describe the exact failure scenario: "When X happens, Y occurs, causing Z."

**Evidence:** What you found in the code that confirms this is real
(e.g., "Line 42 does X without checking Y, and grep shows no other guard").

**Fix:**
\`\`\`go
// Concrete code showing exactly how to fix it
\`\`\`
```

Order findings: Critical → High → Medium → Low.

Omit severity levels with no findings. End with a summary line: `N findings: X critical, Y high, Z medium, W low.`

### Step 6 — PR mode: ask before posting

If in PR mode and findings exist, ask:

> "Post these findings as a PR comment? (yes/no)"

If yes: use `gh pr comment [N] --body "..."` with a clean markdown version of the findings (omit confidence scores from the posted comment — they're internal signals, not useful for PR reviewers).

If no findings: do not ask about posting.

---

## Anti-Hallucination Rules

**These are hard rules. Never violate them.**

1. **Never flag something you haven't read.** Before reporting a bug on line 42, you must have read lines 30–60 and understood the context.
2. **Absence of evidence is not evidence of a problem.** If you don't see error handling, check if the caller handles it. If you don't see a nil check, check if nil is possible.
3. **One data point is not a pattern.** If you find a pattern once, grep for it across the codebase before deciding it's wrong.
4. **If you're uncertain, drop it.** The user would rather see 2 real bugs than 10 speculative ones. A false positive wastes their time and erodes trust.
5. **Never use "consider", "might", "could", "potentially" in findings.** These words are signals that the finding is speculative. If you can't state the problem definitively, drop it.
6. **If the language/framework makes it safe, it's safe.** Don't flag issues that the type system, borrow checker, or GC already prevents.
