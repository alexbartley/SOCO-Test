CREATE OR REPLACE FORCE VIEW sbxtax2.datax_check_out_approved_vw (data_check_name,data_check_id,prex_count) AS
SELECT c.name, c.data_check_id, count(*) prex_count
FROM datax_check_output o, datax_checks c
WHERE reviewed_approved is not null
AND o.data_check_id = c.data_check_id
GROUP BY c.name, c.data_check_id
 
 ;