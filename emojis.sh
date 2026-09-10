#!/usr/bin/env bash

# ------------------------------------------------------------
# Emoji aliases
#
# Add more aliases here as needed.
# The input uses GitHub-style :alias: notation.
# ------------------------------------------------------------

# Each alias resolves to a bundled Twemoji SVG (assets/emoji/) rather
# than a Unicode emoji character, so icons render identically on every
# OS instead of depending on whatever emoji font there is.
emoji_lookup() {
    case "$1" in
        pen) printf '%s' "img:assets/emoji/pen.svg" ;;
        book) printf '%s' "img:assets/emoji/book.svg" ;;
        computer) printf '%s' "img:assets/emoji/computer.svg" ;;

        leaf) printf '%s' "img:assets/emoji/leaf.svg" ;;
        palette) printf '%s' "img:assets/emoji/palette.svg" ;;
        crayons) printf '%s' "img:assets/emoji/crayons.svg" ;;
        notes) printf '%s' "img:assets/emoji/notes.svg" ;;

        christian-cross) printf '%s' "img:assets/emoji/christian-cross.svg" ;;
        union-jack) printf '%s' "img:assets/emoji/union-jack.svg" ;;
        basketball) printf '%s' "img:assets/emoji/basketball.svg" ;;
        handshake) printf '%s' "img:assets/emoji/handshake.svg" ;;

        *) return 1 ;;
    esac
}
