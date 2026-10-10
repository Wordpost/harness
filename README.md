# AI Project Harness Boilerplate

Установочный шаблон repo-local обвязки для ИИ-агентов. Этот README остаётся в boilerplate: он не заменяет README продукта и не является runtime-инструкцией агента. После установки entrypoint — `AGENTS.md` проекта.

## Режим установки

- **Новый проект:** скопировать `AGENTS.md`, `docs/` и `scripts/validate-docs.ps1`; этот README не копировать.
- **Существующий проект:** не перезаписывать `AGENTS.md`, product README и действующие docs. Сначала сопоставить owners, затем merge-ить недостающие rules/routes. Эквивалентный project doc сохраняется как owner; второй boilerplate-owner не создавать.

В обоих режимах переносить только нужные правила из `.gitignore`, не заменяя существующий файл целиком.

`scripts/test-validate-docs.ps1` — regression suite разработки boilerplate;
по умолчанию остаётся здесь. Копировать её можно при самостоятельной разработке
validator в целевом проекте; установка и обычные doc edits её запуска не требуют.

## Integration Flow

1. Собрать live evidence: существующие agent instructions/docs, manifests, CI, entrypoints, code references и `.env.example`. Production `.env` и secrets не читать.
2. Сопоставить существующих owners с Session Router из `AGENTS.md`. Копировать только недостающие surfaces; ссылки и имена адаптировать под проект.
3. Заполнить `[INSERT_*]` по live evidence. Неприменимые строки/sections удалить либо явно пометить `none / not applicable`; факты не додумывать.
4. Подтвердить module owners, shared/public boundaries, protected zones, commands, exact test selection, executor и shared test resources по коду/manifests/CI. Заполнить Verification Protocol; названия моделей, test runners и ограничения другого проекта не переносить.
   Для `INV-ERR-1` сопоставить существующий framework error entrypoint, wrappers и background/callback boundaries; заполнить [Error Handling Boundaries](./docs/architecture/module-map.md#error-handling-boundaries) ссылками на project owner и live code. Зафиксировать сохранение native cause/codes, public serialization, безопасную диагностику/корреляцию и expected vs critical classification. Alert channel указывать только если он нужен проекту; `none / not applicable` требует причины. Если механизма нет, явно описать отсутствие и требуемую boundary; установка harness не означает его реализацию.
   Выбрать существующий адресный failure test либо manual flow и заполнить error verification hook/executor в Infrastructure. Проверяемый сценарий должен обнаруживать применимые потери cause/code, утечки, пропущенный terminal failure или шум от expected/retry/stale ошибок. Status `auto` допустим только с работающим hook; проектные skills, если используются, направить к этому owner без копии контракта.
5. Инициализировать phase surface: `active/`, `completed/`, готовые phase contracts и отдельный queued roadmap либо честные markers отсутствия работы. Сверить source roots/extensions для temporary-doc consumer scan в validator с реальным layout; включать только поддерживаемые source directories.
   Scope и исключения настраиваются по [руководству validator](./docs/validate-docs.md).
6. Получить список placeholders и structural drift:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-docs.ps1
   ```

7. Провести cold-start smoke в новой сессии:
   - ясная локальная правка → известный owner + live reference + targeted `INV-*` → изменение → выбранный gate; без общего чтения wiki и создания phase;
   - verification → Definition of Done + project commands;
   - phase task → roadmap → `active/` parent → step.
   - feature с catch/integration/callback → project error owner + `INV-ERR-1` + применимая failure-path проверка, без обязательного вызова skill.
8. Запустить финальную проверку:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-docs.ps1 -Strict
   ```

## Готовность установки

- `[INSERT_*]` заполнены;
- entrypoint ведёт к актуальным owners, а не к boilerplate-прозе;
- stack/commands совпадают с manifests и CI;
- module owners, consumers и protected boundaries подтверждены live references;
- нет parallel owners и копий одного contract;
- project-specific invariant hooks имеют честный status;
- error policy/terminal owners и failure verification reference определены по live evidence; `INV-ERR-1` доступен через Session Router и Definition of Done;
- phase surface и cold-start smoke проверены;
- strict validation завершается с exit code `0`; исключений для `[FAIL]` нет.

## Проверка исходного шаблона

В неустановленном boilerplate `[INSERT_*]` намеренно не заполнены: обычный
validator завершает structural gate с exit code `0` и перечисляет warnings.
`-Strict` требует заполнения project facts и используется после установки.
Не заменять placeholders выдуманными значениями ради зелёной проверки.

Ссылки `phase-N/step-*` и `../phase-N-name.md` распознаются только как exact
examples внутри двух phase templates. Такие же пути вне templates — ошибки.
Поддерживаемый Markdown syntax и границы автоматической проверки принадлежат
[руководству validator](./docs/validate-docs.md).

При изменении реализации validator выполнить
[regression suite](./scripts/test-validate-docs.ps1): реальные child-process
fixtures, включая заполненную установку с `-Strict`, positive и forced-negative
cases. Фикстуры не меняют рабочие docs; structural errors нельзя игнорировать.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-validate-docs.ps1
```

Для Windows PowerShell 5.1 сохранять `scripts/validate-docs.ps1` в UTF-8 с BOM;
чтение Markdown в validator явно использует UTF-8 и не зависит от системной ANSI
code page.

## Когда запускать validator

Запускай его при установке boilerplate и после изменений `AGENTS.md`/`docs/`. Для обычной продуктовой правки без изменения документационной структуры он не является обязательным gate.

Это read-only проверка structural hygiene документации harness. Назначение,
покрытие, режимы и настройка исключений — в [руководстве validator](./docs/validate-docs.md).

## Состав

```text
.gitignore  # merge rules only
AGENTS.md
docs/
  validate-docs.md
  architecture/
    infrastructure.md
    module-map.md
    invariants.md
    guidelines.md
    gotchas.md
  phases/
    README.md
    PHASE_AUTHORING_GUIDE.md
    COMPLETED_PHASES.md
    active/
    completed/
    templates/
      phase-template.md
      step-template.md
scripts/
  validate-docs.ps1
  test-validate-docs.ps1  # boilerplate development only; optional copy
```

После установки runtime-маршрут начинается в `AGENTS.md`. Этот README не владеет engineering, phase или coordination rules.
