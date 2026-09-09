{% macro parse_lap_time(column) %}
    CASE
        WHEN {{ column }} IS NULL THEN NULL
        ELSE
            CAST(SPLIT({{ column }}, ':')[0] AS INT) * 60000
            + CAST(SPLIT(SPLIT({{ column }}, ':')[1], '\\.')[0] AS INT) * 1000
            + CAST(SPLIT({{ column }}, '\\.')[1] AS INT)
    END
{% endmacro %}