//
//  NetworkRetryManager.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

// MARK: - Retry Policy
public struct RetryPolicy {
    public let maxAttempts: Int
    public let initialDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let multiplier: Double
    public let jitter: Bool
    
    public static let `default` = RetryPolicy(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 30.0,
        multiplier: 2.0,
        jitter: true
    )
    
    public static let aggressive = RetryPolicy(
        maxAttempts: 5,
        initialDelay: 0.5,
        maxDelay: 10.0,
        multiplier: 1.5,
        jitter: true
    )
    
    public static let conservative = RetryPolicy(
        maxAttempts: 2,
        initialDelay: 2.0,
        maxDelay: 60.0,
        multiplier: 3.0,
        jitter: false
    )
    
    func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = initialDelay * pow(multiplier, Double(attempt - 1))
        var delay = min(exponentialDelay, maxDelay)
        
        if jitter {
            // Add random jitter (±25%)
            let jitterRange = delay * 0.25
            delay += Double.random(in: -jitterRange...jitterRange)
        }
        
        return max(0, delay)
    }
}

// MARK: - Circuit Breaker State
public enum CircuitBreakerState {
    case closed
    case open(until: Date)
    case halfOpen
}

// MARK: - Circuit Breaker
public final class CircuitBreaker {
    private let failureThreshold: Int
    private let resetTimeout: TimeInterval
    private let queue = DispatchQueue(label: "circuit.breaker.queue")
    
    private var state: CircuitBreakerState = .closed
    private var failureCount = 0
    private var successCount = 0
    
    public init(failureThreshold: Int = 5, resetTimeout: TimeInterval = 60) {
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
    }
    
    public var isOpen: Bool {
        queue.sync {
            switch state {
            case .open(let until):
                if Date() > until {
                    state = .halfOpen
                    return false
                }
                return true
            case .halfOpen, .closed:
                return false
            }
        }
    }
    
    public func recordSuccess() {
        queue.async {
            switch self.state {
            case .halfOpen:
                self.successCount += 1
                if self.successCount >= 2 {
                    // Two successful calls in half-open, close the circuit
                    self.state = .closed
                    self.failureCount = 0
                    self.successCount = 0
                    EnhancedLogger.shared.info("Circuit breaker closed", category: .network)
                }
            case .closed:
                self.failureCount = max(0, self.failureCount - 1)
            case .open:
                break
            }
        }
    }
    
    public func recordFailure() {
        queue.async {
            switch self.state {
            case .closed:
                self.failureCount += 1
                if self.failureCount >= self.failureThreshold {
                    self.state = .open(until: Date().addingTimeInterval(self.resetTimeout))
                    EnhancedLogger.shared.warning("Circuit breaker opened for \(self.resetTimeout)s", category: .network)
                }
            case .halfOpen:
                // Failed in half-open, re-open the circuit
                self.state = .open(until: Date().addingTimeInterval(self.resetTimeout))
                self.successCount = 0
                EnhancedLogger.shared.warning("Circuit breaker re-opened", category: .network)
            case .open:
                break
            }
        }
    }
    
    public func reset() {
        queue.async {
            self.state = .closed
            self.failureCount = 0
            self.successCount = 0
        }
    }
}

// MARK: - Network Retry Manager
public final class NetworkRetryManager {
    
    public static let shared = NetworkRetryManager()
    
    private let circuitBreakers: NSMapTable<NSString, CircuitBreaker> = .strongToStrongObjects()
    private let queue = DispatchQueue(label: "network.retry.queue")
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Execute a network request with retry logic
    public func execute<T>(
        endpoint: String,
        policy: RetryPolicy = .default,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let breaker = getCircuitBreaker(for: endpoint)
        
        // Check circuit breaker
        if breaker.isOpen {
            EnhancedLogger.shared.warning("Circuit breaker is open for \(endpoint)", category: .network)
            throw AppError.networkUnavailable
        }
        
        var lastError: Error?
        
        for attempt in 1...policy.maxAttempts {
            do {
                // Log attempt
                EnhancedLogger.shared.debug(
                    "Network request attempt \(attempt)/\(policy.maxAttempts)",
                    category: .network,
                    metadata: ["endpoint": endpoint]
                )
                
                // Execute operation
                let result = try await operation()
                
                // Record success
                breaker.recordSuccess()
                
                // Track telemetry
                TelemetryManager.shared.track(
                    .networkRequest,
                    severity: .verbose,
                    metadata: [
                        "endpoint": endpoint,
                        "attempts": String(attempt),
                        "status": "success"
                    ]
                )
                
                return result
                
            } catch {
                lastError = error
                
                // Check if error is retryable
                guard isRetryable(error) else {
                    EnhancedLogger.shared.error(
                        "Non-retryable error",
                        category: .network,
                        error: error,
                        metadata: ["endpoint": endpoint]
                    )
                    breaker.recordFailure()
                    throw error
                }
                
                // Check if we have more attempts
                if attempt < policy.maxAttempts {
                    let delay = policy.delay(for: attempt)
                    
                    EnhancedLogger.shared.warning(
                        "Request failed, retrying in \(delay)s",
                        category: .network,
                        error: error,
                        metadata: [
                            "endpoint": endpoint,
                            "attempt": String(attempt),
                            "delay": String(delay)
                        ]
                    )
                    
                    // Wait before retry
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    // Max attempts reached
                    breaker.recordFailure()
                    
                    EnhancedLogger.shared.error(
                        "Max retry attempts reached",
                        category: .network,
                        error: error,
                        metadata: [
                            "endpoint": endpoint,
                            "attempts": String(policy.maxAttempts)
                        ]
                    )
                }
            }
        }
        
        // Track failure telemetry
        TelemetryManager.shared.track(
            .networkRequest,
            severity: .error,
            metadata: [
                "endpoint": endpoint,
                "attempts": String(policy.maxAttempts),
                "status": "failed",
                "error": lastError?.localizedDescription ?? "unknown"
            ]
        )
        
        throw lastError ?? AppError.unknown(NSError(domain: "NetworkRetry", code: -1))
    }
    
    /// Execute with fallback
    public func executeWithFallback<T>(
        endpoint: String,
        policy: RetryPolicy = .default,
        operation: @escaping () async throws -> T,
        fallback: @escaping () async -> T
    ) async -> T {
        do {
            return try await execute(
                endpoint: endpoint,
                policy: policy,
                operation: operation
            )
        } catch {
            EnhancedLogger.shared.info(
                "Using fallback for \(endpoint)",
                category: .network,
                metadata: ["error": error.localizedDescription]
            )
            return await fallback()
        }
    }
    
    // MARK: - Private Methods
    
    private func getCircuitBreaker(for endpoint: String) -> CircuitBreaker {
        queue.sync {
            let key = endpoint as NSString
            if let existing = circuitBreakers.object(forKey: key) {
                return existing
            }
            let breaker = CircuitBreaker()
            circuitBreakers.setObject(breaker, forKey: key)
            return breaker
        }
    }
    
    private func isRetryable(_ error: Error) -> Bool {
        // Check AppError cases
        if let appError = error as? AppError {
            return appError.isRetryable
        }
        
        // Check URLError cases
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .networkConnectionLost,
                 .dnsLookupFailed,
                 .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        
        // Check NSError
        let nsError = error as NSError
        
        // Network errors
        if nsError.domain == NSURLErrorDomain {
            let retryableCodes = [
                NSURLErrorTimedOut,
                NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorDNSLookupFailed,
                NSURLErrorNotConnectedToInternet
            ]
            return retryableCodes.contains(nsError.code)
        }
        
        // Default to not retryable
        return false
    }
    
    /// Reset all circuit breakers
    public func resetAllBreakers() {
        queue.async {
            self.circuitBreakers.removeAllObjects()
        }
    }
    
}

// MARK: - Convenience Extensions
public extension NetworkRetryManager {
    
    /// Simple retry wrapper for existing code
    func withRetry<T>(
        attempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () throws -> T
    ) throws -> T {
        var lastError: Error?
        
        for attempt in 1...attempts {
            do {
                return try operation()
            } catch {
                lastError = error
                
                if attempt < attempts {
                    Thread.sleep(forTimeInterval: delay * Double(attempt))
                }
            }
        }
        
        throw lastError ?? AppError.unknown(NSError(domain: "Retry", code: -1))
    }
    
    /// Async version
    func withRetryAsync<T>(
        attempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...attempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < attempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * Double(attempt) * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? AppError.unknown(NSError(domain: "RetryAsync", code: -1))
    }
}

