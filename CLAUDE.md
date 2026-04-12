# places

This is a personal travel log. It tracks every place Paulo has ever visited or lived in, from 1987 to the present day.

## Data structure

A single table `checkin` defined in `database.sql`:

- `arrival` / `departure` — datetime range for the stay
- `country` / `city` — where he was
- `lived` — 1 if he actually lived there, 0 for visits

All the data lives in `data.sql` (~540 rows and growing).

## What the queries.sql does

Contains aggregation queries to answer things like:
- Which countries/cities were visited and how many times
- Total days spent per city or country
- Whether a place was lived in vs. just visited

## Note for future Claude

You do not need Docker or a running MySQL database to answer questions about this data. Read `data.csv` directly — it is the canonical, clean version of the dataset and is much easier to parse than the SQL file.

The `docker-compose.yml`, MariaDB, and phpMyAdmin setup exist for historical reasons and are now redundant.

### data.csv format

Plain CSV, header row included:

```
arrival,departure,country,city,lived
```

- `arrival` / `departure` — datetime strings (`YYYY-MM-DD HH:MM`), occasionally date-only for open-ended stays
- `country` / `city` — all in English; Brazilian city names kept in Portuguese as they have no standard English equivalent
- `lived` — `1` if Paulo lived there, `0` for visits
- Three city values contain commas and are quoted: `"Juquehy, São Paulo"`, `"Lençóis, Bahia"`, `"Extrema, Minas Gerais"`

When Paulo asks for statistics, travel summaries, or queries about his travels, read `data.csv` and compute directly. `data.sql` exists as the database-importable version but `data.csv` is the one to use for analysis.

## Frequently asked statistics

Always compute these fresh from `data.csv` — never use cached answers, the data grows over time.

### How many countries have I visited?
Count unique values in the `country` column. When reporting, mention:
- England, Scotland, Wales, and Northern Ireland are counted separately — offer the merged "United Kingdom" count too
- Abkhazia, Kosovo, and Hong Kong have disputed/special status worth flagging
- Vatican is counted separately from Italy

### Top N countries by time spent
For each row compute `(departure - arrival)` in days, group by `country`, sum, sort descending. Report days and approximate human-readable duration (years/months) for the big ones.

### Top N cities by time spent
Same as above but group by `city` + `country` together (to avoid merging same-named cities in different countries).

### Where was I on this day in past years?
Get today's month and day. For each row, iterate every year between `arrival.year` and `departure.year`, build a candidate date `datetime(year, month, day)`, and check if `arrival <= candidate <= departure`. Collect results in a `year -> (city, country)` dict.

Then iterate every year from min to max in the dict. For years with no match:
1. First, try the **home base fallback**: find the most recent `lived=1` entry whose `arrival` is before the target date — use that city/country. This handles data gaps where Paulo was at his home base but it wasn't explicitly logged.
2. Only if no `lived=1` fallback exists, show: `transit <city before>, <country before> -> <city after>, <country after>`
