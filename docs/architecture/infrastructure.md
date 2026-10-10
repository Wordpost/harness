[⬅️ К runtime router](../../AGENTS.md)

# Infrastructure & Runtime Contract

Source of truth для stack fingerprint, runtime topology, dependency manifests, verification scripts и deployment contour.

## Stack

| Layer | Technology / version | Evidence |
| --- | --- | --- |
| Primary runtime | `[INSERT_PRIMARY_RUNTIME]` | `[INSERT_RUNTIME_VERSION_FILE]` |
| Package / dependency manager | `[INSERT_PACKAGE_MANAGER_OR_NONE]` | manifest / lockfile |
| Backend / core | `[INSERT_BACKEND_STACK_OR_NONE]` | `[INSERT_BACKEND_MANIFEST]` |
| Frontend / UI | `[INSERT_FRONTEND_STACK_OR_NONE]` | `[INSERT_FRONTEND_MANIFEST]` |
| Data store | `[INSERT_DATA_STORE_OR_NONE]` | `[INSERT_SCHEMA_OR_CONFIG_REFERENCE]` |
| Queue / jobs | `[INSERT_QUEUE_STACK_OR_NONE]` | `[INSERT_QUEUE_REFERENCE]` |
| External integrations | `[INSERT_INTEGRATION_STACK_OR_NONE]` | [module-map.md](./module-map.md) |

Точные versions и packages принадлежат manifests/lockfiles. Здесь хранится только объяснение стека и ownership.

## Runtime Topology

- Application entrypoint: `[INSERT_APPLICATION_ENTRYPOINT]`.
- UI/client entrypoint: `[INSERT_UI_ENTRYPOINT_OR_NONE]`.
- Background workers/schedulers: `[INSERT_WORKER_ENTRYPOINTS_OR_NONE]`.
- Data/runtime context: `[INSERT_DATA_RUNTIME_CONTEXT]`.
- Local development flow: `[INSERT_LOCAL_START_FLOW]`.

## Commands

| Purpose | Command | Owner / evidence |
| --- | --- | --- |
| Install | `[INSERT_INSTALL_COMMAND]` | `[INSERT_PACKAGE_MANIFEST_PATH]` |
| Lint | `[INSERT_LINT_COMMAND_OR_NONE]` | manifest / CI |
| Test | `[INSERT_TEST_COMMAND_OR_NONE]` | manifest / CI |
| Typecheck | `[INSERT_TYPECHECK_COMMAND_OR_NONE]` | manifest / CI |
| Build | `[INSERT_BUILD_COMMAND_OR_NONE]` | manifest / CI |
| Hygiene | `[INSERT_HYGIENE_COMMAND_OR_NONE]` | repo convention |
| Docs structure | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-docs.ps1 -Strict` | [validator](../../scripts/validate-docs.ps1) |

Если команды нет, записать `none` и причину. Не подставлять типовую команду без live evidence.

### Docs validator contract

Назначение, покрытие, режимы и настройка исключений принадлежат
[руководству validator](../validate-docs.md). Команда проектного gate — в таблице выше.

## Verification Protocol

| Surface / risk | Минимальный gate | Executor / live evidence |
| --- | --- | --- |
| Docs structure / owner routing | Docs structure из Commands | agent / `scripts/validate-docs.ps1` |
| Изолированный behavior | `[INSERT_TARGETED_COMMAND_AND_EXACT_SELECTION_OR_NONE]` | `[INSERT_TARGETED_EXECUTOR_AND_REFERENCE]` |
| Shared/public boundary | `[INSERT_BOUNDARY_GATE_AND_CONSUMER_AUDIT]` | `[INSERT_BOUNDARY_GATE_EXECUTOR_AND_REFERENCE]` |
| Изменённый failure path (`INV-ERR-1`) | `[INSERT_ERROR_HANDLING_CHECK_HOOK_OR_MANUAL]`; применимый сценарий по [project error owner](./module-map.md#error-handling-boundaries) | `[INSERT_ERROR_CHECK_EXECUTOR_AND_REFERENCE]` |
| Broad change / phase or release closure | `[INSERT_AGGREGATE_GATE_OR_MANUAL_FLOW]` | `[INSERT_AGGREGATE_EXECUTOR_AND_REFERENCE]` |

- До изменения выбрать exact command/selection или manual flow, доказывающий acceptance criteria; масштаб и отсутствие дублирующих проверок — [INV-VER-1](./invariants.md).
- Связанные правки owner и consumers собрать до запуска выбранного набора gates. Промежуточный запуск нужен, когда его результат определяет диагностику или разрешает зависимое изменение; отдельный изменённый файл сам по себе не требует нового запуска.
- Executor определяется по live project policy: agent, operator или CI; чужой
  runner, full-suite prohibition и команды без manifest evidence не переносятся.
- Exact selection: runner должен выбрать нужный test/spec; zero selected tests
  не является доказательством. Если syntax неясен, читать targeted command
  reference или `--help` соответствующего runner.
- Shared mutable resources: `[INSERT_SHARED_TEST_RESOURCES_AND_SERIAL_ORDER_OR_NONE]`.
- Receipt: exact command/selection или manual flow, проверенные inputs/revision,
  exit code, counts, actual result и короткий relevant failure tail. Полные логи
  не копируются в contract docs.
- Required gate без результата остаётся непроверенным; infra failure отражается
  отдельно от product defect. Минимальность и closure — [INV-VER-*](./invariants.md).

## Environment Contract

- Safe variable template: `[INSERT_ENV_EXAMPLE_PATH_OR_NONE]`.
- Production secrets owner: `[INSERT_SECRET_STORE_OWNER]`.
- Required variable groups: `[INSERT_ENV_GROUPS]` — только имена и назначение, без значений.

## Deployment

- Targets/environments: `[INSERT_DEPLOY_TARGETS]`.
- Deployment owner/pipeline: `[INSERT_DEPLOY_OWNER_OR_CI_PATH]`.
- Migration order: `[INSERT_MIGRATION_ORDER_OR_NONE]`.
- Health/readiness checks: `[INSERT_HEALTHCHECKS]`.
- Rollback/forward-fix contract: `[INSERT_ROLLBACK_CONTRACT]`.

## Verification Notes

- Stack-sensitive изменения сверять с manifests, lockfiles, CI и этим документом.
- Дрейф между этим файлом и live config исправлять в той же задаче.
- Cross-cutting verification semantics брать из [invariants.md](./invariants.md).
