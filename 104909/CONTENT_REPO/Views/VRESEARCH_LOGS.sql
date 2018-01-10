CREATE OR REPLACE FORCE VIEW content_repo.vresearch_logs ("ID",research_source_id,source_contact_id,note,entered_by,entered_date,document_id,contact_id) AS
SELECT rl.id,
          rsc.research_source_id,
          rl.source_contact_id,
          rl.note,
          rl.entered_by,
          TO_CHAR (rl.entered_date, 'mm/dd/yyyy hh24:mi:ss') entered_date,
          dn.document_id,
          rsc.id contact_id
     FROM research_logs rl
          JOIN research_source_contacts rsc
             ON (rsc.id = rl.source_contact_id)
          LEFT OUTER JOIN vdocument_notes dn
             ON (dn.id = rl.id)
 
 
 ;