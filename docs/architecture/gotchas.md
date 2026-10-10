[⬅️ К runtime router](../../AGENTS.md)

# Gotchas & Known Risks

Подтверждённые ловушки, edge cases и operational risks. Это не backlog и не changelog.

## Entry Format

```markdown
## GOTCHA-N — Краткое имя

- Symptom:
- Root cause:
- Safe fix / rule:
- Open when:
- Evidence: code/test/incident/owner link
- Status: active | mitigated | obsolete
- Updated: YYYY-MM-DD
```

## Rules

- Записывать только воспроизводимый или доказанный риск.
- Не копировать architecture contract: ставить ссылку на owner.
- Если риск стал общим обязательным правилом, добавить/обновить `INV-*`, а здесь оставить symptom и context.
- Obsolete entry помечать, не использовать как current guidance.

## Entries

*(Добавляйте entries по мере появления подтверждённых gotchas.)*
