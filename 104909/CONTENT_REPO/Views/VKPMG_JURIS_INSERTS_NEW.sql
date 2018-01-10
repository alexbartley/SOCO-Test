CREATE OR REPLACE FORCE VIEW content_repo.vkpmg_juris_inserts_new (official_name,start_date,description,geoareacategory) AS
SELECT
    OFFICIAL_NAME,
    start_date,
    DESCRIPTION,
    GEOAREACATEGORY
FROM
    (
        SELECT
            official_name,
            MIN(start_date) start_date,
            description,
            geoareacategory
        FROM
            (
                SELECT
                    official_name,
                    start_date,
                    UPPER(SUBSTR(rateauthlevel,5)) || ' '|| transaction_type description,
                    kpmg_import.getgeoareacategory(SUBSTR(rateauthlevel,5)) geoareacategory
                FROM
                    kpmg_rates rates
                WHERE
                    official_name NOT LIKE 'CANADA%')
        GROUP BY
            official_name,
            description,
            geoareacategory);