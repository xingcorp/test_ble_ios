# Augment AI User Guidelines - Naming Conventions

## 🎯 Primary Directive
Always prioritize CLARITY over cleverness in all naming decisions. Code is read 10x more than it's written.

## 📱 Swift/iOS Development Standards

### Core Naming Principles
- Use INTENTION-REVEALING names that explain purpose and context
- Avoid MENTAL MAPPING - names should be immediately understandable
- Apply DOMAIN LANGUAGE consistently throughout the codebase
- Maintain CONSISTENT VOCABULARY - don't mix synonyms randomly

### Class and Protocol Naming
```swift
// ✅ PREFERRED - Clear purpose and responsibility
class LocationCoordinator: Coordinator
class UserRepository: Repository
class NetworkClient: HTTPClient
protocol LocationProviding: AnyObject

// ❌ AVOID - Generic or unclear purpose
class LocationManager
class DataService  
class UserHelper
protocol LocationDelegate
```

### Method Naming Standards
```swift
// ✅ PREFERRED - Action-oriented with clear intent
func startLocationUpdates()
func validateUserCredentials(email: String, password: String) -> ValidationResult
func fetchUserProfile(for userID: String) async throws -> UserProfile

// ❌ AVOID - Vague or abbreviated
func doWork()
func validate(e: String, p: String) -> Bool
func getData(id: String) -> Any
```

### Property and Variable Naming
```swift
// ✅ PREFERRED - Role-based, descriptive
var currentUser: User?
var isLocationPermissionGranted: Bool
var selectedMenuItems: [MenuItem]
var maxRetryAttempts: Int = 3

// ❌ AVOID - Type-based or context-less
var user: User?
var flag: Bool
var items: [MenuItem]
var count: Int = 3
```

## 🏗️ Architecture Pattern Enforcement

### Coordinator Pattern
- Use "Coordinator" suffix for navigation and flow control
- Examples: AppCoordinator, AuthenticationCoordinator, OnboardingCoordinator

### Repository Pattern  
- Use "Repository" suffix for data access layers
- Examples: UserRepository, LocationRepository, CacheRepository

### Provider Pattern
- Use "Provider" suffix for service abstractions
- Examples: LocationProvider, NetworkProvider, ConfigurationProvider

### Factory Pattern
- Use "Factory" suffix for object creation
- Examples: ViewControllerFactory, ModelFactory, ServiceFactory

## ❌ Forbidden Patterns

### Generic Suffixes Without Context
Never use these without specific context:
- Manager (unless truly managing resources)
- Service (unless providing specific services)
- Helper (unless providing specific assistance)
- Utility (unless providing specific utilities)

### Buzzword Pollution
Avoid meaningless adjectives:
- Unified, Enhanced, Advanced, Smart, Intelligent
- Super, Mega, Ultra, Turbo, Pro, Max

### Type Information in Names
Don't include type information in variable names:
- nameString → name
- userArray → users  
- countInteger → count

## 🎯 Context-Aware Guidelines

### File and Directory Naming
```
// ✅ PREFERRED - Clear hierarchy and purpose
Sources/
├── Core/
│   ├── Networking/
│   │   ├── NetworkClient.swift
│   │   └── APIEndpoint.swift
│   └── Location/
│       ├── LocationCoordinator.swift
│       └── LocationProvider.swift
└── Features/
    └── Authentication/
        ├── AuthenticationCoordinator.swift
        └── UserRepository.swift

// ❌ AVOID - Generic or unclear structure
Sources/
├── Managers/
├── Services/
├── Helpers/
└── Utils/
```

### Test File Naming
```swift
// ✅ PREFERRED - Mirrors production structure
LocationCoordinatorTests.swift
UserRepositoryTests.swift
NetworkClientTests.swift

// ❌ AVOID - Generic or unclear
LocationTests.swift
UserTests.swift
NetworkTests.swift
```

## 📊 Quality Expectations

### Minimum Standards
- All names must be pronounceable in English
- No abbreviations unless universally understood (URL, API, JSON)
- Names should explain "why" not just "what"
- Consistent vocabulary throughout feature modules

### Code Review Focus
When reviewing code, prioritize:
1. Naming clarity and consistency
2. Proper use of architectural patterns
3. Avoidance of anti-patterns
4. Domain-appropriate terminology

## 🔧 AI Interaction Guidelines

### When Requesting Code Generation
- Specify the architectural pattern to follow
- Mention any domain-specific terminology
- Request explanation of naming choices
- Ask for alternative naming suggestions

### When Asking for Code Review
- Focus on naming consistency across the feature
- Request identification of potential naming improvements
- Ask for architectural pattern compliance check
- Seek suggestions for better domain modeling

## 📈 Success Indicators
- New team members understand code without extensive explanation
- Code reviews spend less time on naming discussions
- Codebase search and navigation becomes more efficient
- Consistent vocabulary emerges naturally across features

## 🎯 Remember
Good naming is an investment in your future self and your team. Take the extra time to choose names that will make sense in 6 months when you're debugging at 2 AM.
