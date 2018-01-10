CREATE OR REPLACE FORCE VIEW content_repo.juris_tax_descriptions_v ("ID",nkid,rid,next_rid,juris_id,juris_nkid,juris_rid,juris_next_rid,tax_description_id,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT jtd.id,
       jtd.nkid,
       jtd.rid,
       jtd.next_rid,
       si.juris_id,
       si.entity_nkid juris_nkid,
       si.entity_rid,
       si.entity_next_rid,
       jtd.tax_description_id,
       TO_CHAR (jtd.start_date, 'mm/dd/yyyy') start_date,
       TO_CHAR (jtd.end_date, 'mm/dd/yyyy') end_date,
       jtd.status,
       jtd.status_modified_date,
       jtd.entered_by,
       jtd.entered_date
  FROM juris_tax_descriptions jtd
  JOIN juris_taxdesc_id_sets si on (jtd.id = si.id)
 
 
 ;