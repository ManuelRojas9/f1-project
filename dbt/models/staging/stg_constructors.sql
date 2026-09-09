
SELECT
    constructorId as constructor_id,
    name as constructor_name,
    nationality
FROM {{ source('bronze', 'constructors') }}