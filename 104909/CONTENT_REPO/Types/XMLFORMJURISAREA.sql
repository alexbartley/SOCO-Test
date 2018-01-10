CREATE OR REPLACE TYPE content_repo."XMLFORMJURISAREA"                                          AS OBJECT
    (
        id NUMBER,
        jurisdiction_id NUMBER,
        geo_polygon_id  NUMBER,
        requires_establishment NUMBER,
        start_date DATE,
        end_date   DATE,
        entered_by NUMBER,
        rid      NUMBER,
        nkid     NUMBER,
        modified NUMBER,
        deleted  NUMBER
    );
/