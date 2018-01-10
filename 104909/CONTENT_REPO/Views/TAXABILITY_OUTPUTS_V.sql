CREATE OR REPLACE FORCE VIEW content_repo.taxability_outputs_v ("ID",nkid,rid,next_rid,entity_rid,entity_nkid,entity_next_rid,juris_tax_app_id,short_text,status,status_modified_date,entered_by,entered_date,is_current) AS
SELECT tou.id,
          tou.nkid,
          tou.rid,
          tou.next_rid,
          tis.entity_rid,
          tis.entity_nkid,
          tis.entity_next_rid,
          tou.juris_tax_applicability_id,
          tou.short_text,
          tou.status,
          tou.status_modified_date,
          tou.entered_by,
          tou.entered_date,
          is_current(tou.rid,tis.entity_next_rid,tou.next_rid) is_current
     FROM tax_output_id_sets tis
          JOIN taxability_outputs tou
             ON (  tou.id = tis.id)
 
 
 ;