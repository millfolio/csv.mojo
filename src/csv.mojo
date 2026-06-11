"""csv — a from-scratch RFC-4180 CSV parser in Mojo.

A single UTF-8-safe state machine over codepoints. Handles `"`-quoted fields,
embedded commas, embedded newlines inside quotes, and `""` escaped quotes.
Unquoted fields are trimmed; quoted fields are kept verbatim (so `"1,234.56"`
and `"AMAZON.COM, INC."` survive intact). Fully empty rows (blank lines) are
dropped. Returns ALL rows including the header — the caller decides whether to
skip it.

    from csv import parse, read
    var rows = read("statement.csv")     # List[List[String]]
    var rows2 = parse(text)              # parse an in-memory String

Originally part of millrace/dacular's vault readers; extracted so any project
can reuse it.
"""


def _row_all_empty(row: List[String]) -> Bool:
    for i in range(len(row)):
        if row[i].byte_length() > 0:
            return False
    return True


def parse(text: String) raises -> List[List[String]]:
    """Parse CSV `text` into rows of string fields (RFC-4180)."""
    var rows = List[List[String]]()
    if text.byte_length() == 0:
        return rows^

    var row = List[String]()
    var field = String("")
    var field_quoted = False     # was the current field opened with a quote?
    var in_quotes = False
    var pending_quote = False    # saw a `"` inside quotes — escape or close?

    for cp in text.codepoint_slices():
        var ch = String(cp)
        if pending_quote:
            pending_quote = False
            if ch == '"':
                field += '"'      # "" -> literal quote, stay in the quoted field
                continue
            in_quotes = False     # the quote closed the field; fall through to ch
        if in_quotes:
            if ch == '"':
                pending_quote = True
            else:
                field += ch       # includes newlines inside quotes
            continue
        # ── unquoted ──
        if ch == '"':
            in_quotes = True
            field_quoted = True
        elif ch == ",":
            row.append(field if field_quoted else String(field.strip()))
            field = String(""); field_quoted = False
        elif ch == "\n":
            row.append(field if field_quoted else String(field.strip()))
            if not _row_all_empty(row):
                rows.append(row.copy())
            row = List[String](); field = String(""); field_quoted = False
        elif ch == "\r":
            pass                  # skip CR (CRLF handled by the LF case)
        else:
            field += ch

    # flush a trailing field/row with no terminating newline
    if field.byte_length() > 0 or len(row) > 0:
        row.append(field if field_quoted else String(field.strip()))
        if not _row_all_empty(row):
            rows.append(row^)
    return rows^


def read(path: String) raises -> List[List[String]]:
    """Read the file at `path` and `parse` it."""
    var text: String
    with open(path, "r") as f:
        text = f.read()
    return parse(text)
