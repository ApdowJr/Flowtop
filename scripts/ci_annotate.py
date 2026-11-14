#!/usr/bin/env python3
"""Turn (part of) a log file into one GitHub Actions annotation.

Annotations are the only part of a CI run that can be read without opening the
Actions UI (for example through the checks API), so the workflow uses this to
keep the interesting lines of long Flutter output visible.

Usage:
  ci_annotate.py LOG --level error --title "flutter analyze" --grep ' • '
  ci_annotate.py LOG --level warning --grep '\\[E\\]' --after 12
"""
import argparse
import re
from pathlib import Path


def select_lines(lines, pattern, after):
    """Keep lines matching `pattern` plus `after` lines of context."""
    keep = set()
    for index, line in enumerate(lines):
        if pattern.search(line):
            keep.update(range(index, min(index + after + 1, len(lines))))
    selected = []
    previous = None
    for index in sorted(keep):
        if previous is not None and index != previous + 1:
            selected.append('---')
        selected.append(lines[index])
        previous = index
    return selected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('file')
    parser.add_argument('--level', default='error',
                        choices=['error', 'warning', 'notice'])
    parser.add_argument('--title', default='')
    parser.add_argument('--tail', type=int, default=12000,
                        help='maximum number of characters kept from the end')
    parser.add_argument('--grep', default=None,
                        help='keep only lines matching this regular expression')
    parser.add_argument('--after', type=int, default=0,
                        help='extra lines kept after every --grep match')
    args = parser.parse_args()

    lines = Path(args.file).read_text(errors='replace').splitlines()
    if args.grep:
        lines = select_lines(lines, re.compile(args.grep), args.after)
    text = '\n'.join(lines)[-args.tail:]
    if not text.strip():
        return

    text = text.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
    title = args.title.replace(',', ' ').replace(':', ' ')
    properties = f' title={title}' if title else ''
    print(f'::{args.level}{properties}::{text}')


if __name__ == '__main__':
    main()
