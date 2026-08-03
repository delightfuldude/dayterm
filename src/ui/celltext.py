try:
    from wcwidth import wcwidth
except ImportError:
    from unicodedata import category, east_asian_width

    def wcwidth(character):
        if category(character).startswith(("C", "M")):
            return 0
        return 2 if east_asian_width(character) in ("F", "W") else 1


def decode_ansi(value):
    return value.encode("utf-8").decode("unicode_escape") if value else ""


def iter_parts(value):
    i = 0
    while i < len(value):
        if value[i] == "\x1b" and i + 1 < len(value) and value[i + 1] == "[":
            j = i + 2
            while j < len(value) and not ("@" <= value[j] <= "~"):
                j += 1
            if j < len(value):
                yield ("ansi", value[i:j + 1])
                i = j + 1
                continue
        yield ("char", value[i])
        i += 1


def text_width(value):
    total = 0
    for part_type, part in iter_parts(value):
        if part_type == "ansi":
            continue
        width = wcwidth(part)
        if width > 0:
            total += width
    return total


def fit(value, max_width, reset="\x1b[0m"):
    if max_width <= 0:
        return ""
    if text_width(value) <= max_width:
        return value
    if max_width <= 3:
        suffix = ""
        content_width = max_width
    else:
        suffix = "..."
        content_width = max_width - text_width(suffix)

    out = []
    used = 0
    saw_ansi = False
    truncated = False
    for part_type, part in iter_parts(value):
        if part_type == "ansi":
            saw_ansi = True
            out.append(part)
            continue
        width = wcwidth(part)
        if width < 0:
            width = 0
        if used + width > content_width:
            truncated = True
            break
        out.append(part)
        used += width

    result = "".join(out) + suffix
    if truncated and saw_ansi and reset:
        result += reset
    return result


def rpad(value, width, reset="\x1b[0m"):
    value = fit(value, width, reset)
    return value + (" " * max(0, width - text_width(value)))


def color(color_code, value, reset):
    return f"{color_code}{value}{reset}" if color_code else value
