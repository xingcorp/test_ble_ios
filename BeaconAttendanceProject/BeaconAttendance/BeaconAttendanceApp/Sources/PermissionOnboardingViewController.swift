//
//  PermissionOnboardingViewController.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import UIKit
import BeaconAttendanceCore

/// Permission onboarding flow with proper explanation
final class PermissionOnboardingViewController: UIViewController {
    
    // MARK: - Types
    
    private enum PermissionStep: Int, CaseIterable {
        case welcome = 0
        case notification
        case locationWhenInUse
        case locationAlways
        case complete
        
        var title: String {
            switch self {
            case .welcome:
                return "Welcome to Beacon Attendance"
            case .notification:
                return "Stay Informed"
            case .locationWhenInUse:
                return "Detect Nearby Beacons"
            case .locationAlways:
                return "Automatic Check-in"
            case .complete:
                return "You're All Set!"
            }
        }
        
        var description: String {
            switch self {
            case .welcome:
                return "We need a few permissions to provide the best experience.\n\nThis will only take a moment."
            case .notification:
                return "Receive notifications when you check in or out of work sites.\n\n📱 We'll notify you of attendance events."
            case .locationWhenInUse:
                return "Allow location access to detect beacons when the app is open.\n\n📍 Required for basic beacon detection."
            case .locationAlways:
                return "Enable background location for automatic attendance tracking.\n\n🔄 Check in/out automatically even when app is closed."
            case .complete:
                return "Everything is configured!\n\n✅ You can now use automatic attendance tracking."
            }
        }
        
        var icon: String {
            switch self {
            case .welcome: return "👋"
            case .notification: return "🔔"
            case .locationWhenInUse: return "📍"
            case .locationAlways: return "🗺"
            case .complete: return "🎉"
            }
        }
    }
    
    // MARK: - UI Components
    
    private lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.progressTintColor = .systemBlue
        view.trackTintColor = .systemGray5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 80)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Skip", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(.systemGray, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    private var currentStep: PermissionStep = .welcome
    private let permissionManager: PermissionManager
    private var completion: (() -> Void)?
    
    // MARK: - Initialization
    
    init(completion: (() -> Void)? = nil) {
        self.permissionManager = DependencyContainer.shared.resolve(PermissionManager.self) ?? PermissionManager()
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.permissionManager = DependencyContainer.shared.resolve(PermissionManager.self) ?? PermissionManager()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        updateUI()
        
        // Set permission manager delegate
        permissionManager.delegate = self
        
        LoggerService.shared.info("Permission onboarding started", category: .app)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(progressView)
        view.addSubview(iconLabel)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(actionButton)
        view.addSubview(skipButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Progress view
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Icon
            iconLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 60),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Action button
            actionButton.bottomAnchor.constraint(equalTo: skipButton.topAnchor, constant: -10),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            actionButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Skip button
            skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        let step = currentStep
        
        // Update progress
        let progress = Float(step.rawValue) / Float(PermissionStep.allCases.count - 1)
        progressView.setProgress(progress, animated: true)
        
        // Update content with animation
        UIView.animate(withDuration: 0.3) {
            self.iconLabel.alpha = 0
            self.titleLabel.alpha = 0
            self.descriptionLabel.alpha = 0
        } completion: { _ in
            self.iconLabel.text = step.icon
            self.titleLabel.text = step.title
            self.descriptionLabel.text = step.description
            
            UIView.animate(withDuration: 0.3) {
                self.iconLabel.alpha = 1
                self.titleLabel.alpha = 1
                self.descriptionLabel.alpha = 1
            }
        }
        
        // Update button
        switch step {
        case .welcome:
            actionButton.setTitle("Get Started", for: .normal)
            skipButton.isHidden = false
        case .notification:
            actionButton.setTitle("Enable Notifications", for: .normal)
            skipButton.isHidden = false
        case .locationWhenInUse:
            actionButton.setTitle("Allow Location Access", for: .normal)
            skipButton.isHidden = true // Can't skip location
        case .locationAlways:
            actionButton.setTitle("Enable Background Location", for: .normal)
            skipButton.isHidden = false
        case .complete:
            actionButton.setTitle("Start Using App", for: .normal)
            skipButton.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func actionButtonTapped() {
        LoggerService.shared.info("User action: permission_onboarding_action - step: \(currentStep)", category: .app)
        
        switch currentStep {
        case .welcome:
            moveToNextStep()
            
        case .notification:
            requestNotificationPermission()
            
        case .locationWhenInUse:
            requestLocationPermission()
            
        case .locationAlways:
            requestAlwaysLocationPermission()
            
        case .complete:
            completeOnboarding()
        }
    }
    
    @objc private func skipButtonTapped() {
        LoggerService.shared.info("User action: permission_onboarding_skip - step: \(currentStep)", category: .app)
        
        let alert = UIAlertController(
            title: "Skip Permission?",
            message: "Some features may not work properly without this permission.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Skip", style: .default) { [weak self] _ in
            self?.moveToNextStep()
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Permission Requests
    
    private func requestNotificationPermission() {
        permissionManager.requestNotificationPermission { [weak self] granted in
            DispatchQueue.main.async {
                LoggerService.shared.info("Notification permission: \(granted)", category: .app)
                self?.moveToNextStep()
            }
        }
    }
    
    private func requestLocationPermission() {
        // This will request whenInUse first
        permissionManager.requestLocationPermission()
        
        // Wait a bit for permission dialog to appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkLocationStatusAndProceed()
        }
    }
    
    private func requestAlwaysLocationPermission() {
        // This will upgrade to Always if we have whenInUse
        permissionManager.requestLocationPermission()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.moveToNextStep()
        }
    }
    
    private func checkLocationStatusAndProceed() {
        let status = permissionManager.checkLocationStatus()
        
        if status == .authorized || status == .denied {
            moveToNextStep()
        } else {
            // Still waiting for user response, check again
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.checkLocationStatusAndProceed()
            }
        }
    }
    
    // MARK: - Navigation
    
    private func moveToNextStep() {
        guard let nextStep = PermissionStep(rawValue: currentStep.rawValue + 1) else {
            completeOnboarding()
            return
        }
        
        currentStep = nextStep
        updateUI()
    }
    
    private func completeOnboarding() {
        // Save onboarding completed
        UserDefaults.standard.set(true, forKey: "com.oxii.beacon.onboarding.completed")
        
        LoggerService.shared.info("Permission onboarding completed", category: .app)
        
        // Call completion or dismiss
        if let completion = completion {
            completion()
        } else {
            dismiss(animated: true)
        }
    }
}

// MARK: - PermissionManagerDelegate

extension PermissionOnboardingViewController: PermissionManagerDelegate {
    
    func permissionManager(_ manager: PermissionManager, didUpdateLocationStatus status: PermissionStatus) {
        LoggerService.shared.info("Location permission updated: \(status)", category: .location)
        
        // Auto-proceed if permission was granted
        if status == .authorized && (currentStep == .locationWhenInUse || currentStep == .locationAlways) {
            DispatchQueue.main.async { [weak self] in
                self?.moveToNextStep()
            }
        }
    }
    
    func permissionManager(_ manager: PermissionManager, didUpdateNotificationStatus status: PermissionStatus) {
        LoggerService.shared.info("Notification permission updated: \(status)", category: .notification)
    }
    
    func permissionManager(_ manager: PermissionManager, didUpdateBluetoothStatus status: PermissionStatus) {
        LoggerService.shared.info("Bluetooth status updated: \(status)", category: .beacon)
    }
}

// MARK: - Presentation Helper

extension PermissionOnboardingViewController {
    
    /// Check if onboarding is needed and present if necessary
    static func presentIfNeeded(from viewController: UIViewController) {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "com.oxii.beacon.onboarding.completed")
        
        guard !hasCompletedOnboarding else { return }
        
        let onboardingVC = PermissionOnboardingViewController { [weak viewController] in
            viewController?.dismiss(animated: true)
        }
        
        onboardingVC.modalPresentationStyle = .fullScreen
        viewController.present(onboardingVC, animated: true)
    }
}
