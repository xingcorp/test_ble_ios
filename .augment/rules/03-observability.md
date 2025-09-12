# Observability Policy

- **OSLog/Logger** thay `print()`, có `subsystem/category`, **privacy redaction**.
- **Signpost**: app_cold_start, feature_first_paint, api_request_duration, db_write_duration.
- **MetricKit** bật & gửi payload; đặt alert theo SLO.
- (Optional) **OpenTelemetry**: instrument URLSession; propagate `traceparent`/`x-correlation-id`.
- KPI: crash-free users, P90/P99 latency, error budget, hang rate, battery impact.
