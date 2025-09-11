//
//  BeaconTableViewCell.swift  
//  BeaconAttendance
//
//  Created by Senior iOS Developer
//

import UIKit

/// Custom table view cell for beacon display
public final class BeaconTableViewCell: UITableViewCell {
    
    static let identifier = "BeaconTableViewCell"
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let signalImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "antenna.radiowaves.left.and.right")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let uuidLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let majorMinorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let signalStrengthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(iconView)
        iconView.addSubview(signalImageView)
        containerView.addSubview(uuidLabel)
        containerView.addSubview(majorMinorLabel)
        containerView.addSubview(distanceLabel)
        containerView.addSubview(signalStrengthLabel)
        containerView.addSubview(statusIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Icon
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            signalImageView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            signalImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            signalImageView.widthAnchor.constraint(equalToConstant: 24),
            signalImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Labels
            uuidLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            uuidLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            uuidLabel.trailingAnchor.constraint(lessThanOrEqualTo: distanceLabel.leadingAnchor, constant: -8),
            
            majorMinorLabel.topAnchor.constraint(equalTo: uuidLabel.bottomAnchor, constant: 4),
            majorMinorLabel.leadingAnchor.constraint(equalTo: uuidLabel.leadingAnchor),
            majorMinorLabel.trailingAnchor.constraint(lessThanOrEqualTo: signalStrengthLabel.leadingAnchor, constant: -8),
            
            // Distance & Signal
            distanceLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            distanceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            distanceLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            signalStrengthLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 4),
            signalStrengthLabel.trailingAnchor.constraint(equalTo: distanceLabel.trailingAnchor),
            signalStrengthLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Status indicator
            statusIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            statusIndicator.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            statusIndicator.widthAnchor.constraint(equalToConstant: 8),
            statusIndicator.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    // MARK: - Configuration
    
    public func configure(with beacon: BeaconScannerViewModel.BeaconInfo) {
        // UUID (truncate for display)
        let displayUUID = String(beacon.uuid.prefix(8)) + "..." + String(beacon.uuid.suffix(4))
        uuidLabel.text = displayUUID
        
        // Major/Minor
        majorMinorLabel.text = "Major: \(beacon.major) • Minor: \(beacon.minor)"
        
        // Distance
        distanceLabel.text = beacon.formattedDistance
        
        // Signal
        signalStrengthLabel.text = "\(beacon.rssi) dBm • \(beacon.signalStrength)"
        
        // Status indicator color
        if beacon.isConfigured {
            statusIndicator.backgroundColor = .systemGreen
            iconView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
            signalImageView.tintColor = .systemGreen
        } else {
            statusIndicator.backgroundColor = .systemOrange
            iconView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            signalImageView.tintColor = .systemBlue
        }
        
        // Signal strength icon
        updateSignalIcon(rssi: beacon.rssi)
    }
    
    private func updateSignalIcon(rssi: Int) {
        let iconName: String
        if rssi >= -50 {
            iconName = "wifi"
        } else if rssi >= -70 {
            iconName = "wifi.exclamationmark"
        } else {
            iconName = "wifi.slash"
        }
        
        signalImageView.image = UIImage(systemName: iconName)
    }
    
    // MARK: - Reuse
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        uuidLabel.text = nil
        majorMinorLabel.text = nil
        distanceLabel.text = nil
        signalStrengthLabel.text = nil
        statusIndicator.backgroundColor = .clear
    }
}
