# Code Review Checklist

This checklist is a list of **things to look for**, not things to blindly report.
For every item you notice, you MUST verify it's actually a problem before adding it to candidates.

---

## Bugs & Correctness

- **Off-by-one errors**: Loop bounds, slice indices, length vs capacity checks.
  - Verify: trace what values the index takes at start and end of loop. Is the last element accessed? Is an index ever out-of-bounds?
- **Nil/null dereference**: Pointer access without nil check.
  - Verify: Can this value actually be nil here? Check callers. Check if the language makes this impossible (non-nullable type, etc.).
- **Error ignored**: `err` returned but not checked.
  - Verify: Is the error checked by the caller? Is it intentionally swallowed (and if so, is that safe)?
- **Wrong error handling**: Error checked but action taken is wrong (e.g., continuing after a fatal error).
  - Verify: What happens if the error occurs and execution continues? Is data corrupted?
- **Integer overflow/underflow**: Arithmetic on bounded integer types.
  - Verify: What are the realistic maximum/minimum values? Is overflow actually possible?
- **Use after free / dangling reference**: In non-GC languages.
  - Verify: Is the original still accessible? Is the borrow/ownership correct?
- **Incorrect comparison**: Using `=` instead of `==`, comparing wrong fields, wrong types.
  - Verify: Read the comparison carefully. What are the types on each side?
- **Wrong default/zero value assumption**: Assuming a variable has a specific initial value.
  - Verify: How is the variable initialized? Is the zero value actually problematic?
- **Resource leak**: File, connection, goroutine not closed/released on all paths.
  - Verify: Trace every code path through the function. Is the resource always released?
- **Incorrect mutex scope**: Lock released too early, or locked twice (deadlock).
  - Verify: Map out lock acquisitions and releases across all paths.

---

## Security

- **SQL injection**: String interpolation in SQL queries.
  - Verify: Is this actually user-controlled input? Is there parameterization elsewhere?
- **XSS**: Unescaped user input in HTML context.
  - Verify: Is this output escaped by the template engine? Is this actually user data?
- **Path traversal**: File paths constructed from user input without sanitization.
  - Verify: Can the user supply `../` sequences? Is there a whitelist check?
- **Hardcoded credentials**: API keys, passwords, tokens in source.
  - Verify: Is it actually a credential or a placeholder? Is it a test value?
- **Insecure deserialization**: Deserializing untrusted data without validation.
  - Verify: Is this input actually untrusted? Is there schema validation?
- **Missing auth check**: Privileged operation without authorization check.
  - Verify: Is auth checked at a higher level (middleware, gateway)? Check the call chain.
- **Timing attack**: Secret comparison with `==` instead of constant-time comparison.
  - Verify: Is this actually a secret (token, password, HMAC)? Is `==` used?
- **Insecure random**: Using non-cryptographic random for security-sensitive values.
  - Verify: Is this value used for security (token, nonce, key)? What RNG is used?
- **Log injection**: User input logged without sanitization, enabling log forging.
  - Verify: Is this actually user-controlled? Would it affect log parsing?

---

## Edge Cases & Race Conditions

- **Empty collection**: Code assumes non-empty slice/map/string.
  - Verify: Is empty input possible? What happens when the collection has 0 items?
- **Concurrent map access**: Map read/written from multiple goroutines without sync.
  - Verify: Are there multiple goroutines? Is there a mutex or channel protecting this?
- **TOCTOU (time-of-check vs time-of-use)**: Check-then-act without atomicity.
  - Verify: Can state change between the check and the use? What's the consequence?
- **Context not propagated**: Long operation doesn't respect context cancellation.
  - Verify: Is a context available? Is it passed to blocking calls?
- **Partial failure**: Batch operation where some items fail but the error is lost.
  - Verify: What happens when item N of M fails? Is the error surfaced?
- **Integer conversion truncation**: `int64` to `int32`, etc.
  - Verify: Can the value actually exceed the target type's range?

---

## Performance

- **N+1 query**: DB query inside a loop.
  - Verify: Is there really a DB call per iteration? Could it be batched?
- **Unbounded growth**: Slice/map that grows without bound (memory leak).
  - Verify: Is there a cleanup path? Is there a cap?
- **Unnecessary allocation in hot path**: Allocation inside a tight loop or frequently-called function.
  - Verify: Is this actually hot? Profile evidence, not speculation.
- **Quadratic algorithm**: Nested loops over the same data.
  - Verify: What's the realistic input size? Is this actually O(N²) in practice?
- **Serialization under lock**: IO or slow operation while holding a mutex.
  - Verify: Is this actually slow? Is it inside a locked section?

---

## Architecture & Design

- **Abstraction leak**: Implementation detail exposed in a public API.
  - Verify: Is this detail intentional (e.g., for testing)? Does it couple consumers to internals?
- **Missing interface**: Concrete type used where an interface would allow testing/extension.
  - Verify: Is this actually tested? Is it actually extended? Don't flag if neither is needed.
- **God function**: Single function doing too many distinct things (> ~40 lines with multiple concerns).
  - Verify: Are the concerns actually separable? Is the complexity incidental or inherent?
- **Circular dependency**: Package A imports B which imports A.
  - Verify: Use LSP or import graph. Don't guess.
- **Configuration not validated**: External config parsed but not validated.
  - Verify: Can invalid config cause a hard-to-debug failure? Is validation done elsewhere?

---

## Overengineering

- **Unnecessary abstraction**: Interface with a single implementation, never extended.
  - Verify: Is there actually a second implementation planned? Don't flag if it exists for testing.
- **Premature optimization**: Complex code to optimize something not on the hot path.
  - Verify: Is there evidence (benchmark, profiling) this matters?
- **Unused flexibility**: Config options, feature flags, or generics that are never used.
  - Verify: Search the codebase. Is there actually no use?
- **Over-parameterization**: Function takes 8 parameters, most always the same value.
  - Verify: Are the parameters actually variable? Would callers benefit from a simpler API?

---

## How to Use This Checklist

1. Scan the diff/code and note which items from above *might* apply.
2. For each: use Read/Grep/LSP to verify it's actually a problem.
3. If you can't verify it in 2–3 tool calls, drop it.
4. Only confirmed, concrete issues with specific fixes become findings.
