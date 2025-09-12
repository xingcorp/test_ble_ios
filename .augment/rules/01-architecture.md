# Clean Architecture (iOS Swift)

- Flow phụ thuộc 1 chiều: **Presentation → Domain → Data** (hướng vào Domain).
- Presentation: **MVVM + Coordinator**; UI chỉ render, state trong ViewModel.
- Domain: **UseCase, Entities** (pure Swift, không UIKit).
- Data: **Repository + DataSources (Remote/Local)**; **Mapper** tách **DTO ↔ Entity**.
- **Cấm**: UI import trong Domain; networking trong Presentation; DTO ở UI.
- DI: qua **protocol + initializer** (Swinject/Factory tuỳ chọn).
- Module SPM: `Core/(Networking, Observability, Persistence, Auth)`, `Domain/`, `Data/`, `DesignSystem/`, `Features/*`, `App/`.
