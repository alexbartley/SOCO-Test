CREATE OR REPLACE FORCE VIEW content_repo.jurisdiction_attributes_v ("ID",nkid,rid,next_rid,juris_id,juris_nkid,juris_rid,juris_next_rid,attribute_category,attribute_category_id,"VALUE",attribute_name,attribute_id,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT ja.id,
          ja.nkid,
          ja.rid,
          ja.next_rid,
          si.juris_id juris_id,
          si.entity_nkid,
          si.entity_rid,
          si.entity_next_rid,
          ac.name,
          ac.id,
          ja.VALUE,
          aa.name,
          aa.id,
          TO_CHAR (ja.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (ja.end_date, 'mm/dd/yyyy') end_date,
          ja.status,
          ja.status_modified_date,
          ja.entered_by,
          ja.entered_date
     FROM juris_att_id_sets si
     join jurisdiction_attributes ja on (ja.id= si.id)
          JOIN additional_attributes aa
             ON (aa.id = ja.attribute_id)
          JOIN attribute_categories ac
             ON (ac.id = aa.attribute_category_id)
 
 
 ;