CREATE OR REPLACE FORCE VIEW content_repo.vdocument_citations ("ID",document_id,"TEXT",entered_by,entered_date,status,status_modified_date) AS
SELECT c.id,
          c.attachment_id,
          c.text,
          u.firstname || ' ' || u.lastname,
          c.entered_date,
          c.status,
          c.status_modified_date
     FROM citations c
          join users u on (c.entered_by = u.id)
 
 ;