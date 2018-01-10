CREATE OR REPLACE FORCE VIEW sbxtax.datax_re_reported_vw (data_check_name,data_check_description,flag_level_id,data_check_id,original_run_id,run_id) AS
SELECT c.name, c.description, c.flag_level_id, c.data_check_id, s.original_run_id, o.run_id
FROM datax_output_save s, datax_checks c, datax_check_output o
WHERE s.data_check_id = c.data_check_id
AND c.data_check_id = o.data_check_id
 
 
 ;