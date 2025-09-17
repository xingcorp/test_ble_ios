# Beacon Attendance iOS - Warp AI Rules

## 🎯 Dự Án Overview

**Beacon Attendance iOS** là production-grade app sử dụng iBeacon technology với Core Location framework. App hoạt động trong background/terminated state để track attendance thông qua iBeacon detection.

## 🏗️ Kiến Trúc & Coding Standards

### Clean Architecture Principles
- **Domain Layer**: `Sources/Core/` - Business logic, entities, use cases
- **Data Layer**: `Sources/Core/Networking/`, `Sources/Core/Persistence/` - Data sources, repositories
- **Presentation Layer**: `Sources/Features/` - UI, coordinators, view models
- **App Layer**: `Sources/App/` - Dependency injection, app lifecycle

### SOLID Principles Enforcement
- **Single Responsibility**: Mỗi class có một nhiệm vụ duy nhất
- **Open/Closed**: Extend thông qua protocols, không modify existing code
- **Liskov Substitution**: Protocols phải có thể thay thế implementations
- **Interface Segregation**: Protocols nhỏ, focused, không force unused methods
- **Dependency Inversion**: Depend on abstractions (protocols), không depend on concrete types

### Swift Coding Standards
- **Naming**: PascalCase cho types, camelCase cho variables/functions
- **Access Control**: Luôn sử dụng explicit access modifiers (private, internal, public)
- **Error Handling**: Sử dụng custom error types trong `Sources/Core/Errors/`
- **Async/Await**: Ưu tiên async/await thay vì completion handlers
- **Memory Management**: Sử dụng weak references để tránh retain cycles
- **Constants**: Centralize trong `Sources/Core/Constants/`

### 🎯 Naming Conventions (CRITICAL - Always Apply)

#### Architecture Pattern Naming
```swift
// ✅ REQUIRED - Use these patterns exclusively
class LocationCoordinator { }           // NOT LocationManager
class BeaconCoordinator { }            // NOT BeaconManager
class UserRepository { }               // NOT UserService
class NetworkClient { }                // NOT NetworkManager
class LocationProvider { }             // NOT LocationService
class CoreLocationFacade { }           // NOT UnifiedLocationService
```

#### Forbidden Patterns (NEVER USE)
```swift
// ❌ BANNED - These violate our standards
class LocationManager { }              // Use LocationCoordinator
class BeaconManager { }                // Use BeaconCoordinator
class DataService { }                  // Use DataRepository
class UserHelper { }                   // Use UserProvider
class UtilityClass { }                 // Use specific purpose name
class UnifiedLocationService { }       // Use LocationCoordinator
```

#### Quality Standards
- **Clarity over Cleverness**: Names must explain purpose immediately
- **Domain Language**: Use BLE/iOS terminology correctly
- **Consistent Vocabulary**: Same terms throughout codebase
- **No Buzzwords**: Avoid "Smart", "Advanced", "Enhanced", "Unified"
- **Pronounceable**: Must be speakable in team meetings

### iOS-Specific Best Practices
- **Background Processing**: Sử dụng BGTaskScheduler cho background tasks
- **Core Location**: Implement proper region monitoring với error handling
- **Battery Optimization**: Minimize ranging sessions, sử dụng burst mode
- **Permissions**: Request permissions properly với clear user messaging
- **Lifecycle Management**: Handle app states (active, background, terminated)

## 🔧 Development Workflow

### Testing Requirements
- **Unit Tests**: Minimum 80% coverage cho Core layer
- **Integration Tests**: Test beacon detection workflows
- **UI Tests**: Critical user flows (check-in/out)
- **Field Tests**: Physical device testing với real iBeacons

### Code Quality Gates
- SwiftLint compliance (no warnings)
- SwiftFormat applied
- All tests passing
- No force unwrapping (!) except in tests
- Proper error handling throughout

### Dependencies & Architecture
- **Swift Package Manager**: Preferred dependency management
- **No External UI Frameworks**: Sử dụng UIKit native
- **Dependency Injection**: Container-based DI trong CompositionRoot
- **Protocol-Oriented Programming**: Protocols cho all major components

## 📱 iBeacon Development Context

### Hardware Specifications
- **UUID**: `FDA50693-0000-0000-0000-290995101092`
- **Major**: Fixed per physical beacon/site
- **Minor**: Rotates (không dùng cho identification)
- **RSSI Smoothing**: Moving average để reduce noise

### Core Location Best Practices
- Region monitoring cho background detection
- Ranging sessions trong bursts (không continuous)
- Grace period (45s) cho soft-exit scenarios
- Proper CLLocationManager delegate implementation

### Background Execution
- Location updates background mode
- Background fetch capability
- Heartbeat service với smart scheduling
- Local notifications cho user feedback

## 🚨 Common Pitfalls & Solutions

### iOS Limitations
- **Force Quit**: App stops tracking until manual relaunch
- **20 Regions Limit**: iOS limits monitored regions per app
- **Simulator**: iBeacon không hoạt động trên simulator
- **Battery Drain**: Continuous ranging drains battery

### Error Handling Patterns
- Custom error types với context information
- Telemetry logging cho debugging
- Graceful degradation khi services unavailable
- User-friendly error messages

## 🤖 Warp AI Features Mới Nhất (September 2025)

### Warp Code Suite (September 2025)
- **#1 Coding Agent**: Top Terminal-bench (52%) và SWE-bench Verified (75.8%)
- **Claude Sonnet 4**: Recommended model (72.7% SWE-bench vs 46% GPT-5 Medium)
- **GPT-5 High Reasoning**: Alternative model với improved performance
- **Code Review**: Dedicated panel cho reviewing agent-generated code
- **Native File Editor**: Syntax highlighting, tabbed viewing, file tree
- **Suggested Code Diffs**: Proactive fixes cho compiler errors và merge conflicts
- **97% Acceptance Rate**: Over 150M lines of code generated weekly

### Agent Profiles & Permissions (September 2025)
- **Custom Behavior**: Define model + permissions cho different tasks
- **Project-Specific Rules**: WARP.md file với automatic application
- **Autonomy Controls**: Set permissions và notification preferences
- **Model Switching**: Avoid frequent switches để optimize caching

### Rules System (September 2025)
- **Global Rules**: Apply across all projects và contexts
- **Project Rules**: WARP.md files với precedence system
- **Multiple Formats**: Support CLAUDE.md, .cursorrules, AGENT.md, GEMINI.md
- **Automatic Context**: Rules automatically pulled into agent interactions
- **Slash Commands**: `/init`, `/add-rule`, `/open-project-rules`

### Active AI Features
- **Prompt Suggestions**: AI gợi ý câu hỏi contextual
- **Next Command**: Predict command tiếp theo dựa trên history
- **Context Management**: Smart context gathering với request optimization
- **Error Analysis**: Intelligent error detection và solutions
- **Voice Input**: Voice transcription cho natural language prompts

### Session Sharing & Collaboration
- **Live Collaboration**: Share terminal sessions qua web links
- **Web Access**: Teammates có thể join từ browser
- **Permission Control**: View-only hoặc edit access
- **No Account Required**: Guests có thể join không cần account

### Warp Drive Integration
- **Notebooks**: Interactive runbooks với markdown + code
- **Environment Variables**: Manage dev/staging/prod environments
- **Workflow Enum Arguments**: Define options cho workflow parameters
- **Public Sharing**: Share workflows publicly trên web
- **MCP Support**: Model Context Protocol cho external integrations

## 🎯 AI Assistant Guidelines

### Code Generation Preferences
- Generate Swift code theo project structure
- Include proper error handling và logging
- Follow established patterns trong codebase
- Add comprehensive documentation comments
- Consider battery optimization trong implementations
- Sử dụng Agent Mode với context từ WARP.md file
- Leverage Code Review panel để review changes
- Use Native File Editor cho quick edits

### Architecture Decisions
- Prefer composition over inheritance
- Use protocols cho testability
- Implement proper separation of concerns
- Leverage Agent Profiles cho consistent behavior
- Follow existing DI patterns
- Maintain consistency với current code style
- Use Suggested Code Diffs cho proactive fixes

### Testing Approach
- Generate unit tests cho new components
- Include mock implementations cho protocols
- Test error scenarios và edge cases
- Verify background behavior patterns
- Include performance considerations
- Sử dụng Agent Mode để generate test cases
- Leverage AI cho comprehensive test coverage
- Use Code Review để validate test implementations

### Request Optimization (September 2025)
- **Keep Conversations Focused**: Start new conversations cho different tasks
- **Context Management**: Attach relevant files only, avoid large blocks
- **Model Selection**: Stick với one model per conversation để optimize caching
- **Rules Leverage**: Use WARP.md rules để reduce repetitive prompting
- **Slash Commands**: Use `/generate`, `/explain`, `/fix` cho quick actions

## 📚 Key Files & Patterns

### Entry Points
- `Sources/App/AppDelegate.swift` - App lifecycle
- `Sources/App/CompositionRoot.swift` - Dependency injection setup

### Core Components
- `Sources/Core/Beacon/` - iBeacon management
- `Sources/Core/Attendance/` - Check-in/out logic
- `Sources/Core/Services/` - Background services
- `Sources/Core/Telemetry/` - Monitoring & logging

### Feature Modules
- `Sources/Features/Attendance/` - Attendance coordinator
- `Sources/Features/BeaconScanner/` - Beacon scanning UI

## 🚀 Warp AI Best Practices cho iOS Development (September 2025)

### Sử Dụng Warp Code Suite Hiệu Quả
- **Code Review Panel**: Review all agent changes trước khi commit
- **Native File Editor**: Quick edits cho variable names, copy changes
- **Suggested Code Diffs**: Accept proactive fixes cho compiler errors
- **Context Setup**: Luôn attach relevant files với @ symbol
- **Model Selection**: **Ưu tiên Claude Sonnet 4** cho coding tasks (72.7% SWE-bench vs 46% GPT-5)
- **Task Lists**: Sử dụng Agent task tracking cho multi-step workflows

### Agent Profiles & Rules Optimization
- **Project Rules**: Initialize với `/init` command cho WARP.md setup
- **Agent Profiles**: Define different profiles cho different tasks
- **Global Rules**: Set coding standards across all projects
- **Rules Precedence**: Subdirectory rules > root rules > global rules
- **Slash Commands**: Use `/add-rule`, `/open-project-rules` cho quick access

### Request Efficiency (97% Acceptance Rate Target)
- **Focused Conversations**: Start new conversations cho unrelated tasks
- **Context Management**: Select specific text thay vì entire blocks
- **Model Consistency**: Avoid switching models mid-conversation
- **Rules Leverage**: Let WARP.md rules guide agent behavior
- **Caching Optimization**: Keep conversations recent để benefit from caching

### Session Sharing cho Team Collaboration
- **Code Reviews**: Share terminal sessions cho real-time code review
- **Debugging**: Collaborate trực tiếp trên debugging sessions
- **Knowledge Transfer**: Sử dụng cho onboarding và training
- **Pair Programming**: Remote pair programming với shared control

### Warp Drive Organization
- **Notebooks**: Tạo interactive documentation cho setup procedures
- **Workflows**: Save common commands với parameters
- **Environment Variables**: Manage different deployment environments
- **Team Sharing**: Share knowledge base với team members
- **MCP Integration**: Connect external tools và services

### Performance & Productivity Tips
- **Voice Input**: Sử dụng voice transcription cho natural language prompts
- **Image Context**: Attach screenshots cho UI-related questions
- **Codebase Context**: Leverage automatic codebase indexing
- **File Tree Navigation**: Use file tree cho quick file access
- **Proactive Fixes**: Let agent suggest fixes cho merge conflicts

### Production Deployment Workflow
1. **Development**: Use Agent Mode với WARP.md context
2. **Code Review**: Review changes trong Code Review panel
3. **Testing**: Generate comprehensive tests với AI assistance
4. **Validation**: Hand-edit critical sections trong Native File Editor
5. **Deployment**: Use Suggested Code Diffs cho last-minute fixes

## 📈 Key Benefits cho Dự Án iOS Beacon

1. **Faster Development**: Code Review panel giúp review agent changes nhanh chóng
2. **Better Quality**: 97% acceptance rate với Claude Sonnet 4 (72.7% SWE-bench)
3. **Cost Efficiency**: Claude Sonnet 4 at $3/$15 per million tokens
4. **Optimized Requests**: Rules system giảm repetitive prompting
5. **Team Collaboration**: Session sharing cho real-time collaboration
6. **Proactive Fixes**: Suggested Code Diffs cho compiler errors

## 🎯 Model Performance Benchmarks (September 2025)

### SWE-bench Verified Scores:
- **Claude Sonnet 4**: 72.7% ⭐ (Best cost/performance ratio)
- **Claude Opus 4.1**: 72.5% - 72.7% (tùy mode)
- **Claude Opus 4**: 72.5%
- **GPT-5 Medium**: 46% (HAL leaderboard)
- **GPT-4.1**: ~44%
- **o3 Medium**: ~46%

### Cost Efficiency (per million tokens):
- **Claude Sonnet 4**: $3/$15 ⭐ (Recommended)
- **Claude Opus 4**: $15/$75
- **GPT-5 Medium**: $1.25/$10

### Coding Performance Advantages (Claude Sonnet 4):
- ✅ Superior code conciseness while maintaining functionality
- ✅ Novel approaches to complex TypeScript type narrowing
- ✅ Excellent instruction-following for iOS development
- ✅ Strong performance on multi-file code generation
- ✅ Consistent results across different coding tasks

---

Khi làm việc với codebase này, hãy luôn ưu tiên stability, battery efficiency, và user experience. Mọi thay đổi phải được test kỹ trên physical device với real iBeacons. **Sử dụng Claude Sonnet 4 làm primary model** để achieve 97% acceptance rate và save 1+ hour per day productivity.
