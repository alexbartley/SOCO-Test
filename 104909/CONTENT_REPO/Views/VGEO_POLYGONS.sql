CREATE OR REPLACE FORCE VIEW content_repo.vgeo_polygons ("ID",rid,nkid,next_rid,geo_poly_rid,geo_poly_next_rid,geo_area_key,hierarchy_level,geo_area_id,geo_area,polygon_type_id,polygon_type,start_date,end_date,status,status_modified_date,"VIRTUAL") AS
SELECT  DISTINCT
            p.id,
            p.rid,
            p.nkid,
            p.next_rid,
            r.id,
            r.next_rid,
            p.geo_area_key,
            p.hierarchy_level_id,
            ac.id    geo_area_id,
            ac.NAME  geo_area,
            pt.id    polygon_type_id,
            pt.NAME  polygon_type,
            p.start_date,
            p.end_date,
            p.status,
            p.status_modified_date,
            p.virtual
    FROM    geo_poly_ref_revisions r
            JOIN geo_polygons p ON (    r.nkid = p.nkid
                                    AND rev_join (p.rid, r.id, COALESCE(p.next_rid, 999999999)) = 1)
            JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
            JOIN geo_area_categories ac ON (hl.geo_area_category_id = ac.id)
            JOIN geo_polygon_types pt ON (p.geo_polygon_type_id = pt.id)
 
 ;