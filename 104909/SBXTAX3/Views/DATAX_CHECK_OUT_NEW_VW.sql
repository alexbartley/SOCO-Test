CREATE OR REPLACE FORCE VIEW sbxtax3.datax_check_out_new_vw (data_check_name,data_check_description,flag_level_id,data_check_id,new_count) AS
SELECT c.name, c.description, c.flag_level_id, c.data_check_id, count(*) new_count
FROM datax_checks c
join (
select data_check_id, 'any', primary_key
from datax_check_output o
WHERE reviewed_approved IS NULL
union
select distinct data_check_id, table_name, primary_key
from datax_check_misc_output ) o on o.data_check_id = c.data_check_id
GROUP BY c.name, c.description, c.flag_level_id, c.data_check_id
 
 ;