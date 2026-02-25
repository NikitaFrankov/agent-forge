# Kotlin Debugger

Systematic debugging and error fixing for Kotlin projects.

## 50 Retry Strategy

When encountering persistent errors:

1. **Attempt 1-10**: Direct fixes based on error message
2. **Attempt 11-20**: Alternative patterns and approaches
3. **Attempt 21-30**: Refactor surrounding code
4. **Attempt 31-40**: Simplify implementation
5. **Attempt 41-50**: Check dependencies, configuration, external factors

If all 50 attempts fail: Stop and report to user.

## Common Error Patterns

### Null Pointer Exceptions

**Error:**
```
kotlin.NullPointerException
```

**Causes & Fixes:**

```kotlin
// BAD: Force unwrap
val name = user!!.name  // Crashes if user is null

// GOOD: Safe call with default
val name = user?.name ?: "Unknown"

// GOOD: Early return
val user = repository.findById(id) ?: return@withContext Result.failure("Not found")

// GOOD: Require/check
val validated = requireNotNull(input) { "Input required" }
```

### Type Mismatches

**Error:**
```
Type mismatch: required String, found String?
```

**Fixes:**

```kotlin
// Option 1: Provide default
val value: String = nullableValue ?: ""

// Option 2: Safe call with transformation
val length: Int = nullableValue?.length ?: 0

// Option 3: Filter nulls from collection
val nonNull: List<String> = list.filterNotNull()

// Option 4: MapNotNull
val results: List<Int> = items.mapNotNull { it.value }
```

### Smart Cast Issues

**Error:**
```
Smart cast to 'String' is impossible, because 'x' is a mutable property
```

**Fixes:**

```kotlin
// BAD
if (x != null) {
    x.length  // Error: smart cast impossible
}

// Option 1: Local immutable variable
val localX = x
if (localX != null) {
    localX.length  // Works!
}

// Option 2: Safe call
x?.length

// Option 3: Require/check
require(x != null)
x.length  // Works after require
```

### Coroutine Cancellation

**Error:**
```
kotlinx.coroutines.CancellationException
```

**Causes & Fixes:**

```kotlin
// BAD: Swallowing cancellation
try {
    suspendingFunction()
} catch (e: Exception) {
    // CancellationException caught here!
}

// GOOD: Re-throw cancellation
try {
    suspendingFunction()
} catch (e: CancellationException) {
    throw e  // Always re-throw!
} catch (e: Exception) {
    // Handle other exceptions
}

// GOOD: Use finally for cleanup
try {
    suspendingFunction()
} finally {
    cleanup()
}
```

### Timeout Issues

**Error:**
```
TimeoutCancellationException
```

**Fixes:**

```kotlin
// Increase timeout
withTimeout(30.seconds) {
    slowOperation()
}

// Or handle gracefully
val result = withTimeoutOrNull(10.seconds) {
    operation()
} ?: run {
    log.warn("Operation timed out, using fallback")
    fallbackValue
}
```

### Gradle Build Failures

**Error:**
```
Execution failed for task ':test'
```

**Debugging Steps:**

```bash
# 1. Clean build
./gradlew clean

# 2. Run with stacktrace
./gradlew test --stacktrace

# 3. Run with info logging
./gradlew test --info

# 4. Run specific test
./gradlew test --tests "ExactTestClass"

# 5. Check dependencies
./gradlew dependencies

# 6. Refresh dependencies
./gradlew build --refresh-dependencies
```

### Detekt Warnings

**Warning:**
```
ComplexMethod - Method is too complex
```

**Fixes:**

```kotlin
// Extract to smaller functions
fun processUser(user: User): Result {
    return when {
        !validateBasic(user) -> Result.invalid("basic")
        !validateEmail(user) -> Result.invalid("email")
        !validateAge(user) -> Result.invalid("age")
        else -> Result.valid()
    }
}

private fun validateBasic(user: User) = user.name.isNotBlank()
private fun validateEmail(user: User) = user.email.contains("@")
private fun validateAge(user: User) = user.age >= 0
```

**Warning:**
```
LongMethod - Method is too long
```

**Fix:** Extract logical sections into separate functions.

**Warning:**
```
MagicNumber - Magic number detected
```

**Fix:**
```kotlin
// BAD
Thread.sleep(5000)

// GOOD
companion object {
    private const val TIMEOUT_MS = 5000L
}
Thread.sleep(TIMEOUT_MS)
```

### Test Failures

**Error:**
```
AssertionFailedError: expected:<42> but was:<0>
```

**Debugging Steps:**

```kotlin
// 1. Add debug output
println("Debug: actual value is $actual")

// 2. Use soft assertions
assertSoftly {
    actual shouldBe 42
    actual shouldNotBe 0
}

// 3. Check test isolation
@BeforeTest
fun setup() {
    // Reset state
    MockKAnnotations.init(this)
    clearAllMocks()
}

// 4. Verify mock interactions
verify { repository.findById(any()) }
verify(exactly = 1) { service.process(any()) }
```

### Dependency Injection Issues

**Error:**
```
NoBeanDefFoundException: No definition found for ...
```

**Fixes:**

```kotlin
// 1. Check module is loaded
startKoin {
    modules(appModule, repositoryModule)
}

// 2. Check binding is defined
val appModule = module {
    single<UserRepository> { InMemoryUserRepository() }
    single<UserService> { UserService(get()) }  // get() injects UserRepository
}

// 3. Use named for multiple bindings
single<DataSource>(named("primary")) { PrimaryDataSource() }
single<DataSource>(named("replica")) { ReplicaDataSource() }

// 4. Inject by name
val primary: DataSource by inject(named("primary"))
```

### Serialization Issues

**Error:**
```
SerializationException: Serializer for class '...' is not found
```

**Fixes:**

```kotlin
// Add @Serializable annotation
@Serializable
data class User(
    val id: String,
    val name: String
)

// For sealed classes
@Serializable
sealed interface Event {
    @Serializable
    data class UserCreated(val id: String) : Event

    @Serializable
    data class UserDeleted(val id: String) : Event
}
```

## Debugging Commands

```bash
# Run with debug logging
./gradlew test --debug

# Run specific test file
./gradlew test --tests "*UserServiceTest*"

# Run specific test method
./gradlew test --tests "UserServiceTest.should create user"

# Continuous testing
./gradlew test --continuous

# Generate test report
open build/reports/tests/test/index.html
```

## Common Gotchas

1. **Mutable default arguments** - Don't use mutable defaults
2. **Companion object access** - Use `Companion` not `companion`
3. **Extension function scope** - Extensions don't see private members
4. **Data class copy** - `copy()` is shallow
5. **Coroutine context** - Always specify dispatcher for CPU/IO work

## Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| NPE | Use `?.` or `?: default` |
| Type mismatch | Add null check or use `!!` with caution |
| Smart cast | Use local variable |
| Cancellation | Re-throw `CancellationException` |
| Timeout | Use `withTimeoutOrNull` |
| Build failure | `./gradlew clean build --stacktrace` |
| Test failure | Check isolation, verify mocks |
