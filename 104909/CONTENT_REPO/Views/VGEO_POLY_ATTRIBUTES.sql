CREATE OR REPLACE FORCE VIEW content_repo.vgeo_poly_attributes ("ID",nkid,rid,next_rid,geo_poly_id,geo_poly_nkid,geo_poly_rid,geo_poly_next_rid,attribute_category,attribute_category_id,"VALUE",attribute_name,attribute_id,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT ga.id,
          ga.nkid,
          ga.rid,
          ga.next_rid,
          gi.id     geo_poly_id,
          gi.nkid   geo_poly_nkid,
          r.id      geo_poly_entity_rid,
          r.next_rid,
          ac.name,
          ac.id,
          ga.VALUE,
          aa.name,
          aa.id,
          TO_CHAR (ga.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (ga.end_date, 'mm/dd/yyyy') end_date,
          ga.status,
          ga.status_modified_date,
          ga.entered_by,
          ga.entered_date
     FROM geo_poly_attributes ga
        JOIN vgeo_poly_ids gi ON (
            gi.id = ga.geo_polygon_id
        )
        JOIN geo_poly_ref_revisions r ON (
            r.nkid = gi.nkid
            and rev_join(ga.rid, r.id, COALESCE(ga.next_rid, 99999999)) = 1
            )
          JOIN additional_attributes aa
             ON (aa.id = ga.attribute_id)
          JOIN attribute_categories ac
             ON (ac.id = aa.attribute_category_id)
 
 ;