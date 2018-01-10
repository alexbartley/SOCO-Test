CREATE OR REPLACE FORCE VIEW content_repo.collection_conditions_v (rid,juris_tax_applicability_id,conditions) AS
with jtaQ1 as
/*
 How would you know what row you're looing at if you don't have this as a JSON or XML
 or actually adding something that tells you what is what??
 Formatting is, in this way, on the database side, which is not a good solution.
 If this data could be sent as JSON or XML a stylesheet could use it and display it as
 a table. 
*/
/*
( select jta.rid, jta.juris_tax_applicability_id,
  listagg('Element: '||jta.element_name||' '||',Descr: '||jta.description||
       ',Element: '||jta.element_value_type||
       ',Qualifier: '||jta.logical_qualifier||
       ',Value: '||jta.value||
       ',RefGroupName: '||jta.reference_group_name||
       Case When jta.official_name is not null then
       ',Name'||jta.official_name
       else
       '' end
       ||',Start Date: '||to_char(jta.start_date)||
       ',End Date: '||to_char(jta.end_date),',') 
   WITHIN GROUP (ORDER BY rid) conditions
  from 
  taxability_conditions_v jta
  group by jta.rid, jta.juris_tax_applicability_id
)
select "RID","JURIS_TAX_APPLICABILITY_ID","CONDITIONS" from jtaQ1
*/
( 
select jta.rid, jta.juris_tax_applicability_id,
  listagg(case when element_name = 'AUTHORITY' and jta.official_name is not null then jta.official_name else element_name end ||'|'|| logical_qualifier||'|'||nvl(value, reference_group_name), chr(13) ) 
   WITHIN GROUP (ORDER BY rid) conditions
  from 
  taxability_conditions_v jta
  group by jta.rid, jta.juris_tax_applicability_id
)
select "RID","JURIS_TAX_APPLICABILITY_ID","CONDITIONS" from jtaQ1;