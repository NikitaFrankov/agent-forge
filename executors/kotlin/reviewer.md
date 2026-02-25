# Kotlin Code Reviewer

Code review checklist and standards for Kotlin projects.

## Review Process

### Stage 1: Spec Compliance
Verify implementation matches requirements before code quality review.

### Stage 2: Code Quality
Evaluate Kotlin-specific quality standards.

---

## Kotlin Quality Checklist

### Null Safety
- [ ] No unnecessary `!!` operator usage
- [ ] Safe calls (`?.`) used appropriately
- [ ] Elvis operator (`?:`) provides sensible defaults
- [ ] `requireNotNull` / `checkNotNull` used for validation
- [ ] Platform types from Java handled properly

```kotlin
// BAD
val name = user!!.name  // Risky

// GOOD
val name = user?.name ?: "Unknown"
```

### Idiomatic Kotlin

- [ ] Data classes used for DTOs/value objects
- [ ] Expression bodies for simple functions
- [ ] Default parameters over overloads
- [ ] Extension functions for utility operations
- [ ] Sealed classes for closed hierarchies
- [ ] When expressions are exhaustive

```kotlin
// BAD
class UserDto(val id: String, val name: String)

// GOOD
data class UserDto(val id: String, val name: String)

// BAD
fun square(x: Int): Int { return x * x }

// GOOD
fun square(x: Int): Int = x * x
```

### Collections

- [ ] Immutable collections preferred (`List` over `MutableList`)
- [ ] Functional operations used (`map`, `filter`, `fold`)
- [ ] No unnecessary loops when collection operations exist
- [ ] Sequences used for large collections/chained operations

```kotlin
// BAD
val result = mutableListOf<String>()
for (user in users) {
    if (user.isActive) {
        result.add(user.name)
    }
}

// GOOD
val result = users
    .filter { it.isActive }
    .map { it.name }
```

### Coroutines

- [ ] Structured concurrency followed
- [ ] Proper dispatcher selection (`Dispatchers.IO` for I/O, `Dispatchers.Default` for CPU)
- [ ] Cancellation handled properly (re-throw `CancellationException`)
- [ ] Timeouts used for external calls
- [ ] No blocking calls in suspend functions

```kotlin
// BAD
suspend fun fetchData(): Data {
    return Thread.sleep(1000)  // Blocking!
}

// GOOD
suspend fun fetchData(): Data {
    delay(1000)  // Non-blocking
}
```

### Error Handling

- [ ] `Result<T>` used for expected failures
- [ ] Exceptions used for unexpected errors
- [ ] Error messages are meaningful
- [ ] No swallowed exceptions

```kotlin
// BAD
try {
    operation()
} catch (e: Exception) {
    // Silently ignored
}

// GOOD
try {
    operation()
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    log.error("Operation failed", e)
    Result.failure(e)
}
```

### Dependency Injection

- [ ] Constructor injection preferred
- [ ] No service locator pattern
- [ ] Interfaces over implementations
- [ ] Scopes defined correctly

```kotlin
// BAD
class UserService {
    private val repo = ServiceLocator.get<UserRepository>()
}

// GOOD
class UserService(
    private val repo: UserRepository
)
```

### Naming

- [ ] Classes: PascalCase (`UserService`)
- [ ] Functions: camelCase (`calculateTotal`)
- [ ] Properties: camelCase (`userName`)
- [ ] Constants: SCREAMING_SNAKE_CASE (`MAX_RETRIES`)
- [ ] Backing properties: underscore prefix (`_items`)

### Code Organization

- [ ] One class per file (except sealed classes, related small classes)
- [ ] Package structure follows convention
- [ ] No God classes (too many responsibilities)
- [ ] Functions are focused and small

### Testing

- [ ] All new code has tests
- [ ] Tests cover edge cases
- [ ] Mocks used appropriately
- [ ] Test names describe behavior

```kotlin
// BAD
@Test
fun test1() { ... }

// GOOD
it("should return user when found by valid id") { ... }
```

### Performance

- [ ] No unnecessary object creation in loops
- [ ] Lazy initialization for expensive objects
- [ ] Proper use of `inline` for higher-order functions
- [ ] Sequences for large collection operations

```kotlin
// BAD - creates intermediate lists
users.filter { it.isActive }.map { it.name }.take(10)

// GOOD - lazy evaluation
users.asSequence().filter { it.active }.map { it.name }.take(10).toList()
```

### Security

- [ ] No hardcoded credentials
- [ ] Input validation at boundaries
- [ ] SQL injection prevented (parameterized queries)
- [ ] Sensitive data not logged

---

## Common Issues

### Issue: Data Class with Logic

```kotlin
// BAD - data class with business logic
data class User(val name: String) {
    fun validate(): Boolean = name.isNotBlank()
}

// GOOD - separate concerns
data class User(val name: String)

class UserValidator {
    fun validate(user: User): Boolean = user.name.isNotBlank()
}
```

### Issue: Mutable State

```kotlin
// BAD
var counter = 0
fun increment() { counter++ }

// GOOD
class Counter(private val value: Int = 0) {
    fun increment() = Counter(value + 1)
}
```

### Issue: Exception for Control Flow

```kotlin
// BAD
fun findUser(id: String): User {
    val user = repository.findById(id) ?: throw NotFoundException()
    return user
}

// GOOD
fun findUser(id: String): Result<User> {
    val user = repository.findById(id) ?: return Result.failure("Not found")
    return Result.success(user)
}
```

### Issue: Premature Optimization

```kotlin
// BAD - complex for no reason
fun process(data: List<String>) = data
    .asSequence()
    .filter { it.isNotEmpty() }
    .map { it.uppercase() }
    .toList()

// GOOD - simple for small data
fun process(data: List<String>) = data
    .filter { it.isNotEmpty() }
    .map { it.uppercase() }
```

---

## Review Report Template

```markdown
## Code Review: [TASK-XXX]

**Verdict:** APPROVED | ISSUES_FOUND

### Spec Compliance
| Check | Status | Notes |
|-------|--------|-------|
| Acceptance criteria | ✅/❌ | |
| Required tests | ✅/❌ | |
| No scope creep | ✅/❌ | |

### Code Quality
| Category | Status | Issues |
|----------|--------|--------|
| Null Safety | ✅/❌ | |
| Idiomatic Kotlin | ✅/❌ | |
| Collections | ✅/❌ | |
| Coroutines | ✅/❌ | |
| Error Handling | ✅/❌ | |
| Testing | ✅/❌ | |
| Performance | ✅/❌ | |
| Security | ✅/❌ | |

### Issues Found
1. **[File.kt:45]** <issue>
   - Expected: <what>
   - Found: <what>

### Recommendations (optional)
- <improvement suggestion>
```

---

## Quick Reference

| Issue | Severity | Action |
|-------|----------|--------|
| `!!` operator | High | Require justification or change |
| Blocking in suspend | High | Must fix |
| No tests | High | Require tests |
| Swallowed exception | High | Must fix |
| God class | Medium | Consider refactoring |
| Non-idiomatic code | Low | Suggest improvement |
| Missing docs | Low | Suggest addition |
