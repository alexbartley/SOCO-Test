CREATE OR REPLACE FORCE VIEW sbxtax2.datax_summary_vw ("PRIORITY",former_id,data_check_id,"CATEGORY",data_check_desc,plan_name,last_run,new_unapproved_count,prex_approved_count) AS
select c.flag_level_id priority, to_number(substr(replace(substr(description,1,5),'_','.'),1,instr(description,':')-1)) former_id, c.data_check_id, c.category, c.description, ep.plan_name, replace(to_Char(max(NVL(execution_date,'31-Dec-9999')),'DD-Mon-yyyy HH:MI PM'),'31-Dec-9999') last_run, nw.new_count, aw.prex_count
from datax_Checks c
join datax_planned_checks pc ON (pc.data_check_id = c.data_Check_id)
join datax_execution_plans ep on (ep.execution_plan_id = pc.execution_plan_id)
left outer join datax_run_executions r on (r.data_check_id = c.data_check_id)
left outer join datax_check_output o on (o.data_check_id = c.data_Check_id)
left outer join datax_check_out_new_vw nw on (nw.data_check_id = c.data_Check_id)
left outer join datax_check_out_approved_vw aw on (aw.data_check_id = c.data_Check_id)
group by c.flag_level_id, c.data_check_id, c.category, c.description, ep.plan_name, new_count, aw.prex_count
 
 ;