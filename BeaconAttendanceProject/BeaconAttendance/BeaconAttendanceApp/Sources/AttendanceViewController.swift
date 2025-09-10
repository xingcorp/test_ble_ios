//
//  AttendanceViewController.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import UIKit
// Note: Import statements for packages will be added when creating Xcode project
// TODO: Uncomment when package is added to project
// import BeaconAttendanceCore
// import BeaconAttendanceFeatures

class AttendanceViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var statusCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var statusIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 60)
        label.textAlignment = .center
        label.text = "📍"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var statusTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.text = "Not at Work"
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var statusDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.text = "Move closer to beacon to check in"
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var beaconInfoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var checkInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Manual Check-In", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(checkInTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var checkOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Check Out", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(checkOutTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var sessionInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .tertiaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    
    private var isCheckedIn = false {
        didSet {
            updateUI()
        }
    }
    
    private var currentSession: String?
    private var lastBeaconDetection: Date?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkPermissions()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        // Add subviews
        view.addSubview(statusCard)
        statusCard.addSubview(statusIconLabel)
        statusCard.addSubview(statusTitleLabel)
        statusCard.addSubview(statusDescriptionLabel)
        
        view.addSubview(beaconInfoStack)
        view.addSubview(checkInButton)
        view.addSubview(checkOutButton)
        view.addSubview(sessionInfoLabel)
        
        // Add beacon info labels
        addBeaconInfoRow(title: "Site:", value: "Not detected")
        addBeaconInfoRow(title: "Signal:", value: "No signal")
        addBeaconInfoRow(title: "Distance:", value: "Unknown")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Status Card
            statusCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Icon
            statusIconLabel.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 30),
            statusIconLabel.centerXAnchor.constraint(equalTo: statusCard.centerXAnchor),
            
            // Title
            statusTitleLabel.topAnchor.constraint(equalTo: statusIconLabel.bottomAnchor, constant: 16),
            statusTitleLabel.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 20),
            statusTitleLabel.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -20),
            
            // Description
            statusDescriptionLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 8),
            statusDescriptionLabel.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 20),
            statusDescriptionLabel.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -20),
            statusDescriptionLabel.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -30),
            
            // Beacon Info
            beaconInfoStack.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 30),
            beaconInfoStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            beaconInfoStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Check In Button
            checkInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            checkInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            checkInButton.heightAnchor.constraint(equalToConstant: 56),
            checkInButton.bottomAnchor.constraint(equalTo: sessionInfoLabel.topAnchor, constant: -20),
            
            // Check Out Button (same position as check in)
            checkOutButton.leadingAnchor.constraint(equalTo: checkInButton.leadingAnchor),
            checkOutButton.trailingAnchor.constraint(equalTo: checkInButton.trailingAnchor),
            checkOutButton.heightAnchor.constraint(equalTo: checkInButton.heightAnchor),
            checkOutButton.centerYAnchor.constraint(equalTo: checkInButton.centerYAnchor),
            
            // Session Info
            sessionInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sessionInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sessionInfoLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupNavigationBar() {
        title = "Beacon Attendance"
        
        // Add settings button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
    }
    
    private func addBeaconInfoRow(title: String, value: String) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .label
        valueLabel.tag = beaconInfoStack.arrangedSubviews.count // Use tag to identify later
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 80),
            
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        beaconInfoStack.addArrangedSubview(container)
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        if isCheckedIn {
            statusIconLabel.text = "✅"
            statusTitleLabel.text = "Checked In"
            statusDescriptionLabel.text = "You are at work"
            statusCard.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
            checkInButton.isHidden = true
            checkOutButton.isHidden = false
            
            if let session = currentSession {
                sessionInfoLabel.text = "Session: \(session)"
            }
        } else {
            statusIconLabel.text = "📍"
            statusTitleLabel.text = "Not Checked In"
            statusDescriptionLabel.text = "Move closer to beacon or check in manually"
            statusCard.backgroundColor = UIColor.systemBackground
            checkInButton.isHidden = false
            checkOutButton.isHidden = true
            sessionInfoLabel.text = ""
        }
    }
    
    func updateBeaconInfo(site: String?, signal: Int?, distance: Double?) {
        // Update beacon info displays
        if let container = beaconInfoStack.arrangedSubviews[0] as? UIView,
           let valueLabel = container.subviews.compactMap({ $0 as? UILabel }).last {
            valueLabel.text = site ?? "Not detected"
        }
        
        if let container = beaconInfoStack.arrangedSubviews[1] as? UIView,
           let valueLabel = container.subviews.compactMap({ $0 as? UILabel }).last {
            valueLabel.text = signal != nil ? "\(signal!) dBm" : "No signal"
        }
        
        if let container = beaconInfoStack.arrangedSubviews[2] as? UIView,
           let valueLabel = container.subviews.compactMap({ $0 as? UILabel }).last {
            if let distance = distance {
                valueLabel.text = String(format: "%.1f meters", distance)
            } else {
                valueLabel.text = "Unknown"
            }
        }
        
        lastBeaconDetection = Date()
    }
    
    // MARK: - Actions
    
    @objc private func checkInTapped() {
        // Simulate check-in
        isCheckedIn = true
        currentSession = UUID().uuidString.prefix(8).uppercased()
        
        // Show success alert
        let alert = UIAlertController(
            title: "Checked In",
            message: "You have been checked in successfully",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func checkOutTapped() {
        // Confirm check out
        let alert = UIAlertController(
            title: "Check Out?",
            message: "Are you sure you want to check out?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Check Out", style: .destructive) { [weak self] _ in
            self?.isCheckedIn = false
            self?.currentSession = nil
        })
        
        present(alert, animated: true)
    }
    
    @objc private func settingsTapped() {
        let alert = UIAlertController(
            title: "Settings",
            message: "Settings will be available in the next version",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Permissions
    
    private func checkPermissions() {
        // This will be connected to PermissionManager when integrated
        // For now, just show status
        sessionInfoLabel.text = "Location: Unknown | Bluetooth: Unknown"
    }
}
