CREATE OR REPLACE PACKAGE content_repo."LOAD_GIS"
IS
    PROCEDURE master_data (stcode_i IN VARCHAR2, user_i IN NUMBER, job_id_i IN NUMBER);

    PROCEDURE update_data (stcode_i IN VARCHAR2, user_i IN NUMBER, job_id_i IN NUMBER);

    FUNCTION extract_gis_areas (stcode_i IN VARCHAR2, stname_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER) RETURN NUMBER;

    PROCEDURE extract_mailing_city (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER);

    FUNCTION create_geo_polygons (stcode_i IN VARCHAR2, stfips_i IN VARCHAR2, stname_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER) RETURN NUMBER;

    PROCEDURE get_polygon_date (stcode_i IN VARCHAR2, user_i IN NUMBER, poly_i IN VARCHAR2, fips_i IN VARCHAR2, type_i IN VARCHAR2, id_i IN NUMBER);

    FUNCTION update_geo_polygons (stcode_i IN VARCHAR2, stname_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER) RETURN NUMBER;

    PROCEDURE update_ranking (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER);

    PROCEDURE get_defaultzip (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER);

    FUNCTION update_geo_polygon_usps (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER, type_i IN VARCHAR2) RETURN NUMBER;

    PROCEDURE create_unique_areas (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER);

    PROCEDURE update_unique_areas (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER);

    PROCEDURE map_juris_geo_areas (stcode_i IN VARCHAR2, user_i IN NUMBER, pID_i IN NUMBER);

    PROCEDURE archive_uaz9(stcode_i VARCHAR2, user_i NUMBER, pID_i NUMBER); -- crapp-3451

    ----------------------------------

    TYPE r_zip9feed IS RECORD(  state               VARCHAR2(2 CHAR)
                               , geo_polygon_id     NUMBER
                               , geo_area_key       VARCHAR2(100 CHAR)
                               , hierarchy_level_id NUMBER
                               , countyname         VARCHAR2(64 CHAR)
                               , zip9               VARCHAR2(9 CHAR)
                               , multiple_cities    NUMBER
                               , area_id            VARCHAR2(60 CHAR)
                             );
    TYPE t_zip9feed IS TABLE OF r_zip9feed;

    FUNCTION F_GetZip9Feed(pState_code IN varchar2) RETURN t_zip9feed PIPELINED;

END load_gis;
/