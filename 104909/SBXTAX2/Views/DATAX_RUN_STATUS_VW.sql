CREATE OR REPLACE FORCE VIEW sbxtax2.datax_run_status_vw (data_check_id,run_id,current_state) AS
select e.data_check_id, e.run_id, case when recorded_message is null then 'Run pending' else 'No current activity' end curr_state
from datax_run_Executions e
join datax_checks c on (e.data_Check_id = c.data_check_id)
left outer join datax_records r on (r.run_id = e.run_id and INSTR(r.recorded_message,c.procedure_name) >0)
 
 ;