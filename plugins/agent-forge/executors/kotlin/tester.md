# Kotlin Tester

Comprehensive testing guidance for Kotlin projects.

## Test Structure

```
src/test/kotlin/
└── com/company/project/
    ├── unit/
    │   ├── UserServiceTest.kt
    │   └── UserRepositoryTest.kt
    ├── integration/
    │   └── UserFlowTest.kt
    └── TestBase.kt
```

## Kotest Framework

### Test Styles

```kotlin
// Describe Spec (recommended for BDD)
class UserServiceTest : DescribeSpec({
    describe("UserService") {
        describe("createUser") {
            it("should create user with valid data") {
                // test
            }
            it("should reject invalid email") {
                // test
            }
        }
    }
})

// Should Spec
class CalculatorTest : ShouldSpec({
    should("add two numbers") {
        calculator.add(2, 3) shouldBe 5
    }
})

// Fun Spec
class StringTest : FunSpec({
    test("string length") {
        "hello".length shouldBe 5
    }
})
```

### Assertions

```kotlin
// Equality
result shouldBe expected
result shouldNotBe other

// Comparisons
value shouldBeGreaterThan 0
value shouldBeLessThan 100
value shouldBeInRange 1..10

// Collections
list shouldContain "item"
list shouldContainAll listOf("a", "b")
list shouldBeEmpty()
list shouldHaveSize 3

// Strings
str shouldStartWith "prefix"
str shouldEndWith "suffix"
str shouldContain "substring"

// Exceptions
shouldThrow<IllegalArgumentException> {
    service.invalidOperation()
}

shouldThrow<UserNotFoundException> {
    service.getUser("invalid")
}

// Soft assertions (all checked, not short-circuit)
assertSoftly {
    user.name shouldBe "John"
    user.email shouldBe "john@example.com"
    user.age shouldBeGreaterThan 18
}
```

### Test Lifecycle

```kotlin
class UserServiceTest : DescribeSpec({
    // One-time setup
    val repository = mockk<UserRepository>()
    val service = UserService(repository)

    beforeEach {
        // Reset mocks before each test
        clearMocks(repository)
    }

    describe("getUser") {
        it("should return user") {
            // Test implementation
        }
    }

    afterEach {
        // Cleanup after each test
    }
})
```

## MockK

### Basic Mocking

```kotlin
// Create mock
val repository = mockk<UserRepository>()

// Define behavior
every { repository.findById("1") } returns User(id = "1", name = "Test")
every { repository.findById("99") } returns null
every { repository.save(any()) } returns User(id = "new", name = "Saved")

// Verify calls
verify { repository.findById("1") }
verify(exactly = 2) { repository.save(any()) }
verify(atLeast = 1) { repository.findById(any()) }
verifyOrder {
    repository.findById("1")
    repository.save(any())
}

// Clear mocks
clearMocks(repository)
clearAllMocks()
```

### Advanced Mocking

```kotlin
// Answer with lambda
every { repository.findById(any()) } answers {
    User(id = firstArg(), name = "Generated")
}

// Throw exception
every { repository.delete(any()) } throws RuntimeException("Not allowed")

// Capture arguments
val slot = slot<User>()
every { repository.save(capture(slot)) } returns slot.captured

service.createUser(CreateUserRequest(name = "Test"))
slot.captured.name shouldBe "Test"

// Mock coroutines
coEvery { repository.findByIdAsync(any()) } returns User(id = "1")
coVerify { repository.findByIdAsync("1") }
```

### Spy

```kotlin
// Partial mock
val service = spyk(UserService(repository))

// Call real method
every { service.validate(any()) } returns true
every { service.process(any()) } callsRealMethod()
```

## Test Patterns

### Given-When-Then

```kotlin
it("should calculate total price") {
    // Given
    val items = listOf(
        Item(price = 10.0),
        Item(price = 20.0),
        Item(price = 30.0)
    )
    val calculator = PriceCalculator()

    // When
    val total = calculator.calculateTotal(items)

    // Then
    total shouldBe 60.0
}
```

### Parameterized Tests

```kotlin
withData(
    nameFn = { "email $it should be ${if (it.contains("@")) "valid" else "invalid"}" },
    "test@example.com",
    "invalid",
    "user@domain",
    "@nodomain.com"
) { email ->
    val result = validator.validateEmail(email)
    if (email.contains("@") && !email.startsWith("@")) {
        result shouldBe true
    } else {
        result shouldBe false
    }
}
```

### Table-Driven Tests

```kotlin
context("discount calculation") {
    withData(
        mapOf(
            "no discount" to (100.0 to 0.0),
            "10% discount" to (200.0 to 20.0),
            "20% discount" to (500.0 to 100.0)
        )
    ) { (price, expectedDiscount) ->
        val discount = calculator.calculateDiscount(price)
        discount shouldBe expectedDiscount
    }
}
```

## Integration Testing

### Test Containers

```kotlin
class RepositoryIntegrationTest : DescribeSpec({
    // PostgreSQL container
    val postgres = PostgreSQLContainer<Nothing>("postgres:15").apply {
        withDatabaseName("testdb")
        withUsername("test")
        withPassword("test")
    }

    beforeSpec {
        postgres.start()
    }

    afterSpec {
        postgres.stop()
    }

    describe("UserRepository") {
        lateinit var repository: UserRepository

        beforeEach {
            repository = UserRepository(
                dataSource = createDataSource(postgres)
            )
        }

        it("should persist and retrieve user") {
            val user = User(id = "1", name = "Test")

            repository.save(user)
            val found = repository.findById("1")

            found shouldBe user
        }
    }
})
```

### Ktor Test Application

```kotlin
class ApiIntegrationTest : DescribeSpec({
    val testApp = testApplication {
        install(ContentNegotiation) { json() }
        routing {
            userRoutes()
        }
    }

    describe("GET /users/{id}") {
        it("should return user") {
            testApp.client.get("/users/1").apply {
                status shouldBe HttpStatusCode.OK
                body<User>().id shouldBe "1"
            }
        }
    }
})
```

## Test Commands

```bash
# Run all tests
./gradlew test

# Run specific test class
./gradlew test --tests "com.company.project.UserServiceTest"

# Run specific test method
./gradlew test --tests "com.company.project.UserServiceTest.should create user"

# Run with pattern
./gradlew test --tests "*Service*"

# Run with tags
./gradlew test -Dkotest.tags="Integration"

# Continuous testing
./gradlew test --continuous

# Generate coverage
./gradlew koverReport

# View test report
open build/reports/tests/test/index.html
```

## Test Coverage

```kotlin
// build.gradle.kts
kover {
    excludeSourceSets {
        exclude("generated")
    }
}

koverReport {
    filters {
        excludes {
            classes("*Generated*", "*.dto.*")
        }
    }
    xml {
        onCheck = true
    }
    html {
        onCheck = true
    }
}
```

## Best Practices

1. **One assertion per test** - Clear failure reasons
2. **Descriptive test names** - Should read like documentation
3. **Test behavior, not implementation** - Focus on outcomes
4. **Isolate tests** - No shared mutable state
5. **Use fixtures** - Reusable test data
6. **Mock external dependencies** - Fast, reliable tests
7. **Test edge cases** - Null, empty, boundary values
8. **Test error paths** - Not just happy path

## Test Template

```kotlin
class FeatureTest : DescribeSpec({
    // Dependencies
    val dependency = mockk<Dependency>()
    val sut = FeatureService(dependency)  // System Under Test

    beforeEach {
        clearMocks(dependency)
    }

    describe("methodName") {
        context("when condition") {
            beforeEach {
                // Setup
                every { dependency.method() } returns expected
            }

            it("should expected behavior") {
                // When
                val result = sut.method()

                // Then
                result shouldBe expected
                verify { dependency.method() }
            }
        }

        context("when error condition") {
            beforeEach {
                every { dependency.method() } throws Exception("error")
            }

            it("should handle error") {
                shouldThrow<Exception> {
                    sut.method()
                }
            }
        }
    }
})
```
