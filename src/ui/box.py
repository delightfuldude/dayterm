import sys

from celltext import color, decode_ansi, fit, rpad, text_width


def box_chars(style):
    if style == "ascii":
        return "+", "+", "+", "+", "-", "|"
    return "┌", "┐", "└", "┘", "─", "│"


def main():
    title = sys.argv[1]
    width = int(sys.argv[2])
    style = sys.argv[3]
    border_color = decode_ansi(sys.argv[4])
    title_color = decode_ansi(sys.argv[5])
    reset = decode_ansi(sys.argv[6])
    lines = sys.argv[7:] or [""]

    tl, tr, bl, br, h, v = box_chars(style)
    label = fit(f" {title} ", max(0, width - 4), reset)
    top_fill = max(0, width - 2 - text_width(label))
    inner_width = max(0, width - 4)

    print(
        f"{color(border_color, tl, reset)}"
        f"{color(title_color, label, reset)}"
        f"{color(border_color, h * top_fill + tr, reset)}"
    )

    for line in lines:
        print(
            f"{color(border_color, v, reset)} "
            f"{rpad(line, inner_width, reset)} "
            f"{color(border_color, v, reset)}"
        )

    print(color(border_color, bl + (h * max(0, width - 2)) + br, reset))


if __name__ == "__main__":
    main()
