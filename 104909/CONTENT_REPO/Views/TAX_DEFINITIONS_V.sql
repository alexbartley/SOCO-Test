CREATE OR REPLACE FORCE VIEW content_repo.tax_definitions_v ("ID",nkid,rid,next_rid,juris_tax_id,juris_tax_nkid,juris_tax_rid,juris_tax_next_rid,tax_outline_id,tax_outline_nkid,tax_outline_rid,tax_outline_next_rid,min_threshold,max_limit,"VALUE",currency_id,value_type,ref_juris_tax_id,definition_status,status_modified_date,entered_by,entered_date,is_current) AS
SELECT td.id,
          td.nkid,
          td.rid,
          td.next_rid,
          ois.juris_tax_id,
          tis.entity_nkid,
          tis.entity_rid,
          tis.entity_next_rid,
          ois.id,
          ois.nkid,
          ois.rid,
          ois.next_rid,
          td.min_threshold,
          td.max_limit,
          td.VALUE,
          TD.CURRENCY_ID,
          td.value_type,
          td.defer_to_juris_tax_id,
          td.status definition_status,
          td.status_modified_date,
          td.entered_by,
          td.entered_date,
          tis.is_current
     FROM tax_def_id_sets tis
     join tax_definitions td on (td.id = tis.id)
     join tax_outln_id_sets ois on (
        ois.id = td.tax_outline_id
        and ois.entity_rid = tis.entity_rid)
 
 
 ;