//
//  BaseViewModel.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import Combine

// MARK: - ViewState Protocol
public protocol ViewState {
    var isLoading: Bool { get }
    var error: Error? { get }
}

// MARK: - BaseViewState
public struct BaseViewState: ViewState {
    public let isLoading: Bool
    public let error: Error?
    
    public init(isLoading: Bool = false, error: Error? = nil) {
        self.isLoading = isLoading
        self.error = error
    }
    
    public static let initial = BaseViewState()
}

// MARK: - ViewModel Protocol
public protocol ViewModel: ObservableObject {
    associatedtype State: ViewState
    associatedtype Input
    
    var state: State { get }
    var statePublisher: Published<State>.Publisher { get }
    
    func handle(_ input: Input)
    func onAppear()
    func onDisappear()
}

// MARK: - BaseViewModel
open class BaseViewModel<State: ViewState, Input>: ViewModel {
    
    @Published public private(set) var state: State
    public var statePublisher: Published<State>.Publisher { $state }
    
    public var cancellables = Set<AnyCancellable>()
    
    // Error handling
    private let errorSubject = PassthroughSubject<Error, Never>()
    public var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // Loading state
    private let loadingSubject = CurrentValueSubject<Bool, Never>(false)
    public var isLoadingPublisher: AnyPublisher<Bool, Never> {
        loadingSubject.eraseToAnyPublisher()
    }
    
    public init(initialState: State) {
        self.state = initialState
        setupBindings()
    }
    
    // MARK: - Abstract Methods (Override in subclasses)
    
    open func handle(_ input: Input) {
        // Override in subclass
    }
    
    open func onAppear() {
        EnhancedLogger.shared.verbose("\(String(describing: Self.self)) appeared", category: .ui)
    }
    
    open func onDisappear() {
        EnhancedLogger.shared.verbose("\(String(describing: Self.self)) disappeared", category: .ui)
        cancellables.removeAll()
    }
    
    open func setupBindings() {
        // Override to setup Combine bindings
    }
    
    // MARK: - Protected Methods
    
    protected func updateState(_ newState: State) {
        DispatchQueue.main.async { [weak self] in
            self?.state = newState
        }
    }
    
    protected func setLoading(_ isLoading: Bool) {
        loadingSubject.send(isLoading)
    }
    
    protected func handleError(_ error: Error) {
        errorSubject.send(error)
        EnhancedLogger.shared.error(
            "ViewModel error",
            category: .ui,
            error: error,
            metadata: ["viewModel": String(describing: Self.self)]
        )
    }
    
    // MARK: - Async Helpers
    
    protected func execute<T>(
        operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void,
        onError: ((Error) -> Void)? = nil
    ) {
        Task { @MainActor [weak self] in
            do {
                let result = try await operation()
                onSuccess(result)
            } catch {
                self?.handleError(error)
                onError?(error)
            }
        }
    }
    
    protected func executeWithLoading<T>(
        operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void,
        onError: ((Error) -> Void)? = nil
    ) {
        setLoading(true)
        
        Task { @MainActor [weak self] in
            do {
                let result = try await operation()
                self?.setLoading(false)
                onSuccess(result)
            } catch {
                self?.setLoading(false)
                self?.handleError(error)
                onError?(error)
            }
        }
    }
}

// MARK: - Reactive Extensions
public extension BaseViewModel {
    
    /// Bind a publisher to state update
    func bind<T>(_ publisher: AnyPublisher<T, Never>, to handler: @escaping (T) -> State) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.updateState(handler(value))
            }
            .store(in: &cancellables)
    }
    
    /// Bind a publisher with error handling
    func bindWithError<T>(_ publisher: AnyPublisher<T, Error>, to handler: @escaping (T) -> State) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] value in
                    self?.updateState(handler(value))
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Debounce Helper
public extension BaseViewModel {
    
    func debounce<T>(
        _ publisher: AnyPublisher<T, Never>,
        for duration: TimeInterval = 0.3
    ) -> AnyPublisher<T, Never> {
        publisher
            .debounce(for: .seconds(duration), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func throttle<T>(
        _ publisher: AnyPublisher<T, Never>,
        for duration: TimeInterval = 0.3
    ) -> AnyPublisher<T, Never> {
        publisher
            .throttle(for: .seconds(duration), scheduler: RunLoop.main, latest: true)
            .eraseToAnyPublisher()
    }
}
