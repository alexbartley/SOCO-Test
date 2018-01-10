CREATE OR REPLACE FORCE VIEW content_repo.vcommodity_attributes ("ID",nkid,rid,next_rid,commodity_id,commodity_nkid,commodity_rid,commodity_next_rid,attribute_category,attribute_category_id,"VALUE",attribute_name,attribute_id,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT ca.id,
          ca.nkid,
          ca.rid,
          ca.next_rid,
          ci.id commodity_id,
          ci.nkid commodity_nkid,
          r.id commodity_entity_rid,
          r.next_rid,
          ac.name,
          ac.id,
          ca.VALUE,
          aa.name,
          aa.id,
          TO_CHAR (ca.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (ca.end_date, 'mm/dd/yyyy') end_date,
          ca.status,
          ca.status_modified_date,
          ca.entered_by,
          ca.entered_date
     FROM commodity_attributes ca
        JOIN vcommodity_ids ci ON (
            ci.id = ca.commodity_id
        )
        JOIN commodity_revisions r ON (
            r.nkid = ci.nkid
            and rev_join(ca.rid,r.id,COALESCE(ca.next_rid,99999999)) = 1)
          JOIN additional_attributes aa
             ON (aa.id = ca.attribute_id)
          JOIN attribute_categories ac
             ON (ac.id = aa.attribute_category_id)
 
 
 ;