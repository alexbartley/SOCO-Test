CREATE OR REPLACE FORCE VIEW content_repo.vdocuments ("ID",filename,display_name,attached_file,research_log_id,research_source_id,entered_by,entered_date,effective_date,expiration_date,acquired_date,language_id,attachment_language,posted_date,description,status) AS
SELECT a.id,
          a.filename,
          a.display_name,
          a.attached_file,
          a.research_log_id,
          a.research_source_id,
          a.entered_by,
          TO_CHAR (a.entered_date, 'mm/dd/yyyy') entered_date,
          TO_CHAR (a.effective_date, 'mm/dd/yyyy') effective_date,
          TO_CHAR (a.expiration_date, 'mm/dd/yyyy') expiration_date,
          TO_CHAR (a.acquired_date, 'mm/dd/yyyy') acquired_date,
          al.id language_id,
          al.name attachment_language,
          TO_CHAR (a.posted_date, 'mm/dd/yyyy') posted_date,
          a.description
          ,a.status
     FROM attachments a
          LEFT OUTER JOIN languages al
             ON (al.id = NVL(a.language_id,-1))
 
 ;