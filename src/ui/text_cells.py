import sys

from celltext import fit, rpad, text_width


def main():
    mode = sys.argv[1]
    width = int(sys.argv[2])
    text = sys.stdin.read()

    if mode == "width":
        sys.stdout.write(str(text_width(text)))
    elif mode == "rpad":
        sys.stdout.write(rpad(text, width))
    else:
        sys.stdout.write(fit(text, width))


if __name__ == "__main__":
    main()
