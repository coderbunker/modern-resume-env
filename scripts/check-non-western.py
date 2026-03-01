#!/usr/bin/env python3
import sys
import os
import unicodedata

def is_western(char):
    code = ord(char)
    cat = unicodedata.category(char)

    # 1. Allow all basic Western ranges (covers basic letters, control chars, punctuation)
    if code <= 0x02AF: # Latin and IPA
        return True

    # 2. Allow all Symbols (S), Punctuation (P), Numbers (N), and Separators (Z)
    # This specifically allows Emojis, math symbols, tech symbols, etc. regardless of range.
    if cat[0] in ('S', 'P', 'N', 'Z'):
        return True

    # 3. Specifically allowed supplementary technical/punctuation blocks (for extra safety)
    if 0x2000 <= code <= 0x206F: # General Punctuation
        return True
    if 0x20A0 <= code <= 0x20CF: # Currency Symbols
        return True
    if 0x2100 <= code <= 0x214F: # Letterlike Symbols
        return True
    if 0x2300 <= code <= 0x23FF: # Miscellaneous Technical
        return True
    if 0xFE00 <= code <= 0xFE0F: # Variation Selectors
        return True

    return False

def check_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                for char_num, char in enumerate(line, 1):
                    if not is_western(char):
                        print(f"ERROR: Non-Western character '{char}' (U+{ord(char):04X}) found in {filepath}:{line_num}:{char_num}")
                        return False
    except UnicodeDecodeError:
        # Skip binary files if they are not utf-8
        return True
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return False
    return True

def main():
    files = sys.argv[1:]
    if not files:
        print("Usage: check-non-western.py <file1> <file2> ...")
        sys.exit(0)

    failed = False
    for filepath in files:
        if os.path.isdir(filepath):
            continue
        if not check_file(filepath):
            failed = True

    if failed:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()
