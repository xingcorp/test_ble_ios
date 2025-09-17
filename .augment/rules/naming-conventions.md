---
type: "always_apply"
description: "Enforce consistent naming conventions across all code generation and analysis"
---

# Naming Conventions Rules

## 🎯 Core Principles
When generating or analyzing code, apply these naming rules:

### CLARITY OVER CLEVERNESS
- Use intention-revealing names that explain purpose
- Avoid mental mapping - names should be self-explanatory
- Prioritize readability for team collaboration

### CONSISTENT VOCABULARY
- Maintain same terminology across entire codebase
- Use domain-specific language consistently
- Avoid mixing synonyms (fetch vs get vs retrieve)

## 📱 Swift/iOS Specific Rules

### Class Naming Patterns
```swift
// ✅ GOOD - Specific, descriptive names
class LocationCoordinator { }
class UserRepository { }
class NetworkClient { }
class ValidationEngine { }

// ❌ BAD - Generic suffixes without context
class LocationManager { }
class DataService { }
class UserHelper { }
class UtilityClass { }
```

### Method Naming Standards
```swift
// ✅ GOOD - Clear intent and purpose
func startLocationUpdates()
func validateUserCredentials() -> Bool
func fetchUserProfile(for userID: String)
func isLocationPermissionGranted() -> Bool

// ❌ BAD - Unclear or abbreviated
func doStuff()
func validateUsr() -> Bool
func getData(id: String)
func checkLoc() -> Bool
```

### Property Naming Guidelines
```swift
// ✅ GOOD - Role-based, descriptive
var currentUser: User
var isLocationEnabled: Bool
var selectedItems: [Item]
var maxRetryAttempts: Int

// ❌ BAD - Type-based or unclear
var userObject: User
var flag: Bool
var items: [Item]
var count: Int
```

## 🏗️ Architecture Pattern Naming

### Coordinator Pattern
```swift
class AppCoordinator { }
class LocationCoordinator { }
class UserFlowCoordinator { }
class AuthenticationCoordinator { }
```

### Repository Pattern
```swift
class UserRepository { }
class LocationRepository { }
class DataRepository { }
class CacheRepository { }
```

### Provider Pattern
```swift
class LocationProvider { }
class DataProvider { }
class ServiceProvider { }
class ConfigurationProvider { }
```

### Facade Pattern
```swift
class CoreLocationFacade { }
class NetworkFacade { }
class DatabaseFacade { }
class AuthenticationFacade { }
```

## ❌ Anti-Patterns to Avoid

### Buzzword Pollution
```swift
// ❌ AVOID
class UnifiedLocationService { }
class EnhancedDataManager { }
class AdvancedUserHelper { }
class SmartConfigurationUtility { }

// ✅ USE INSTEAD
class LocationCoordinator { }
class UserRepository { }
class ValidationEngine { }
class ConfigurationProvider { }
```

### Generic Suffixes Without Context
```swift
// ❌ AVOID - Too generic
class DataManager { }
class UtilityHelper { }
class BaseService { }

// ✅ USE INSTEAD - Specific purpose
class UserDataRepository { }
class ValidationEngine { }
class NetworkClient { }
```

### Type Information in Names
```swift
// ❌ AVOID
var nameString: String
var userArray: [User]
var countInteger: Int

// ✅ USE INSTEAD
var name: String
var users: [User]
var count: Int
```

## 📊 Quality Scoring System

Rate names 0-100 based on:

### Clarity (30 points)
- Can new team member understand immediately?
- Does name explain the "why" not just "what"?

### Consistency (25 points)
- Follows established project conventions?
- Uses consistent vocabulary?

### Searchability (20 points)
- Easy to find in codebase?
- Unique enough to avoid false positives?

### Pronounceability (15 points)
- Can be spoken clearly in meetings?
- No awkward abbreviations?

### Domain Relevance (10 points)
- Uses appropriate technical terminology?
- Fits the business domain context?

## 🎯 Context-Aware Application

### Team Size Considerations
- **Small teams (2-5)**: Allow contextual abbreviations
- **Medium teams (6-15)**: Require more explicit naming
- **Large teams (15+)**: Mandate maximum clarity
- **Open source**: Self-documenting names required

### Scope-Based Naming
```swift
// Local scope - shorter acceptable
for user in users { }
let item = items.first

// Class scope - more descriptive
private var currentUser: User
private var selectedItems: [Item]

// Global scope - very descriptive
public static let MAX_CONCURRENT_CONNECTIONS = 10
public static let DEFAULT_TIMEOUT_INTERVAL: TimeInterval = 30
```

## 🔧 Automatic Enforcement

### Code Generation Rules
1. Always suggest specific names over generic ones
2. Provide context-aware naming suggestions
3. Flag potential naming violations during analysis
4. Offer refactoring suggestions for existing code

### Integration Points
- Code completion suggestions
- Refactoring recommendations
- Code review comments
- Architecture analysis reports

## 📈 Success Metrics
- Naming quality score improvements
- Reduced code review time on naming issues
- Faster onboarding for new team members
- Improved code searchability and navigation
