SELECT
    driverId as driver_id,
    permanentNumber as permanent_number,
    code,
    givenName as first_name,
    familyName as last_name,
    CAST(dateOfBirth as DATE) as date_of_birth,
    nationality
FROM {{ source('bronze', 'drivers') }}