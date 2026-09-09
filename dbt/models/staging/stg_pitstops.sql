WITH pitstops_exploded as (
  SELECT
    season,
    round,
    date,
    explode(PitStops) as pitstops
  FROM
    {{ source('bronze', 'pitstops') }}
)
SELECT
  CAST(season AS INT),
  CAST(round AS INT),
  pitstops.driverId as driver_id,
  CAST(pitstops.stop AS INT) as pitstop_number,
  CAST(pitstops.lap AS INT) as pitstop_lap,
  CAST(pitstops.time AS TIME) as time,
  CAST(CONCAT(date, ' ', pitstops.time) AS TIMESTAMP) AS pitstop_timestamp,
  TRY_CAST(pitstops.duration AS DECIMAL(10, 3)) as duration
from
  pitstops_exploded;