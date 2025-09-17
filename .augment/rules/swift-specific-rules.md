---
type: "always_apply"
description: "Swift and iOS specific naming conventions and patterns"
---

# Swift/iOS Specific Naming Rules

## 🍎 Apple Guidelines Compliance

### Protocol Naming
```swift
// ✅ PREFERRED - Capability-based naming
protocol LocationProviding: AnyObject {
    func getCurrentLocation() async throws -> CLLocation
}

protocol UserAuthenticating: AnyObject {
    func authenticate(credentials: UserCredentials) async throws -> AuthResult
}

// ❌ AVOID - Generic delegate pattern
protocol LocationDelegate: AnyObject {
    func didUpdateLocation(_ location: CLLocation)
}
```

### Extension Naming
```swift
// ✅ PREFERRED - Clear purpose and context
extension UserRepository {
    // MARK: - Validation Methods
    func validateUserData(_ user: User) -> ValidationResult { }
}

extension String {
    // MARK: - Email Validation
    var isValidEmail: Bool { }
}

// ❌ AVOID - Generic or unclear extensions
extension UserRepository {
    // MARK: - Helper Methods
    func doStuff() { }
}
```

### Enum Naming
```swift
// ✅ PREFERRED - Clear states and actions
enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case authenticationFailed(AuthError)
}

enum NetworkError: Error {
    case noInternetConnection
    case invalidResponse
    case serverError(Int)
    case decodingFailed(DecodingError)
}

// ❌ AVOID - Abbreviated or unclear
enum AuthState {
    case none
    case loading
    case done
    case error
}
```

## 📱 iOS Architecture Patterns

### MVVM Pattern
```swift
// ✅ PREFERRED - Clear separation of concerns
class UserProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userRepository: UserRepositoryProtocol
    
    func loadUserProfile() async { }
    func updateUserProfile(_ user: User) async { }
}

// ❌ AVOID - Generic or unclear responsibility
class UserVM: ObservableObject {
    var data: Any?
    var loading: Bool = false
    
    func doWork() { }
}
```

### Coordinator Pattern
```swift
// ✅ PREFERRED - Navigation and flow control
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    var childCoordinators: [Coordinator] { get set }
    
    func start()
    func coordinate(to destination: Destination)
}

class AuthenticationCoordinator: Coordinator {
    func showLoginScreen() { }
    func showRegistrationScreen() { }
    func showForgotPasswordScreen() { }
}

// ❌ AVOID - Generic navigation management
class NavigationManager {
    func goTo(_ screen: String) { }
}
```

### Repository Pattern
```swift
// ✅ PREFERRED - Data access abstraction
protocol UserRepositoryProtocol {
    func fetchUser(by id: String) async throws -> User
    func saveUser(_ user: User) async throws
    func deleteUser(by id: String) async throws
}

class CoreDataUserRepository: UserRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    func fetchUser(by id: String) async throws -> User { }
}

// ❌ AVOID - Generic data handling
class DataManager {
    func getData(_ type: String) -> Any? { }
    func saveData(_ data: Any) { }
}
```

## 🔧 SwiftUI Specific Rules

### View Naming
```swift
// ✅ PREFERRED - Purpose-driven view names
struct UserProfileView: View {
    let user: User
    
    var body: some View { }
}

struct LoginFormView: View {
    @StateObject private var viewModel: LoginViewModel
    
    var body: some View { }
}

// ❌ AVOID - Generic or unclear views
struct ContentView: View {
    var body: some View { }
}

struct MyView: View {
    var body: some View { }
}
```

### State Management
```swift
// ✅ PREFERRED - Clear state purpose
@StateObject private var locationViewModel: LocationViewModel
@State private var isShowingLocationPicker: Bool = false
@Binding var selectedLocation: CLLocation?
@Environment(\.dismiss) private var dismiss

// ❌ AVOID - Generic or unclear state
@State private var flag: Bool = false
@State private var data: Any?
@State private var thing: String = ""
```

## 🧪 Testing Conventions

### Test Class Naming
```swift
// ✅ PREFERRED - Clear test scope and purpose
final class UserRepositoryTests: XCTestCase {
    func testFetchUser_WithValidID_ReturnsUser() { }
    func testFetchUser_WithInvalidID_ThrowsError() { }
    func testSaveUser_WithValidUser_SavesSuccessfully() { }
}

final class LocationCoordinatorTests: XCTestCase {
    func testStartLocationUpdates_WhenPermissionGranted_StartsUpdates() { }
    func testStartLocationUpdates_WhenPermissionDenied_ThrowsError() { }
}

// ❌ AVOID - Generic or unclear test scope
final class UserTests: XCTestCase {
    func testUser() { }
    func testSave() { }
}
```

### Mock and Stub Naming
```swift
// ✅ PREFERRED - Clear mock purpose
class MockUserRepository: UserRepositoryProtocol {
    var fetchUserResult: Result<User, Error>?
    var saveUserCalled: Bool = false
    
    func fetchUser(by id: String) async throws -> User { }
}

class StubLocationProvider: LocationProviding {
    let stubbedLocation = CLLocation(latitude: 0, longitude: 0)
    
    func getCurrentLocation() async throws -> CLLocation {
        return stubbedLocation
    }
}

// ❌ AVOID - Generic or unclear mocks
class FakeUser { }
class TestRepository { }
```

## 📦 Framework Integration

### Core Data Naming
```swift
// ✅ PREFERRED - Clear entity and relationship names
@objc(UserEntity)
class UserEntity: NSManagedObject {
    @NSManaged var userID: String
    @NSManaged var email: String
    @NSManaged var profile: UserProfileEntity?
}

extension UserEntity {
    func toDomainModel() -> User { }
}

// ❌ AVOID - Generic or unclear entities
@objc(DataEntity)
class DataEntity: NSManagedObject {
    @NSManaged var info: String
}
```

### Networking Layer
```swift
// ✅ PREFERRED - Clear API structure
enum APIEndpoint {
    case fetchUser(id: String)
    case updateUser(User)
    case deleteUser(id: String)
    
    var path: String { }
    var method: HTTPMethod { }
}

struct NetworkClient {
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T { }
}

// ❌ AVOID - Generic networking
class NetworkManager {
    func get(_ url: String) async -> Data? { }
    func post(_ url: String, data: Data) async -> Data? { }
}
```

## 🎯 Quality Checklist

### Before Code Review
- [ ] All classes follow architectural pattern naming
- [ ] Methods have clear, action-oriented names
- [ ] Properties explain their role, not their type
- [ ] Protocols describe capabilities, not implementations
- [ ] Enums have meaningful case names
- [ ] Test methods describe scenario and expected outcome

### Red Flags to Avoid
- [ ] Generic suffixes: Manager, Service, Helper
- [ ] Abbreviations: usr, loc, auth, config
- [ ] Type information in names: userString, dataArray
- [ ] Meaningless adjectives: smart, advanced, enhanced
- [ ] Single-letter variables (except in short loops)
- [ ] Numbers in names without clear meaning: user1, data2
