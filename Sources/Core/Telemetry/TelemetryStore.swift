//
//  TelemetryStore.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

public protocol TelemetryStore {
    func record(_ event: TelemetryEvent)
    func export() -> URL?
    func clear()
}

/// File-based Telemetry Store with JSON lines for easy export
public final class FileTelemetryStore: TelemetryStore {
    private let folderURL: URL
    private let fileURL: URL
    private let queue = DispatchQueue(label: "telemetry.store.queue")
    
    public init?(folderName: String = "Telemetry") {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        folderURL = docs.appendingPathComponent(folderName, isDirectory: true)
        fileURL = folderURL.appendingPathComponent("events.ndjson")
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            }
        } catch {
            print("TelemetryStore init failed: \(error)")
            return nil
        }
    }
    
    public func record(_ event: TelemetryEvent) {
        queue.async {
            do {
                let data = try JSONEncoder().encode(event)
                if let json = String(data: data, encoding: .utf8) {
                    let line = json + "\n"
                    if let handle = try? FileHandle(forWritingTo: self.fileURL) {
                        handle.seekToEndOfFile()
                        handle.write(line.data(using: .utf8)!)
                        try? handle.close()
                    }
                }
            } catch {
                print("Telemetry record failed: \(error)")
            }
        }
    }
    
    public func export() -> URL? {
        return fileURL
    }
    
    public func clear() {
        queue.async {
            do {
                try "".write(to: self.fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Telemetry clear failed: \(error)")
            }
        }
    }
}

