#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
CSV="data.csv"
SQL="data.sql"
[[ -f "$CSV" && -f "$SQL" ]] || { echo "data.csv / data.sql not found"; exit 1; }

is_date()     { [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; }
is_time()     { [[ "$1" =~ ^[0-9]{2}:[0-9]{2}$ ]]; }
is_datetime() { [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]]; }

prompt_dt() {
  local label="$1" allow="$2" v t
  while :; do
    read -rp "$label (YYYY-MM-DD [HH:MM]$([[ "$allow" == 1 ]] && echo ", blank=open")): " v
    if [[ -z "$v" ]]; then
      if [[ "$allow" == 1 ]]; then echo ""; return; fi
      echo "  required — use format YYYY-MM-DD HH:MM" >&2; continue
    fi
    if is_datetime "$v"; then echo "$v"; return; fi
    if is_date "$v"; then
      while :; do
        read -rp "  time for $v (HH:MM): " t
        is_time "$t" && { echo "$v $t"; return; }
        echo "  invalid — use HH:MM" >&2
      done
    fi
    echo "  invalid — use format YYYY-MM-DD or 'YYYY-MM-DD HH:MM'" >&2
  done
}

mapfile -t open_lines < <(awk -F, 'NR>1 && $2=="" {print NR}' "$CSV")

choice=""
if (( ${#open_lines[@]} > 0 )); then
  echo "Open check-ins:"
  for i in "${!open_lines[@]}"; do
    printf "  [%d] %s\n" "$((i+1))" "$(sed -n "${open_lines[$i]}p" "$CSV")"
  done
  echo "  [n] Add a new entry"
  read -rp "Choice: " choice
fi

if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#open_lines[@]} )); then
  # ============ DEPART FLOW ============
  csv_n=${open_lines[$((choice-1))]}
  csv_row=$(sed -n "${csv_n}p" "$CSV")

  arrival=${csv_row%%,*}
  rest=${csv_row#*,}           # drop arrival,
  rest=${rest#,}               # drop empty departure,
  lived=${rest##*,}
  rest=${rest%,*}              # drop ,lived
  country=${rest%%,*}
  city=${rest#*,}
  [[ "$city" == \"*\" ]] && city=${city:1:${#city}-2}

  dep=$(prompt_dt "Departure" 0)

  echo
  echo "Close out:"
  echo "  $arrival → $dep   $country / $city"
  read -rp "Save? [y/N] " ok
  [[ "$ok" =~ ^[Yy]$ ]] || { echo "aborted"; exit 0; }

  if [[ "$city" == *,* ]]; then csv_city="\"$city\""; else csv_city="$city"; fi
  new_csv_row="$arrival,$dep,$country,$csv_city,$lived"
  awk -v n="$csv_n" -v r="$new_csv_row" 'NR==n{print r; next} {print}' \
      "$CSV" > "$CSV.tmp" && mv "$CSV.tmp" "$CSV"

  old_sql="(\"$arrival\", \"\", \"$country\", \"$city\", \"$lived\"),"
  new_sql="(\"$arrival\", \"$dep\", \"$country\", \"$city\", \"$lived\"),"
  sql_n=$(grep -Fxn -- "$old_sql" "$SQL" | head -1 | cut -d: -f1)
  [[ -n "$sql_n" ]] || { echo "couldn't find matching SQL row: $old_sql"; exit 1; }
  awk -v n="$sql_n" -v r="$new_sql" 'NR==n{print r; next} {print}' \
      "$SQL" > "$SQL.tmp" && mv "$SQL.tmp" "$SQL"

  echo "updated $CSV line $csv_n and $SQL line $sql_n"

else
  # ============ NEW ENTRY FLOW ============
  read -rp "Country: " country
  read -rp "City:    " city
  arrival=$(prompt_dt   "Arrival  " 0)
  departure=$(prompt_dt "Departure" 1)
  read -rp "Lived [0/1, default 0]: " lived
  lived=${lived:-0}
  [[ "$lived" == 0 || "$lived" == 1 ]] || { echo "lived must be 0 or 1"; exit 1; }
  [[ -n "$country" && -n "$city" ]] || { echo "country and city required"; exit 1; }

  if [[ "$city" == *,* ]]; then csv_city="\"$city\""; else csv_city="$city"; fi
  csv_row="$arrival,$departure,$country,$csv_city,$lived"
  sql_row="(\"$arrival\", \"$departure\", \"$country\", \"$city\", \"$lived\"),"

  echo
  echo "CSV:  $csv_row"
  echo "SQL:  $sql_row"
  read -rp "Save? [y/N] " ok
  [[ "$ok" =~ ^[Yy]$ ]] || { echo "aborted"; exit 0; }

  printf '%s\n' "$csv_row" >> "$CSV"

  last_data=$(awk '/^\(/{n=NR} END{print n}' "$SQL")
  [[ -n "$last_data" ]] || { echo "couldn't locate last data row in $SQL"; exit 1; }
  awk -v n="$last_data" -v r="$sql_row" 'NR==n{print; print r; next} {print}' \
      "$SQL" > "$SQL.tmp" && mv "$SQL.tmp" "$SQL"

  echo "appended to $CSV and inserted after $SQL line $last_data"
fi
