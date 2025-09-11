//
//  BeaconScannerViewController.swift
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import UIKit
import Combine
import BeaconAttendanceCore

/// Professional beacon scanner UI with real-time updates
public final class BeaconScannerViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Beacon Scanner"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Ready to scan"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var scanButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Scan", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .bar)
        progress.progressTintColor = .systemBlue
        progress.trackTintColor = .systemGray5
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.isHidden = true
        return progress
    }()
    
    private lazy var filterSegmentedControl: UISegmentedControl = {
        let items = BeaconScannerViewModel.BeaconFilter.allCases.map { $0.displayName }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        return control
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(BeaconTableViewCell.self, forCellReuseIdentifier: BeaconTableViewCell.identifier)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .systemGroupedBackground
        return table
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let imageView = UIImageView(image: UIImage(systemName: "antenna.radiowaves.left.and.right"))
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "No beacons detected"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .systemGray2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        return view
    }()
    
    // MARK: - Properties
    
    private let viewModel: BeaconScannerViewModel
    private var cancellables = Set<AnyCancellable>()
    private var displayTimer: Timer?
    
    // MARK: - Initialization
    
    public init(viewModel: BeaconScannerViewModel = BeaconScannerViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = BeaconScannerViewModel()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
        bindViewModel()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopScanning()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(statusLabel)
        headerView.addSubview(scanButton)
        headerView.addSubview(progressView)
        headerView.addSubview(filterSegmentedControl)
        
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            // Status
            statusLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            // Scan button
            scanButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            scanButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            scanButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Progress
            progressView.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: scanButton.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: scanButton.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Filter
            filterSegmentedControl.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            filterSegmentedControl.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            filterSegmentedControl.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            filterSegmentedControl.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            // Table
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Empty state
            emptyStateView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: tableView.widthAnchor, constant: -40),
            emptyStateView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        
        let sortButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(showSortOptions)
        )
        
        let exportButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(exportLogs)
        )
        
        navigationItem.rightBarButtonItems = [exportButton, sortButton]
    }
    
    // MARK: - Bindings
    
    private func bindViewModel() {
        // Scan state
        viewModel.$scanState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateUI(for: state)
            }
            .store(in: &cancellables)
        
        // Beacons list
        viewModel.$detectedBeacons
            .receive(on: DispatchQueue.main)
            .sink { [weak self] beacons in
                self?.tableView.reloadData()
                self?.emptyStateView.isHidden = !beacons.isEmpty || self?.viewModel.isScanning == true
            }
            .store(in: &cancellables)
        
        // Scan duration
        viewModel.$scanDuration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] duration in
                guard self?.viewModel.isScanning == true else { return }
                self?.progressView.progress = Float(duration / 30.0)
                self?.statusLabel.text = String(format: "Scanning... %.1fs", duration)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func scanButtonTapped() {
        if viewModel.isScanning {
            viewModel.stopScanning()
        } else {
            viewModel.startScanning(duration: 30)
        }
    }
    
    @objc private func filterChanged() {
        let filter = BeaconScannerViewModel.BeaconFilter.allCases[filterSegmentedControl.selectedSegmentIndex]
        viewModel.applyFilter(filter)
    }
    
    @objc private func showSortOptions() {
        let alert = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        
        for option in BeaconScannerViewModel.SortOption.allCases {
            alert.addAction(UIAlertAction(title: option.displayName, style: .default) { [weak self] _ in
                self?.viewModel.applySorting(option)
                self?.tableView.reloadData()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        
        present(alert, animated: true)
    }
    
    @objc private func exportLogs() {
        guard let url = viewModel.exportLogs() else {
            showAlert(title: "Export Failed", message: "Could not export scan results")
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(activityVC, animated: true)
    }
    
    // MARK: - UI Updates
    
    private func updateUI(for state: BeaconScannerViewModel.ScanState) {
        switch state {
        case .idle:
            scanButton.setTitle("Start Scan", for: .normal)
            scanButton.backgroundColor = .systemBlue
            statusLabel.text = "Ready to scan"
            progressView.isHidden = true
            progressView.progress = 0
            
        case .scanning:
            scanButton.setTitle("Stop Scan", for: .normal)
            scanButton.backgroundColor = .systemRed
            progressView.isHidden = false
            
        case .completed(let count):
            scanButton.setTitle("Start Scan", for: .normal)
            scanButton.backgroundColor = .systemBlue
            statusLabel.text = "Found \(count) beacon(s)"
            progressView.isHidden = true
            progressView.progress = 0
            
        case .error(let message):
            statusLabel.text = "Error: \(message)"
            progressView.isHidden = true
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension BeaconScannerViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.detectedBeacons.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BeaconTableViewCell.identifier, for: indexPath) as! BeaconTableViewCell
        let beacon = viewModel.detectedBeacons[indexPath.row]
        cell.configure(with: beacon)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BeaconScannerViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let beacon = viewModel.detectedBeacons[indexPath.row]
        showBeaconDetails(beacon)
    }
    
    private func showBeaconDetails(_ beacon: BeaconScannerViewModel.BeaconInfo) {
        let details = """
        UUID: \(beacon.uuid)
        Major: \(beacon.major)
        Minor: \(beacon.minor)
        
        Signal: \(beacon.rssi) dBm (\(beacon.signalStrength))
        Distance: \(beacon.formattedDistance)
        Proximity: \(beacon.proximity)
        
        Last Seen: \(DateFormatter.localizedString(from: beacon.lastSeen, dateStyle: .none, timeStyle: .medium))
        
        Status: \(beacon.isConfigured ? "✅ Configured" : "⚠️ Unknown")
        """
        
        let alert = UIAlertController(title: "Beacon Details", message: details, preferredStyle: .alert)
        
        if !beacon.isConfigured {
            alert.addAction(UIAlertAction(title: "Copy UUID", style: .default) { _ in
                UIPasteboard.general.string = beacon.uuid
            })
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}
