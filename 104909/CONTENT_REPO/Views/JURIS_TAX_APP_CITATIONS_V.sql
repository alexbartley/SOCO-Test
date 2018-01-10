CREATE OR REPLACE FORCE VIEW content_repo.juris_tax_app_citations_v (citation_id,status,status_modified_date,change_log_id,rid,table_name,"SUMMARY",attachment_id,"TEXT") AS
(select jtact.citation_id, jtact.status,
jtact.status_modified_date,
jtach.id change_log_id,
jtach.rid,
jtach.table_name,
jtach.summary,
ci.attachment_id, ci.text
from juris_tax_app_chg_logs jtach
join juris_tax_app_chg_cits jtact on (jtact.juris_tax_app_chg_log_id = jtach.id)
join citations ci ON (ci.id = jtact.citation_id))
 
 
 ;