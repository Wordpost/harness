# Docs Validator: руководство разработчика

Руководство для [validate-docs.ps1](../scripts/validate-docs.ps1) — скрипта проверки
документации харнеса: ссылок, незаполненных полей, структуры фаз и их статусов.
Он не меняет файлы и не запускает приложение или его тесты.

## Запуск и результат

Из корня проекта, Windows PowerShell 5.1:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-docs.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-docs.ps1 -Strict
```

- Обычный режим: незаполненные `[INSERT_*]` — предупреждения; остальные структурные
  нарушения — ошибки. Подходит для исходного шаблона и поиска незаполненных полей при установке.
- `-Strict`: placeholders тоже являются errors. Проектный docs gate использует этот режим.
- Есть errors — exit code `1`; нет errors — `0`, в том числе при warnings.
- `.ps1` сохраняется в UTF-8 с BOM; Markdown читается как UTF-8 независимо от ANSI code page.

## Проверяемое покрытие

- Наличие обязательных `AGENTS.md` и `docs/architecture/invariants.md`,
  уникальность invariant IDs и placeholders.
- Canonical phase paths, lifecycle statuses и согласованность verification verdicts.
  Пути `phase-N/step-*` и `../phase-N-name.md` допустимы как exact examples только
  внутри двух phase templates.
- Local links: inline destinations со скобками, angle brackets и titles;
  full/collapsed/shortcut references с однострочными definitions. Fenced code
  и inline code examples исключены из разбора links.
- Локальные `.md` fragments: ATX/Setext headings с text/code/emphasis, Unicode
  и повторными headings, а также explicit HTML `id`/`name`.
- Запрет ссылок из architecture owners на phase artifacts и lifecycle indexes;
  ссылки на стабильные phase guide/templates допустимы.
- Запрет ссылок из поддерживаемого source на temporary docs; сам validator
  не участвует в этом consumer scan.
- Exact duplicate длинных Markdown-блоков после нормализации пробелов:
  сравнение учитывает регистр; короткие общие labels не проверяются.

Внешние URL не запрашиваются. Другой Markdown/HTML/MDX syntax и
renderer-specific anchors требуют адресной ручной проверки.

## Scope и исключения

Markdown scan охватывает `.md` в корне проекта и `docs/`. Source consumer scan
использует roots/extensions, заданные в script; при установке адаптируй их
к поддерживаемым source directories проекта. `.gitignore` не применяется.

Для исключений редактируй `$excludedPaths` в начале
[script](../scripts/validate-docs.ps1). Один список применяется к Markdown
и source scans; отдельного config file или CLI flag нет.

- Путь относительно корня проекта, разделитель `/`.
- `docs/example.md` исключает один файл.
- `docs/custom/` исключает каталог и всё его содержимое; завершающий `/` обязателен
  для папки. Аналогично `src/generated/` внутри проверяемого каталога исходников.
- Wildcards не поддерживаются; запись не добавляет новый scan root.
- Defaults: `docs/work/`, `docs/audits/audit.md`, `docs/plans/plan.md`,
  `scripts/test-validate-docs.ps1`. Закомментированные editable examples находятся в script.

Исключённые каталоги не обходятся, содержимое исключённых файлов и их якоря
не читаются. Ссылка из проверяемого документа в исключённую папку всё равно должна
указывать на существующий файл; якорь в этом файле не проверяется.
Наличие обязательных `AGENTS.md` и `docs/architecture/invariants.md` проверяется
даже при исключении их content scan.

## Границы доказательства

Ownership/SRP/reuse, смысл prose, содержательная граница AGENTS и freshness
evidence проверяются вручную по [invariants](./architecture/invariants.md)
и [runtime router](../AGENTS.md). Green structural gate не доказывает архитектуру
или поведение приложения. Проверок и сигналов количества строк/слов нет.
