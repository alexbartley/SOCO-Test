CREATE OR REPLACE TYPE content_repo."XMLFORM_GIS_POLYGON"                                          as object
(id NUMBER,
 rid NUMBER,
 nkid NUMBER,
 geo_polygon_id NUMBER,
 requires_establishment NUMBER,
 start_date DATE,
 end_date   DATE,
 entered_by NUMBER,
 modified NUMBER,
 deleted  NUMBER
)
/