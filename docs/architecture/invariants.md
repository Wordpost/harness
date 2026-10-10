[⬅️ К runtime router](../../AGENTS.md)

# Engineering Invariants

Registry проверяемых code-level правил и Definition of Done.

## How To Use

- Открывать только релевантные `INV-*` через Session Router в [AGENTS.md](../../AGENTS.md).
- Доменные контракты живут в профильных docs; здесь только cross-cutting rules и closure gates.
- Status: `auto` — проверяет машина; `manual` — review/grep; `not wired` — правило принято, tooling ещё нет.
- Ссылаться на ID, а не копировать правила в phase docs, templates или gotchas.
- При установке шаблона заменить project hooks на подтверждённые значения либо `not applicable`.

## Registry

| ID | Rule | Status | Open when / project hook |
| --- | --- | --- | --- |
| INV-ARCH-1 | У изменяемого поведения явно определены implementation owner и durable contract owner. Один факт/contract имеет один home; consumers и phase docs ссылаются на него. Изменения ownership, runtime, auth, public contract и deploy записываются в соответствующем durable owner. | manual | Любое изменение; [module-map.md](./module-map.md). |
| INV-BND-1 | У shared/public workflow один явный owner; adapters не дублируют domain behavior. | manual | API/UI/CLI/job boundary; [module-map.md](./module-map.md). |
| INV-ENTRY-1 | Entrypoint валидирует input, делегирует owner и формирует response; business/data orchestration не расползается по adapters. | manual | Controller/handler/command/resolver edits. |
| INV-TYPE-1 | External input разбирается и валидируется на boundary; unsafe type bypass не заменяет contract. | `[INSERT_TYPE_INVARIANT_STATUS]` | `[INSERT_TYPECHECK_OR_VALIDATION_HOOK]`. |
| INV-SRP-1 | Границы code/docs определяются независимыми responsibilities и reasons to change; неделимый contract, acceptance criteria и evidence сохраняются целиком. Делить или сжимать их ради количества строк/слов запрещено. Перед `completed` итоговый diff и затронутые owners/consumers проверяются на конкретный overlap, смешение независимых responsibilities и cleanup, созданный правкой; известные нарушения исправляются у owner в текущем scope. | manual | Любое изменение; Responsibility Gate. |
| INV-REUSE-1 | Новая util/service/helper/abstraction, wrapper, dependency или config обоснована конкретной текущей ответственностью/acceptance scenario и причиной недостаточности более простого варианта из OODA Decide. Перед вводом адресно проверить owners и call sites через `rg`; overlap переиспользовать/расширить. Гипотетическое будущее reuse не основание; один consumer/implementation сам по себе не запрещает необходимую boundary. | manual | New helper/layer, dependency or configuration; [OODA](../../AGENTS.md#ooda-runtime). |
| INV-TX-1 | Связанные multi-step mutations атомарны там, где это поддерживается; irreversible/external effects выполняются только после успешного commit/state transition. | `[INSERT_TRANSACTION_INVARIANT_STATUS]` | Data writes, jobs, webhooks, messaging. |
| INV-SEC-1 | Logs, errors и external responses не раскрывают credentials или sensitive payloads. | manual | Logging, integrations, incidents. |
| INV-ERR-1 | При смысловом оборачивании ошибки сохраняются первопричина и канонические коды, технические коды-синонимы не создаются; публичный outcome отделён от безопасной диагностики. Критический/неожиданный сбой достигает назначенной terminal boundary без потерь и дублирования; expected failures не создают incidents. Reporting не меняет retry/unknown/side-effect semantics. | manual | Catch/throw, integrations, callbacks/jobs, unavailable outcomes, log/alert; [project error owner](./module-map.md#error-handling-boundaries), `[INSERT_ERROR_HANDLING_CHECK_HOOK_OR_MANUAL]`. |
| INV-VER-1 | Выбирается минимальный недублирующий gate по changed surface и риску из [infrastructure.md](./infrastructure.md#verification-protocol); command catalog не является checklist. Full suite нужен для broad change, phase/release closure или прямого требования. Green gate не повторяется при неизменных inputs; superset заменяет subset. | auto + manual choice | Verification planning. |
| INV-VER-2 | Изменённый contract доказан тестом или manual/runtime flow с binary expected result. | manual | Contract-sensitive changes. |
| INV-VER-3 | Infra/harness failure отделён от code defect и не выдаётся за green/red product verdict. | manual | Любой noisy/failed gate. |
| INV-VER-4 | После изменения shared/public contract выполнен consumer audit: call sites, imports/re-exports, adapters, tests и docs. | manual | API/service/schema/event move or change. |

## Definition of Done

Task, step или PR получает `completed` только если:

1. Минимально достаточный gate зелёный либо infra failure явно отделён и не скрывает обязательную проверку.
2. Automated invariants не красные; manual invariant debt не замаскирован.
3. Новые механизмы проверены по `INV-REUSE-1`.
4. Ownership и responsibilities проверены по `INV-ARCH-1` и `INV-SRP-1`.
5. Contract доказан; consumers и boundary adapters обновлены.
6. Durable contract change синхронизирован по `INV-ARCH-1`.
7. Lifecycle и verification verdict не смешиваются: `blocked` status и `FAIL`/`PARTIAL`/`BASELINE` verdict не называются `completed`.
8. Для изменённого failure path выполнен review по `INV-ERR-1` и применимая failure-path проверка; один happy-path PASS не доказывает этот контракт.

## Project Enforcement

| ID / group | Tooling hook | Status |
| --- | --- | --- |
| Types / validation | `[INSERT_TYPECHECK_OR_VALIDATION_HOOK]` | `[INSERT_STATUS]` |
| Ownership / SRP / reuse | Итоговый diff и targeted owner/consumer review по `INV-ARCH-1`, `INV-SRP-1`, `INV-REUSE-1` | manual |
| Tests | `[INSERT_TEST_HOOK]` | `[INSERT_STATUS]` |
| Lint / formatting | `[INSERT_LINT_OR_FORMAT_HOOK]` | `[INSERT_STATUS]` |
| Consumer/API checks | `[INSERT_CONSUMER_CHECK_HOOK_OR_MANUAL]` | `[INSERT_STATUS]` |
| Error handling | `[INSERT_ERROR_HANDLING_CHECK_HOOK_OR_MANUAL]` | manual |
| Docs structure | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-docs.ps1 -Strict` | auto |

Автоматизацию подключать по одному правилу вместе с cleanup текущих нарушений; не объявлять `auto`, пока hook реально не работает.
