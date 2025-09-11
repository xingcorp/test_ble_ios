//
//  AttendanceViewController.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import UIKit
import BeaconAttendanceCore
import CoreLocation

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
    
    private var currentSession: AttendanceSession?
    private var lastBeaconDetection: Date?
    private var detectedBeacon: BeaconRegion?
    
    // Services
    private let beaconManager: BeaconManagerProtocol
    private let attendanceService: AttendanceServiceProtocol
    private let locationManager: LocationManagerProtocol
    
    // MARK: - Initialization
    
    init() {
        // Resolve dependencies
        self.beaconManager = DependencyContainer.shared.resolve(BeaconManagerProtocol.self)!
        self.attendanceService = DependencyContainer.shared.resolve(AttendanceServiceProtocol.self)!
        self.locationManager = DependencyContainer.shared.resolve(LocationManagerProtocol.self)!
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        // Resolve dependencies
        self.beaconManager = DependencyContainer.shared.resolve(BeaconManagerProtocol.self)!
        self.attendanceService = DependencyContainer.shared.resolve(AttendanceServiceProtocol.self)!
        self.locationManager = DependencyContainer.shared.resolve(LocationManagerProtocol.self)!
        
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
        setupBeaconDetection()
        updateUI()
        
        LoggerService.shared.info("AttendanceViewController loaded", category: .ui)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkPermissions()
        startBeaconScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopBeaconScanning()
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
        LoggerService.shared.info("Manual check-in requested", category: .ui)
        
        Task {
            do {
                let location = try? await locationManager.getCurrentLocation()
                let session = try await attendanceService.checkIn(
                    at: location,
                    beaconId: detectedBeacon?.identifier
                )
                
                await MainActor.run {
                    self.isCheckedIn = true
                    self.currentSession = session
                    
                    LoggerService.shared.info("Check-in successful: \(session.id)", category: .beacon)
                    
                    let alert = UIAlertController(
                        title: "Checked In ✅",
                        message: "Session ID: \(session.id.prefix(8))",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    LoggerService.shared.error("Check-in failed", error: error, category: .beacon)
                    
                    let alert = UIAlertController(
                        title: "Check-in Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func checkOutTapped() {
        let alert = UIAlertController(
            title: "Check Out?",
            message: "Are you sure you want to check out?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Check Out", style: .destructive) { [weak self] _ in
            guard let sessionId = self?.currentSession?.id else { return }
            
            LoggerService.shared.info("Check-out requested for session: \(sessionId)", category: .ui)
            
            Task {
                do {
                    try await self?.attendanceService.checkOut(sessionId: sessionId)
                    
                    await MainActor.run {
                        self?.isCheckedIn = false
                        self?.currentSession = nil
                        LoggerService.shared.info("Check-out successful", category: .beacon)
                    }
                } catch {
                    await MainActor.run {
                        LoggerService.shared.error("Check-out failed", error: error, category: .beacon)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    @objc private func settingsTapped() {
        #if DEBUG
        // Show debug menu in development
        let alert = UIAlertController(
            title: "Debug Menu",
            message: "Choose an option",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "🔍 Professional Beacon Scanner", style: .default) { [weak self] _ in
            let scannerVC = BeaconScannerViewController()
            self?.navigationController?.pushViewController(scannerVC, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "📡 Quick Scan (10s)", style: .default) { [weak self] _ in
            self?.runQuickBeaconScan()
        })
        
        alert.addAction(UIAlertAction(title: "📋 View Logs", style: .default) { [weak self] _ in
            // TODO: Implement log viewer
            let logAlert = UIAlertController(
                title: "Logs",
                message: "Log viewer coming soon",
                preferredStyle: .alert
            )
            logAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(logAlert, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "🗑 Clear Session", style: .destructive) { [weak self] _ in
            self?.currentSession = nil
            self?.isCheckedIn = false
            self?.updateUI()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
        #else
        // Production version
        let alert = UIAlertController(
            title: "Settings",
            message: "Settings will be available in the next version",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        #endif
    }
    
    // MARK: - Permissions
    
    private func checkPermissions() {
        // Check location permission
        locationManager.requestLocationPermission()
        
        let locationStatus = locationManager.getAuthorizationStatus()
        let bluetoothStatus = "Enabled" // Would check CBCentralManager in real app
        
        sessionInfoLabel.text = "Location: \(locationStatus.rawValue) | Bluetooth: \(bluetoothStatus)"
        
        if locationStatus == .denied || locationStatus == .restricted {
            LoggerService.shared.warning("Location permission denied", category: .location)
        }
    }
    
    // MARK: - Beacon Detection
    
    private func setupBeaconDetection() {
        // Setup beacon monitoring for configured UUID
        let config = AppConfiguration.shared.beacon
        guard let uuid = UUID(uuidString: config.defaultUUID) else {
            LoggerService.shared.error("Invalid beacon UUID", category: .beacon)
            return
        }
        
        let region = BeaconRegion(
            identifier: "com.oxii.beacon.main",
            uuid: uuid,
            major: nil,
            minor: nil
        )
        
        beaconManager.delegate = self
        beaconManager.startMonitoring(for: region)
        
        LoggerService.shared.info("Beacon monitoring started for UUID: \(config.defaultUUID)", category: .beacon)
    }
    
    private func startBeaconScanning() {
        guard AppConfiguration.shared.features.isBeaconRangingEnabled else { return }
        
        let config = AppConfiguration.shared.beacon
        guard let uuid = UUID(uuidString: config.defaultUUID) else { return }
        
        let region = BeaconRegion(
            identifier: "com.oxii.beacon.main",
            uuid: uuid,
            major: nil,
            minor: nil
        )
        
        beaconManager.startRanging(for: region)
        LoggerService.shared.info("Beacon ranging started", category: .beacon)
        
        // Debug: Check all monitored regions after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.debugCheckMonitoredRegions()
        }
    }
    
    private func stopBeaconScanning() {
        let config = AppConfiguration.shared.beacon
        guard let uuid = UUID(uuidString: config.defaultUUID) else { return }
        
        let region = BeaconRegion(
            identifier: "com.oxii.beacon.main",
            uuid: uuid,
            major: nil,
            minor: nil
        )
        
        beaconManager.stopRanging(for: region)
        LoggerService.shared.info("Beacon ranging stopped", category: .beacon)
    }
    
    private func debugCheckMonitoredRegions() {
        LoggerService.shared.info("🔍 DEBUG: Checking monitored regions...", category: .beacon)
        
        let monitoredRegions = beaconManager.getMonitoredRegions()
        LoggerService.shared.info("📋 Currently monitoring \(monitoredRegions.count) region(s)", category: .beacon)
        
        for region in monitoredRegions {
            LoggerService.shared.info("📡 Region: \(region.identifier) - UUID: \(region.uuid)", category: .beacon)
        }
        
        // Try to force another state request
        if let firstRegion = monitoredRegions.first {
            let clRegion = firstRegion.toCLBeaconRegion()
            LoggerService.shared.info("🔄 Force requesting state for: \(firstRegion.identifier)", category: .beacon)
        }
    }
    
    private func runQuickBeaconScan() {
        let progressAlert = UIAlertController(
            title: "Scanning for Beacons",
            message: "\n\nSearching...\n\n",
            preferredStyle: .alert
        )
        
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        progressAlert.view.addSubview(spinner)
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: progressAlert.view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: progressAlert.view.topAnchor, constant: 95)
        ])
        
        present(progressAlert, animated: true) {
            UniversalBeaconScanner.shared.onBeaconsDetected = { beacons in
                DispatchQueue.main.async {
                    progressAlert.dismiss(animated: true) {
                        self.showQuickScanResults(beacons)
                    }
                }
            }
            
            UniversalBeaconScanner.shared.runDiagnosticScan(duration: 10)
        }
    }
    
    private func showQuickScanResults(_ beacons: [DetectedBeacon]) {
        let title = beacons.isEmpty ? "⚠️ No Beacons Found" : "✅ Found \(beacons.count) Beacon(s)"
        
        var message = ""
        if beacons.isEmpty {
            message = "No beacons detected. Check:\n• Beacon power\n• Bluetooth enabled\n• Location permission"
        } else {
            for beacon in beacons.prefix(5) {
                message += "\n📡 \(beacon.uuid)\n   Major: \(beacon.major), Minor: \(beacon.minor)\n   Signal: \(beacon.rssi) dBm\n"
            }
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - BeaconManagerDelegate

extension AttendanceViewController: BeaconManagerDelegate {
    
    func beaconManager(_ manager: BeaconManagerProtocol, didEnterRegion region: BeaconRegion) {
        LoggerService.shared.info("Entered beacon region: \(region.identifier)", category: .beacon)
        
        detectedBeacon = region
        
        // Auto check-in if enabled
        if !isCheckedIn && AppConfiguration.shared.getValue(for: "auto_checkin", default: true) {
            checkInTapped()
        }
    }
    
    func beaconManager(_ manager: BeaconManagerProtocol, didExitRegion region: BeaconRegion) {
        LoggerService.shared.info("Exited beacon region: \(region.identifier)", category: .beacon)
        
        // Update UI
        DispatchQueue.main.async { [weak self] in
            self?.detectedBeacon = nil
            self?.updateBeaconInfo(site: nil, signal: nil, distance: nil)
        }
    }
    
    func beaconManager(_ manager: BeaconManagerProtocol, didRangeBeacons beacons: [CLBeacon], in region: BeaconRegion) {
        guard let beacon = beacons.first else { return }
        
        let distance = beacon.accuracy > 0 ? beacon.accuracy : nil
        let signal = beacon.rssi != 0 ? beacon.rssi : nil
        
        DispatchQueue.main.async { [weak self] in
            self?.detectedBeacon = region
            self?.updateBeaconInfo(
                site: "Beacon \(beacon.major).\(beacon.minor)",
                signal: signal,
                distance: distance
            )
            
            // Auto check-in if very close
            if let distance = distance,
               distance < 2.0,
               self?.isCheckedIn == false,
               AppConfiguration.shared.getValue(for: "proximity_checkin", default: false) {
                self?.checkInTapped()
            }
        }
        
        LoggerService.shared.debug("Beacon ranged - Distance: \(distance ?? -1)m, RSSI: \(signal ?? 0)", category: .beacon)
    }
    
    func beaconManager(_ manager: BeaconManagerProtocol, didFailWithError error: Error) {
        LoggerService.shared.error("Beacon manager error", error: error, category: .beacon)
        
        DispatchQueue.main.async { [weak self] in
            self?.statusDescriptionLabel.text = "Beacon detection error: \(error.localizedDescription)"
        }
    }
}
