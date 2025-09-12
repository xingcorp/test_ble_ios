# Networking Policy

- **URLSession + async/await**, `waitsForConnectivity=true`.
- Interceptor pipeline: **Auth → Idempotency → Retry(backoff+jitter) → Cache(URLCache/ETag) → Metrics/Trace → Logging**.
- BackgroundSession khi cần; **NWPathMonitor**; **HTTP/3** fallback **H2/H1**.
- Phân loại lỗi: **NetworkError, DomainError, PersistenceError**; UI chỉ nhận lỗi domain đã map.
- Cache: HTTP caching (URLCache), TTL rõ ràng; ETag/If-None-Match; LocalDataSource cho offline.
- Security: **ATS on**, pinning khi yêu cầu; **không log token/PII**.
