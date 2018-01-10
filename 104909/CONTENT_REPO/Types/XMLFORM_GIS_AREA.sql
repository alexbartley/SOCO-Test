CREATE OR REPLACE TYPE content_repo."XMLFORM_GIS_AREA"                                          AS OBJECT
  (
        id NUMBER,
        entity NUMBER,
        entity_id number,
        geo_polygon_id  NUMBER,
        start_date DATE,
        end_date   DATE,
        entered_by NUMBER,
        rid      NUMBER,
        nkid     NUMBER,
        modified NUMBER,
        deleted  NUMBER,
        geo_area_id number
  );
/