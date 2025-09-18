//
//  RSSISmoother.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation
import CoreLocation

/// Enhanced RSSI smoother with history tracking and outlier filtering
public final class RSSISmoother {
    private var smoothedValues: [String: Double] = [:] // key = beacon key, value = smoothed RSSI
    private var rssiHistory: [String: [Double]] = [:] // key = beacon key, value = history window
    private let alpha: Double // Weight for exponential moving average
    private let window: Int // History window size
    private let outlierThreshold: Double = 20.0 // Ignore RSSI changes > 20 dBm
    private let noSignalRSSI: Double = -100.0 // Default for no signal
    
    public init(alpha: Double = 0.4, window: Int = 5) {
        self.alpha = alpha
        self.window = max(3, window) // Ensure minimum window size
    }
    
    /// Get smoothed RSSI value for a beacon with outlier filtering
    public func value(for beacon: CLBeacon) -> Double {
        let key = beaconKey(for: beacon)
        let rawRSSI = Double(beacon.rssi == 0 ? Int(noSignalRSSI) : beacon.rssi)
        
        // Initialize if first time seeing this beacon
        if smoothedValues[key] == nil {
            smoothedValues[key] = rawRSSI
            rssiHistory[key] = [rawRSSI]
            return rawRSSI
        }
        
        // Get previous smoothed value
        let previousSmoothed = smoothedValues[key] ?? rawRSSI
        
        // Filter outliers: if change is too dramatic, ignore it
        if abs(rawRSSI - previousSmoothed) > outlierThreshold {
            LoggerService.shared.debug("🚫 Ignoring outlier RSSI: \(rawRSSI) (previous: \(previousSmoothed))", category: .beacon)
            return previousSmoothed
        }
        
        // Apply exponential weighted moving average
        let smoothedRSSI = alpha * rawRSSI + (1 - alpha) * previousSmoothed
        smoothedValues[key] = smoothedRSSI
        
        // Update history window
        var history = rssiHistory[key] ?? []
        history.append(rawRSSI)
        if history.count > window {
            history.removeFirst()
        }
        rssiHistory[key] = history
        
        return smoothedRSSI
    }
    
    /// Get average RSSI from history window (useful for stability checks)
    public func averageRSSI(for beacon: CLBeacon) -> Double? {
        let key = beaconKey(for: beacon)
        guard let history = rssiHistory[key], !history.isEmpty else { return nil }
        return history.reduce(0, +) / Double(history.count)
    }
    
    /// Check if beacon signal is stable (low variance in recent history)
    public func isStable(for beacon: CLBeacon, varianceThreshold: Double = 5.0) -> Bool {
        let key = beaconKey(for: beacon)
        guard let history = rssiHistory[key], history.count >= 3 else { return false }
        
        let mean = history.reduce(0, +) / Double(history.count)
        let variance = history.map { pow($0 - mean, 2) }.reduce(0, +) / Double(history.count)
        
        return variance <= varianceThreshold
    }
    
    /// Get confidence score (0-1) based on signal stability and strength
    public func confidence(for beacon: CLBeacon) -> Double {
        let smoothed = value(for: beacon)
        let stable = isStable(for: beacon)
        
        // Signal strength component (normalize -100 to -30 dBm to 0-1)
        let signalStrength = max(0, min(1, (smoothed + 100) / 70))
        
        // Stability component
        let stability = stable ? 1.0 : 0.5
        
        // Combined confidence score
        return signalStrength * 0.7 + stability * 0.3
    }
    
    /// Clear history for a specific beacon
    public func clear(for beacon: CLBeacon) {
        let key = beaconKey(for: beacon)
        smoothedValues.removeValue(forKey: key)
        rssiHistory.removeValue(forKey: key)
    }
    
    /// Reset all smoothing data
    public func reset() {
        smoothedValues.removeAll()
        rssiHistory.removeAll()
    }
    
    /// Generate unique key for beacon identification
    private func beaconKey(for beacon: CLBeacon) -> String {
        // Use UUID + Major for key (ignore Minor as it rotates)
        return "\(beacon.uuid.uuidString)-\(beacon.major)"
    }
}
