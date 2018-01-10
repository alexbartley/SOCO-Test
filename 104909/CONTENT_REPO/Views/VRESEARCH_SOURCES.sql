CREATE OR REPLACE FORCE VIEW content_repo.vresearch_sources ("ID",description,entered_by,entered_date,status,status_modified_date,frequency,next_contact_date,"OWNER") AS
SELECT rs.id,
          rs.description,
          rs.entered_by,
          rs.entered_date,
          rs.status,
          rs.status_modified_date,
          frequency,
          TO_CHAR (next_contact_date, 'mm/dd/yyyy') next_contact_date,
          owner
     FROM research_sources rs
 
 
 ;