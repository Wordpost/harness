[⬅️ Назад к плану фаз](README.md)

# Phase Authoring Guide

Owner формы active parent, active step и completed parent.

## Когда нужна фаза

Фаза нужна для законченного product/runtime/architecture slice, который:

- требует 3–8 отдельно проверяемых шагов;
- затрагивает несколько surfaces или имеет реальные зависимости;
- нуждается в durable status и phase-level verification.

Маленькая правка, unrelated cleanup, идея без решения и scope шире восьми шагов
фазой не становятся.

Создание:

1. Сверить [active roadmap](./README.md).
2. Создать parent из [phase template](./templates/phase-template.md) и step files
   из [step template](./templates/step-template.md).
3. Связать каждое решение с current owner и live reference.
4. Для каждого step назвать один owned outcome, current owner/live references,
   exact target delta, direct consumers, зависимости и binary proof. Один
   behavior не назначать двум steps.
5. Пройти [Implementation Readiness Gate](#implementation-readiness-gate) для
   каждого step; неизвестное решение не оставлять будущему implementer.
6. Добавить phase в roadmap только после готовности parent и всех steps.

## Ownership и active parent

| Artifact | Владеет | Не владеет |
| --- | --- | --- |
| Active parent | Цель, результат, зависимости, phase-local решения, steps, phase verification, status | Durable domain contract, step evidence, tutorial |
| Active step | Один target delta до его activation, implementation boundaries, acceptance, status и evidence | Current contract вместо architecture owner, private coding recipe, completed history |
| Roadmap/index | Queued outcome либо active/completed lifecycle state и ссылка | Contract или evidence |
| Completed parent | Compact result, ключевые решения, final verification | Step journal и rollout process |

Active parent содержит:

1. `Цель` — один observable outcome.
2. `Результат` — что появится в системе.
3. `Зависимости` — owners, live references и реальные blockers.
4. Optional `Решения` — только phase-local выбор с кратким why и owner link.
5. `Шаги` — ссылки на все step files.
6. `Верификация` — phase-level scenario и binary expected result.
7. `Статус` — lifecycle state и current step.

`Execution topology` допустим только для реального fork/DAG, а не как пересказ
списка шагов. Active parent хранит phase-local факты по таблице ownership;
общие правила — в [Engineering Invariants](../architecture/invariants.md).

## Step и implementation contract

Step содержит:

1. `Цель`.
2. `Current owner и live references` — durable owner/section, один live
   code/test/runtime reference и direct consumers; не inventory всего repo.
3. `Реализационный контракт` — exact target delta и только применимые границы:
   - owner surface/path и responsibility после изменения;
   - public/external input, output, typed errors/outcomes и forbidden exports;
   - persisted transitions, transaction/lock/side-effect order;
   - idempotency, replay, concurrency, stale result и restart/recovery;
   - consumer migration и parallel path/duplicate owner, которые должны исчезнуть;
   - explicit non-goals, отсекающие правдоподобное расширение scope.
4. `Acceptance criteria` — binary scenario/pass-fail для каждой существенной
   ветки контракта, а не пожелание к качеству.
5. Optional реальные `Зависимости` и `Не входит в scope`.
6. `Статус`: `planned | in_progress | blocked | completed`.
7. `Верификация / Evidence` — gate, expected result, actual verdict и только
   фактический outcome/deviation.

Step задаёт обязательное наблюдаемое устройство, но не предписывает private
class/function decomposition, если она не является public boundary, lock order
или другим contract fact. Неприменимую границу удаляют, а не заполняют `N/A`.

## Implementation Readiness Gate

Step можно передать implementer-у, только если из него и ссылок однозначно
следуют:

- один current owner, target owner surface и direct consumers;
- exact behavior и public/external contract, если boundary меняется;
- transaction и irreversible side-effect order для mutation;
- persisted state, replay/race/stale/restart outcomes для durable/background flow;
- consumer migration, cleanup создаваемой правкой и explicit non-goals;
- binary acceptance scenarios и минимальный falsifying gate.

Если применимый пункт неизвестен и выбор меняет ownership, schema, API,
security, failure semantics или scope, создаётся time-boxed discovery step с
decision/evidence outcome. Implementer не получает разрешения выбрать вариант
во время написания кода. Phase не попадает в roadmap, пока все implementation
steps не прошли этот gate.

Active steps удаляются при closure, поэтому текст хранит unique target contract, а не tutorial,
journal или повтор owner text.

## Status и evidence

`NOT_RUN`, `PARTIAL`, `BASELINE`, `PASS`, `FAIL` — verification verdicts, не
lifecycle statuses. `planned` использует `NOT_RUN`; `completed` совместим только
с `PASS`. Empty Evidence, `Blocker: N/A`, полный diff, длинный log и список
каждого изменённого файла не добавляются.

Команда, selection, executor и receipt берутся из проектного
[verification protocol](../architecture/infrastructure.md#verification-protocol).
Если обязательный gate выполняет пользователь, ставится `Manual gate:
MANUAL_BY_USER`; эта пометка не является evidence запуска. Без другого evidence
`Actual verdict` остаётся `NOT_RUN`; после частичных green gates, но до
результата обязательной проверки — `PARTIAL`. `Agent handoff` добавляется
только при реальной bounded delegation; хранит scope и подтверждённый результат,
а не копию owner contract.

## Исполнение и freshness evidence

- До первого semantic change owning step переводится в `in_progress`. Связанные
  правки owner и direct consumers выполняются как один цельный результат;
  порядок запуска gates — по [verification protocol](../architecture/infrastructure.md#verification-protocol).
  Неизвестный consumer, ownership conflict или `FAIL` обязательного prerequisite
  gate блокирует зависимую работу.
- Target delta живёт в step до activation. В owning implementation slice новый
  durable current contract синхронно переносится в architecture owner; после
  этого step оставляет ссылку, scope и evidence, а не вторую копию contract.
- Если prerequisite переезжает между steps, сначала обновляются parent и оба
  steps: один владеет contract, поздний только переиспользует его.
- Receipt действителен только для проверенных inputs. Semantic change контракта,
  owner boundary, direct consumers, side effects или gate inputs инвалидирует
  связанный receipt: completed step возвращается в `in_progress`, verdict —
  `NOT_RUN` либо `PARTIAL`, если независимое evidence сохранилось.
  Formatting-only change не инвалидирует receipt.
- Перед `completed` выполняются review итогового diff и применимые
  consumer/SRP/performance audits; обязательные gates должны иметь evidence
  для итоговых inputs. Уже действительный receipt не требует повторного запуска.
  Findings исправляются у owner; closure-step возвращает defect owning step, а
  не поглощает его общим cleanup.
- Strict docs gate проверяет форму status/evidence, но freshness receipt остаётся
  обязательным manual review gate.

## Writing Rules

- До activation step владеет target delta, а architecture doc — live contract;
  после activation durable факт
  принадлежит architecture owner, step ставит ссылку.
- Architecture owner получает только новый current contract, boundary/path или
  gotcha, без phase narrative.
- Important why — одно короткое объяснение неочевидного решения.
- Не копировать DoD, owner text, test matrix, wiki, chronology, commit log или
  соседний step.
- Optional section без факта удаляется.
- Placeholder полностью заменяется конкретикой.

### Ownership review и docs gate

Общие правила ownership, responsibilities и reuse принадлежат `INV-ARCH-1`,
`INV-SRP-1` и `INV-REUSE-1` в [Engineering Invariants](../architecture/invariants.md).
В phase review проверяются phase-local ownership из таблицы выше и перенос
target delta к durable owner при activation.

Strict docs gate проверяет structural lifecycle/verdict consistency и exact
duplicate long blocks. Semantics prose он не доказывает; owner/consumer review
и freshness evidence проверяются вручную.

## Closure

1. Выполнить phase-level DoD/E2E и зафиксировать final evidence. Обязательные
   aggregate gates выполняет executor из проектного verification protocol;
   запрошенная, но не выполненная проверка не закрывает фазу.
2. Проверить, что owning steps уже синхронизировали изменившиеся durable
   contracts. Новый conflict возвращает соответствующий step в `in_progress`,
   а не исправляется впервые в closure.
3. Сжать parent: удалить estimate, topology, step journal, prerequisites и
   target-contract copies; verification plan заменить final result.
4. Удалить active step directory, переместить parent в `completed/`, обновить
   roadmap и [completed index](./COMPLETED_PHASES.md).
5. Проверить links, status и strict docs gate.

Completed parent содержит только:

- `Цель`;
- достигнутый `Результат`;
- до 3–5 ключевых решений с why и owner links;
- final `Верификация`;
- `Статус: ✅ Завершена`;
- optional PR/merge/release pointer, если он сокращает археологию.

Затраченное время, process artifacts и повтор durable contracts в completed
parent не сохраняются; unique result и final evidence сохраняются по `INV-SRP-1`.
