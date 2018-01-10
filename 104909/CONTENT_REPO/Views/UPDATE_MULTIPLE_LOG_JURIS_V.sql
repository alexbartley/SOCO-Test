CREATE OR REPLACE FORCE VIEW content_repo.update_multiple_log_juris_v (process_id,status,"ID",rid,table_name) AS
(select um.process_id, um.status, lg.id, lg.rid, lg.table_name
from juris_chg_logs lg
join update_multiple_log um on (um.primary_key = lg.primary_key)
where um.action!='E')
 
 
 ;