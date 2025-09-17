## Planning Block
**Goal:** Ship feature X safely
**Constraints:** P99<=800ms; iOS15+; no PII; deadline+7d
**Strategy:** MVVM+Coordinator → UseCase → Repo; DTO↔Entity; DI via protocol
**Task Graph:**
- D1: Design (diagram/contracts)
- I1: Domain: UseCase/Entity + Mapper
- I2: Data: Repository + DataSources
- I3: Presentation: ViewModel + Coordinator
- O1: Observability hooks (OSLog signpost, MetricKit)
- T1: Unit tests (UseCase/Mapper/Repo contract)
- V1: Verify (SwiftLint/format/tests/SLO guard)
**Done Criteria:** tests+lint pass; arch rules ok; metrics hooks added
**Risks & Mitigations:** API instability → feature flag; network flakiness → retry/backoff
