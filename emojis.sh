#!/usr/bin/env bash

# ------------------------------------------------------------
# Emoji aliases
#
# Add more aliases here as needed.
# The input uses GitHub-style :alias: notation.
# ------------------------------------------------------------

emoji_lookup() {
    case "$1" in
        pen) printf '%s' "🖊️" ;;
        book) printf '%s' "📖" ;;
        computer) printf '%s' "💻" ;;

        leaf) printf '%s' "🌱" ;;
        palette) printf '%s' "🎨" ;;
        crayons) printf '%s' "🖍️" ;;
        notes) printf '%s' "🎵" ;;

        christian-cross) printf '%s' "✝️" ;;
        union-jack) printf '%s' "🇬🇧" ;;
        basketball) printf '%s' "🏀" ;;
        handshake) printf '%s' "🤝" ;;

        *) return 1 ;;
    esac
}
