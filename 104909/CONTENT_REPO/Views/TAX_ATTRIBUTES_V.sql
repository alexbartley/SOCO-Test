CREATE OR REPLACE FORCE VIEW content_repo.tax_attributes_v ("ID",nkid,rid,next_rid,entity_rid,entity_next_rid,juris_tax_imposition_id,attribute_id,"VALUE",start_date,end_date,status,status_modified_date,entered_by,entered_date,is_current) AS
SELECT aa.id,
          aa.nkid,
          aa.rid,
          aa.next_rid,
          tis.entity_rid,
          tis.entity_next_rid,
          aa.juris_tax_imposition_id,
          aa.attribute_id,
          aa.value,
          aa.start_date,
          aa.end_date,
          aa.status,
          aa.status_modified_date,
          aa.entered_by,
          aa.entered_date,
          is_current(aa.rid,tis.entity_next_rid,aa.next_rid) is_current
     FROM tax_att_id_sets tis
          JOIN tax_attributes aa
             ON (  aa.id = tis.id)
 
 
 ;