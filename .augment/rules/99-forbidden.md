# Forbidden

- Massive VC; DTO ở UI; network gọi trực tiếp ngoài HTTPClient/interceptors.
- `print()` trong production; log PII/token; block main thread sync I/O.
- PR khổng lồ đa mục tiêu; hardcoded secrets; circular deps.
