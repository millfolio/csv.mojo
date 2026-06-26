# csv.mojo

> 💬 **Community:** questions, ideas, and show-and-tell live in [GitHub Discussions](https://github.com/millfolio/millfolio/discussions).

> Part of [**millfolio**](https://millfolio.app) — local-first AI on Apple Silicon.

A small, from-scratch **RFC-4180 CSV parser** in Mojo. One UTF-8-safe state
machine over codepoints — no dependencies.

Handles the cases a naive split-on-comma gets wrong:
- `"`-quoted fields with **embedded commas** (`"AMAZON.COM, INC."`)
- quoted numbers with separators (`"1,234.56"`)
- **embedded newlines** inside quoted fields
- **escaped quotes** (`""` → `"`)
- CRLF or LF line endings; blank lines dropped

Unquoted fields are trimmed; quoted fields are kept verbatim. Returns all rows
including the header.

## Use

```mojo
from csv import parse, read

def main() raises:
    var rows = read("statement.csv")     # List[List[String]]
    var rows2 = parse(text)              # parse an in-memory String
    for r in rows:
        ...
```

Consume it like the other millfolio Mojo libs — `-I ../csv.mojo/src` (no FFI, no
link flags).

## API

| function | signature | notes |
|---|---|---|
| `parse` | `parse(text: String) -> List[List[String]]` | parse in-memory CSV text |
| `read` | `read(path: String) -> List[List[String]]` | read a file, then `parse` |

## Test

```sh
pixi run test   # RFC-4180 conformance cases
```

Extracted from [dacular](https://github.com/millfolio/dacular)'s vault readers so
any project can reuse it.
