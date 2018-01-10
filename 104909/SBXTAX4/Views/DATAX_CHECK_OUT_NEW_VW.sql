CREATE OR REPLACE FORCE VIEW sbxtax4.datax_check_out_new_vw (data_check_name,data_check_description,flag_level_id,data_check_id,new_count) AS
SELECT
    c.name,
    c.description,
    c.flag_level_id,
    c.data_check_id,
    COUNT(*) new_count
FROM
    datax_checks c
JOIN
    (
        SELECT
            data_check_id,
            'any',
            primary_key
        FROM
            datax_check_output o
        WHERE
            reviewed_approved IS NULL
    ) o
ON
    o.data_check_id = c.data_check_id
GROUP BY
    c.name,
    c.description,
    c.flag_level_id,
    c.data_check_id
 
 ;