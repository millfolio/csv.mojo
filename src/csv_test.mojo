"""Conformance test for the csv parser — the RFC-4180 cases the naive
split-on-comma approach gets wrong. Run via `pixi run test`."""

from csv import parse


def _check(cond: Bool, msg: String) raises:
    if not cond:
        raise Error("FAIL: " + msg)
    print("  [OK]", msg)


def main() raises:
    # Quoted fields with embedded commas + escaped quotes + CRLF.
    var text = String(
        'Date,Description,Amount\r\n'
        '2025-03-01,"AMAZON.COM, INC. PURCHASE","1,234.56"\r\n'
        '2025-03-02,"Refund ""partial""","-12.00"\r\n'
        '\r\n'                                   # blank line -> dropped
        '2025-03-03,Simple Cafe,8.50\r\n'
    )
    var rows = parse(text)

    _check(len(rows) == 4, "row count == 4 (header + 3, blank dropped)")
    _check(len(rows[0]) == 3, "header has 3 fields")
    _check(rows[1][1] == "AMAZON.COM, INC. PURCHASE", "embedded comma preserved")
    _check(rows[1][2] == "1,234.56", "quoted number with comma preserved")
    _check(rows[2][1] == 'Refund "partial"', "escaped quotes unescaped")
    _check(rows[3][0] == "2025-03-03", "unquoted field trimmed")

    # Embedded newline inside a quoted field stays one field.
    var multi = parse(String('a,"line1\nline2",c\n'))
    _check(len(multi) == 1, "embedded newline keeps one row")
    _check(len(multi[0]) == 3, "embedded-newline row has 3 fields")
    _check(multi[0][1] == "line1\nline2", "newline preserved inside quotes")

    # No trailing newline still flushes the last row.
    var notrail = parse(String("x,y\n1,2"))
    _check(len(notrail) == 2, "row without trailing newline is flushed")

    print("PASS — RFC-4180 cases")
