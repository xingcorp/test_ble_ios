# iOS Auto‑Attendance — **Implementation Guide**
**Beacon UUID theo dõi:** `FDA50693-0000-0000-0000-290995101092`

> Mục tiêu: triển khai **tự động chấm công** khi người dùng đi gần beacon, hoạt động ổn ngay cả khi app đóng, iPhone khoá/tắt màn hình, và **không mất dữ liệu** trong mọi tình huống.

---

## 0) Scope & Assumptions
- iOS **15+** (khuyến nghị 16+), Swift **5.9+**.
- App life‑cycle dùng `UIApplicationDelegate` + (tuỳ) `SceneDelegate`.
- Phần cứng beacon hỗ trợ iBeacon (UUID cố định ở trên). *Tuỳ chọn*: quảng cáo connectable + dịch vụ GATT cho handshake.

---

## 1) Cấu hình dự án

### 1.1 Info.plist (bắt buộc)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Ứng dụng cần vị trí để phát hiện điểm chấm khi bạn đến công ty.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Cho phép “Luôn luôn” để tự chấm công ngay cả khi ứng dụng không mở.</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Dùng Bluetooth để phát hiện beacon gần bạn.</string>
<key>NSMotionUsageDescription</key>
<string>Dùng dữ liệu chuyển động để tăng độ chính xác và chống gian lận chấm công.</string>
<!-- Nếu dùng HealthKit steps (tuỳ chọn) -->
<key>NSHealthShareUsageDescription</key>
<string>Cho phép đọc số bước chân để xác định bạn đang di chuyển vào công ty.</string>
```

### 1.2 Capabilities / Background Modes
- Bật **Background Modes**:
  - `Location updates`
  - *(tuỳ chọn nếu có handshake)* `Uses Bluetooth LE accessories`
- *(tuỳ chọn)* Push Notifications để dùng **silent push**.
- *(tuỳ chọn)* HealthKit + **Background Delivery**.

### 1.3 App Constants (Beacon/Geo)
```swift
enum BeaconConfig {
  static let uuid = UUID(uuidString: "FDA50693-0000-0000-0000-290995101092")! // ✅ UUID theo dõi
  static let regionIdentifier = "com.company.attendance.ibeacon"
  // Geofence quanh cơ sở (cấu hình từ server/RemoteConfig)
  static let defaultCampusRadius: CLLocationDistance = 200 // mét
}
```

---

## 2) Bootstrap (AppDelegate)
```swift
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  private let supervisor = AttendanceSupervisor.shared

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    supervisor.bootstrap()
    return true
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    supervisor.drainOutbox(background: true)
  }
}
```

---

## 3) AttendanceSupervisor (orchestrator)
```swift
final class AttendanceSupervisor {
  static let shared = AttendanceSupervisor()
  private init() {}

  private let location = CLLocationManager()
  private let motion = CMMotionActivityManager()
  private let pedometer = CMPedometer()
  private let outbox = OutboxQueue()
  private let client = HttpClient(baseURL: URL(string: "https://api.example.com")!)
  private let logger = TelemetryLogger()

  private lazy var beaconRegion: CLBeaconRegion = {
    let r = CLBeaconRegion(uuid: BeaconConfig.uuid, identifier: BeaconConfig.regionIdentifier)
    r.notifyOnEntry = true
    r.notifyOnExit = true
    r.notifyEntryStateOnDisplay = true
    return r
  }()

  func bootstrap() {
    location.delegate = self
    location.allowsBackgroundLocationUpdates = true
    requestPermissionsIfNeeded()
    // Monitors
    startBeaconRegionMonitoring()
    GeofenceManager.shared.startCampusGeofences() // radius từ server
    SLCVisitManager.shared.start()                // Significant-change + Visits
    // Drain outbox khi có mạng
    NetworkReachability.shared.onReachable = { [weak self] in self?.drainOutbox(background: false) }
  }

  private func requestPermissionsIfNeeded() {
    if location.authorizationStatus != .authorizedAlways { location.requestAlwaysAuthorization() }
    // Motion quyền implicit khi gọi query, nhưng nên preflight để UX rõ ràng
  }

  private func startBeaconRegionMonitoring() {
    location.startMonitoring(for: beaconRegion)
    location.requestState(for: beaconRegion) // kick initial state
  }

  func drainOutbox(background: Bool) {
    OutboxDrainer.drain(outbox: outbox, client: client, background: background, logger: logger)
  }
}

extension AttendanceSupervisor: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    guard region.identifier == beaconRegion.identifier else { return }
    logger.event("region_enter", attrs: ["id": region.identifier])
    RangingWindow(uuid: BeaconConfig.uuid).runAndDecide { [weak self] decision in
      self?.handleDecision(decision)
    }
  }

  func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
    guard region.identifier == beaconRegion.identifier else { return }
    if state == .inside {
      // Khi bật màn hình hoặc app khởi động, có thể nhận inside → cố gắng ranging nhanh
      RangingWindow(uuid: BeaconConfig.uuid).runAndDecide { [weak self] d in self?.handleDecision(d) }
    }
  }

  private func handleDecision(_ decision: AttendanceDecision) {
    switch decision {
    case .confirmed(let context):
      postAttendance(context)
    case .insufficient:
      logger.event("candidate_drop", attrs: ["reason": "insufficient_confidence"]) // giữ log để audit
    }
  }

  private func postAttendance(_ ctx: AttendanceContext) {
    var ev = AttendanceEvent.make(from: ctx)
    outbox.persist(ev)
    client.post("/v1/attendance/events", body: ev, idempotencyKey: ev.idempotencyKey) { [weak self] result in
      switch result {
      case .success:
        self?.outbox.markSent(ev)
        self?.logger.event("api_201", attrs: ["receipt": "ok"])
      case .failure:
        self?.outbox.scheduleRetry(ev)
        self?.logger.event("api_retry", attrs: [:])
      }
    }
  }
}
```

---

## 4) RangingWindow (5–10s, median + hysteresis)
```swift
enum AttendanceDecision { case confirmed(AttendanceContext), insufficient }
struct AttendanceContext { let beacon: CLBeacon; let samples: [Int]; let motion: MotionSnapshot }

final class RangingWindow: NSObject, CLLocationManagerDelegate {
  private let lm = CLLocationManager()
  private let uuid: UUID
  private var samples: [Int] = []
  private var best: CLBeacon?
  private var bgTask: UIBackgroundTaskIdentifier = .invalid
  private var timer: Timer?
  private var done: ((AttendanceDecision) -> Void)?

  init(uuid: UUID) { self.uuid = uuid; super.init(); lm.delegate = self }

  func runAndDecide(maxSeconds: TimeInterval = 8, _ completion: @escaping (AttendanceDecision) -> Void) {
    done = completion
    bgTask = UIApplication.shared.beginBackgroundTask(withName: "rangingWindow") { [weak self] in self?.finish(.insufficient) }
    let constraint = CLBeaconIdentityConstraint(uuid: uuid)
    lm.startRangingBeacons(satisfying: constraint)
    timer = Timer.scheduledTimer(withTimeInterval: maxSeconds, repeats: false) { [weak self] _ in self?.decideAndFinish() }
  }

  func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying constraint: CLBeaconIdentityConstraint) {
    guard let nearest = beacons.filter({ $0.rssi != 0 }).sorted(by: { $0.rssi > $1.rssi }).first else { return }
    best = nearest
    samples.append(nearest.rssi)
    if samples.count >= 4, stdev(samples) < 6, median(samples) > -70 { decideAndFinish() }
  }

  private func decideAndFinish() {
    guard let b = best else { return finish(.insufficient) }
    MotionGating.querySnapshot(lookbackMinutes: 3) { [weak self] motion in
      guard let self = self else { return }
      if motion.isWalkingLike || median(self.samples) > -65 {
        self.finish(.confirmed(.init(beacon: b, samples: self.samples, motion: motion)))
      } else {
        self.finish(.insufficient)
      }
    }
  }

  private func finish(_ d: AttendanceDecision) {
    if lm.rangedBeaconConstraints.count > 0 { lm.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: uuid)) }
    timer?.invalidate()
    if bgTask != .invalid { UIApplication.shared.endBackgroundTask(bgTask); bgTask = .invalid }
    done?(d)
    done = nil
  }
}
```

> **Notes**
> - `median`/`stdev` triển khai đơn giản (ở phụ lục).
> - Ngưỡng `-70 dBm` tuỳ chỉnh theo môi trường.
> - Bắt đầu sớm **stopRanging** nếu đủ tin cậy để tiết kiệm thời gian nền.

---

## 5) MotionGating (Core Motion)
```swift
struct MotionSnapshot { let isWalkingLike: Bool; let steps2min: Int }

enum MotionGating {
  static func querySnapshot(lookbackMinutes: Int, completion: @escaping (MotionSnapshot) -> Void) {
    let ped = CMPedometer(); let mm = CMMotionActivityManager()
    let now = Date(); let from = Calendar.current.date(byAdding: .minute, value: -lookbackMinutes, to: now)!

    var steps = 0; var walking = false
    let group = DispatchGroup(); group.enter(); group.enter()

    ped.queryPedometerData(from: from, to: now) { data, _ in
      if let d = data { steps = d.numberOfSteps.intValue }
      group.leave()
    }
    mm.queryActivityStarting(from: from, to: now, to: .main) { acts, _ in
      if let a = acts { walking = a.contains { ($0.walking || $0.running) && $0.confidence != .low } }
      group.leave()
    }

    group.notify(queue: .main) { completion(.init(isWalkingLike: walking, steps2min: steps)) }
  }
}
```

> **Lưu ý:** handler live của Motion không chạy khi app bị suspend ⇒ dùng **query** trong cửa sổ nền.

---

## 6) Geofence & SLC/Visit (arming + hồi sinh)
```swift
final class GeofenceManager: NSObject, CLLocationManagerDelegate {
  static let shared = GeofenceManager(); private override init() { super.init() }
  private let lm = CLLocationManager()

  func startCampusGeofences() {
    lm.delegate = self
    // Ví dụ 1 site; thực tế lấy danh sách site từ server/RemoteConfig
    let center = CLLocationCoordinate2D(latitude: 10.771, longitude: 106.698)
    let region = CLCircularRegion(center: center, radius: BeaconConfig.defaultCampusRadius, identifier: "campus.hq")
    region.notifyOnEntry = true; region.notifyOnExit = true
    lm.startMonitoring(for: region)
  }

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    // Arming: preload config, đặt cờ
    RemoteConfig.shared.set(armed: true)
  }
}

final class SLCVisitManager: NSObject, CLLocationManagerDelegate {
  static let shared = SLCVisitManager(); private override init() { super.init() }
  private let lm = CLLocationManager()

  func start() {
    lm.delegate = self
    lm.startMonitoringSignificantLocationChanges()
    lm.startMonitoringVisits()
  }

  func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
    AttendanceSupervisor.shared.drainOutbox(background: true) // hồi sinh & sync cấu hình nếu cần
  }
}
```

---

## 7) (Tuỳ chọn) CoreBluetooth GATT Handshake
> Chỉ dùng nếu beacon hỗ trợ **connectable** + Service UUID riêng. Mục tiêu: chống spoof bằng challenge‑response **ngắn** trong cửa sổ nền.
```swift
final class CBHandshake: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  private var cm: CBCentralManager!
  private var peripheral: CBPeripheral?
  private let serviceUUID = CBUUID(string: "1234")
  private let challengeUUID = CBUUID(string: "1235")
  private let responseUUID  = CBUUID(string: "1236")
  private var onDone: ((Bool) -> Void)?

  func run(_ completion: @escaping (Bool) -> Void) {
    onDone = completion
    cm = CBCentralManager(delegate: self, queue: .main, options: [CBCentralManagerOptionRestoreIdentifierKey: "cb.handshake"])
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    guard central.state == .poweredOn else { onDone?(false); return }
    cm.scanForPeripherals(withServices: [serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in self?.finish(false) } // giới hạn thời gian
  }

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    self.peripheral = peripheral
    cm.stopScan(); cm.connect(peripheral)
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices([serviceUUID])
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let s = peripheral.services?.first else { return finish(false) }
    peripheral.discoverCharacteristics([challengeUUID, responseUUID], for: s)
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard let ch = service.characteristics?.first(where: { $0.uuid == challengeUUID }),
          let rs = service.characteristics?.first(where: { $0.uuid == responseUUID }) else { return finish(false) }
    peripheral.readValue(for: ch)
    // Khi nhận challenge → tính toán response và write
    // (ví dụ HMAC(sharedKey, challenge))
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    guard characteristic.uuid == challengeUUID, let challenge = characteristic.value else { return finish(false) }
    let response = Crypto.hmacSHA256(data: challenge, key: Keychain.shared.sharedKey())
    if let rs = characteristic.service.characteristics?.first(where: { $0.uuid == responseUUID }) {
      peripheral.writeValue(response, for: rs, type: .withResponse)
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    finish(error == nil)
  }

  private func finish(_ ok: Bool) { onDone?(ok); onDone = nil; if let p = peripheral { cm.cancelPeripheralConnection(p) } }
}
```

---

## 8) Networking (Idempotent + Timeout ngắn)
```swift
struct HttpResult { let status: Int }

final class HttpClient {
  private let baseURL: URL; init(baseURL: URL) { self.baseURL = baseURL }

  func post<T: Encodable>(_ path: String, body: T, idempotencyKey: String, completion: @escaping (Result<HttpResult, Error>) -> Void) {
    var req = URLRequest(url: baseURL.appendingPathComponent(path))
    req.httpMethod = "POST"
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")
    req.addValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
    req.timeoutInterval = 4
    req.httpBody = try? JSONEncoder().encode(body)
    let task = URLSession.shared.dataTask(with: req) { _, resp, err in
      if let err = err { completion(.failure(err)); return }
      let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
      if (200...299).contains(code) { completion(.success(.init(status: code))) } else { completion(.failure(NSError(domain: "http", code: code))) }
    }
    task.resume()
  }
}
```

---

## 9) WAL + Outbox (no‑loss)
> Sản xuất nên dùng **SQLite (WAL)**, ví dụ GRDB. Ở đây minh hoạ **JSONL queue** gọn nhẹ; thay bằng SQLite rất dễ.

```swift
struct AttendanceEvent: Codable {
  let id: String
  let idempotencyKey: String
  let timestamp: Date
  let userId: String
  let deviceId: String
  let siteId: String
  let beacon: BeaconPayload
  let rssiSeries: [Int]
  let motion: MotionPayload
  static func make(from ctx: AttendanceContext) -> AttendanceEvent { /* build theo domain */
    let id = UUID().uuidString
    let key = Idempotency.make(userId: "u", deviceId: Device.id(), beacon: ctx.beacon, time: Date())
    return AttendanceEvent(id: id, idempotencyKey: key, timestamp: Date(), userId: "u", deviceId: Device.id(), siteId: "S_HQ", beacon: .from(ctx.beacon), rssiSeries: ctx.samples, motion: .from(ctx.motion))
  }
}

final class OutboxQueue {
  private let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("outbox.jsonl")
  private let q = DispatchQueue(label: "outbox.queue")

  func persist(_ ev: AttendanceEvent) { q.async { self.appendLine(ev) } }
  func markSent(_ ev: AttendanceEvent) { /* optional: write receipt index */ }
  func scheduleRetry(_ ev: AttendanceEvent) { /* no‑op with JSONL; SQLite nên có backoffAt */ }

  func popBatch(_ limit: Int = 20) -> [AttendanceEvent] {
    var arr: [AttendanceEvent] = []
    q.sync {
      guard let data = try? Data(contentsOf: fileURL), let str = String(data: data, encoding: .utf8) else { return }
      for line in str.split(separator: "\n").prefix(limit) {
        if let d = line.data(using: .utf8), let ev = try? JSONDecoder().decode(AttendanceEvent.self, from: d) { arr.append(ev) }
      }
    }
    return arr
  }

  private func appendLine(_ ev: AttendanceEvent) {
    let enc = try! JSONEncoder().encode(ev)
    let line = String(data: enc, encoding: .utf8)! + "\n"
    if !FileManager.default.fileExists(atPath: fileURL.path) { FileManager.default.createFile(atPath: fileURL.path, contents: nil) }
    if let h = try? FileHandle(forWritingTo: fileURL) { h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); try? h.close() }
  }
}

enum OutboxDrainer {
  static func drain(outbox: OutboxQueue, client: HttpClient, background: Bool, logger: TelemetryLogger) {
    var bgTask: UIBackgroundTaskIdentifier = .invalid
    if background { bgTask = UIApplication.shared.beginBackgroundTask(withName: "outboxDrain") { /* expire */ } }
    let batch = outbox.popBatch()
    let group = DispatchGroup()
    for ev in batch {
      group.enter()
      client.post("/v1/attendance/events", body: ev, idempotencyKey: ev.idempotencyKey) { result in
        switch result {
        case .success: outbox.markSent(ev)
        case .failure: outbox.scheduleRetry(ev)
        }
        group.leave()
      }
    }
    group.notify(queue: .main) {
      if bgTask != .invalid { UIApplication.shared.endBackgroundTask(bgTask) }
      logger.event("outbox_drained", attrs: ["count": batch.count])
    }
  }
}
```

---

## 10) IdempotencyKey
```swift
enum Idempotency {
  static func make(userId: String, deviceId: String, beacon: CLBeacon, time: Date) -> String {
    let raw = "\(userId)|\(deviceId)|\(beacon.uuid.uuidString)|\(beacon.major)|\(beacon.minor)|\(Int(time.timeIntervalSince1970))"
    return Crypto.sha256(raw)
  }
}
```

---

## 11) Local Notifications (fallback)
```swift
enum FallbackNotify {
  static func promptManualCheckin(reason: String) {
    let c = UNMutableNotificationContent()
    c.title = "Mở ứng dụng để chấm công"
    c.body = reason
    let req = UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil)
    UNUserNotificationCenter.current().add(req)
  }
}
```

---

## 12) Telemetry (gợi ý)
```swift
final class TelemetryLogger {
  func event(_ name: String, attrs: [String: Any]) { print("[EVENT]", name, attrs) }
}
```

---

## 13) Phụ lục: Tiện ích nhỏ
```swift
func median(_ xs: [Int]) -> Double { let s = xs.sorted(); let n = s.count; return n % 2 == 1 ? Double(s[n/2]) : Double(s[n/2-1] + s[n/2]) / 2 }
func stdev(_ xs: [Int]) -> Double { let m = xs.map(Double.init).reduce(0,+)/Double(xs.count); let v = xs.map{ pow(Double($0)-m,2)}.reduce(0,+)/Double(xs.count); return sqrt(v) }

enum Device { static func id() -> String { UIDevice.current.identifierForVendor?.uuidString ?? "unknown" } }

struct BeaconPayload: Codable { let uuid: String; let major: Int; let minor: Int; static func from(_ b: CLBeacon) -> Self { .init(uuid: b.uuid.uuidString, major: b.major.intValue, minor: b.minor.intValue) } }
struct MotionPayload: Codable { let walking: Bool; let steps2min: Int; static func from(_ m: MotionSnapshot) -> Self { .init(walking: m.isWalkingLike, steps2min: m.steps2min) } }
```

---

## 14) Kiểm thử & cấu hình
- **Ngưỡng RSSI**: đo thực tế từng cổng; bắt đầu với `median > -70`, `stdev < 6`, mẫu ≥ 3–4.
- **Ranging window**: 5–10s; cổng đông người giảm còn 4–6s + adv interval 200–300 ms.
- **Geofence radius**: 150–300 m; chỉ vài geofence chính để không vượt 20 regions/app.
- **SLC/Visit**: xác thực app tự **relaunch** sau reboot/force‑quit.
- **Offline 72h**: tắt mạng, đi qua cổng nhiều lần → mở mạng → xác thực Outbox drain idempotent.

---

## 15) Bảo mật & App Review
- Chỉ dùng vị trí/Bluetooth/Chuyển động cho **chấm công**; mô tả quyền rõ ràng.
- Chống gian lận: co‑location (geofence + beacon), motion gating, *(tuỳ chọn)* GATT challenge.
- Bật **Background App Refresh** trong hướng dẫn người dùng; khuyến cáo không **force‑quit**.

---

## 16) Nâng cao (tuỳ chọn)
- **BGAppRefresh** lập lịch drain Outbox định kỳ.
- **Remote Config**: bật/tắt `use_healthkit`, `use_gatt`, `ranging_ms`, `rssi_threshold`…
- **Diagnostics View**: hiển thị state regions, geofence, lần gửi gần nhất, backlog outbox.

---

**Kết thúc:** File này cung cấp **xương sống mã nguồn** để team cắm thẳng vào dự án. UUID iBeacon đã cố định: `FDA50693-0000-0000-0000-290995101092`. Có thể mở rộng dần sang SQLite (GRDB), HealthKit, và handshake GATT khi phần cứng sẵn sàng.

