WITH sprint_results_exploded (
  SELECT
    season,
    round,
    explode(SprintResults) as sprint_results
  FROM
    {{ source('bronze', 'sprint') }}
)
SELECT
  season,
  round,
  sprint_results.Constructor.constructorid as constructor_id,
  sprint_results.Driver.driverId as driver_id,
  sprint_results.Driver.code as driver_code,
  sprint_results.FastestLap.Time.time as fastest_lap_time,
  CAST(sprint_results.FastestLap.lap AS INT) as fastest_lap,
  CAST(sprint_results.FastestLap.rank AS INT) as fastest_lap_rank,
  CAST(sprint_results.grid AS INT) as grid,
  CAST(sprint_results.laps AS INT) as laps,
  CAST(sprint_results.number AS INT) as driver_number,
  CAST(sprint_results.points AS INT) as points,
  CAST(sprint_results.position AS INT) as position,
  sprint_results.status as status,
  (
        CAST(SPLIT(sprint_results.FastestLap.Time.time, ':')[0] AS INT) * 60000        -- minutos a ms
        + CAST(SPLIT(SPLIT(sprint_results.FastestLap.Time.time, ':')[1], '\\.')[0] AS INT) * 1000   -- segundos a ms
        + CAST(SPLIT(sprint_results.FastestLap.Time.time, '\\.')[1] AS INT)             -- milisegundos
    ) AS fastest_lap_millis
FROM
  sprint_results_exploded