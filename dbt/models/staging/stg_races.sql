SELECT 
    season,
    round,
    raceName as race_name,
    CAST(date AS date),
    CAST(time AS timestamp),
    Circuit.circuitId as circuit_id,
    Circuit.circuitName as circuit_name,
    -- `Circuit.Location.lat` as lat,
    -- `Circuit.Location.long` as long,
    Circuit.Location.locality as locality,
    Circuit.Location.country as country
    -- `FirstPractice.date` as first_practice_date,
    -- `FirstPractice.time` as first_practice_time,
    -- `SecondPractice.date` as second_practice_date,
    -- `SecondPractice.time` as second_practice_time,
    -- `ThirdPractice.date` as third_practice_date,
    -- `ThirdPractice.time` as third_practice_time,
    -- `Qualifying.date` as qualifying_date,
    -- `Qualifying.time` as qualifying_time,
    -- `Sprint.date` as sprint_date,
    -- `Sprint.time` as sprint_time,
    -- `SprintQualifying.date` as sprint_qualifying_date,
    -- `SprintQualifying.time` as sprint_qualifying_time

FROM {{ source('bronze', 'races') }};