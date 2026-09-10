#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# lesson-plan-to-markdown.sh
#
# Usage:
#   ./lesson-plan-to-markdown.sh plan.txt
#
# Output:
#   plan.md
#
# The generated Markdown contains an HTML table and CSS
# suitable for rendering/printing as A4 landscape.
# ============================================================

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <lesson-plan.txt>"
    exit 1
fi

INPUT="$1"

if [[ ! -f "$INPUT" ]]; then
    echo "Error: file not found: $INPUT"
    exit 1
fi

# Derive output filename from input basename (strip any path, remove final extension)
NAME="$(basename "$INPUT")"
NAME="${NAME%.*}"
OUTPUT="./outputs/${NAME}.md"

# Ensure output directory exists
mkdir -p "./outputs"

# Ask user which season background to use
# Options: 1=Spring, 2=Summer, 3=Autumn, 4=Winter
SEASON=""
while true; do
    echo "Choose background season:"
    echo "  [1] Spring"
    echo "  [2] Summer"
    echo "  [3] Autumn"
    echo "  [4] Winter"
    read -rp "Selection [1-4]: " SELECTION
    case "${SELECTION}" in
        1) SEASON="spring"; break ;;
        2) SEASON="summer"; break ;;
        3) SEASON="autumn"; break ;;
        4) SEASON="winter"; break ;;
        *) echo "Please enter 1, 2, 3 or 4." ;;
    esac
done

BACKGROUND_SRC="./assets/backgrounds/${SEASON}.bg.png"
if [[ ! -f "${BACKGROUND_SRC}" ]]; then
    echo "Warning: background asset not found: ${BACKGROUND_SRC}"
    # Fallback to the original default image name so behavior remains working
    BACKGROUND_SRC="background.png"
fi

# ------------------------------------------------------------
# Emoji aliases
#
# Add more aliases here as needed.
# The input uses GitHub-style :alias: notation.
# ------------------------------------------------------------

source ./emojis.sh

# ------------------------------------------------------------
# Weekday names
# ------------------------------------------------------------

WEEKDAY_SHORTS=(Pon Wt Śr Sr Czw Pt Sob Nd)

weekday_name() {
    case "$1" in
        Pon) printf '%s' "Poniedziałek" ;;
        Wt) printf '%s' "Wtorek" ;;
        Śr) printf '%s' "Środa" ;;
        Sr) printf '%s' "Środa" ;;
        Czw) printf '%s' "Czwartek" ;;
        Pt) printf '%s' "Piątek" ;;
        Sob) printf '%s' "Sobota" ;;
        Nd) printf '%s' "Niedziela" ;;
    esac
}

# ------------------------------------------------------------
# Read input
# ------------------------------------------------------------

LINES=()
while IFS= read -r RAW_LINE || [[ -n "$RAW_LINE" ]]; do
    LINES+=("$RAW_LINE")
done < "$INPUT"

if [[ ${#LINES[@]} -eq 0 ]]; then
    echo "Error: input file is empty."
    exit 1
fi

TITLE="${LINES[0]}"

# Remove possible Windows CR characters.
TITLE="${TITLE//$'\r'/}"

# ------------------------------------------------------------
# Data structures
#
# LESSON_NAMES / LESSON_EMOJIS are parallel arrays keyed by
# position; LESSON_KEYS holds the matching "number|weekday"
# combined key for each position, since bash 3.2 has no
# associative arrays.
# ------------------------------------------------------------

LESSON_KEYS=()
LESSON_NAMES=()
LESSON_EMOJIS=()
TIMES=()

CURRENT_DAY=""
MODE="lessons"

MAX_LESSON=0

# ------------------------------------------------------------
# Helper: find the array index for a lesson key.
# ------------------------------------------------------------

lesson_index() {
    local key="$1"
    local i
    local count="${#LESSON_KEYS[@]}"

    for (( i=0; i<count; i++ )); do
        if [[ "${LESSON_KEYS[$i]}" == "$key" ]]; then
            printf '%s' "$i"
            return 0
        fi
    done

    return 1
}

# ------------------------------------------------------------
# Helper: convert emoji alias to Unicode
# ------------------------------------------------------------

emoji_to_unicode() {
    local value="$1"

    # Already Unicode / ordinary text?
    if [[ "$value" != :*: ]]; then
        printf '%s' "$value"
        return
    fi

    local alias="${value#:}"
    alias="${alias%:}"

    local resolved
    if resolved="$(emoji_lookup "$alias")"; then
        printf '%s' "$resolved"
    else
        # Unknown alias: leave it untouched.
        printf '%s' "$value"
    fi
}

# ------------------------------------------------------------
# Parse file
# ------------------------------------------------------------

for RAW_LINE in "${LINES[@]}"; do

    # Remove CR from Windows line endings.
    LINE="${RAW_LINE//$'\r'/}"

    # Ignore completely empty lines.
    [[ -z "${LINE//[[:space:]]/}" ]] && continue

    # *** switches to the timetable section.
    if [[ "$LINE" == "***" ]]; then
        MODE="times"
        CURRENT_DAY=""
        continue
    fi

    if [[ "$MODE" == "times" ]]; then

        # Example:
        # 1. 08:10 - 08:55

        if [[ "$LINE" =~ ^([0-9]+)\.[[:space:]]*(.+)$ ]]; then
            NUMBER="${BASH_REMATCH[1]}"
            TIME="${BASH_REMATCH[2]}"

            TIMES[$NUMBER]="$TIME"

            if (( NUMBER > MAX_LESSON )); then
                MAX_LESSON="$NUMBER"
            fi
        fi

        continue
    fi

    # Ignore separator.
    [[ "$LINE" == "---" ]] && continue

    # Detect weekday.
    #
    # Allows optional whitespace after it:
    # Pon.
    # Pon
    # Wt.
    # etc.

    DAY_FOUND=""

    for SHORT in "${WEEKDAY_SHORTS[@]}"; do
        if [[ "$LINE" =~ ^${SHORT//./\\.}\.?[[:space:]]*$ ]]; then
            DAY_FOUND="$SHORT"
            break
        fi
    done

    if [[ -n "$DAY_FOUND" ]]; then
        CURRENT_DAY="$DAY_FOUND"
        continue
    fi

    # Lesson:
    #
    # 1. J. polski, :pen:
    # 2. Matematyka, :heart:
    #
    if [[ "$LINE" =~ ^([0-9]+)\.[[:space:]]*(.*)$ ]]; then

        if [[ -z "$CURRENT_DAY" ]]; then
            echo "Warning: lesson found before a weekday: $LINE"
            continue
        fi

        NUMBER="${BASH_REMATCH[1]}"
        CONTENT="${BASH_REMATCH[2]}"

        EMOJI_VALUE=""

        # Look for final :emoji_alias:
        if [[ "$CONTENT" =~ ^(.*),[[:space:]]*(:[^:]+:)[[:space:]]*$ ]]; then
            NAME="${BASH_REMATCH[1]}"
            EMOJI_VALUE="${BASH_REMATCH[2]}"
        else
            NAME="$CONTENT"
        fi

        NAME="${NAME%"${NAME##*[![:space:]]}"}"
        NAME="${NAME#"${NAME%%[![:space:]]*}"}"

        KEY="${NUMBER}|${CURRENT_DAY}"

        IDX="$(lesson_index "$KEY")" || IDX=""
        if [[ -z "$IDX" ]]; then
            IDX="${#LESSON_KEYS[@]}"
            LESSON_KEYS+=("$KEY")
        fi

        LESSON_NAMES[$IDX]="$NAME"
        LESSON_EMOJIS[$IDX]="$(emoji_to_unicode "$EMOJI_VALUE")"

        if (( NUMBER > MAX_LESSON )); then
            MAX_LESSON="$NUMBER"
        fi
    fi

done

# ------------------------------------------------------------
# Build ordered list of weekdays.
#
# We preserve the order in which weekdays appeared in the file.
# ------------------------------------------------------------

DAYS=()

for RAW_LINE in "${LINES[@]}"; do

    LINE="${RAW_LINE//$'\r'/}"

    for SHORT in "${WEEKDAY_SHORTS[@]}"; do
        if [[ "$LINE" =~ ^${SHORT//./\\.}\.?[[:space:]]*$ ]]; then

            # Check if already added.
            ALREADY=0
            DAYS_COUNT="${#DAYS[@]}"

            for (( DI=0; DI<DAYS_COUNT; DI++ )); do
                if [[ "${DAYS[$DI]}" == "$SHORT" ]]; then
                    ALREADY=1
                    break
                fi
            done

            if (( ! ALREADY )); then
                DAYS+=("$SHORT")
            fi
        fi
    done

done

if [[ ${#DAYS[@]} -eq 0 ]]; then
    echo "Error: no weekdays found."
    exit 1
fi

# ------------------------------------------------------------
# Generate Markdown
# ------------------------------------------------------------

{
    cat <<EOF
<div class="lesson-plan"><link rel="stylesheet" href="../styles.css"><img id="page-background" src="../${BACKGROUND_SRC}" alt="">
<h1 class="plan-title">${TITLE}</h1>

<table class="plan-table">
<thead>
<tr>
<th class="lesson-number">#</th>
<th class="lesson-time">Godzina</th>
EOF

    for DAY in "${DAYS[@]}"; do
        printf '<th>%s</th>\n' "$(weekday_name "$DAY")"
    done

    cat <<EOF
</tr>
</thead>
<tbody>
EOF

    # One row per lesson number.
    for (( NUMBER=1; NUMBER<=MAX_LESSON; NUMBER++ )); do

        TIME="${TIMES[$NUMBER]:-}"

        printf '<tr>\n'
        printf '<th class="lesson-number">%s.</th>\n' "$NUMBER"
        printf '<td class="lesson-time">%s</td>\n' "$TIME"

        for DAY in "${DAYS[@]}"; do

            KEY="${NUMBER}|${DAY}"

            NAME=""
            ICON=""

            IDX="$(lesson_index "$KEY")" || IDX=""
            if [[ -n "$IDX" ]]; then
                NAME="${LESSON_NAMES[$IDX]}"
                ICON="${LESSON_EMOJIS[$IDX]}"
            fi

            if [[ -n "$NAME" ]]; then

                if [[ "$ICON" == img:* ]]; then
                    ICON_MARKUP="<img class=\"lesson-emoji-img\" src=\"../${ICON#img:}\" alt=\"\">"
                else
                    ICON_MARKUP="$ICON"
                fi

                cat <<EOF
<td class="lesson"><div class="lesson-content"><span class="lesson-emoji">${ICON}</span><span class="lesson-name">${NAME}</span></div></td>
EOF

            else

                printf '<td class="lesson empty"></td>\n'

            fi

        done

        printf '</tr>\n'

    done

    cat <<'EOF'
</tbody>
</table>

</div>
EOF

} > "$OUTPUT"

echo "Created: $OUTPUT"
