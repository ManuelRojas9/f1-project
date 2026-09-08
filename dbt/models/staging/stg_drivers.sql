SELECT
    driverId,
    permanentNumber,
    code,
    givenName,
    familyName,
    dateOfBirth,
    nationality
FROM {{ source('bronze', 'drivers') }}