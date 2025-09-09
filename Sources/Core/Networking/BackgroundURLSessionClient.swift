//
//  BackgroundURLSessionClient.swift
//  BeaconAttendance
//
//  Created by Senior iOS Team
//

import Foundation

public final class BackgroundURLSessionClient: NSObject {
    public static let shared = BackgroundURLSessionClient()
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "bg.attendance.session")
        config.waitsForConnectivity = true
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    private override init() {
        super.init()
    }
    
    public func uploadJSON<T: Encodable>(_ body: T, to url: URL, headers: [String: String] = [:]) {
        do {
            let data = try JSONEncoder().encode(body)
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
            try data.write(to: tmp)
            
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            for (k, v) in headers {
                req.setValue(v, forHTTPHeaderField: k)
            }
            
            let task = session.uploadTask(with: req, fromFile: tmp)
            task.resume()
        } catch {
            print("BG upload prepare failed: \(error)")
        }
    }
}

extension BackgroundURLSessionClient: URLSessionDelegate, URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("BG task failed: \(error)")
        } else {
            print("BG task ok: \(task.taskIdentifier)")
        }
        
        // Clean up temp file if needed
        if let uploadTask = task as? URLSessionUploadTask,
           let _ = uploadTask.originalRequest?.url {
            // Cleanup logic here
        }
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // Called when all background tasks are complete
        print("All background tasks finished")
    }
}
