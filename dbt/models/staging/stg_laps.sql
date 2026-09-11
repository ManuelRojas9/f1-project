WITH laps_exploded as (
  SELECT
    season,
    round,
    explode(Laps) as laps
  FROM
    {{ source('bronze', 'laps') }}
),
timings_exploded as (
  select
    season,
    round,
    explode(laps.Timings) as timings,
    laps.number as lap_number
  FROM
    laps_exploded
)
SELECT
  CAST(season AS int),
  CAST(round AS int),
  CAST(lap_number as int),
  timings.driverid as driver_id,
  CAST(timings.position as int) as position,
  timings.time,
  CAST(SPLIT(timings.time, ':')[0] AS INT) * 60000
    + CAST(SPLIT(SPLIT(timings.time, ':')[1], '\\.')[0] AS INT) * 1000
    + CAST(SPLIT(timings.time, '\\.')[1] AS INT) AS time_millis
FROM
  timings_exploded
ORDER BY
  season,
  round,
  driver_id,
  lap_number;
