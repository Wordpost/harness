[⬅️ К runtime router](../../AGENTS.md)

# System & Module Map

Current-state карта: где живёт логика, кто owner, какие entrypoints и shared/public boundaries реально существуют.

## Назначение системы

`[INSERT_SYSTEM_PURPOSE]`

Architecture model: `[INSERT_ARCHITECTURE_TYPE]`.

## Runtime Surfaces

| Surface | Entrypoint | Owner | Consumers |
| --- | --- | --- | --- |
| UI / client | `[INSERT_UI_ENTRYPOINTS_OR_NONE]` | `[INSERT_UI_OWNER]` | `[INSERT_UI_CONSUMERS]` |
| API / server | `[INSERT_API_ENTRYPOINTS_OR_NONE]` | `[INSERT_API_OWNER]` | `[INSERT_API_CONSUMERS]` |
| CLI / commands | `[INSERT_CLI_ENTRYPOINTS_OR_NONE]` | `[INSERT_CLI_OWNER]` | `[INSERT_CLI_CONSUMERS]` |
| Jobs / schedulers | `[INSERT_BACKGROUND_ENTRYPOINTS_OR_NONE]` | `[INSERT_JOB_OWNER]` | `[INSERT_JOB_CONSUMERS]` |
| Data layer | `[INSERT_DATA_ENTRYPOINTS]` | `[INSERT_DATA_OWNER]` | `[INSERT_DATA_CONSUMERS]` |
| External integrations | `[INSERT_INTEGRATION_ENTRYPOINTS_OR_NONE]` | `[INSERT_INTEGRATION_OWNER]` | `[INSERT_INTEGRATION_CONSUMERS]` |

Удалить неприменимые строки либо пометить `none`; не оставлять вымышленные surfaces.

## Structure

```text
[INSERT_PROJECT_STRUCTURE]
```

Показывать только directories/files, помогающие найти owners и entrypoints. Полный tree здесь не нужен.

## Module Ownership

| Module / domain | Responsibility | Primary owner / entrypoints | Shared/public contracts | Must not own |
| --- | --- | --- | --- | --- |
| `[INSERT_MODULE]` | `[INSERT_RESPONSIBILITY]` | `[INSERT_OWNER_PATHS]` | `[INSERT_CONTRACTS]` | `[INSERT_FORBIDDEN_OVERLAP]` |

`LIVE` описывает наблюдаемый код; `PARTIAL LIVE` — только реализованный срез.
`TARGET / RESERVED` обозначает нормативную границу, которая сама по себе не
разрешает scaffold, migration или import. Live deviation не меняет target rule.
Server/client public surfaces указываются только при их наличии в проекте.

## Cross-Module Flows

Для каждого важного workflow указывать один orchestration owner и downstream consumers.

1. `[INSERT_FLOW_NAME]`
   - Input/boundary: `[INSERT_FLOW_INPUT]`
   - Owner: `[INSERT_FLOW_OWNER]`
   - Consumers/side effects: `[INSERT_FLOW_CONSUMERS]`
   - Verification reference: `[INSERT_FLOW_TEST_OR_RUNTIME_EVIDENCE]`

## Error Handling Boundaries

Карта project owners для [INV-ERR-1](./invariants.md). Поведение принадлежит указанному
профильному контракту, runtime — существующим entrypoints; второй owner не создавать.
Заполнить по live code для реально существующих surfaces; отсутствие механизма указать явно.

| Boundary / decision | Project owner / contract reference |
| --- | --- |
| Единая политика обработки ошибок | `[INSERT_ERROR_HANDLING_OWNER_DOC_OR_SECTION]` |
| Native error → wrapper: cause, оригинальные HTTP/system/provider codes и допустимые metadata | `[INSERT_ERROR_CAUSE_AND_CODE_CONTRACT]` |
| Terminal перехват/reporting для API/UI, CLI, jobs и detached callbacks, где они существуют | `[INSERT_ERROR_TERMINAL_BOUNDARIES_AND_OWNER_PATHS]` |
| Публичный формат ошибок, безопасные сообщения и совместимость consumers | `[INSERT_PUBLIC_ERROR_SERIALIZATION_CONTRACT_OR_NONE]` |
| Безопасная диагностика, stack policy и correlation/trace context | `[INSERT_ERROR_LOGGING_AND_CORRELATION_CONTRACT]` |
| Expected vs critical/unhandled; владелец alert delivery либо обоснованное отсутствие | `[INSERT_ERROR_CLASSIFICATION_AND_ALERT_OWNER_OR_NONE]` |
| Ближайший failure test либо проверяемый manual/runtime flow | `[INSERT_ERROR_FAILURE_REFERENCE]` |

Для HTTP различать локальный response status и upstream status; validation/expected 4xx
не должны становиться critical alerts. Для иных entrypoints применять project classification,
а не искусственно назначать HTTP-коды. При наличии alerts зафиксировать неблокирующую доставку,
dedup/rate limiting, failure delivery и shutdown behavior в их existing owner.

Общие правила реализуются средствами выбранного стека. Наличие этой секции не разрешает
scaffold нового handler/service, каталога кодов, очереди или канала оповещений.

## Protected Zones

- `[INSERT_DO_NOT_TOUCH_WITHOUT_REASON]`
- Generated/vendor/build paths: `[INSERT_GENERATED_OR_VENDOR_PATHS]`
- Schema/migrations/deploy boundaries: `[INSERT_HIGH_RISK_PATHS]`

Обновлять этот документ при появлении нового крупного owner, изменении entrypoint или shared/public boundary. Детали поведения держать в профильном document, если карта начинает разрастаться.
