CREATE OR REPLACE PACKAGE BODY content_repo."GIS_STAGING_LIB"
as
  FUNCTION f_GetFeed(pState_code IN VARCHAR2) RETURN t_feed PIPELINED
  IS
    lo_feed r_feed;
  BEGIN
   FOR r_row IN (SELECT id, rownum crec
                 FROM   geo_usps_lookup
                 WHERE  state_code = pState_code)
   LOOP
     lo_feed.usps_id := r_row.id;
     lo_feed.recno := r_row.crec;
     PIPE ROW(lo_feed);
   END LOOP;
  END F_GetFeed;


  PROCEDURE P_ProcessMT(pState_code IN VARCHAR2) IS
    ln_totalRecords NUMBER;
  BEGIN

    EXECUTE IMMEDIATE 'ALTER TABLE geo_usps_mv_staging MODIFY PARTITION MK_USPS_' ||pState_code|| ' UNUSABLE LOCAL INDEXES'; -- 01/15/16
    EXECUTE IMMEDIATE 'ALTER TABLE geo_usps_mv_staging TRUNCATE PARTITION MK_USPS_' ||pState_code|| '';  -- Changed to TRUNCATE 01/14/16

    INSERT INTO GEO_USPS_MV_STAGING(
        SELECT /*+index (p geo_polygons_un) */
              DISTINCT
              p.geo_area_key
              ,p.hierarchy_level_id
              ,u.state_code
              ,u.state_name
              ,u.state_fips
              ,u.county_name
              ,u.county_fips
              ,u.city_name
              ,u.city_fips
              ,u.zip
              ,u.zip9
              ,CASE WHEN ac.name = 'District'
                    THEN SUBSTR(p.geo_area_key, 4, INSTR(p.geo_area_key, '-', 4, 1) - 4)
                    ELSE NULL
               END stj_fips
              ,p.rid
              ,p.nkid
              ,p.next_rid
              ,DECODE(u.zip, null, 2, 1) MT_UNION_SECTION
              ,u.area_id
        FROM  geo_usps_lookup u
              JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
              JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                                AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
              JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
              JOIN geo_area_categories ac ON (hl.geo_area_category_id = ac.id)
              JOIN table(F_GetFeed(pState_Code)) XV ON (u.id = xv.usps_id AND u.state_code = pState_Code)
        WHERE p.next_rid IS NULL
              AND u.area_id IS NOT NULL);   -- 02/24/16 added to improve materialzied view refresh
    COMMIT;

    -- Rebuild Indexes --
    EXECUTE IMMEDIATE 'ALTER INDEX geo_usps_mv_i1 REBUILD PARTITION MK_USPS_' ||pState_Code|| '';
    EXECUTE IMMEDIATE 'ALTER INDEX geo_usps_mv_i2 REBUILD PARTITION MK_USPS_' ||pState_Code|| '';
    EXECUTE IMMEDIATE 'ALTER INDEX geo_usps_mv_i3 REBUILD PARTITION MK_USPS_' ||pState_Code|| '';   -- crapp-2801

    DBMS_STATS.gather_table_stats('CONTENT_REPO', 'GEO_USPS_MV_STAGING', cascade => TRUE);
    DBMS_OUTPUT.Put_Line( pState_Code );
  END P_ProcessMT;


  PROCEDURE P_ProcessLookup(pState IN VARCHAR2) IS
    CURSOR s_cur(sstate IN VARCHAR2) IS
        SELECT u.id
              ,u.geo_polygon_id
              ,u.state_code
              ,u.state_name
              ,u.state_fips
              ,u.county_name
              ,u.county_fips
              ,NVL2 (ua.id, SUBSTR (ua.VALUE, 7), u.city_name) city_name
              ,NVL2 (ua.id, TRIM (SUBSTR (ua.VALUE, 1, 6)), u.city_fips) city_fips
              ,u.zip
              ,NVL2 (u.plus4_range, (u.zip || u.plus4_range), NULL) zip9
              ,ua.attribute_id
              ,ua.override_rank
              ,u.start_date
              ,u.end_date
              ,u.area_id
        FROM  geo_polygon_usps u
              LEFT JOIN gis_usps_attributes ua on (ua.geo_polygon_usps_id = u.id)
        WHERE u.state_code = sState;

    type fetch_array is table of s_cur%rowtype;
    s_array fetch_array;
  BEGIN
    DBMS_OUTPUT.Put_Line( '--> Start:'||to_char(sysdate,'HH24:MI:SS'));

    EXECUTE IMMEDIATE 'ALTER TABLE geo_usps_lookup MODIFY PARTITION LK_USPS_' ||pState|| ' UNUSABLE LOCAL INDEXES'; -- 01/15/16
    EXECUTE IMMEDIATE 'ALTER TABLE geo_usps_lookup TRUNCATE PARTITION LK_USPS_' ||pState|| '';  -- Changed to TRUNCATE 01/14/16

    DBMS_OUTPUT.Put_Line( 'State:'||pState||' deleted '||to_char(sysdate,'HH24:MI:SS'));

    OPEN s_cur(pState);
    LOOP
        FETCH s_cur BULK COLLECT INTO s_array LIMIT 50000;  -- 02/24/16 increased from 45,000
        FORALL i IN 1..s_array.COUNT
            INSERT INTO geo_usps_lookup VALUES s_array(i);
        EXIT WHEN s_cur%NOTFOUND;
        COMMIT; -- 09/22/15 moved to inside loop
    END LOOP;
    CLOSE s_cur;
    COMMIT;

    -- Rebuild Indexes --
    EXECUTE IMMEDIATE 'ALTER INDEX geo_usps_lookup_i1 REBUILD PARTITION LK_USPS_' ||pState|| '';
    EXECUTE IMMEDIATE 'ALTER INDEX geo_usps_lookup_i2 REBUILD PARTITION LK_USPS_' ||pState|| '';
    EXECUTE IMMEDIATE 'ALTER INDEX geo_usps_lookup_i3 REBUILD PARTITION LK_USPS_' ||pState|| '';
    EXECUTE IMMEDIATE 'ALTER INDEX geo_usps_lookup_i4 REBUILD PARTITION LK_USPS_' ||pState|| '';
    EXECUTE IMMEDIATE 'ALTER INDEX geo_usps_lookup_i5 REBUILD PARTITION LK_USPS_' ||pState|| '';
    EXECUTE IMMEDIATE 'ALTER INDEX geo_usps_lookup_i6 REBUILD PARTITION LK_USPS_' ||pState|| '';

    DBMS_STATS.gather_table_stats('CONTENT_REPO', 'geo_usps_lookup', cascade => TRUE);
    DBMS_OUTPUT.Put_Line( '<-- End:'||to_char(sysdate,'HH24:MI:SS'));
  END P_ProcessLookup;



  -- Crapp-2794 --
  PROCEDURE P_RefreshMV(pState_code IN VARCHAR2) IS
  BEGIN

    DBMS_OUTPUT.Put_Line( '--> Start: '||to_char(sysdate,'HH24:MI:SS'));

    EXECUTE IMMEDIATE 'ALTER TABLE vgeo_unique_areas2 MODIFY PARTITION MV_UA_' ||pState_code|| ' UNUSABLE LOCAL INDEXES';
    EXECUTE IMMEDIATE 'ALTER TABLE vgeo_unique_areas2 TRUNCATE PARTITION MV_UA_' ||pState_code|| '';

        dbms_mview.refresh(LIST=>'VGEO_UNIQUE_AREAS2', METHOD=>'C', ATOMIC_REFRESH=>FALSE);

    EXECUTE IMMEDIATE 'ALTER INDEX vgeo_unique_areas_mv_i1 REBUILD PARTITION MV_UA_' ||pState_Code|| '';
    EXECUTE IMMEDIATE 'ALTER INDEX vgeo_unique_areas_mv_i2 REBUILD PARTITION MV_UA_' ||pState_Code|| '';
    COMMIT;

    DBMS_STATS.gather_table_stats('CONTENT_REPO', 'vgeo_unique_areas2', cascade => TRUE);

    DBMS_OUTPUT.Put_Line( '--> End:   '||to_char(sysdate,'HH24:MI:SS'));
  END P_RefreshMV;


END GIS_STAGING_LIB;
/