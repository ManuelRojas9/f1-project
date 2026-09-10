WITH season_max_grid AS (
    SELECT
        season,
        explode(sequence(1, max_grid)) AS position
    FROM (
        SELECT season, MAX(grid) AS max_grid
        FROM {{ ref('stg_results') }}
        GROUP BY season
    )
),

driver_seasons AS (
    SELECT DISTINCT season, driver_id
    FROM {{ ref('stg_results') }}
),

grid AS (
    SELECT
        ds.season,
        ds.driver_id,
        smg.position
    FROM driver_seasons ds
    JOIN season_max_grid smg
        ON ds.season = smg.season
),

driver_count AS (
    SELECT
        season,
        driver_id,
        position,
        COUNT(*) AS cnt
    FROM {{ ref('stg_results') }}
    GROUP BY season, driver_id, position
),

counts_filled AS (
    SELECT
        grid.season,
        grid.driver_id,
        grid.position,
        COALESCE(driver_count.cnt, 0) AS cnt
    FROM grid
    LEFT JOIN driver_count
        ON grid.season = driver_count.season
        AND grid.driver_id = driver_count.driver_id
        AND grid.position = driver_count.position
),

-- Array de conteos ordenado por posición: [conteo_pos1, conteo_pos2, conteo_pos3, ...]
-- Sirve para desempate tipo F1: más victorias gana, si empatan más 2dos lugares, etc.
position_counts AS (
    SELECT
        season,
        driver_id,
        transform(
            sort_array(collect_list(struct(position, cnt))),
            x -> x.cnt
        ) AS position_counts
    FROM counts_filled
    GROUP BY season, driver_id
),

sum_points AS (
    SELECT
        driver_id,
        season,
        SUM(points) AS total_points
    FROM {{ ref('stg_results') }}
    GROUP BY driver_id, season
),

combined AS (
    SELECT
        sp.season,
        sp.driver_id,
        sp.total_points,
        pc.position_counts
    FROM sum_points sp
    LEFT JOIN position_counts pc
        ON sp.season = pc.season
        AND sp.driver_id = pc.driver_id
)

SELECT
    season,
    driver_id,
    total_points,
    ROW_NUMBER() OVER (
        PARTITION BY season
        ORDER BY total_points DESC, position_counts DESC, driver_id ASC
    ) AS championship_rank
FROM combined
ORDER BY season, championship_rank