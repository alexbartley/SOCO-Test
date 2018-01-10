CREATE OR REPLACE FORCE VIEW content_repo.vcontact_reasons ("ID",research_source_id,contact_reason_id,contact_reason,start_date,end_date) AS
SELECT rsc.id,
       rsc.research_source_id,
       cut.id contact_reason_id,
       cut.name contact_reason,
       TO_CHAR (cu.start_date, 'mm/dd/yyyy') start_date,
       TO_CHAR (cu.end_date, 'mm/dd/yyyy') end_date
  FROM research_source_contacts rsc
       JOIN contact_usages cu
          ON (rsc.id = cu.research_source_contact_id)
       JOIN contact_usage_types cut
          ON (cut.id = cu.contact_usage_type_id)
 
 
 ;