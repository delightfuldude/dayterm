import json
from pathlib import Path

from ui.celltext import color, decode_ansi, fit, rpad, text_width


def box_chars(style):
    if style == "ascii":
        return "+", "+", "+", "+", "-", "|"
    return "┌", "┐", "└", "┘", "─", "│"


def read_json(path):
    try:
        return json.loads(Path(path).read_text())
    except (OSError, json.JSONDecodeError):
        return []


def make_colorizer(names, values):
    palette = {name: decode_ansi(value) for name, value in zip(names, values)}

    def colorize(name, value):
        return color(palette[name], str(value), palette["reset"])

    return palette, colorize


def build_box(title, lines, cols, style, palette):
    if cols < 24:
        return [title, *[fit(line, cols, palette["reset"]) for line in lines]]

    tl, tr, bl, br, horizontal, vertical = box_chars(style)
    label = fit(f" {title} ", max(0, cols - 4), palette["reset"])
    top_fill = max(0, cols - 2 - text_width(label))
    inner = max(0, cols - 4)
    rendered = [
        f"{color(palette['border'], tl, palette['reset'])}"
        f"{color(palette['title'], label, palette['reset'])}"
        f"{color(palette['border'], horizontal * top_fill + tr, palette['reset'])}"
    ]

    for line in lines or [""]:
        rendered.append(
            f"{color(palette['border'], vertical, palette['reset'])} "
            f"{rpad(line, inner, palette['reset'])} "
            f"{color(palette['border'], vertical, palette['reset'])}"
        )

    bottom = bl + horizontal * max(0, cols - 2) + br
    rendered.append(color(palette["border"], bottom, palette["reset"]))
    return rendered


def build_plain(title, lines, cols, _style, palette):
    heading = color(palette["title"], title, palette["reset"])
    rule = color(palette["border"], "-" * cols, palette["reset"])
    return [heading, rule, *[fit(line, cols, palette["reset"]) for line in lines]]


def column_widths(total_width, count):
    content_width = max(count, total_width - (count - 1) * 3)
    base, remainder = divmod(content_width, count)
    return [base + (1 if index < remainder else 0) for index in range(count)]


def grid_line(cells, widths, separator, c):
    divider = f" {c('border', separator)} "
    return divider.join(rpad(cell, width) for cell, width in zip(cells, widths))


def grid_rule(widths, style, c):
    horizontal = "-" if style == "ascii" else "─"
    junction = "+" if style == "ascii" else "┼"
    return c("border", (horizontal + junction + horizontal).join(horizontal * width for width in widths))
