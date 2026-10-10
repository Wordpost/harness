# Step XX — Name

> Заполнить по Phase Authoring Guide; удалить эту строку и ненужные optional blocks.

[⬅️ Назад к Phase N](../phase-N-name.md)

## Цель

`[Один проверяемый outcome]`

## Current owner и live references

- Owner: `[durable owner + exact section]`
- Live reference: `[один code/test/runtime path]`
- Direct consumers: `[точные surfaces/call sites]`

## Реализационный контракт

- Owned delta: `[что меняется и где живёт responsibility]`
- Public/external contract (если применимо): `[input → output/typed outcomes; forbidden exports]`
- State и ordering (если применимо): `[persistence, transaction, locks, side effects]`
- Replay/concurrency/recovery (если применимо): `[idempotency, race, stale, restart]`
- Consumer migration: `[кого перевести; какой duplicate/parallel path удалить]`
- Explicit non-goals: `[правдоподобные, но запрещённые расширения]`

## Acceptance criteria

- `[Given/when → exact observable result]`
- `[Failure/replay/race scenario → exact persisted/public result]` (если применимо)

## Не входит в scope (optional)

- `[...]`

## Зависимости

- `[Step / decision | Нет]`

## Статус

`planned | in_progress | blocked | completed`

## Верификация / Evidence

- `[INV-*]`
- `[Применимый owner/consumer/SRP/performance audit → expected result]`
- `[Targeted runner после последнего semantic change → expected result]`
- `Manual gate: MANUAL_BY_USER` (optional; если gate выполняет пользователь)
- Actual verdict: `NOT_RUN | PASS | FAIL | PARTIAL | BASELINE`
- `[Actual outcome / deviation — добавляется после запуска]`
