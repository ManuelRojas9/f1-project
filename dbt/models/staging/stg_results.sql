WITH exploded AS (
    SELECT
        season,
        round,
        explode(Results) AS result
    FROM {{ source('bronze', 'results') }}
)

SELECT
    season,
    round,
    result.Driver.driverId AS driver_id,
    result.Driver.code AS driver_code,
    result.Constructor.constructorId AS constructor_id,

    -- Resultado de la carrera
    CAST(result.grid AS INT) AS grid,
    CAST(result.laps AS INT) AS laps,
    CAST(result.number AS INT) AS car_number,
    CAST(result.points AS INT) AS points,
    CAST(result.position AS INT)  AS position,
    result.status AS status,

    -- Time (tiempo total de carrera)
    CAST(result.Time.millis AS INT) AS time_millis,
    result.Time.time as time_formatted,

    -- FastestLap (struct dentro de struct)
    CAST(result.FastestLap.lap AS INT) AS fastest_lap_number,
    CAST(result.FastestLap.rank AS INT) AS fastest_lap_rank,
    result.FastestLap.Time.time as  fastest_lap_time,     -- << 3 niveles: FastestLap.Time.time
    (
        CAST(SPLIT(result.FastestLap.Time.time, ':')[0] AS INT) * 60000        -- minutos a ms
        + CAST(SPLIT(SPLIT(result.FastestLap.Time.time, ':')[1], '\\.')[0] AS INT) * 1000   -- segundos a ms
        + CAST(SPLIT(result.FastestLap.Time.time, '\\.')[1] AS INT)             -- milisegundos
    ) AS fastest_lap_millis
from exploded;