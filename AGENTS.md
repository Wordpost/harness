# [INSERT_PROJECT_NAME] Agent Harness

## OODA Runtime

1. **Observe:** до решения или кода выбери маршрут ниже; открой owner, один live code/test/runtime reference и затронутых consumers; для любого изменения применяй `INV-ARCH-1`, `INV-SRP-1` и `INV-REUSE-1`.
2. **Orient:** сопоставь contract с реальным кодом и проверками; проверь owner изменяемого поведения и границы responsibilities по этим invariants; явно назови существенные противоречия, допущения и неизвестные.
3. **Decide:** для изменения задай binary success criteria. Выбирай первый вариант, полностью выполняющий target contract и обязательные invariants: подходящий existing project code → стандартный механизм платформы → установленная dependency → минимальный новый код. Основание для нового механизма — `INV-REUSE-1`.
4. **Act:** меняй только файлы и контракты, необходимые для результата или cleanup, созданного самой правкой; выполни выбранный gate и обнови тот же owner, если contract изменился.

**Re-orientation Gate:** если решение превращается в workaround, не требуемый контрактом compatibility shim, duplicate owner или заметно разрастается относительно задачи — остановись и вернись к Orient.

## Session Router

Выбери основной маршрут по намерению и добавь применимые маршруты риска. Читай только нужные sections owners, live references и `INV-*` одним batch, если среда это поддерживает; пересекающийся контекст читай один раз.

| Намерение / риск | Открыть следующим | Targeted `INV-*` |
| --- | --- | --- |
| Существующая phase/step задача | [docs/phases/README.md](./docs/phases/README.md) → `active/` parent → step | по риску шага; при closure `INV-VER-*` |
| Создать phase | [Phase Authoring Guide](./docs/phases/PHASE_AUTHORING_GUIDE.md) + [phase template](./docs/phases/templates/phase-template.md) + [step template](./docs/phases/templates/step-template.md) | `INV-ARCH-*`, `INV-VER-*` |
| Переразбить или закрыть phase | [Phase Authoring Guide](./docs/phases/PHASE_AUTHORING_GUIDE.md) + `active/` parent + затронутые steps | `INV-ARCH-*`, `INV-VER-*` |
| Изменение существующего module, API или shared workflow | owning technical doc; если owner неизвестен — [docs/architecture/module-map.md](./docs/architecture/module-map.md) | по затронутой boundary: `INV-BND-*`, `INV-ENTRY-*`, `INV-VER-4` |
| Новое architecture или ownership decision | [docs/architecture/module-map.md](./docs/architecture/module-map.md) + затронутый owner | `INV-ARCH-*`, `INV-BND-*` |
| Stack, scripts, env contract, CI или deploy | [docs/architecture/infrastructure.md](./docs/architecture/infrastructure.md) | `INV-ARCH-*`, `INV-VER-*` |
| Новый локальный pattern или abstraction | [docs/architecture/guidelines.md](./docs/architecture/guidelines.md) | `INV-REUSE-*` |
| Известная ловушка, incident или повторный баг | [docs/architecture/gotchas.md](./docs/architecture/gotchas.md) | ID риска из записи |
| External input, types или sensitive output | owning technical doc; если owner неизвестен — [docs/architecture/module-map.md](./docs/architecture/module-map.md) | `INV-TYPE-*`, `INV-SEC-*` |
| Mutation, transaction или side effect | owning technical doc; если owner неизвестен — [docs/architecture/module-map.md](./docs/architecture/module-map.md) | `INV-TX-*` |
| Изменение failure path: catch/throw, integration, callback/job, unavailable outcome, log/alert | [Error Handling Boundaries](./docs/architecture/module-map.md#error-handling-boundaries) → project error owner + live failure reference | `INV-ERR-1`, `INV-SEC-1`, применимые `INV-TX-*` |
| Verification или completion verdict | [Definition of Done](./docs/architecture/invariants.md#definition-of-done) + targeted search/range нужной команды в [Infrastructure](./docs/architecture/infrastructure.md#commands), не весь owner | `INV-VER-*` |
| Completed phase context | [docs/phases/COMPLETED_PHASES.md](./docs/phases/COMPLETED_PHASES.md) → `completed/` parent | — |
| Technical topic не распознан | [docs/architecture/module-map.md](./docs/architecture/module-map.md) + targeted search по code/docs | выбрать после нахождения owner |

Применимые ID находи одним targeted search в [invariants.md](./docs/architecture/invariants.md), а не чтением всего registry.
Для failure path профильный маршрут обязателен, включая обычную feature-разработку без вызова skill.

## Hard Gates

- **Socratic:** если после Observe неоднозначность меняет contract, ownership или acceptance criteria — задай один точечный вопрос.
- **Isolation:** не читать production `.env`, secrets, credentials и их dumps; использовать только safe example/template.
- **Placeholders:** незаполненный `[INSERT_*]` означает «доисследовать», а не разрешение додумать факт.
- **Single Home:** ownership и размещение contract — по `INV-ARCH-1`.
- **AGENTS boundary:** здесь живут только runtime-router, gates и стабильный adapter. Текущие статус и фаза, история разработки, стек, команды и доменные контракты запрещены.
- **No prose:** каждый блок хранит contract/boundary, owner/path, phase-local status/evidence, важное why или verification hook; пересказ, tutorial, журнал, длинный лог и копия owner text запрещены.
- **Documentation:** index только маршрутизирует; phase хранит свой contract/status/verification; новый doc создаётся только для отдельного durable contract/read mode.

`docs/work`, `docs/plans`, `docs/audits` и `task.md` — temporary context, не durable truth. Проверяй их выводы по live code и переноси durable решение в owner из Session Router.

## Context и skill hygiene

- Когда известны owner, изменяемое поведение, затронутые consumers и достаточный gate, переходи к действию. Расширяй чтение только для конкретного неизвестного, противоречия или нового риска; всю `docs/` подряд не сканируй.
- Ясная локальная правка вне существующей phase/step идёт прямо по OODA без отдельного документа плана и обязательного дополнительного reviewer. Условия создания phase — в [Phase Authoring Guide](./docs/phases/PHASE_AUTHORING_GUIDE.md#когда-нужна-фаза).
- Вывод команд: success — команда, exit code и count; failure — релевантная ошибка и короткий лог.
- Большие файлы и diff читать targeted; неизменённое не повторять.
- Skills выбирать по текущей задаче; review skill — только для review/audit, docs-only edit не запускает runtime skills.

## Project Adapter

- Documentation language: `[INSERT_DOCUMENTATION_LANGUAGE]`.
