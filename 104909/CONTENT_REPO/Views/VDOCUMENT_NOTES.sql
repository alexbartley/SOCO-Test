CREATE OR REPLACE FORCE VIEW content_repo.vdocument_notes ("ID",document_id,note,source_contact_id,entered_by,entered_date) AS
select rl.id, a.id, rl.note, rl.source_contact_id, rl.entered_by, rl.entered_Date
from research_logs rl
join attachments a on (a.research_log_id = rl.id)
 
 
 ;