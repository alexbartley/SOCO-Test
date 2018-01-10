CREATE OR REPLACE PACKAGE content_repo.gis
  IS
-- *****************************************************************
-- Description:
--
-- Revision History
-- Date            Author       Reason for Change
-- ----------------------------------------------------------------
-- 01/15/2015      dlg          Added "Get_Area_Revisions" functions
-- ??/??/????      tnn          added bunch of stuff
-- 10/21/2015      tnn          CRAPP-1348
-- *****************************************************************
    Type dsUIGetZip is record
    (
        id number,
        state_name varchar2(64),
        county_name varchar2(64),
        city_name varchar2(128),
        zip varchar2(5),
        plus4_range varchar2(5),
        default_flag varchar2(3),
        unique_area_id number,
        unique_area_rid number,
        unique_area_nkid number,
        unique_area varchar2(4000),
        rid number,
        nkid number,
        next_rid number,
        usps_start_date date,
        usps_end_date date,
        state_code varchar2(2)
    );
    Type dtUIGetZip is Table of dsUIGetZip;

    TYPE XMLForm_Attr_Rec IS RECORD
    (
        uiuserid NUMBER,
        recid   NUMBER,
        recrid   NUMBER,
        recnkid   NUMBER,
        attribute_id NUMBER,
        value VARCHAR2 (128),
        start_date date,
        end_date date,
        modified NUMBER ,
        deleted NUMBER,
        comm_id NUMBER
    );
    TYPE XMLForm_Attr_TT IS TABLE OF XMLForm_Attr_Rec;

    PROCEDURE delete_revision
    (
        revision_id_i IN NUMBER,
        deleted_by_i IN NUMBER,
        success_o OUT NUMBER
    );

    PROCEDURE delete_area_revision
    (
        revision_id_i IN NUMBER,
        deleted_by_i IN NUMBER,
        success_o OUT NUMBER
    );

    FUNCTION get_revision
    (
        rid_i IN NUMBER,
        entered_by_i IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_revision
    (
        entity_id_io IN OUT NUMBER,
        entity_nkid_i IN NUMBER,
        entered_by_i IN NUMBER
    ) RETURN NUMBER;


    FUNCTION get_area_revision
    (
        rid_i IN NUMBER,
        entered_by_i IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_area_revision
    (
        entity_id_io IN OUT NUMBER,
        entity_nkid_i IN NUMBER,
        entered_by_i IN NUMBER
    ) RETURN NUMBER;


    FUNCTION get_current_revision (p_nkid IN NUMBER) RETURN NUMBER;
    FUNCTION get_cur_area_revision (p_nkid IN NUMBER) RETURN NUMBER;

    /*PROCEDURE reset_status (revision_id_i IN NUMBER,
                            reset_by_i IN NUMBER,
                            success_o OUT NUMBER);
    */


    FUNCTION XMLForm_JurisArea(form_xml_i IN sys.XMLType) RETURN XMLForm_JurisArea_TT PIPELINED;

    -- Orig. used for dataload Juris_Geo_Area
    PROCEDURE XMLProcess_Form_JurisArea
    (
        sx IN CLOB,
        update_success OUT NUMBER,
        rid_o  OUT NUMBER,
        nkid_o OUT NUMBER
    );

    -- Form tabs
    Procedure XMLBoundary_Form(sx in CLOB, success OUT NUMBER, rid_o OUT NUMBER, nkid_o OUT NUMBER);
    Procedure XMLUniqueArea_Form(sx in CLOB, success OUT NUMBER, rid_o OUT NUMBER, nkid_o OUT NUMBER);

    PROCEDURE update_full_juris_area
    (
        details_i IN XMLFormJurisArea,
        tag_list  IN XMLForm_Tags_TT,
        rid_o  OUT NUMBER,
        nkid_o OUT NUMBER
    );

    PROCEDURE update_record_juris_area
    (
        id_io  IN OUT NUMBER,
        juris_id_i   IN NUMBER,
        polygon_id_i IN NUMBER,
        req_est_i    IN NUMBER,
        start_date_i IN DATE,
        end_date_i   IN DATE,
        entered_by_i IN NUMBER,
        rid_o  OUT NUMBER,
        nkid_o OUT NUMBER
    );


    PROCEDURE Delete_Unique_Attribute(id_i IN NUMBER, deleted_by_i IN NUMBER);
    PROCEDURE Delete_Boundary_Attribute(id_i IN NUMBER, deleted_by_i IN NUMBER);

    -- CRAPP-1348 Zip Code Search is Very Slow
    PROCEDURE refGet_Zip(pZipCode IN VARCHAR2, p_ref OUT SYS_REFCURSOR);
    FUNCTION UI_Get_Zip(pZipCode IN varchar2) RETURN dtUIGetZip PIPELINED;

    -- CRAPP-3654 --
    PROCEDURE gis_process_etl(stcode_i VARCHAR2, instance_grp_i NUMBER, preview_i NUMBER DEFAULT 0, compliance_i NUMBER DEFAULT 1);

    -- CRAPP-2244 --
    PROCEDURE update_sched_task(stcode_i IN VARCHAR2, method_i IN VARCHAR2, msg_i IN VARCHAR2);

    -- CRAPP-3241 --
    PROCEDURE copy_etl_preview(stcode_i IN VARCHAR2, instance_i IN NUMBER, schema_i IN VARCHAR2, compliance_i IN NUMBER);

    /*
    -- CRAPP-3363 -- moved from POST_PUBLISH --
    TYPE r_zonedetailfeed IS RECORD (
                                    state_code    VARCHAR2(2 CHAR),
                                    state_name    VARCHAR2(64 CHAR),
                                    county_name   VARCHAR2(64 CHAR),
                                    city_name     VARCHAR2(122 CHAR),
                                    zip           VARCHAR2(5 CHAR),
                                    zip9          VARCHAR2(10 CHAR),
                                    zip4          VARCHAR2(4 CHAR),
                                    default_flag  VARCHAR2(1 CHAR),
                                    code_fips     VARCHAR2(25 CHAR),
                                    geo_area      VARCHAR2(15 CHAR),
                                    unique_area   VARCHAR2(500 CHAR),
                                    rid           NUMBER
                                   );
    TYPE t_zonedetailfeed IS TABLE OF r_zonedetailfeed;
    */

    --FUNCTION F_GenerateZoneDetail(pState_code IN VARCHAR2) RETURN t_zonedetailfeed PIPELINED; -- 09/08/17, removed
    --FUNCTION F_GetZoneDetailFeed(pState_code IN VARCHAR2) RETURN t_zonedetailfeed PIPELINED;  -- 09/08/17, removed

    PROCEDURE push_gis_zone_tree (stcode_i IN VARCHAR2, instance_grp_i IN NUMBER);  -- crapp-3025 (instance_grp_i instead of instance_i and tag_grp_i)
    PROCEDURE push_gis_zone_authorities(stcode_i IN VARCHAR2, tag_grp_i IN NUMBER, instance_i IN NUMBER);
    PROCEDURE push_gis_ua_taxids(stcode_i IN VARCHAR2, instance_grp_i IN NUMBER);   -- crapp-3025, replaced tag_grp_i with instance_grp_i

    -- ************************************* --
    PROCEDURE delete_boundary
    (
        geo_polygon_id_i IN NUMBER,
        success_o OUT NUMBER
    ); -- new proc created as part of crapp-3073
END GIS;
/