WITH results as (
    SELECT season, round, grid, driver_id, constructor_id, points, "classic" as race_format, position FROM {{ ref('stg_results') }}
    UNION ALL
    SELECT season, round, grid, driver_id, constructor_id, points, "sprint" as race_format, position FROM {{ ref('stg_sprints') }}
),
season_max_grid AS (
    SELECT
        season,
        explode(sequence(1, max_grid)) AS position
    FROM (
        SELECT season, MAX(grid) AS max_grid
        FROM results
        GROUP BY season
    )
),

driver_seasons AS (
    SELECT DISTINCT season, constructor_id
    FROM results
),

grid AS (
    SELECT
        ds.season,
        ds.constructor_id,
        smg.position
    FROM driver_seasons ds
    JOIN season_max_grid smg
        ON ds.season = smg.season
),

driver_count AS (
    SELECT
        season,
        constructor_id,
        position,
        COUNT(*) AS cnt
    FROM results
    GROUP BY season, constructor_id, position
),

counts_filled AS (
    SELECT
        grid.season,
        grid.constructor_id,
        grid.position,
        COALESCE(driver_count.cnt, 0) AS cnt
    FROM grid
    LEFT JOIN driver_count
        ON grid.season = driver_count.season
        AND grid.constructor_id = driver_count.constructor_id
        AND grid.position = driver_count.position
),

-- Array de conteos ordenado por posición: [conteo_pos1, conteo_pos2, conteo_pos3, ...]
-- Sirve para desempate tipo F1: más victorias gana, si empatan más 2dos lugares, etc.
position_counts AS (
    SELECT
        season,
        constructor_id,
        transform(
            sort_array(collect_list(struct(position, cnt))),
            x -> x.cnt
        ) AS position_counts
    FROM counts_filled
    GROUP BY season, constructor_id
),

sum_points AS (
    SELECT
        constructor_id,
        season,
        SUM(points) AS total_points
    FROM results
    GROUP BY constructor_id, season
),

combined AS (
    SELECT
        sp.season,
        sp.constructor_id,
        sp.total_points,
        pc.position_counts
    FROM sum_points sp
    LEFT JOIN position_counts pc
        ON sp.season = pc.season
        AND sp.constructor_id = pc.constructor_id
)

SELECT
    season,
    constructor_id,
    total_points,
    ROW_NUMBER() OVER (
        PARTITION BY season
        ORDER BY total_points DESC, position_counts DESC, constructor_id ASC
    ) AS championship_rank
FROM combined
ORDER BY season, championship_rank