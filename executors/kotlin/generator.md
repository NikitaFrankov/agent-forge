# Kotlin Code Generator

Guidance for writing idiomatic Kotlin code.

## Project Structure

```
src/
├── main/
│   ├── kotlin/
│   │   └── com/company/project/
│   │       ├── domain/       # Domain models
│   │       ├── repository/   # Data access
│   │       ├── service/      # Business logic
│   │       ├── controller/   # HTTP handlers (if Ktor/Spring)
│   │       └── util/         # Utilities
│   └── resources/
│       └── application.conf  # Config (Ktor) or application.yml (Spring)
└── test/
    └── kotlin/
        └── com/company/project/
```

## Naming Conventions

```kotlin
// Classes: PascalCase
class UserService { }
data class UserDto { }

// Functions: camelCase
fun calculateTotal() { }
fun getUserById(id: String) { }

// Properties: camelCase
val userName: String
var isEnabled: Boolean

// Constants: SCREAMING_SNAKE_CASE
const val MAX_RETRIES = 3
const val DEFAULT_TIMEOUT_MS = 5000L

// Backing properties: underscore prefix
private var _items: MutableList<Item> = mutableListOf()
val items: List<Item> get() = _items
```

## Data Classes

```kotlin
// Prefer data classes for DTOs
data class User(
    val id: String,
    val name: String,
    val email: String,
    val createdAt: Instant = Instant.now()
)

// Use copy for modifications
val updated = user.copy(name = "New Name")

// With default values for optional fields
data class Config(
    val host: String = "localhost",
    val port: Int = 8080,
    val enabled: Boolean = true
)
```

## Null Safety

```kotlin
// Safe call
val name: String? = user?.name

// Elvis operator
val name: String = user?.name ?: "Unknown"

// Safe cast
val service = obj as? UserService

// Require not null
val name = requireNotNull(user.name) { "Name is required" }

// Check not null
checkNotNull(value) { "Value must not be null" }

// Lateinit for dependency injection
lateinit var repository: UserRepository
```

## Functions

```kotlin
// Expression body for simple functions
fun square(x: Int): Int = x * x

fun greet(name: String): String = "Hello, $name"

// Default parameters
fun connect(
    host: String = "localhost",
    port: Int = 8080,
    timeout: Duration = 10.seconds
) { ... }

// Named arguments
connect(port = 9090, host = "api.example.com")

// Extension functions
fun String.isEmail(): Boolean = this.contains("@")

fun List<User>.findActive(): List<User> = filter { it.isActive }

// Infix functions
infix fun User.hasRole(role: String): Boolean = roles.contains(role)

if (user hasRole "admin") { ... }
```

## Collections

```kotlin
// Immutable by default
val items: List<String> = listOf("a", "b", "c")
val map: Map<String, Int> = mapOf("a" to 1, "b" to 2)

// Mutable when needed
val mutableItems: MutableList<String> = mutableListOf()

// Functional operations
val result = users
    .filter { it.isActive }
    .map { it.name }
    .sorted()
    .take(10)

// Grouping
val byRole = users.groupBy { it.role }

// Association
val nameToUser = users.associateBy { it.name }

// Partitioning
val (active, inactive) = users.partition { it.isActive }
```

## Coroutines

```kotlin
// Suspend functions
suspend fun fetchUser(id: String): User {
    return httpClient.get("/users/$id").body()
}

// Coroutine scope
class UserService(
    private val scope: CoroutineScope = CoroutineScope(Dispatchers.Default)
) {
    fun processDataAsync(data: Data) = scope.async {
        processData(data)
    }
}

// Structured concurrency
suspend fun fetchAll(): List<User> = coroutineScope {
    val deferred1 = async { fetchUser("1") }
    val deferred2 = async { fetchUser("2") }
    listOf(deferred1.await(), deferred2.await())
}

// Flow for streams
fun watchUsers(): Flow<User> = channelFlow {
    // Emit users as they arrive
    send(user)
}

// Cancellation handling
suspend fun processWithTimeout() = withTimeout(5.seconds) {
    // Will cancel after 5 seconds
}
```

## Error Handling

```kotlin
// Result type
fun parse(input: String): Result<Int> = runCatching {
    input.toInt()
}

// Usage
val result = parse("42")
    .map { it * 2 }
    .getOrElse { 0 }

// Custom exceptions
class UserNotFoundException(id: String) : RuntimeException("User not found: $id")

// Try-catch when needed
fun safeOperation(): Result<Data> = runCatching {
    riskyOperation()
}.recoverCatching { e ->
    log.error("Operation failed", e)
    Data.empty()
}
```

## Dependency Injection (Koin)

```kotlin
// Module definition
val appModule = module {
    single { UserRepository(get()) }
    single { UserService(get()) }
    single { HttpClient {
        install(ContentNegotiation) { json() }
    }}
}

// Injection in classes
class UserController : KoinComponent {
    private val service: UserService by inject()
}

// Constructor injection (preferred)
class UserController(
    private val service: UserService
) {
    // ...
}
```

## Testing

```kotlin
// Kotest
class UserServiceTest : DescribeSpec({
    val repository = mockk<UserRepository>()
    val service = UserService(repository)

    describe("getUser") {
        it("should return user when found") {
            // Given
            val user = User(id = "1", name = "Test")
            every { repository.findById("1") } returns user

            // When
            val result = service.getUser("1")

            // Then
            result shouldBe user
        }

        it("should throw when not found") {
            every { repository.findById("99") } returns null

            shouldThrow<UserNotFoundException> {
                service.getUser("99")
            }
        }
    }
})

// MockK patterns
every { mock.function(any()) } returns "result"
every { mock.function("specific") } throws RuntimeException("error")
verify { mock.function("expected") }
verify(exactly = 2) { mock.function(any()) }
```

## Common Patterns

### Repository Pattern
```kotlin
interface UserRepository {
    suspend fun findById(id: String): User?
    suspend fun save(user: User): User
    suspend fun delete(id: String)
}

class InMemoryUserRepository : UserRepository {
    private val users = mutableMapOf<String, User>()

    override suspend fun findById(id: String) = users[id]

    override suspend fun save(user: User) = user.also { users[it.id] = it }

    override suspend fun delete(id: String) { users.remove(id) }
}
```

### Service Layer
```kotlin
class UserService(
    private val repository: UserRepository,
    private val eventPublisher: EventPublisher
) {
    suspend fun createUser(request: CreateUserRequest): User {
        val user = User(
            id = UUID.randomUUID().toString(),
            name = request.name,
            email = request.email
        )
        val saved = repository.save(user)
        eventPublisher.publish(UserCreatedEvent(saved.id))
        return saved
    }
}
```

### Sealed Classes for State
```kotlin
sealed interface State<out T> {
    data class Loading<T>(val progress: Float = 0f) : State<T>
    data class Success<T>(val data: T) : State<T>
    data class Error<T>(val message: String, val cause: Throwable? = null) : State<T>
}

// Usage
when (val state = viewModel.state.value) {
    is State.Loading -> showProgress(state.progress)
    is State.Success -> showData(state.data)
    is State.Error -> showError(state.message)
}
```

## Build Commands

```bash
# Run specific test
./gradlew test --tests "com.company.project.UserServiceTest"

# Run all tests
./gradlew test

# Lint check
./gradlew detekt

# Format code
./gradlew ktlintFormat

# Build
./gradlew build

# Clean build
./gradlew clean build
```

## Quality Checklist

- [ ] Use data classes for DTOs
- [ ] Prefer immutability
- [ ] Use expression bodies for simple functions
- [ ] Handle nulls explicitly (no !! unless certain)
- [ ] Use coroutines for async operations
- [ ] Follow naming conventions
- [ ] Write tests for new code
- [ ] Run detekt before committing
