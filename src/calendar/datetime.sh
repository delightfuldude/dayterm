#!/usr/bin/env bash

DAYTERM_DATE_ORDER=''
DAYTERM_KHAL_DATE_FORMAT=''

test_khal() {
    command -v khal >/dev/null 2>&1 && khal printcalendars >/dev/null 2>&1
}

test_jq() {
    command -v jq >/dev/null 2>&1
}

get_calendars() {
    khal printcalendars 2>/dev/null | sed '/^[[:space:]]*$/d;s/[[:space:]]*$//'
}

calendar_detect_date_order() {
    local sample digits a b c pattern

    if [[ -n "$DAYTERM_DATE_ORDER" && -n "$DAYTERM_KHAL_DATE_FORMAT" ]]; then
        return 0
    fi
    if [[ -n "$DAYTERM_DATE_ORDER" ]]; then
        case "$DAYTERM_DATE_ORDER" in
            ymd) DAYTERM_KHAL_DATE_FORMAT='%Y-%m-%d' ;;
            mdy) DAYTERM_KHAL_DATE_FORMAT='%m/%d/%Y' ;;
            dmy|*) DAYTERM_KHAL_DATE_FORMAT='%d/%m/%Y' ;;
        esac
        return 0
    fi
    sample=$(khal printformats 2>/dev/null | awk -F': ' '/^dateformat:/ {print $2; exit}')
    digits=${sample//[!0-9]/ }
    read -r a b c <<< "$digits"

    if [[ "$a" == "2013" || "$a" == "13" ]]; then
        DAYTERM_DATE_ORDER="ymd"
    elif [[ "$a" == "21" ]]; then
        DAYTERM_DATE_ORDER="dmy"
    elif [[ "$b" == "21" ]]; then
        DAYTERM_DATE_ORDER="mdy"
    else
        DAYTERM_DATE_ORDER="dmy"
    fi

    if [[ "$sample" == *2013* ]]; then
        pattern=${sample//2013/%Y}
    else
        pattern=${sample//13/%y}
    fi
    pattern=${pattern//21/%d}
    pattern=${pattern//12/%m}
    if [[ "$pattern" == *%Y* && "$pattern" == *%m* && "$pattern" == *%d* ]]; then
        DAYTERM_KHAL_DATE_FORMAT="$pattern"
    else
        DAYTERM_KHAL_DATE_FORMAT='%d/%m/%Y'
    fi
}

calendar_format_query_date() {
    local value="$1"

    if [[ "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        calendar_detect_date_order
        date -d "$value" +"$DAYTERM_KHAL_DATE_FORMAT"
    else
        printf '%s\n' "$value"
    fi
}
