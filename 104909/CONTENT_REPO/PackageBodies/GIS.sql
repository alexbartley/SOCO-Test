CREATE OR REPLACE PACKAGE BODY content_repo.gis
IS

    type G_T_Boundary is record
    (
          ac_id number,
          ac_nkid number,
          ac_rid number,
          ac_jurisdiction_id number,
          ac_official_name varchar2(500),
          ac_location_category_id number,
          ac_start_date varchar2(11),
          ac_end_date varchar2(11),
          requires_establishment number,
          ac_modified number,
          ac_deleted number,
          id number,
          geo_area_key varchar2(500),
          start_date varchar2(11),
          end_date varchar2(11),
          entered_by number,
          geo_area_category_id number
    );
    TYPE T_GIS_Boundary IS TABLE OF G_T_Boundary;
    r_T_gis_boundary T_GIS_Boundary:=T_GIS_Boundary();


    -- UA Jurisdiction Overrides --
    type G_T_Unique_J_O is record
    (
          at_id number,
          at_nkid number,
          at_rid number,
          at_value number,
          at_attribute_id number,
          at_attribute_category_id number,
          at_start_date varchar2(11),
          at_end_date varchar2(11),
          at_modified number,
          at_deleted number,
          id number,
          nkid number,
          rid number,
          entered_by number
    );
    TYPE T_GIS_UQ_JO IS TABLE OF G_T_Unique_J_O;
    r_T_gis_uqa_jo T_GIS_UQ_JO:=T_GIS_UQ_JO();


    -- UA Attributes --
    type G_T_Unique is record
    (
          at_id number,
          at_nkid number,
          at_rid number,
          at_value number,
          at_attribute_id number,
          at_attribute_category_id number,
          at_start_date varchar2(11),
          at_end_date varchar2(11),
          at_modified number,
          at_deleted number,
          id number,
          nkid number,
          rid number,
          entered_by number
    );
    TYPE T_GIS_UQ IS TABLE OF G_T_Unique;
    r_T_gis_uqa T_GIS_UQ:=T_GIS_UQ();

    type G_T_pp is record
    (
          at_id number,
          at_nkid number,
          at_rid number,
          at_value varchar2(500),
          at_attribute_id number,
          at_attribute_category_id number,
          at_start_date varchar2(11),
          at_end_date varchar2(11),
          at_modified number,
          at_deleted number,
          id number,
          nkid number,
          rid number,
          entered_by number
    );
    TYPE T_GIS_pp IS TABLE OF G_T_pp;
    r_T_gis_pp T_GIS_pp:=T_GIS_pp();



    type G_T_Tags is record
    (
      tag_id number,
      status number,
      deleted number,
      id number,
      entered_by number
    );
    TYPE T_GIS_Tags IS TABLE OF G_T_Tags;
    r_T_GIS_Tags T_GIS_Tags:=T_GIS_Tags();    -- Local tag record dataset

    type UM_Attrib is record
    (
      value varchar2(500),
      attribute_id number,
      attribute_category_id number,
      start_date varchar2(11),
      end_date varchar2(11),
      jl varchar2(4000),
      entered_by number
    );
    TYPE T_Attrib IS TABLE OF UM_Attrib;
    r_T_Attrib T_Attrib:=T_Attrib();


PROCEDURE delete_revision
(
   revision_id_i IN NUMBER,
   deleted_by_i  IN NUMBER,
   success_o     OUT NUMBER
)
IS
        l_rid        NUMBER := revision_id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_status     NUMBER;
    BEGIN
        success_o := 0;

        --Get status to validate that it's a deleteable record
        --Get revision ID to delete all depedent records by
        SELECT status
        INTO l_status
        FROM geo_poly_ref_revisions
        WHERE id = l_rid;

        IF (l_status = 0) THEN
            --Remove dependent Geo Areas - Jurisdiction
            --Reset prior revisions to current
            UPDATE juris_geo_areas aa
            SET   aa.next_rid = NULL
            WHERE aa.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key)
            (
                SELECT 'JURIS_GEO_AREAS', aa.id
                FROM  juris_geo_areas aa
                WHERE aa.rid = l_rid
            );

            DELETE FROM juris_geo_areas aa
            WHERE aa.rid = l_rid;


            --Remove Revision record
            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) VALUES ('GEO_POLY_REF_REVISIONS',l_rid);
            DELETE FROM geo_poly_ref_chg_logs ac  WHERE ac.rid = l_rid;
            DELETE FROM geo_poly_ref_revisions ar WHERE ar.id = l_rid;

            INSERT INTO delete_logs (table_name, primary_key, deleted_by)
            (
                SELECT table_name, primary_key, l_deleted_by
                FROM tmp_delete
            );

            COMMIT;
            success_o := 1;
        ELSE
            RAISE errnums.cannot_delete_record;
        END IF;

    EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            errlogger.report_and_stop(errnums.en_cannot_delete_record,'Record could not be deleted because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END delete_revision;


PROCEDURE delete_area_revision
(
   revision_id_i IN NUMBER,
   deleted_by_i  IN NUMBER,
   success_o     OUT NUMBER
)
IS
        l_rid        NUMBER := revision_id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_status     NUMBER;
    BEGIN
        success_o := 0;

        --Get status to validate that it's a deleteable record
        --Get revision ID to delete all depedent records by
        SELECT status
        INTO l_status
        FROM geo_unique_area_revisions
        WHERE id = l_rid;

        IF (l_status = 0) THEN
            --Remove dependent Geo Areas - Jurisdiction
            --Reset prior revisions to current
            UPDATE juris_geo_areas aa
            SET   aa.next_rid = NULL
            WHERE aa.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key)
            (
                SELECT 'JURIS_GEO_AREAS', aa.id
                FROM  juris_geo_areas aa
                WHERE aa.rid = l_rid
            );

            DELETE FROM juris_geo_areas aa
            WHERE aa.rid = l_rid;


            --Remove Revision record
            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) VALUES ('GEO_UNIQUE_AREA_REVISIONS',l_rid);
            DELETE FROM geo_unique_area_chg_logs ac  WHERE ac.rid = l_rid;
            DELETE FROM geo_unique_area_revisions ar WHERE ar.id = l_rid;

            INSERT INTO delete_logs (table_name, primary_key, deleted_by)
            (
                SELECT table_name, primary_key, l_deleted_by
                FROM tmp_delete
            );

            COMMIT;
            success_o := 1;
        ELSE
            RAISE errnums.cannot_delete_record;
        END IF;

    EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            errlogger.report_and_stop(errnums.en_cannot_delete_record,'Record could not be deleted because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END delete_area_revision;



FUNCTION get_revision
(
    rid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER
IS
        l_new_rid  NUMBER;
        l_curr_rid NUMBER;
        l_nkid   NUMBER;
        l_nrid   NUMBER;
        l_status NUMBER := -1;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN

        IF (rid_i IS NOT NULL) THEN
            --this is for existing records,
            --they will have existing revision records
            --doesn't matter if it's published or not,
            --just looking for the current revision
            SELECT gr.id, gr.status, gr.nkid
            INTO   l_curr_rid, l_status, l_nkid
            FROM   geo_poly_ref_revisions gr
            WHERE  EXISTS (
                            SELECT 1
                            FROM   geo_poly_ref_revisions gr2
                            WHERE  gr.nkid = gr2.nkid
                                   AND gr2.id = rid_i
                          )
                   AND gr.next_rid IS NULL;
        END IF;

        IF l_status IN (0,1) THEN
            --This record is already in a pending state.
            --Return its current RID
            retval := l_curr_rid;
        ELSE
            --The current version has been published, create a new one.
            --First, expire the previous version
            INSERT INTO geo_poly_ref_revisions( nkid, entered_by )
            VALUES (l_nkid, entered_by_i)
            RETURNING id INTO l_new_rid;

            UPDATE geo_poly_ref_revisions
            SET    next_rid = l_new_rid
            WHERE  id = l_curr_rid;

            retval := l_new_rid;
        END IF;

        RETURN retval;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN 0; --ignore error and return no RID, this means that the last change in revision was deleted an so the revision no longer exists
    END get_revision;


FUNCTION get_revision
(
    entity_id_io  IN OUT NUMBER,
    entity_nkid_i IN NUMBER,
    entered_by_i  IN NUMBER
) RETURN NUMBER
IS
        l_new_rid NUMBER;
        l_poly_id NUMBER := entity_id_io;    -- renamed from l_juris_area_id - dlg 12/15/2014
        l_nkid    NUMBER := entity_nkid_i;
        l_status  NUMBER;
        l_curr_rid NUMBER;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN
        --check for an existing revision
        dbms_output.put_line('l_poly_id = ' || l_poly_id || ' l_nkid = ' || l_nkid);
        IF (l_poly_id IS NOT NULL AND l_nkid IS NOT NULL) THEN
            --dbms_output.put_line('Inserting into GeoPolyRefRevisions');
            INSERT INTO geo_poly_ref_revisions( nkid, entered_by )
            VALUES (l_nkid, entered_by_i)
            RETURNING id INTO l_new_rid;

            retval := l_new_rid;
        ELSE
            --this is a child record, need to get entity nkid
            SELECT a.nkid
            INTO   l_nkid
            FROM   geo_polygons a    -- changed from juris_geo_areas - dlg 12/15/2014
            WHERE  a.id = entity_id_io;

            SELECT ar.id, ar.status, ar.nkid
            INTO   l_curr_rid, l_status, l_nkid
            FROM   geo_poly_ref_revisions ar
            WHERE  ar.nkid = l_nkid
                   AND ar.next_rid IS NULL;

            IF l_status IN (0,1) THEN
                l_new_rid := l_curr_rid;
            ELSE
                INSERT INTO geo_poly_ref_revisions( nkid, entered_by )
                VALUES (l_nkid, entered_by_i)
                RETURNING id INTO l_new_rid;

                UPDATE geo_poly_ref_revisions
                SET    next_rid = l_new_rid
                WHERE  id = l_curr_rid;
            END IF;
        END IF;

        entity_id_io := l_poly_id;
        retval := l_new_rid;
DBMS_OUTPUT.Put_Line( retval );

        RETURN retval;
    END get_revision;


FUNCTION get_area_revision
(
    rid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER
IS
        l_new_rid  NUMBER;
        l_curr_rid NUMBER;
        l_nkid   NUMBER;
        l_nrid   NUMBER;
        l_status NUMBER := -1;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN

        IF (rid_i IS NOT NULL) THEN
            --this is for existing records,
            --they will have existing revision records
            --doesn't matter if it's published or not,
            --just looking for the current revision
            SELECT gr.id, gr.status, gr.nkid
            INTO   l_curr_rid, l_status, l_nkid
            FROM   geo_unique_area_revisions gr
            WHERE  EXISTS (
                            SELECT 1
                            FROM   geo_unique_area_revisions gr2
                            WHERE  gr.nkid = gr2.nkid
                                   AND gr2.id = rid_i
                          )
                   AND gr.next_rid IS NULL;
        END IF;

        IF l_status IN (0,1) THEN
            --This record is already in a pending state.
            --Return its current RID
            retval := l_curr_rid;
        ELSE
            --The current version has been published, create a new one.
            --First, expire the previous version
            INSERT INTO geo_unique_area_revisions( nkid, entered_by )
            VALUES (l_nkid, entered_by_i)
            RETURNING id INTO l_new_rid;

            UPDATE geo_unique_area_revisions
            SET    next_rid = l_new_rid
            WHERE  id = l_curr_rid;

            retval := l_new_rid;
        END IF;

        RETURN retval;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN 0; --ignore error and return no RID, this means that the last change in revision was deleted an so the revision no longer exists
    END get_area_revision;


FUNCTION get_area_revision
(
    entity_id_io  IN OUT NUMBER,
    entity_nkid_i IN NUMBER,
    entered_by_i  IN NUMBER
) RETURN NUMBER
IS
        l_new_rid NUMBER;
        l_area_id NUMBER := entity_id_io;
        l_nkid    NUMBER := entity_nkid_i;
        l_status  NUMBER;
        l_curr_rid NUMBER;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN
        --check for an existing revision
        dbms_output.put_line('l_area_id = ' || l_area_id || ' l_nkid = ' || l_nkid);
        IF (l_area_id IS NOT NULL AND l_nkid IS NOT NULL) THEN
            --dbms_output.put_line('Inserting into GeoUniqueAreaRevisions');
            INSERT INTO geo_unique_area_revisions( nkid, entered_by )
            VALUES (l_nkid, entered_by_i)
            RETURNING id INTO l_new_rid;

            retval := l_new_rid;
        ELSE
            --this is a child record, need to get entity nkid
            SELECT a.nkid
            INTO   l_nkid
            FROM   geo_unique_areas a
            WHERE  a.id = entity_id_io;

            SELECT ar.id, ar.status, ar.nkid
            INTO   l_curr_rid, l_status, l_nkid
from geo_unique_area_revisions ar
--            FROM   geo_poly_ref_revisions ar
            WHERE  ar.nkid = l_nkid
                   AND ar.next_rid IS NULL;

            IF l_status IN (0,1) THEN
                l_new_rid := l_curr_rid;
            ELSE
                INSERT INTO geo_unique_area_revisions( nkid, entered_by )
                VALUES (l_nkid, entered_by_i)
                RETURNING id INTO l_new_rid;

                UPDATE geo_unique_area_revisions
                SET    next_rid = l_new_rid
                WHERE  id = l_curr_rid;
            END IF;
        END IF;

        entity_id_io := l_area_id;
        retval := l_new_rid;
        RETURN retval;
    END get_area_revision;



FUNCTION XMLForm_JurisArea(form_xml_i IN sys.XMLType) RETURN XMLForm_JurisArea_TT
PIPELINED IS
        out_rec XMLFormJurisArea;
        poxml   sys.XMLType;
        i       BINARY_INTEGER := 1;
        l_form_xml   sys.XMLType := form_xml_i;
    BEGIN

        out_rec := XMLFormJurisArea(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

        LOOP
            poxml := l_form_xml.EXTRACT('juris_geo_areas['||i||']');
            EXIT WHEN poxml IS NULL;

            --dbms_output.put_line('Row Count = ' || i);
            SELECT
                x.recid,
                x.juris_id,
                x.poly_id,
                x.req_est,
                TO_DATE(x.start_date) start_date,
                TO_DATE(x.end_date) end_date,
                x.uiuserid,
                x.recrid,
                x.recnkid,
                x.gmodified,
                x.gdeleted
            INTO
                out_rec.id,
                out_rec.jurisdiction_id,
                out_rec.geo_polygon_id,
                out_rec.requires_establishment,
                out_rec.start_date,
                out_rec.end_date,
                out_rec.entered_by,
                out_rec.rid,
                out_rec.nkid,
                out_rec.modified,
                out_rec.deleted
            FROM XMLTABLE (
                '/juris_geo_areas'
                PASSING poxml
                        COLUMNS recid      NUMBER PATH 'id',
                                juris_id   NUMBER PATH 'jurisdiction_id',
                                poly_id    NUMBER PATH 'geo_polygon_id',
                                req_est    NUMBER PATH 'requires_establishment',
                                start_date VARCHAR2(12) PATH 'start_date',
                                end_date   VARCHAR2(12) PATH 'end_date',
                                uiuserid   NUMBER PATH 'entered_by',
                                recrid     NUMBER PATH 'rid',
                                recnkid    NUMBER PATH 'nkid',
                                gmodified  NUMBER PATH 'modified',
                                gdeleted   NUMBER PATH 'deleted'
                          ) x;
            PIPE ROW(out_rec);
            i := i + 1;
        END LOOP;
        RETURN;
        EXCEPTION
            WHEN others THEN
            errlogger.report_and_stop (SQLCODE,'Create of jurisarea_tt failed.');
                RAISE;

    END XMLForm_JurisArea;


PROCEDURE XMLProcess_Form_JurisArea
(
    sx IN CLOB,
    update_success OUT NUMBER,
    rid_o  OUT NUMBER,
    nkid_o OUT NUMBER
)
IS
        area XMLForm_JurisArea_TT := XMLForm_JurisArea_TT();
        tag_list XMLFORM_Tags_TT := XMLFORM_Tags_TT();

        RecCount NUMBER :=0;
        l_upd_success NUMBER := 0;
        l_rid NUMBER;

    BEGIN
        FOR ja_row IN
            ( SELECT *
              FROM   TABLE( CAST( XMLForm_JurisArea( XMLType(sx) ) AS XMLForm_JurisArea_TT))
            )
        LOOP <<juris_area_loop>>
            l_rid := ja_row.rid;
            --dbms_output.put_line('Rid = ' || l_rid);

            area.EXTEND;
            area(area.last) := XMLFormJurisArea
                               (
                                  ja_row.id
                                 ,ja_row.jurisdiction_id
                                 ,ja_row.geo_polygon_id
                                 ,ja_row.requires_establishment
                                 ,ja_row.start_date
                                 ,ja_row.end_date
                                 ,ja_row.entered_by
                                 ,ja_row.rid
                                 ,ja_row.nkid
                                 ,ja_row.modified
                                 ,ja_row.deleted
                               );

            /* Tags */
            FOR itags IN
                (SELECT
                    t.tag_id,
                    t.deleted,
                    t.status
                 FROM XMLTABLE ('/juris_geo_areas/tag'
                                PASSING XMLTYPE(sx)
                                COLUMNS tag_id   NUMBER PATH 'tag_id',
                                        deleted  NUMBER PATH 'deleted',
                                        status   NUMBER PATH 'status'
                               ) t
                )
            LOOP
              tag_list.extend;
              tag_list( tag_list.last ):= xmlform_tags( 10,
                                                        area(area.last).nkid,
                                                        area(area.last).entered_by,
                                                        itags.tag_id,
                                                        itags.deleted,
                                                        0
                                                      );
            END LOOP ;

            gis.update_full_juris_area(area(area.LAST), tag_list, rid_o, nkid_o);
            rid_o := l_rid;
        END LOOP juris_area_loop;

        l_upd_success := 1;
        update_success := l_upd_success;
        EXCEPTION
            WHEN others THEN
                ROLLBACK;
                errlogger.report_and_stop (SQLCODE,'Process of jurisarea_tt failed.');
                RAISE;

    END XMLProcess_Form_JurisArea;


PROCEDURE update_full_juris_area
(
    details_i IN XMLFormJurisArea,
    tag_list  IN XMLForm_Tags_TT,
    rid_o  OUT NUMBER,
    nkid_o OUT NUMBER
)
IS
        l_ja_pk  NUMBER := details_i.id;
        l_nkid_o NUMBER;
    BEGIN

        IF (NVL(details_i.modified, 0) = 1) THEN
            gis.update_record_juris_area(
                    id_io        => l_ja_pk,
                    juris_id_i   => details_i.jurisdiction_id,
                    polygon_id_i => details_i.geo_polygon_id,
                    req_est_i    => details_i.requires_establishment,
                    start_date_i => details_i.start_date,
                    end_date_i   => details_i.end_date,
                    entered_by_i => details_i.entered_by,
                    rid_o  => rid_o,
                    nkid_o => l_nkid_o
                    );
        END IF;

        DBMS_OUTPUT.Put_Line( 'Returned l_ja_pk:'||l_ja_pk );
        IF (nkid_o IS NULL) THEN
            --DBMS_OUTPUT.Put_Line( 'NKID based on l_ja_pk:'||l_ja_pk );
            SELECT nkid
            INTO nkid_o
            FROM geo_polygons
            WHERE id = l_ja_pk;
        DBMS_OUTPUT.Put_Line( 'NKID based on l_ja_pk:'||nkid_o );
        END IF;

        -- Handle tags
        tags_registry.tags_entry(tag_list, nkid_o);

        -- Return values
        nkid_o := l_nkid_o;

        DBMS_OUTPUT.Put_Line( 'Current Rev:'||nkid_o);

        rid_o := get_current_revision(p_nkid=> nkid_o);
        DBMS_OUTPUT.Put_Line( 'Current Rev RID:'||rid_o);
    EXCEPTION
        WHEN errnums.child_exists THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,'Requested delete but child records exist.');
        WHEN others THEN
            ROLLBACK;
            RAISE;
    END update_full_juris_area;


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
)
IS
        l_ja_pk NUMBER := id_io;
        l_juris_id   juris_geo_areas.jurisdiction_id%TYPE := juris_id_i;
        l_polygon_id juris_geo_areas.geo_polygon_id%TYPE := polygon_id_i;
        l_req_est_i  juris_geo_areas.requires_establishment%TYPE := req_est_i;
        l_start_date juris_geo_areas.start_date%TYPE := start_date_i;
        l_end_date   juris_geo_areas.end_date%TYPE := end_date_i;
        l_entered_by NUMBER := entered_by_i;
        l_status     NUMBER := -1;
        l_current_pending NUMBER;
    BEGIN
        --business validation
        IF (l_juris_id IS NULL) OR (l_polygon_id IS NULL) THEN
            RAISE errnums.missing_req_val;
        END IF;

        dbms_output.put_line('l_ja_pk = ' || l_ja_pk);
        IF (l_ja_pk IS NOT NULL) THEN
            dbms_output.put_line('Updating');

            UPDATE juris_geo_areas ji
            SET
                ji.jurisdiction_id = l_juris_id,
                ji.geo_polygon_id = l_polygon_id,
                ji.requires_establishment = l_req_est_i,
                ji.start_date = l_start_date,
                ji.end_date   = l_end_date,
                ji.entered_by = l_entered_by
            WHERE ji.id = l_ja_pk
            RETURNING nkid INTO nkid_o;
        ELSE
            dbms_output.put_line('Inserting');
            INSERT INTO juris_geo_areas
            (
                jurisdiction_id,
                geo_polygon_id,
                requires_establishment,
                start_date,
                end_date,
                entered_by
            ) VALUES (
                l_juris_id,
                l_polygon_id,
                l_req_est_i,
                l_start_date,
                l_end_date,
                l_entered_by
                )
            RETURNING geo_polygon_id, rid, nkid INTO l_ja_pk, rid_o, nkid_o;

        END IF;

       id_io :=l_ja_pk;
    EXCEPTION
        WHEN errnums.missing_req_val THEN
            ROLLBACK;
            errlogger.report_and_stop (errnums.en_missing_req_val,'Key elements missing for record.');
        WHEN errnums.cannot_update_record THEN
            ROLLBACK;
            errlogger.report_and_stop  (errnums.en_cannot_update_record,'Record could not be updated because it does not match the pending record :)');
        WHEN no_data_found THEN
            ROLLBACK;
            errlogger.report_and_go (SQLCODE,'Record could not be updated because the ID was not found.');
        WHEN others THEN
            ROLLBACK;
            RAISE;

    END update_record_juris_area;


    FUNCTION get_current_revision (p_nkid IN NUMBER) RETURN NUMBER
    IS
        l_curr_rid NUMBER;
        l_juris_id NUMBER;
        l_nkid     NUMBER;
        l_nrid     NUMBER;
        l_status   NUMBER := -1;
        retval     NUMBER := -1;
        RETURN NUMBER;
    BEGIN
        IF (p_nkid IS NOT NULL) THEN
            SELECT pr.id, pr.status, pr.nkid
            INTO   l_curr_rid, l_status, l_nkid
            FROM   geo_poly_ref_revisions pr
            WHERE EXISTS (
                SELECT 1
                FROM   geo_poly_ref_revisions pr2
                WHERE  pr.nkid = pr2.nkid
                       AND pr2.nkid = p_nkid
                )
            AND pr.next_rid IS NULL;
            retval := l_curr_rid;
        END IF;
        RETURN retval;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN 0; --ignore error and return no RID, this means that the last change in revision was deleted an so the revision no longer exists
    END get_current_revision;

    FUNCTION get_cur_area_revision (p_nkid IN NUMBER) RETURN NUMBER
    IS
        l_curr_rid NUMBER;
        l_juris_id NUMBER;
        l_nkid     NUMBER;
        l_nrid     NUMBER;
        l_status   NUMBER := -1;
        retval     NUMBER := -1;
        RETURN NUMBER;
    BEGIN
        IF (p_nkid IS NOT NULL) THEN
            SELECT pr.id, pr.status, pr.nkid
            INTO   l_curr_rid, l_status, l_nkid
            FROM   geo_unique_area_revisions pr
            WHERE EXISTS (
                SELECT 1
                FROM   geo_unique_area_revisions pr2
                WHERE  pr.nkid = pr2.nkid
                       AND pr2.nkid = p_nkid
                )
            AND pr.next_rid IS NULL;
            retval := l_curr_rid;
        END IF;
        RETURN retval;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN 0; --ignore error and return no RID, this means that the last change in revision was deleted an so the revision no longer exists
    END get_cur_area_revision;




  /**     Boundary Form
  */
  Procedure XMLBoundary_Form(sx in CLOB, success OUT NUMBER, rid_o OUT NUMBER, nkid_o OUT NUMBER)
  is
    errmsg clob:='';        -- ORA Log error message
    l_process_id number;    -- internal process id
    l_crud number;          -- local update/delete/insert flag
    header_id number;

    pStart_time number;     -- process start time (internal use)
    pEnd_time number;       -- process end time
    n_rec_count number;     -- record count
    vExists number:=0;
    DB_Action number:=0;
    tag_list xmlform_tags_tt := xmlform_tags_tt();
    att_list XMLForm_Attr_TT := XMLForm_Attr_TT();
  Begin
    success:=0;
    -- Get a process id (log)
    l_process_id := gis_xml_process_sq.nextval;
    insert into gis_xml_process_t(process_id, xmlSet) values(l_process_id,sx);

    DBMS_OUTPUT.Put_Line( 'Process:'||l_process_id );
    if dbms_lob.getlength(sx)>1 then

        /* Internal use only : Get what ID should be used */
        SELECT q.id into header_id From
            xmltable('/boundary'
            passing xmltype(sx)
            columns
            id number path 'id') q;

        -- Associated Entities
        SELECT
            h.ac_id,
            h.ac_nkid,
            h.ac_rid,
            h.ac_jurisdiction_id,
            h.ac_official_name,
            h.ac_location_category_id,
            h.ac_start_date,
            h.ac_end_date,
            h.ac_requires_establishment,
            h.ac_modified,
            h.ac_deleted
            ,q.id
            ,q.geo_area_key
            ,q.start_date
            ,q.end_date
            ,q.entered_by
            ,q.geo_area_category_id
        BULK COLLECT INTO r_T_gis_boundary
        FROM XMLTable('for $i in /boundary/associated_entities return $i'
            passing
            xmltype(sx)
            columns
                ac_id number path 'id',
                ac_nkid number path 'nkid',
                ac_rid number path 'rid',
                ac_jurisdiction_id number path 'jurisdiction_id',
                ac_official_name varchar2(500) path 'official_name',
                ac_location_category_id number path 'location_category_id',
                ac_start_date varchar2(11) path 'start_date',
                ac_end_date varchar2(11) path 'end_date',
                ac_requires_establishment number path 'requires_establishment',
                ac_modified number path 'modified',
                ac_deleted number path 'deleted'
            ) h,
            xmltable('/boundary'
            passing xmltype(sx)
            columns
                id number path 'id',
                geo_area_key varchar2(500) path 'geo_area_key',
                start_date varchar2(11) path 'start_date',
                end_date varchar2(11) path 'end_date',
                entered_by number path 'entered_by',
                geo_area_category_id number path 'geo_area_category_id'
            ) q;


        SELECT
            h.at_id,
            h.at_nkid,
            h.at_rid,
            h.at_value,
            h.at_attribute_id,
            h.at_attribute_category_id,
            h.at_start_date,
            h.at_end_date,
            h.at_modified,
            h.at_deleted
            ,q.id
            ,q.rid
            ,q.nkid
            ,q.entered_by
        BULK COLLECT INTO r_T_gis_pp
        FROM XMLTable('for $i in /boundary/attribute return $i'
              passing
              xmltype(sx)
              columns
              at_id number path 'id',
              at_nkid number path 'nkid',
              at_rid number path 'rid',
              at_value varchar2(1) path 'value',
              at_attribute_id number path 'attribute_id',
              at_attribute_category_id number path 'attribute_category_id',
              at_start_date varchar2(11) path 'start_date',
              at_end_date varchar2(11) path 'end_date',
              at_modified number path 'modified',
              at_deleted number path 'deleted'
              ) h,
              xmltable('/boundary'
              passing xmltype(sx)
              columns
              id number path 'id',
              nkid number path 'nkid',
              rid number path 'rid',
              entered_by number path 'entered_by'
              ) q;

        -- tags
        SELECT
            h.tag_id,
            h.status,
            h.deleted,
            q.id,
            q.entered_by
        BULK COLLECT INTO r_T_Gis_Tags
        FROM XMLTable('for $i in /boundary/tag return $i'
            passing
            xmltype(sx)
            columns
                tag_id number path 'tag_id',
                status number path 'status',
                deleted number path 'deleted'
            ) h,
            xmltable('/boundary'
            passing xmltype(sx)
            columns
                id number path 'id',
                entered_by number path 'entered_by'
            ) q;


        /* Process Header and associated */
        if r_T_gis_boundary.count>0 then
            for i
                in r_T_gis_boundary.First..r_T_gis_boundary.Last
            loop
                -- spool
                DBMS_OUTPUT.Put_Line( 'GIS ID:'||r_T_gis_boundary(i).id );
                DBMS_OUTPUT.Put_Line( 'Associated:'||r_T_gis_boundary(i).ac_jurisdiction_id );

                -- Header
                if r_T_gis_boundary(i).ac_id is null then
                    Insert Into juris_geo_areas(JURISDICTION_ID, GEO_POLYGON_ID, START_DATE, END_DATE, REQUIRES_ESTABLISHMENT, ENTERED_BY)
                    values
                        (r_T_gis_boundary(i).ac_jurisdiction_id,
                        r_T_gis_boundary(i).id,
                        r_T_gis_boundary(i).ac_start_date,
                        r_T_gis_boundary(i).ac_end_date,
                        r_T_gis_boundary(i).requires_establishment,
                        r_T_gis_boundary(i).entered_by)
                    returning rid, nkid into rid_o, nkid_o;
                    -- geo_polygon_nkid handled by trigger
                    DB_Action:=0;
                else
                    if (r_T_gis_boundary(i).ac_modified=1 and r_T_gis_boundary(i).ac_deleted=0) then
                        UPDATE juris_geo_areas jga
                        SET jga.start_date      = r_T_gis_boundary(i).ac_start_date,
                            jga.end_date        = r_T_gis_boundary(i).ac_end_date,
                            jga.entered_by      = r_T_gis_boundary(i).entered_by,
                            jga.jurisdiction_id = r_T_gis_boundary(i).ac_jurisdiction_id,
                            jga.requires_establishment = r_T_gis_boundary(i).requires_establishment
                        WHERE jga.id = r_T_gis_boundary(i).ac_id
                        returning rid, nkid into rid_o, nkid_o;
                    end if;

                    if r_T_gis_boundary(i).ac_deleted=1 then
                        DBMS_OUTPUT.Put_Line( 'DEL' );

                        DELETE FROM juris_geo_areas jga
                        where jga.id = r_T_gis_boundary(i).ac_id;
                    end if;

                    DB_Action:=1;
                end if;


                if rid_o is not null then
                    Insert into gis_xml_process_t
                        (process_id, rid_p, nkid_p,action,process_date)
                    values(l_process_id, rid_o, nkid_o, DB_Action, sysdate);
                end if;
                success:=1;
            end loop;
        end if;
    else
        errmsg:='No XML to process';
        success:=0;
    end if;

    -- Attributes
    --r_T_gis_pp
    if r_T_gis_pp.count>0 then
        for i
            in r_T_gis_pp.First..r_T_gis_pp.Last
        loop
            -- spool
            DBMS_OUTPUT.Put_Line( 'ID:'||r_T_gis_pp(i).id );
            DBMS_OUTPUT.Put_Line( 'Attribute:'||r_T_gis_pp(i).at_id);

            -- Header
            if r_T_gis_pp(i).at_id is null then

                DBMS_OUTPUT.Put_Line( 'Insert Into geo_poly_attributes(geo_polygon_id, attribute_id, value, start_date, end_date, entered_by)
                    values
                        ('||r_T_gis_pp(i).id||','||
                        r_T_gis_pp(i).at_attribute_id||','||
                        r_T_gis_pp(i).at_value||','||
                        r_T_gis_pp(i).at_start_date||','||
                        r_T_gis_pp(i).at_end_date||','||
                        r_T_gis_pp(i).entered_by||')');

                Insert Into geo_poly_attributes(geo_polygon_id, attribute_id, value, start_date, end_date, entered_by)
                values
                    (r_T_gis_pp(i).id,
                    r_T_gis_pp(i).at_attribute_id,
                    r_T_gis_pp(i).at_value,
                    r_T_gis_pp(i).at_start_date,
                    r_T_gis_pp(i).at_end_date,
                    r_T_gis_pp(i).entered_by)
                returning rid, nkid into rid_o, nkid_o;
                DB_Action:=0;
            else

                if (r_T_gis_pp(i).at_modified=1 and r_T_gis_pp(i).at_deleted=0) then
                    Update geo_poly_attributes jga
                    SET jga.start_date   = r_T_gis_pp(i).at_start_date,
                        jga.end_date     = r_T_gis_pp(i).at_end_date,
                        jga.entered_by   = r_T_gis_pp(i).entered_by,
                        jga.attribute_id = r_T_gis_pp(i).at_attribute_id,
                        jga.value        = r_T_gis_pp(i).at_value
                    WHERE jga.id = r_T_gis_pp(i).at_id
                    returning rid, nkid into rid_o, nkid_o;
                end if;

                if r_T_gis_pp(i).at_deleted=1 then
                    Delete_Boundary_Attribute(r_T_gis_pp(i).at_id, r_T_gis_pp(i).entered_by);
                end if;

                DB_Action:=1;
            end if;

            --
            /* if rid_o is not null then
             Insert into gis_xml_process_t
             (process_id, rid_p, nkid_p,action,process_date)
              values(l_process_id, rid_o, nkid_o, DB_Action, sysdate);
            end if;*/
            success:=1;
        end loop;
    end if;

    -- tags
    -- (Different nkid variables should have been used here)
    if r_T_GIS_Tags.count>0 then
        for nx in r_T_GIS_Tags.First..r_T_GIS_Tags.Last loop
            --cluge
            SELECT nkid
            INTO nkid_o
            FROM geo_polygons
            WHERE id = header_id;

            tag_list.extend;
            tag_list( tag_list.last ):=xmlform_tags(
                10,
                nkid_o,
                r_T_GIS_Tags(nx).entered_by,
                r_T_GIS_Tags(nx).tag_id,
                r_T_GIS_Tags(nx).deleted,
                0);
        end loop;
        tags_registry.tags_entry(tag_list, nkid_o);
    end if;

    -- Return values
    -- ToDo: Need a function to return success/fail in a better way
    if header_id is not null then
        SELECT nkid
        INTO nkid_o
        FROM geo_polygons
        WHERE id = header_id;

        rid_o := get_current_revision(p_nkid=> nkid_o);
        if rid_o<>0 then
            success:= 1;
        else
            success:= 0;
        end if;
        DBMS_OUTPUT.Put_Line( 'Return rid:'||rid_o );
    end if;

  End XMLBoundary_Form;


  /**     Unique Area Form
  */
  Procedure XMLUniqueArea_Form(sx in CLOB, success OUT NUMBER, rid_o OUT NUMBER, nkid_o OUT NUMBER)
  IS
    /*
        Updated on 09/14/2015 -- crapp-2044
        -- XML format change - splitting "Jurisdiction Overrides" and "Attributes" into their own sections
    */
    errmsg clob:='';        -- ORA Log error message
    l_process_id number;    -- internal process id
    l_crud number;          -- local update/delete/insert flag
    header_id number;

    pStart_time number;     -- process start time (internal use)
    pEnd_time number;       -- process end time
    n_rec_count number;     -- record count
    vExists number:=0;
    DB_Action number:=0;
    n_juris_ovd_AttribID number:=0;
    tag_list xmlform_tags_tt := xmlform_tags_tt();

  Begin
    success:=0;
    -- Get a process id (log)
    l_process_id := gis_xml_process_sq.nextval;
    insert into gis_xml_process_t(process_id, xmlSet) values(l_process_id,sx);

    DBMS_OUTPUT.Put_Line( 'Process:'||l_process_id );
    if dbms_lob.getlength(sx)>1 then

        SELECT q.id, q.rid, q.nkid
        INTO header_id, rid_o, nkid_o
        FROM xmltable('/unique_area'
            passing xmltype(sx)
            columns
                id number path 'id',
                rid number path 'rid',
                nkid number path 'nkid'
            ) q;


        -- Jurisdiction Overrides - crapp-2044
        SELECT id INTO n_juris_ovd_AttribID FROM additional_attributes WHERE name = 'Jurisdiction Override';
        SELECT
            h.at_id,
            h.at_nkid,
            h.at_rid,
            h.at_value,
            n_juris_ovd_AttribID,   -- attribute_id
            h.at_attribute_category_id,
            h.at_start_date,
            h.at_end_date,
            h.at_modified,
            h.at_deleted
            ,q.id
            ,q.rid
            ,q.nkid
            ,q.entered_by
        BULK COLLECT INTO r_T_gis_uqa_jo
        FROM XMLTable('for $i in /unique_area/jurisdiction_overrides return $i'
            passing
            xmltype(sx)
            columns
                at_id number path 'id',
                at_nkid number path 'nkid',
                at_rid number path 'rid',
                at_value number path 'value_id',
                --at_attribute_id number path 'attribute_id',
                at_attribute_category_id number path 'attribute_category_id',
                at_start_date varchar2(11) path 'start_date',
                at_end_date varchar2(11) path 'end_date',
                at_modified number path 'modified',
                at_deleted number path 'deleted'
            ) h,
            xmltable('/unique_area'
            passing xmltype(sx)
            columns
                id number path 'id',
                nkid number path 'nkid',
                rid number path 'rid',
                entered_by number path 'entered_by'
            ) q;


        -- Attributes
        SELECT
            h.at_id,
            h.at_nkid,
            h.at_rid,
            h.at_value,
            h.at_attribute_id,
            h.at_attribute_category_id,
            h.at_start_date,
            h.at_end_date,
            h.at_modified,
            h.at_deleted
            ,q.id
            ,q.rid
            ,q.nkid
            ,q.entered_by
        BULK COLLECT INTO r_T_gis_uqa
        FROM XMLTable('for $i in /unique_area/attribute return $i'
            passing
            xmltype(sx)
            columns
                at_id number path 'id',
                at_nkid number path 'nkid',
                at_rid number path 'rid',
                at_value VARCHAR2(100) path 'value',
                at_attribute_id number path 'attribute_id',
                at_attribute_category_id number path 'attribute_category_id',
                at_start_date varchar2(11) path 'start_date',
                at_end_date varchar2(11) path 'end_date',
                at_modified number path 'modified',
                at_deleted number path 'deleted'
            ) h,
            xmltable('/unique_area'
            passing xmltype(sx)
            columns
                id number path 'id',
                nkid number path 'nkid',
                rid number path 'rid',
                entered_by number path 'entered_by'
            ) q;


        -- tags
        SELECT
            h.tag_id,
            h.status,
            h.deleted,
            q.id,
            q.entered_by
        BULK COLLECT INTO r_T_Gis_Tags
        FROM XMLTable('for $i in /unique_area/tag return $i'
            passing
            xmltype(sx)
            columns
                tag_id number path 'tag_id',
                status number path 'status',
                deleted number path 'deleted'
            ) h,
            xmltable('/unique_area'
            passing xmltype(sx)
            columns
                id number path 'id',
                entered_by number path 'entered_by'
            ) q;


        /* Process Jurisdiction Overrides */
        if r_T_gis_uqa_jo.count>0 then
            for i
                in r_T_gis_uqa_jo.First..r_T_gis_uqa_jo.Last
            loop
                -- spool
                DBMS_OUTPUT.Put_Line( 'Area ID:'||r_T_gis_uqa_jo(i).id );
                DBMS_OUTPUT.Put_Line( 'Attribute:'||r_T_gis_uqa_jo(i).at_id);

                if r_T_gis_uqa_jo(i).at_id is null then
                    DBMS_OUTPUT.Put_Line( 'Insert Into geo_unique_area_attributes(geo_unique_area_id, attribute_id, value,
                        start_date, end_date, entered_by, rid)
                        values
                            ('||r_T_gis_uqa_jo(i).id||','||
                            r_T_gis_uqa_jo(i).at_attribute_id||','||
                            r_T_gis_uqa_jo(i).at_value||','||
                            r_T_gis_uqa_jo(i).at_start_date||','||
                            r_T_gis_uqa_jo(i).at_end_date||','||
                            r_T_gis_uqa_jo(i).entered_by||', null)');

                    Insert Into geo_unique_area_attributes(geo_unique_area_id, attribute_id, value, start_date, end_date, entered_by, rid)
                    values
                        (r_T_gis_uqa_jo(i).id,
                        r_T_gis_uqa_jo(i).at_attribute_id,
                        r_T_gis_uqa_jo(i).at_value,
                        r_T_gis_uqa_jo(i).at_start_date,
                        r_T_gis_uqa_jo(i).at_end_date,
                        r_T_gis_uqa_jo(i).entered_by, null );
                    --returning rid, nkid into rid_o, nkid_o;
                    DB_Action:=0;
                    success:=1;
                else

                    if (r_T_gis_uqa_jo(i).at_modified=1 and r_T_gis_uqa_jo(i).at_deleted=0) then
                        UPDATE geo_unique_area_attributes jga
                        SET jga.start_date   = r_T_gis_uqa_jo(i).at_start_date,
                            jga.end_date     = r_T_gis_uqa_jo(i).at_end_date,
                            jga.entered_by   = r_T_gis_uqa_jo(i).entered_by,
                            jga.attribute_id = r_T_gis_uqa_jo(i).at_attribute_id,
                            jga.value = r_T_gis_uqa_jo(i).at_value
                        WHERE jga.id = r_T_gis_uqa_jo(i).at_id;
                        --returning rid, nkid into rid_o, nkid_o;
                    end if;

                    if r_T_gis_uqa_jo(i).at_deleted=1 then
                        Delete_Unique_Attribute(r_T_gis_uqa_jo(i).at_id, r_T_gis_uqa_jo(i).entered_by);
                    end if;
                    success:=1;
                    DB_Action:=1;
                end if;

                if rid_o is not null then
                    Insert into gis_xml_process_t (process_id, rid_p, nkid_p, action, process_date)
                    values(l_process_id, rid_o, nkid_o, DB_Action, sysdate);
                end if;

                success:=1;
            end loop;
        end if;

        /* Process Attributes */
        if r_T_gis_uqa.count>0 then
            for i
                in r_T_gis_uqa.First..r_T_gis_uqa.Last
            loop
                -- spool
                DBMS_OUTPUT.Put_Line( 'Area ID:'||r_T_gis_uqa(i).id );
                DBMS_OUTPUT.Put_Line( 'Attribute:'||r_T_gis_uqa(i).at_id);

                if r_T_gis_uqa(i).at_id is null then
                    DBMS_OUTPUT.Put_Line( 'Insert Into geo_unique_area_attributes(geo_unique_area_id, attribute_id, value,
                        start_date, end_date, entered_by, rid)
                        values
                            ('||r_T_gis_uqa(i).id||','||
                            r_T_gis_uqa(i).at_attribute_id||','||
                            r_T_gis_uqa(i).at_value||','||
                            r_T_gis_uqa(i).at_start_date||','||
                            r_T_gis_uqa(i).at_end_date||','||
                            r_T_gis_uqa(i).entered_by||', null)');

                    Insert Into geo_unique_area_attributes(geo_unique_area_id, attribute_id, value, start_date, end_date, entered_by, rid)
                    values
                        (r_T_gis_uqa(i).id,
                        r_T_gis_uqa(i).at_attribute_id,
                        r_T_gis_uqa(i).at_value,
                        r_T_gis_uqa(i).at_start_date,
                        r_T_gis_uqa(i).at_end_date,
                        r_T_gis_uqa(i).entered_by, null );
                    --returning rid, nkid into rid_o, nkid_o;
                    DB_Action:=0;
                    success:=1;
                else

                    if (r_T_gis_uqa(i).at_modified=1 and r_T_gis_uqa(i).at_deleted=0) then
                        UPDATE geo_unique_area_attributes jga
                        SET jga.start_date   = r_T_gis_uqa(i).at_start_date,
                            jga.end_date     = r_T_gis_uqa(i).at_end_date,
                            jga.entered_by   = r_T_gis_uqa(i).entered_by,
                            jga.attribute_id = r_T_gis_uqa(i).at_attribute_id,
                            jga.value = r_T_gis_uqa(i).at_value
                        WHERE jga.id = r_T_gis_uqa(i).at_id;
                        --returning rid, nkid into rid_o, nkid_o;
                    end if;

                    if r_T_gis_uqa(i).at_deleted=1 then
                        Delete_Unique_Attribute(r_T_gis_uqa(i).at_id, r_T_gis_uqa(i).entered_by);
                    end if;
                    success:=1;
                    DB_Action:=1;
                end if;

                if rid_o is not null then
                    Insert into gis_xml_process_t (process_id, rid_p, nkid_p, action, process_date)
                    values(l_process_id, rid_o, nkid_o, DB_Action, sysdate);
                end if;

                success:=1;
            end loop;
        end if;

    else
        errmsg:='No XML to process';
        success:=0;
    end if;

    -- tags
    if r_T_GIS_Tags.count>0 then
        for nx in r_T_GIS_Tags.First..r_T_GIS_Tags.Last loop
            --cluge
            SELECT nkid
            INTO nkid_o
            FROM geo_unique_areas
            WHERE id = header_id;

            tag_list.extend;
            tag_list( tag_list.last ):=xmlform_tags(
                11,
                nkid_o,
                r_T_GIS_Tags(nx).entered_by,
                r_T_GIS_Tags(nx).tag_id,
                r_T_GIS_Tags(nx).deleted,
                0);
        end loop;
        tags_registry.tags_entry(tag_list, nkid_o);
    end if;

    -- Return values
    rid_o := get_cur_area_revision(p_nkid=> nkid_o);

    DBMS_OUTPUT.Put_Line( 'Flag:'||success||' RID:'||rid_o||' NKID:'||nkid_o );
  END XMLUniqueArea_Form;

  --
  Procedure Delete_Unique_Attribute(
    id_i IN NUMBER,
    deleted_by_i IN NUMBER
  )
  IS
    l_att_id NUMBER := id_i;
    l_deleted_by NUMBER := deleted_by_i;
    l_juris_id NUMBER;
    l_tax_desc_id NUMBER;
    l_rid NUMBER;
    l_nkid NUMBER;
  BEGIN
    INSERT INTO tmp_delete(table_name, primary_key) VALUES ('GEO_UNIQUE_AREA_ATTRIBUTES',l_att_id);

    DELETE FROM geo_unique_area_attributes ja
    WHERE ja.id = l_att_id
    RETURNING rid, nkid INTO l_rid, l_nkid;

    INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
           SELECT table_name, primary_key, l_deleted_by
           FROM tmp_delete
    );

    UPDATE geo_unique_area_attributes jta
       SET next_Rid = NULL
     WHERE jta.next_rid = l_rid
       AND jta.nkid = l_nkid;
  EXCEPTION
       WHEN others THEN
       ROLLBACK;
       errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_i);
  END Delete_Unique_Attribute;

  Procedure Delete_Boundary_Attribute(
    id_i IN NUMBER,
    deleted_by_i IN NUMBER
  )
  IS
    l_att_id NUMBER := id_i;
    l_deleted_by NUMBER := deleted_by_i;
    l_juris_id NUMBER;
    l_tax_desc_id NUMBER;
    l_rid NUMBER;
    l_nkid NUMBER;
  BEGIN
    INSERT INTO tmp_delete(table_name, primary_key) VALUES ('GEO_POLY_ATTRIBUTES',l_att_id);

    DELETE FROM GEO_POLY_ATTRIBUTES ja
    WHERE ja.id = l_att_id
    RETURNING rid, nkid INTO l_rid, l_nkid;

    INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
           SELECT table_name, primary_key, l_deleted_by
           FROM tmp_delete
    );

    UPDATE GEO_POLY_ATTRIBUTES jta
       SET next_Rid = NULL
     WHERE jta.next_rid = l_rid
       AND jta.nkid = l_nkid;
  EXCEPTION
       WHEN others THEN
       ROLLBACK;
       errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_i);
  END Delete_Boundary_Attribute;

  -- CRAPP-1348
  FUNCTION UI_Get_Zip(pZipCode IN varchar2) RETURN dtUIGetZip PIPELINED
  IS
    dataRecord dsUIGetZip;
    cursor_ui SYS_REFCURSOR;
    l_process_id number;
    l_cpy_type number;
  begin
    refGet_Zip(pZipCode, cursor_ui);
    IF cursor_ui%ISOPEN THEN
      LOOP
        FETCH cursor_ui INTO dataRecord;
        EXIT WHEN cursor_ui%NOTFOUND;
        PIPE row(dataRecord);
      END LOOP;
      CLOSE cursor_ui;
    END IF;
  end UI_Get_Zip;

  procedure refGet_Zip(pZipCode IN varchar2, p_ref OUT SYS_REFCURSOR)
  is
    eSQL CLOB := 'SELECT distinct
                  p.id ID,
                  u.state_name,
                  u.county_name,
                  u.city_name city_name,
                  NVL (u.zip, ''-'') zip,
                  NVL (SUBSTR(u.zip9, 6, 4), ''-'') plus4_range,
                  CASE WHEN u.override_rank = 1 THEN ''Yes'' ELSE ''No'' END
                  default_flag,
                  gua2.id UNIQUE_AREA_ID,
                  gua2.rid UNIQUE_AREA_RID,
                  gua2.nkid UNIQUE_AREA_NKID,
                  gua.UNIQUE_AREA,
                  p.rid,
                  p.nkid,
                  p.next_rid,
                  u.start_date USPS_START_DATE,
                  u.end_date USPS_END_DATE,
                  u.state_code
                  FROM geo_usps_lookup u
                  JOIN geo_polygons p
                       ON (p.id = u.geo_polygon_id)
                  JOIN geo_poly_ref_revisions r
                       ON (    r.nkid = p.nkid
                  AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) =
                        1)
                  JOIN hierarchy_levels hl
                       ON (p.hierarchy_level_id = hl.id)
                  LEFT JOIN vgeo_unique_areas2 gua ON (    u.state_code   = gua.state_code
                                               AND u.county_name  = gua.county_name
                                               AND u.city_name    = gua.city_name
                                               AND NVL(u.zip, -1) = NVL (gua.zip, -1)
                                               AND NVL2(SUBSTR(u.zip9, 6, 4), (u.zip || SUBSTR(u.zip9, 6, 4)), -1) = NVL(gua.zip9, -1)
                                              )
                  JOIN geo_unique_areas gua2 ON (gua2.area_id = gua.area_id)';
  begin
    if length(pZipCode)>5 then
      eSQL:=eSQL||' WHERE u.zip9= :pZipCode ';
    else
      eSQL:=eSQL||' WHERE u.zip= :pZipCode ';
    end if;
    OPEN p_ref FOR eSQL USING pZipCode;
  end;


    -- 10/24/17 - CRAPP-3797 --
    PROCEDURE gis_process_etl(stcode_i VARCHAR2, instance_grp_i NUMBER, preview_i NUMBER DEFAULT 0, compliance_i NUMBER DEFAULT 1) IS
        -- ***************************************************************************** --
        -- Process GIS ETL by calling the appropriate procedures in the correct order    --
        --  Parameters:                                                                  --
        --  - stcode_i       - 2 character abbbreviation of the State (XX = ALL states)  --
        --  - instance_grp_i - ID value of ETL INSTANCE                                  --
        --  - preview_i      - (make_changes_i) Preview flag (0 = Preview, 1 = LOAD)     --
        --  - compliance_i   - Compliance Area Only flag (1 = False, 0 = True)           --
        --                                                                               --
        -- Example of Compliance Only JSON from UI                                       --
        -- {"instance":"9","state":"WY","preview":"0","compliance":"0","entered_by":326} --
        -- ***************************************************************************** --
        vExecString     VARCHAR2(2000 CHAR);
        vSchemaName     VARCHAR2(50 CHAR);
        vMsg            VARCHAR2(500 CHAR);
        vHost           VARCHAR2(10 CHAR);  -- crapp-3797
        vInst           VARCHAR2(50 CHAR);  -- crapp-3797
        vExportedStates NUMBER := 0;
        vDupes          NUMBER := 0;
        vTotalDupes     NUMBER := 0;
        vAreaAuths      NUMBER := 0;
        vUserID         NUMBER := 0;
        vJobID          NUMBER := 0;
        vpID            NUMBER := gis_etl_process_log_sq.NEXTVAL;
        vVintage        DATE;               -- crapp-3797
    BEGIN
        SELECT MIN(id) id
        INTO   vJobID
        FROM   crapp_admin.scheduled_task
        WHERE  status = 1
               AND method = 'export'
               AND PARAMETERS LIKE '{"instance":"%'||instance_grp_i||'%"state":%'||stcode_i||'"%"preview":%'||preview_i||'%'
               AND task_end IS NULL;

        SELECT SUBSTR(PARAMETERS, INSTR(PARAMETERS,'entered_by')+12, LENGTH(PARAMETERS)-(INSTR(PARAMETERS,'entered_by')+12)) userid
        INTO   vUserID
        FROM   crapp_admin.scheduled_task
        WHERE  id = vJobID;
        gis_etl_p(vpID, stcode_i, 'gis_process_etl, instance = '||instance_grp_i||', preview = '||preview_i||', compliance = '||compliance_i, 0, vUserID);

        -- Determine the Server Host --
        SELECT NVL(h.displayname, 'N/A') dsphost
        INTO   vHost
        FROM dual d
             LEFT JOIN geo_etl_server_hosts h ON (h.serverhost = SYS_CONTEXT('USERENV', 'SERVER_HOST'));

        -- Determine the Schema based on the Instance Group ID --
        SELECT schema_name, instance_name
        INTO   vSchemaName, vInst
        FROM   vetl_instance_groups
        WHERE  gis_flag = 'Y'
               AND instance_group_id = instance_grp_i;

        -- Determine if this is a Compliance Only run --
        IF compliance_i = 0 THEN
            gis_etl_p(vpID, stcode_i, ' - Compliance Only process, preview = '||preview_i, 0, vUserID);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_tb_comp_area_dupe_tmp DROP STORAGE';

            -- Get list of states exported in the last 35 days --
            IF stcode_i = 'XX' THEN
                SELECT COUNT(1) cnt
                INTO vExportedStates
                FROM   (
                        SELECT DISTINCT SUBSTR(parameters, INSTR(parameters,'"state"')+9, 2) st     -- 06/23/17, changed to reflect the 2 digit Instance value
                        FROM   crapp_admin.scheduled_task
                        WHERE  status = 2
                               AND method = 'export'
                               AND (PARAMETERS LIKE '{"instance":"'||instance_grp_i||'%"preview":"1"%'
                                    OR PARAMETERS LIKE '{"instance":"'||'1'||'%"preview":"1"%'      -- remove after crapp-3025 rolled to PROD
                                   )
                               AND task_end >= TRUNC(SYSDATE)-35
                               AND SUBSTR(parameters, INSTR(parameters,'"state"')+9, 2) != 'XX'     -- 06/23/17, changed to reflect the 2 digit Instance value
                       );

                IF vExportedStates > 0 THEN
                    FOR s IN (
                                SELECT DISTINCT SUBSTR(parameters, INSTR(parameters,'"state"')+9, 2) state_code -- 06/23/17, changed to reflect the 2 digit Instance value
                                FROM   crapp_admin.scheduled_task
                                WHERE  status = 2
                                       AND method = 'export'
                                       AND (PARAMETERS LIKE '{"instance":"'||instance_grp_i||'%"preview":"1"%'
                                            OR PARAMETERS LIKE '{"instance":"'||'1'||'%"preview":"1"%'      -- remove after crapp-3025 rolled to PROD
                                           )
                                       AND task_end >= TRUNC(SYSDATE)-35
                                       AND SUBSTR(parameters, INSTR(parameters,'"state"')+9, 2) != 'XX'     -- 06/23/17, changed to reflect the 2 digit Instance value568
                                ORDER BY state_code
                             )
                    LOOP
                        vExecString := 'BEGIN gis.push_gis_ua_taxids(:x1, :x2); END;';
                        EXECUTE IMMEDIATE (vExecString) USING s.state_code, instance_grp_i;

                        -- Check for duplicate TaxAreaID values --
                        SELECT COUNT(1) d
                        INTO  vDupes
                        FROM  gis_tb_comp_area_dupe_tmp
                        WHERE state_code = s.state_code;

                        -- Check for Areas with Authorities - DATAX_177 --
                        SELECT COUNT(1) a
                        INTO  vAreaAuths
                        FROM  gis_tb_comp_area_authorities
                        WHERE state_code = s.state_code;

                        IF vDupes = 0 AND vAreaAuths > 0 THEN
                            -- Determination - Compliance Areas --
                            vExecString := 'BEGIN '||vSchemaName||'.gis_etl.compliance_area_data; END;';            -- crapp-3964, changed from CR_EXTRACT
                            EXECUTE IMMEDIATE (vExecString);

                            vExecString := 'BEGIN '||vSchemaName||'.gis_etl.compliance_area_auth_data(:x1); END;';  -- crapp-3964, changed from CR_EXTRACT
                            EXECUTE IMMEDIATE (vExecString) USING preview_i;

                            vExecString := 'BEGIN '||vSchemaName||'.gis_etl.build_tb_comp_areas; END;';             -- crapp-3964, changed from DET_TRANSFORM
                            EXECUTE IMMEDIATE (vExecString);

                            vExecString := 'BEGIN '||vSchemaName||'.gis_etl.build_tb_comp_area_auths(:x1); END;';   -- crapp-3964, changed from DET_TRANSFORM
                            EXECUTE IMMEDIATE (vExecString) USING preview_i;

                            vExecString := 'BEGIN '||vSchemaName||'.gis_etl.compare_comp_areas(:x1); END;';         -- crapp-3964, changed from DET_UPDATE
                            EXECUTE IMMEDIATE (vExecString) USING preview_i;

                            -- crapp-3241 --
                            IF (preview_i = 0) THEN    -- Only process during a Preview
                                gis_etl_p(vpID, stcode_i, '   - Save Compliance ETL preview', 0, vUserID);
                                    gis.copy_etl_preview(stcode_i=>s.state_code, instance_i=>instance_grp_i, schema_i=>vSchemaName, compliance_i=>compliance_i);
                                gis_etl_p(vpID, stcode_i, '   - Save Compliance ETL preview', 1, vUserID);
                            END IF;
                        ELSE
                            vTotalDupes := vTotalDupes + vDupes;
                        END IF;
                    END LOOP;
                END IF; -- vExportedStates > 0
            ELSE

                -- Process compliance for a specific state --
                FOR s IN (
                            SELECT state_code, name
                            FROM   geo_states
                            WHERE  state_code = stcode_i
                         )
                LOOP
                    vExecString := 'BEGIN gis.push_gis_ua_taxids(:x1, :x2); END;';
                    EXECUTE IMMEDIATE (vExecString) USING s.state_code, instance_grp_i;

                    -- Check for duplicate TaxAreaID values --
                    SELECT COUNT(1) d
                    INTO  vDupes
                    FROM  gis_tb_comp_area_dupe_tmp
                    WHERE state_code = s.state_code;

                    -- Check for Areas with Authorities - DATAX_177 --
                    SELECT COUNT(1) a
                    INTO  vAreaAuths
                    FROM  gis_tb_comp_area_authorities
                    WHERE state_code = s.state_code;

                    IF vDupes = 0 AND vAreaAuths > 0 THEN
                        -- Determination - Compliance Areas --
                        vExecString := 'BEGIN '||vSchemaName||'.gis_etl.compliance_area_data; END;';            -- crapp-3964, changed from CR_EXTRACT
                        EXECUTE IMMEDIATE (vExecString);

                        vExecString := 'BEGIN '||vSchemaName||'.gis_etl.compliance_area_auth_data(:x1); END;';  -- crapp-3964, changed from CR_EXTRACT
                        EXECUTE IMMEDIATE (vExecString) USING preview_i;

                        vExecString := 'BEGIN '||vSchemaName||'.gis_etl.build_tb_comp_areas; END;';             -- crapp-3964, changed from DET_TRANSFORM
                        EXECUTE IMMEDIATE (vExecString);

                        vExecString := 'BEGIN '||vSchemaName||'.gis_etl.build_tb_comp_area_auths(:x1); END;';   -- crapp-3964, changed from DET_TRANSFORM
                        EXECUTE IMMEDIATE (vExecString) USING preview_i;

                        vExecString := 'BEGIN '||vSchemaName||'.gis_etl.compare_comp_areas(:x1); END;';         -- crapp-3964, changed from DET_UPDATE
                        EXECUTE IMMEDIATE (vExecString) USING preview_i;

                        -- crapp-3241 --
                        IF (preview_i = 0) THEN    -- Only process during a Preview
                            gis_etl_p(vpID, s.state_code, '   - Save Compliance ETL preview', 0, vUserID);
                                gis.copy_etl_preview(stcode_i=>s.state_code, instance_i=>instance_grp_i, schema_i=>vSchemaName, compliance_i=>compliance_i);
                            gis_etl_p(vpID, s.state_code, '   - Save Compliance ETL preview', 1, vUserID);
                        END IF;
                    ELSE
                        vTotalDupes := vTotalDupes + vDupes;
                    END IF;
                END LOOP;
            END IF; -- stcode_i = 'XX'

            -- Update scheduled task indicating any Dupes --
            IF vTotalDupes > 0 THEN
                SELECT LISTAGG(state_code,',') WITHIN GROUP (ORDER BY state_code) states
                INTO vMsg
                FROM (SELECT DISTINCT state_code FROM gis_tb_comp_area_dupe_tmp);

                UPDATE crapp_admin.scheduled_task
                    SET message = 'The following states have duplicate Tax_Area_ID values: '||vMsg||' in table gis_tb_comp_area_dupe_tmp'
                WHERE id = vJobID;
                COMMIT;
            END IF;
            gis_etl_p(vpID, stcode_i, ' - Compliance Only process, preview = '||preview_i, 1, vUserID);
        ELSE
            -- Build out the Zone Tree/Zone Authority Tree --
            vExecString := 'BEGIN gis.push_gis_zone_tree(:x1, :x2); END;';
            EXECUTE IMMEDIATE (vExecString) USING stcode_i, instance_grp_i;

            -- Determination --
            vExecString := 'BEGIN '||vSchemaName||'.gis_etl.zone_data; END;';                       -- crapp-3964, changed from CR_EXTRACT
            EXECUTE IMMEDIATE (vExecString);

            vExecString := 'BEGIN '||vSchemaName||'.gis_etl.zone_authority_data(:x1); END;';        -- crapp-3964, changed from CR_EXTRACT
            EXECUTE IMMEDIATE (vExecString) USING preview_i;

            vExecString := 'BEGIN '||vSchemaName||'.gis_etl.build_tb_zones; END;';                  -- crapp-3964, changed from DET_TRANSFORM
            EXECUTE IMMEDIATE (vExecString);

            vExecString := 'BEGIN '||vSchemaName||'.gis_etl.build_tb_zone_authorities(:x1); END;';  -- crapp-3964, changed from DET_TRANSFORM
            EXECUTE IMMEDIATE (vExecString) USING preview_i;

            vExecString := 'BEGIN '||vSchemaName||'.gis_etl.compare_zone_trees(:x1); END;';         -- crapp-3964, changed from DET_UPDATE
            EXECUTE IMMEDIATE (vExecString) USING preview_i;

            -- crapp-3241 --
            IF (preview_i = 0) THEN    -- Only process during a Preview
                gis_etl_p(vpID, stcode_i, '   - Save ETL preview', 0, vUserID);
                    gis.copy_etl_preview(stcode_i=>stcode_i, instance_i=>instance_grp_i, schema_i=>vSchemaName, compliance_i=>compliance_i);
                gis_etl_p(vpID, stcode_i, '   - Save ETL preview', 1, vUserID);
            END IF;

            -- crapp-3797 --
            IF vHost = 'PROD' THEN  -- We only want to update the BITI_LOG table when processing an export in PROD --
                gis_etl_p(vpID, stcode_i, '   - Update EXPORT_BITI_LOG', 0, vUserID);

                -- Get BITI Vintage value --
                SELECT MAX(usps_date)
                INTO   vVintage
                FROM   gis.uaz9_archive@gis.corp.ositax.com
                WHERE  state = stcode_i;

                INSERT INTO gis.export_biti_log@gis.corp.ositax.com
                    (
                        state
                        , instance
                        , task_complete
                        , biti_vintage
                    )
                    SELECT stcode_i
                           , CASE WHEN vInst LIKE '%TELCO%' THEN 'Telco' ELSE 'Standard' END
                           , SYSDATE
                           , vVintage
                    FROM dual;

                gis_etl_p(vpID, stcode_i, '   - Update EXPORT_BITI_LOG', 1, vUserID);
            END IF;
        END IF; -- compliance_i = 0

        gis_etl_p(vpID, stcode_i, 'gis_process_etl, instance = '||instance_grp_i||', preview = '||preview_i||', compliance = '||compliance_i, 1, vUserID);
    EXCEPTION
        WHEN no_data_found THEN RAISE_APPLICATION_ERROR(-20001,'GIS_PROCESS_ETL error - '||SQLERRM);
    END gis_process_etl;



    -- CRAPP-2244 --
    PROCEDURE update_sched_task(stcode_i IN VARCHAR2, method_i IN VARCHAR2, msg_i IN VARCHAR2) IS
        PRAGMA autonomous_transaction;
    BEGIN

        UPDATE crapp_admin.scheduled_task
            SET message = msg_i
        WHERE id IN (
                    SELECT id
                    FROM   crapp_admin.scheduled_task
                    WHERE  status = 1
                           AND method = method_i
                           AND PARAMETERS LIKE '%"'||stcode_i||'"%'
                           AND task_end IS NULL
                    );
        COMMIT;
    END update_sched_task;



    PROCEDURE copy_etl_preview(stcode_i IN VARCHAR2, instance_i IN NUMBER, schema_i IN VARCHAR2, compliance_i IN NUMBER) IS    -- 08/23/17 - crapp-3241
        PRAGMA autonomous_transaction;

        l_sql    VARCHAR2(2000 CHAR);
        l_host   VARCHAR2(10 CHAR);
        l_inst   VARCHAR2(25 CHAR);
        l_dt     DATE := SYSDATE;
        l_del_dt TIMESTAMP := SYSTIMESTAMP -8;  -- crapp-2445
        l_zones  NUMBER := 0;
    BEGIN

        -- Determine the Server Host -- crapp-2445/2922 (updated host names)
        SELECT NVL(h.displayname, 'N/A') dsphost    --, SYS_CONTEXT('USERENV', 'SERVER_HOST') sh
        INTO  l_host
        FROM  dual d
              LEFT JOIN geo_etl_server_hosts h ON (h.serverhost = SYS_CONTEXT('USERENV', 'SERVER_HOST'));

        SELECT DECODE(instance_i, 9, 'Standard-', 2, 'Intl-', 3, 'Canada-', 10, 'Telco-', NULL)||l_host
        INTO  l_inst
        FROM  dual;

        -- *************** --
        -- Remove old data -- crapp-2445
        -- *************** --
        IF l_host = 'PROD' THEN -- We only want to Remove old data when processing an Export in PROD --
            DELETE FROM gis_temp.pvw_tb_zones@gis.corp.ositax.com
            WHERE  etl_date <= l_del_dt;

            DELETE FROM gis_temp.pvw_tb_zone_auths@gis.corp.ositax.com
            WHERE  etl_date <= l_del_dt;

            DELETE FROM gis_temp.tmp_gis_ztree@gis.corp.ositax.com
            WHERE  etl_date <= l_del_dt;

            DELETE FROM gis_temp.tmp_gis_zone_authorities@gis.corp.ositax.com
            WHERE  etl_date <= l_del_dt;

            DELETE FROM gis_temp.gis_tb_comp_areas@gis.corp.ositax.com          -- crapp-3241
            WHERE  etl_date <= l_del_dt;

            DELETE FROM gis_temp.pvw_tb_compliance_areas@gis.corp.ositax.com    -- crapp-3241
            WHERE  etl_date <= l_del_dt;

            DELETE FROM gis_temp.pvw_tb_comp_area_auths@gis.corp.ositax.com     -- crapp-3241
            WHERE  etl_date <= l_del_dt;
            COMMIT;
        END IF;


        -- Validate that the state we are processing has Zone Tree records before attempting to backup tables --
        SELECT COUNT(1) cnt
        INTO l_zones
        FROM gis_ztree_tmp z
             JOIN geo_states s ON (z.zone_3_name = s.NAME)
        WHERE s.state_code = stcode_i;


        -- State being processed has records and this is a Compliance ETL, then backup Zone preview tables to GIS_TEMP --
        IF l_zones > 0 AND compliance_i = 1 THEN
            -- ************** --
            -- v_PVW_TB_ZONES --
            -- ************** --

            -- Clear any previous runs for this state --
            DELETE FROM gis_temp.pvw_tb_zones@gis.corp.ositax.com
            WHERE   state_code = stcode_i
                    AND INSTANCE = l_inst;

            l_sql := 'INSERT INTO gis_temp.pvw_tb_zones@gis.corp.ositax.com '||
                        '(state_code, zone_id, name, parent_zone_id, parent_name, code_fips, zone_3_name, zone_4_name, zone_5_name, '||
                         'zone_6_name, zone_7_name, reverse_flag, terminator_flag, default_flag, tree_type, etl_date, instance) '||
                        'SELECT DISTINCT '''||stcode_i||''' state_code'||
                                ', p.zone_id'||
                                ', p.name'||
                                ', p.parent_zone_id'||
                                ', p.parent_name'||
                                ', p.code_fips'||
                                ', p.zone_3_name'||
                                ', p.zone_4_name'||
                                ', p.zone_5_name'||
                                ', p.zone_6_name'||
                                ', p.zone_7_name'||
                                ', p.reverse_flag'||
                                ', p.terminator_flag'||
                                ', p.default_flag'||
                                ', p.tree_type'||
                                ', TO_DATE('''||TO_CHAR(l_dt, 'mm/dd/yyyy HH24:MI:SS')||''',''mm/dd/yyyy HH24:MI:SS'') etl_date'||
                                ', '''||l_inst||''' instance '||
                        'FROM   '||schema_i||'.v_pvw_tb_zones p ';

            EXECUTE IMMEDIATE l_sql;
            COMMIT;


            -- ******************* --
            -- v_PVW_TB_ZONE_AUTHS --
            -- ******************* --

            -- Clear any previous runs for this state --
            DELETE FROM gis_temp.pvw_tb_zone_auths@gis.corp.ositax.com
            WHERE   state_code = stcode_i
                    AND INSTANCE = l_inst;

            l_sql := 'INSERT INTO gis_temp.pvw_tb_zone_auths@gis.corp.ositax.com '||
                        '(state_code, zone_id, authority_id, authority_name, zone_3_name, zone_4_name, zone_5_name, '||
                         'zone_6_name, zone_7_name, tree_type, etl_date, instance) '||
                        'SELECT DISTINCT '''||stcode_i||''' state_code'||
                                ', p.zone_id'||
                                ', p.authority_id'||
                                ', p.authority_name'||
                                ', p.zone_3_name'||
                                ', p.zone_4_name'||
                                ', p.zone_5_name'||
                                ', p.zone_6_name'||
                                ', p.zone_7_name'||
                                ', p.tree_type'||
                                ', TO_DATE('''||TO_CHAR(l_dt, 'mm/dd/yyyy HH24:MI:SS')||''',''mm/dd/yyyy HH24:MI:SS'') etl_date'||
                                ', '''||l_inst||''' instance '||
                        'FROM   '||schema_i||'.v_pvw_tb_zone_auths p ';

            EXECUTE IMMEDIATE l_sql;
            COMMIT;


            -- ************* --
            -- GIS_ZTREE_TMP --
            -- ************* --

            -- Clear any previous runs for this state --
            DELETE FROM gis_temp.tmp_gis_ztree@gis.corp.ositax.com
            WHERE   state_code = stcode_i
                    AND INSTANCE = l_inst;

            l_sql := 'INSERT INTO gis_temp.tmp_gis_ztree@gis.corp.ositax.com '||
                        '(state_code, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, '||
                         'zone_6_name, zone_7_name, default_flag, terminator_flag, etl_date, instance) '||
                        'SELECT DISTINCT '''||stcode_i||''' state_code'||
                                ', p.zone_1_name'||
                                ', p.zone_2_name'||
                                ', p.zone_3_name'||
                                ', p.zone_4_name'||
                                ', p.zone_5_name'||
                                ', p.zone_6_name'||
                                ', p.zone_7_name'||
                                ', p.default_flag'||
                                ', p.terminator_flag'||
                                ', TO_DATE('''||TO_CHAR(l_dt, 'mm/dd/yyyy HH24:MI:SS')||''',''mm/dd/yyyy HH24:MI:SS'') etl_date'||
                                ', '''||l_inst||''' instance '||
                        'FROM   gis_ztree_tmp p ';  -- crapp-3363

            EXECUTE IMMEDIATE l_sql;
            COMMIT;


            -- ******************* --
            -- GIS_AUTHORITIES_TMP --
            -- ******************* --

            -- Clear any previous runs for this state --
            DELETE FROM gis_temp.tmp_gis_zone_authorities@gis.corp.ositax.com
            WHERE   state_code = stcode_i
                    AND INSTANCE = l_inst;

            l_sql := 'INSERT INTO gis_temp.tmp_gis_zone_authorities@gis.corp.ositax.com '||
                        '(state_code, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, '||
                         'zone_7_name, default_flag, terminator_flag, authority_name, etl_date, instance) '||
                        'SELECT DISTINCT '''||stcode_i||''' state_code'||
                                ', p.zone_1_name'||
                                ', p.zone_2_name'||
                                ', p.zone_3_name'||
                                ', p.zone_4_name'||
                                ', p.zone_5_name'||
                                ', p.zone_6_name'||
                                ', p.zone_7_name'||
                                ', p.default_flag'||
                                ', p.terminator_flag'||
                                ', p.authority_name'||
                                ', TO_DATE('''||TO_CHAR(l_dt, 'mm/dd/yyyy HH24:MI:SS')||''',''mm/dd/yyyy HH24:MI:SS'') etl_date'||
                                ', '''||l_inst||''' instance '||
                        'FROM    gis_authorities_tmp p ';   -- crapp-3363

            EXECUTE IMMEDIATE l_sql;
            COMMIT;
        END IF;

        -- crapp-3241 --
        IF instance_i = 9 AND compliance_i = 0 THEN
            -- ***************** --
            -- GIS_TB_COMP_AREAS --
            -- ***************** --

            -- Clear any previous runs for this state --
            DELETE FROM gis_temp.gis_tb_comp_areas@gis.corp.ositax.com
            WHERE   state_code = stcode_i
                    AND INSTANCE = l_inst;
            COMMIT;

            l_sql := 'INSERT INTO gis_temp.gis_tb_comp_areas@gis.corp.ositax.com '||
                        '( state_code'||
                        ', area_id'||
                        ', tax_area_id'||
                        ', unique_area'||
                        ', authority_name'||
                        ', start_date'||
                        ', end_date'||
                        ', etl_date'||
                        ', instance) '||
                        'SELECT DISTINCT '||
                                'caa.state_code'||
                                ', caa.area_id'||
                                ', caa.tax_area_id'||
                                ', ca.unique_area'||
                                ', caa.authority_name'||
                                ', ca.start_date'||
                                ', ca.end_date'||
                                ', TO_DATE('''||TO_CHAR(l_dt, 'mm/dd/yyyy HH24:MI:SS')||''',''mm/dd/yyyy HH24:MI:SS'') etl_date'||
                                ', '''||l_inst||''' instance '||
                        'FROM   gis_tb_comp_area_authorities caa '||
                               'JOIN gis_tb_comp_areas_tmp ca ON (caa.state_code = ca.state_code '||
                                                                 'AND caa.area_id = ca.area_id) '||
                        'WHERE  caa.state_code = '''||stcode_i||'''';

            EXECUTE IMMEDIATE l_sql;
            COMMIT;


            -- ************************* --
            -- V_PVW_TB_COMPLIANCE_AREAS --
            -- ************************* --

            -- Clear any previous runs for this state --
            DELETE FROM gis_temp.pvw_tb_compliance_areas@gis.corp.ositax.com
            WHERE   state_code = stcode_i
                    AND INSTANCE = l_inst;
            COMMIT;

            l_sql := 'INSERT INTO gis_temp.pvw_tb_compliance_areas@gis.corp.ositax.com '||
                        '( state_code'||
                        ', compliance_area_id'||
                        ', name'||
                        ', compliance_area_uuid'||
                        ', effective_zone_level_id'||
                        ', associated_area_count'||
                        ', merchant_id'||
                        ', start_date'||
                        ', end_date'||
                        ', change_type'||
                        ', etl_date'||
                        ', instance) '||
                        'SELECT DISTINCT '''||stcode_i||''' state_code'||
                                ', p.compliance_area_id'||
                                ', p.name'||
                                ', p.compliance_area_uuid'||
                                ', p.effective_zone_level_id'||
                                ', p.associated_area_count'||
                                ', p.merchant_id'||
                                ', p.start_date'||
                                ', p.end_date'||
                                ', p.change_type'||
                                ', TO_DATE('''||TO_CHAR(l_dt, 'mm/dd/yyyy HH24:MI:SS')||''',''mm/dd/yyyy HH24:MI:SS'') etl_date'||
                                ', '''||l_inst||''' instance '||
                        'FROM   '||schema_i||'.v_pvw_tb_compliance_areas p ';

            EXECUTE IMMEDIATE l_sql;
            COMMIT;


            -- ****************************** --
            -- V_PVW_TB_COMP_AREA_AUTHORITIES --
            -- ****************************** --

            -- Clear any previous runs for this state --
            DELETE FROM gis_temp.pvw_tb_comp_area_auths@gis.corp.ositax.com
            WHERE   state_code = stcode_i
                    AND INSTANCE = l_inst;
            COMMIT;

            l_sql := 'INSERT INTO gis_temp.pvw_tb_comp_area_auths@gis.corp.ositax.com '||
                        '( state_code'||
                        ', compliance_area_auth_id'||
                        ', compliance_area_id'||
                        ', NAME'||
                        ', compliance_area_uuid'||
                        ', authority_id'||
                        ', authority_name'||
                        ', change_type'||
                        ', etl_date'||
                        ', instance) '||
                        'SELECT DISTINCT '''||stcode_i||''' state_code'||
                                ', p.compliance_area_auth_id'||
                                ', p.compliance_area_id'||
                                ', p.NAME'||
                                ', p.compliance_area_uuid'||
                                ', p.authority_id'||
                                ', p.authority_name'||
                                ', p.change_type'||
                                ', TO_DATE('''||TO_CHAR(l_dt, 'mm/dd/yyyy HH24:MI:SS')||''',''mm/dd/yyyy HH24:MI:SS'') etl_date'||
                                ', '''||l_inst||''' instance '||
                        'FROM   '||schema_i||'.v_pvw_tb_comp_area_authorities p '||
                        'ORDER BY p.compliance_area_uuid, p.name, p.authority_name';

            EXECUTE IMMEDIATE l_sql;
            COMMIT;
        END IF; -- Compliance Only

    END copy_etl_preview;



    PROCEDURE push_gis_zone_tree (stcode_i IN VARCHAR2, instance_grp_i IN NUMBER) IS   -- 09/26/17 - crapp-4072 - performance changes

        l_merchantid NUMBER            := 2;  -- 'Sabrix US Tax Data'
        l_zone1name  VARCHAR2(10 CHAR) := 'WORLD';
        l_zone2name  VARCHAR2(25 CHAR) := 'UNITED STATES';
        l_uniquearea VARCHAR2(1000 CHAR);
        l_statename  VARCHAR2(50 CHAR);
        l_county     VARCHAR2(50 CHAR);
        l_city       VARCHAR2(50 CHAR);
        l_codefips   VARCHAR2(25 CHAR);
        l_sql        VARCHAR2(500 CHAR);
        l_schema     VARCHAR2(10 CHAR);
        l_default    CHAR(1);
        l_zip        CHAR(5);
        l_zip4min    CHAR(4);
        l_nextzip4   CHAR(4);
        l_zip4ascii  CHAR(4);
        l_nextzip4_ascii NUMBER;
        l_stj        NUMBER(1,0) := 0;
        l_rec        NUMBER := 0;
        l_firstpass  BOOLEAN := TRUE;
        l_user       NUMBER := -204;
        l_pID        NUMBER := gis_etl_process_log_sq.nextval;
        vcurrent_schema VARCHAR2(50);
        l_instance   NUMBER;    -- 04/17/17 crapp-3025 (replaces instance_i)
        l_tag_grp    NUMBER;    -- 04/17/17 crapp-3025 (replaces tag_grp_i)
        l_hlvl       NUMBER;    -- crapp-4072

        TYPE t_stj IS TABLE OF gis_zone_stj_areas_tmp%ROWTYPE;
        v_stj  t_stj;

        -- 06/08/17 - Added for performance
        TYPE t_dtl IS TABLE OF gis_zone_detail_tmp%ROWTYPE;
        v_dtl  t_dtl;

        -- 09/27/17 - Updated for performance - crapp-4072 --
        CURSOR detail(stcd VARCHAR2) IS
            WITH usps AS
                (
                SELECT DISTINCT
                       state_code
                       , SUBSTR(UPPER(state_name), 1, 50)  state_name
                       , SUBSTR(UPPER(county_name), 1, 50) county_name
                       , SUBSTR(UPPER(city_name), 1, 50)   city_name
                       , zip
                       , zip9
                       , SUBSTR(zip9, 6, 4) zip4
                       , CASE WHEN override_rank = 1 THEN 'Y' ELSE NULL END default_flag
                       , (state_fips||county_fips||city_fips||NVL(zip, '')) code_fips
                       , area_id
                       , geo_polygon_id
                FROM   geo_usps_lookup u
                WHERE  state_code = stcd
                ),
                poly AS
                (
                SELECT /*+index(p geo_polygons_un)*/
                       DISTINCT
                       u.state_code
                       , u.state_name
                       , u.county_name
                       , u.city_name
                       , u.zip
                       , u.zip9
                       , u.zip4
                       , u.default_flag
                       , u.code_fips
                       , ac.NAME geo_area
                       , u.area_id
                       , p.rid
                FROM   usps u
                       JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
                       JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                                         AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
                       JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
                       JOIN geo_area_categories ac ON (hl.geo_area_category_id = ac.id)
                WHERE  u.state_code = stcd
                       AND p.next_rid IS NULL
                )
                SELECT   u1.state_code
                       , u1.state_name
                       , u1.county_name
                       , u1.city_name
                       , u1.zip
                       , u1.zip9
                       , u1.zip4
                       , u1.default_flag
                       , u1.code_fips
                       , u1.geo_area
                       , gua.unique_area
                       , u1.rid
                FROM   poly u1
                       JOIN gis_unique_areas_temp gua ON (u1.area_id = gua.area_id);

        CURSOR zip4tree IS
            SELECT  DISTINCT stj_flag, state_code, state_name, county_name, city_name, zip
                    , zip4, default_flag, code_fips, unique_area
                    , CASE WHEN ASCII(zip4) BETWEEN 65 AND 90 THEN ASCII(zip4)                          -- crapp-2087
                           WHEN ASCII(SUBSTR(zip4,3,2)) BETWEEN 65 AND 90 THEN ASCII(SUBSTR(zip4,3,2))  -- crapp-3304
                           ELSE NULL
                      END zip4_ascii
            FROM    gis_zone_list_tmp
            ORDER BY zip, zip4, unique_area;

        CURSOR bottom_up IS
            SELECT  DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
            FROM    gis_zone_authorities_tmp
            WHERE   reverse_flag = 'Y'
                    AND zone_7_name IS NOT NULL;   -- crapp-2536, will be removed

        CURSOR top_down IS
            SELECT  DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
            FROM    gis_zone_authorities_tmp
            WHERE   reverse_flag = 'N'
                    AND zone_7_name IS NOT NULL;   -- crapp-2536, will be removed

        CURSOR defaultzips_crossborder IS   -- crapp-3406
            SELECT  /*+index(gd gis_defaults_tmp_n1)*/
                    zone_3_name, zone_4_name, zone_5_name, zone_6_name
            FROM    gis_defaults_tmp gd
            WHERE   zone_6_name IS NOT NULL
                    AND default_flag = 'Y'
                    AND zone_6_name IN (
                                        SELECT zip
                                        FROM (
                                               SELECT DISTINCT state_code, zip
                                               FROM   geo_usps_lookup u
                                                      JOIN gis_defaults_tmp d ON (u.zip = d.zone_6_name)
                                               WHERE  u.state_code = stcode_i   -- crapp-4072, added
                                                      AND u.override_rank = 1
                                                      AND u.zip9 IS NULL
                                             ) dp
                                        GROUP BY zip
                                        HAVING COUNT(1) > 1
                                       );

        CURSOR defaultzips IS
            SELECT  /*+index(gd gis_defaults_tmp_n1)*/
                    zone_3_name, zone_4_name, zone_5_name, zone_6_name
            FROM    gis_defaults_tmp gd
            WHERE   zone_6_name IS NOT NULL
                    AND default_flag = 'Y';

        CURSOR defaultmulticity IS
            SELECT  d.zone_3_name
                    , d.zone_4_name
                    , d.zone_5_name
                    , MAX(d.default_flag) default_flag
            FROM    gis_defaults_tmp d
                    JOIN (  SELECT zone_5_name, COUNT(DISTINCT zone_4_name) counties    -- 03/16/15 - added distinct
                            FROM   gis_defaults_tmp
                            WHERE  zone_6_name IS NULL
                            GROUP BY zone_5_name
                            HAVING COUNT(DISTINCT zone_4_name) > 1
                         ) c ON d.zone_5_name = c.zone_5_name
            WHERE   d.zone_6_name IS NULL
            GROUP BY d.zone_3_name
                    , d.zone_4_name
                    , d.zone_5_name;

        CURSOR removezip9s_tree IS -- crapp-2087
            SELECT DISTINCT z.zone_4_name, z.zone_5_name, z.zone_6_name, z.zone_7_name, z.code_fips, d.terminator_flag, d.default_flag
            FROM   gis_zone_tree_tmp z
                   JOIN (
                          SELECT DISTINCT zone_4_name, zone_5_name, zone_6_name, terminator_flag, default_flag
                          FROM   gis_zone_tree_tmp
                          WHERE  (zone_4_name, zone_5_name, zone_6_name) IN ( SELECT DISTINCT zone_4_name, zone_5_name, zone_6_name
                                                                              FROM  gis_zone_tree_tmp
                                                                              WHERE ASCII(zone_7_name) BETWEEN 65 AND 90
                                                                                    OR ASCII(SUBSTR(zone_7_name,3,2)) BETWEEN 65 AND 90 -- crapp-3159
                                                                            )
                                  AND zone_7_name IS NULL
                        ) d ON (     z.zone_4_name = d.zone_4_name
                                 AND z.zone_5_name = d.zone_5_name
                                 AND z.zone_6_name = d.zone_6_name
                               )
            WHERE  ASCII(zone_7_name) BETWEEN 65 AND 90
                   OR ASCII(SUBSTR(zone_7_name,3,2)) BETWEEN 65 AND 90; -- crapp-3159

        CURSOR removezip9s_auth IS -- crapp-2087
            SELECT DISTINCT zone_4_name, zone_5_name, zone_6_name, zone_7_name, code_fips
            FROM   gis_authorities_tmp
            WHERE  ASCII(zone_7_name) BETWEEN 65 AND 90
                   OR ASCII(SUBSTR(zone_7_name,3,2)) BETWEEN 65 AND 90; -- crapp-3159


    BEGIN

        -- 04/17/17 crapp-3025
        SELECT tdr_etl_instance_id, tdr_etl_tag_group_id, schema_name
        INTO   l_instance, l_tag_grp, l_schema
        FROM   vetl_instance_groups
        WHERE  gis_flag = 'Y'
               AND instance_group_id = instance_grp_i;

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'push_gis_zone_tree, tag_grp_id = '||l_tag_grp||', instance_id = '||l_instance, paction=>0, puser=>l_user);


        -- CRAPP-3174, Dynamic extraction of schema name to reference tables where needed
        SELECT SYS_CONTEXT( 'userenv', 'current_schema' ) INTO vcurrent_schema FROM dual;


        -- Get STJ Count --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get stj count - gis_zone_stj_areas_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_stj_areas_tmp DROP STORAGE';
        --EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_stj_areas_tmp_n1 UNUSABLE';

        SELECT  hl.id
        INTO    l_hlvl
        FROM    hierarchy_levels hl
                JOIN geo_area_categories g ON (hl.geo_area_category_id = g.id)
                JOIN hierarchy_definitions hd ON (hl.hierarchy_definition_id = hd.id)
        WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                AND g.NAME = 'District';

        WITH zips AS
            (
             SELECT u.state_code
                    , u.zip9
                    , u.area_id
             FROM   geo_usps_lookup u
                    JOIN geo_polygons p ON (u.geo_polygon_id = p.id)
             WHERE  u.state_code = stcode_i
                    AND DECODE(NVL(SUBSTR(u.zip9,6,4), 'XXXX'), 'XXXX', 0, 1) = 1   -- zip4 is not null
                    AND p.hierarchy_level_id = l_hlvl --'District'
                    AND p.next_rid IS NULL
            ),
           areas AS
            (
             SELECT state_code
                    , zip9
                    , unique_area
                    , area_id
             FROM   vgeo_unique_areas2
             WHERE  state_code = stcode_i
                    AND zip9 IS NOT NULL
            )
            SELECT  DISTINCT
                    z.state_code
                    , a.unique_area
                    , 1 stj_flag
                    , z.zip9
            BULK COLLECT INTO v_stj
            FROM    zips z
                    JOIN areas a ON (    z.state_code = a.state_code
                                     AND z.zip9       = a.zip9
                                     AND z.area_id    = a.area_id
                                    );

        FORALL i IN v_stj.first..v_stj.last
            INSERT INTO gis_zone_stj_areas_tmp
            VALUES v_stj(i);
        COMMIT;

        v_stj := t_stj();
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get stj count - gis_zone_stj_areas_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild stats - gis_zone_stj_areas_tmp', paction=>0, puser=>l_user);
            DBMS_STATS.gather_table_stats(vcurrent_schema, 'GIS_ZONE_STJ_AREAS_TMP', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild stats - gis_zone_stj_areas_tmp', paction=>1, puser=>l_user);

        -- Build temp table of GIS Zip data --  crapp-3094, removed view for performance
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_zone_detail_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_detail_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n1 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n2 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n3 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n4 UNUSABLE';
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_zone_detail_tmp', paction=>1, puser=>l_user);

        -- crapp-4072, added --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Detail stage table - gis_unique_areas_temp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_unique_areas_temp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_unique_areas_temp_n1 UNUSABLE';

        INSERT INTO gis_unique_areas_temp
            (state_name, area_id, unique_area)
            SELECT DISTINCT
                   state_name
                   , area_id
                   , UPPER(unique_area) unique_area
            FROM   vgeo_unique_areas2
            WHERE  state_code = stcode_i;
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX gis_unique_areas_temp_n1 REBUILD';
        DBMS_STATS.gather_table_stats('CONTENT_REPO', 'gis_unique_areas_temp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Detail stage table - gis_unique_areas_temp', paction=>1, puser=>l_user);

        -- 06/08/17 - Changed straight insert to a Loop Cusror with a commit limit for performance reasons --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get zipcode detail - gis_zone_detail_tmp', paction=>0, puser=>l_user);
        OPEN detail(stcode_i);
        LOOP
            FETCH detail BULK COLLECT INTO v_dtl LIMIT 25000;

            FORALL d IN 1..v_dtl.COUNT
                INSERT INTO gis_zone_detail_tmp
                VALUES v_dtl(d);
            COMMIT;

            EXIT WHEN detail%NOTFOUND;
        END LOOP;
        COMMIT;

        v_dtl := t_dtl();
        CLOSE detail;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get zipcode detail - gis_zone_detail_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_zone_detail_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n1 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n2 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n3 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n4 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'GIS_ZONE_DETAIL_TMP', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_zone_detail_tmp', paction=>1, puser=>l_user);

        -- crapp-4072 - added staging table for performance --
        gis_etl_p(l_pID, stcode_i, ' - Get default zipcode detail - gis_area_stage_tmp', 0, l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_area_stage_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_area_stage_tmp_n1 UNUSABLE';
        INSERT INTO gis_area_stage_tmp
            (
             unique_area
             , state_name
             , county_name
             , city_name
             , zip
             , zip4
             , default_flag
             , code_fips
             , state_code
            )
            SELECT DISTINCT
                   unique_area
                   , state_name
                   , county_name
                   , city_name
                   , zip
                   , zip4
                   , default_flag
                   , code_fips
                   , state_code
            FROM   gis_zone_detail_tmp z
            WHERE  state_code = stcode_i
                   AND zip4 IS NOT NULL
                   AND default_flag = 'Y';
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX gis_area_stage_tmp_n1 REBUILD';
        gis_etl_p(l_pID, stcode_i, ' - Get default zipcode detail - gis_area_stage_tmp', 1, l_user);

        -- Get zipcode detail for defaults - gis_zone_list_tmp --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_zone_list_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_list_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_list_tmp_n1 UNUSABLE';
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_zone_list_tmp', paction=>1, puser=>l_user);

        -- crapp-4072 - updated to use staging table --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get zipcode detail for defaults - gis_zone_list_tmp', paction=>0, puser=>l_user);
        INSERT INTO gis_zone_list_tmp
            (unique_area, stj_flag, state_name, county_name, city_name, zip, zip4, default_flag, code_fips, state_code)
            SELECT  /*+index(d gis_zone_stj_areas_tmp_n1)*/
                    g.unique_area
                    , NVL(d.stj_flag, 0) stj_flag
                    , g.state_name
                    , g.county_name
                    , g.city_name
                    , g.zip
                    , NVL2(geo_poly_id, NULL, g.zip4) zip4 -- Display Zip4s when no attribute - CRAPP-1074
                    , g.default_flag
                    , g.code_fips
                    , g.state_code
            FROM    gis_area_stage_tmp g    -- crapp-4072, changed to staging table
                    LEFT JOIN gis_zone_stj_areas_tmp d ON ( g.unique_area = d.unique_area
                                                            AND (g.zip||g.zip4) = d.zip9)
                    LEFT JOIN ( SELECT a.geo_poly_id, a.geo_poly_rid, p.geo_area_key
                                FROM   vgeo_poly_attributes a
                                       JOIN geo_polygons p ON (a.geo_poly_id = p.id)
                                WHERE  attribute_name = 'Restrict Zip+4 Load to Determination'
                                       AND VALUE = 'Y'
                               ) pa ON (g.unique_area LIKE ('%'||pa.geo_area_key||'%'));
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_list_tmp_n1 REBUILD';
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get zipcode detail for defaults - gis_zone_list_tmp', paction=>1, puser=>l_user);


        -- Build Zone Tree for Zip4s
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_zone_tree_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_tree_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_tree_tmp_n1 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_tree_tmp_n2 UNUSABLE';     -- 05/25/17, added
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_zone_tree_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build zone tree ranges - gis_zone_tree_tmp', paction=>0, puser=>l_user);
        FOR t IN zip4tree LOOP <<zip4tree_loop>>

            IF l_firstpass THEN -- first pass
                l_firstpass   := FALSE;
                l_uniquearea  := t.unique_area;
                l_statename   := t.state_name;
                l_county      := t.county_name;
                l_city        := t.city_name;
                l_default     := t.default_flag;
                l_codefips    := t.code_fips;
                l_stj         := t.stj_flag;
                l_zip         := t.zip;
                l_zip4min     := t.zip4;

                IF t.zip4_ascii BETWEEN 65 AND 90 THEN      -- crapp-2087 ('A' and 'Z')
                    l_zip4ascii      := t.zip4;
                    l_nextzip4_ascii := TO_NUMBER(t.zip4_ascii + 1);

                    l_zip4min  := NULL; -- crapp-2740
                    l_nextzip4 := NULL; -- crapp-2740
                ELSE
                    l_nextzip4 := LPAD( TO_CHAR( TO_NUMBER(l_zip4min + 1) ), 4, '0');

                    l_zip4ascii      := NULL;   -- crapp-2740
                    l_nextzip4_ascii := NULL;   -- crapp-2740
                END IF;
            ELSE
                -- Determine the if the Zip Range needs to updated
                IF     l_uniquearea <> t.unique_area
                    OR l_county   <> t.county_name
                    OR l_city     <> t.city_name
                    OR l_zip      <> t.zip                              -- crapp-2090
                    OR l_nextzip4 <> t.zip4
                    OR l_nextzip4_ascii <> t.zip4_ascii THEN

                    l_nextzip4 := LPAD( TO_CHAR( TO_NUMBER(l_nextzip4 - 1) ), 4, '0');      -- decrement by one

                    INSERT INTO gis_zone_tree_tmp
                        (merchant_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, code_fips, range_min, range_max, stj_flag)
                        VALUES ( l_merchantid
                                 , l_zone1name
                                 , l_zone2name
                                 , l_statename
                                 , l_county
                                 , l_city
                                 , l_zip
                                 , NVL2(l_zip4min, (l_zip4min ||'-'|| l_nextzip4), NVL2(l_zip4ascii, (l_zip4ascii ||'-'|| l_zip4ascii), NULL))  -- zone7 crapp-2087
                                 , (l_codefips || l_zip4min ||'-'|| l_nextzip4)    -- code_fips
                                 , l_zip4min
                                 , l_nextzip4
                                 , l_stj
                               );

                    IF t.zip4_ascii BETWEEN 65 AND 90 THEN      -- crapp-2087 ('A' and 'Z')
                        l_zip4min  := NULL;
                        l_nextzip4 := NULL;

                        l_zip4ascii      := t.zip4;
                        l_nextzip4_ascii := TO_NUMBER(t.zip4_ascii + 1);
                    ELSE
                        l_zip4min  := t.zip4;
                        l_nextzip4 := LPAD( TO_CHAR( TO_NUMBER(l_zip4min + 1) ), 4, '0');

                        l_zip4ascii      := NULL;
                        l_nextzip4_ascii := NULL;
                    END IF;

                    l_uniquearea  := t.unique_area;
                    l_statename   := t.state_name;
                    l_county      := t.county_name;
                    l_city        := t.city_name;
                    l_zip         := t.zip;
                    l_codefips    := t.code_fips;
                    l_stj         := t.stj_flag;
                ELSE

                    l_nextzip4 := LPAD( TO_CHAR( TO_NUMBER(l_nextzip4 + 1) ), 4, '0');      -- calc next zip in range
                    l_nextzip4_ascii := TO_NUMBER(l_nextzip4_ascii + 1);                    -- crapp-2087

                END IF;
            END IF;

        END LOOP zip4tree_loop;
        COMMIT;

        -- End of Loop, so output last range record
        l_nextzip4 := LPAD( TO_CHAR( TO_NUMBER(l_nextzip4 - 1) ), 4, '0');            -- decrement by one

        INSERT INTO gis_zone_tree_tmp
            (merchant_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, code_fips, range_min, range_max, stj_flag)
            VALUES ( l_merchantid
                     , l_zone1name
                     , l_zone2name
                     , l_statename
                     , l_county
                     , l_city
                     , l_zip
                     , NVL2(l_zip4min, (l_zip4min ||'-'|| l_nextzip4), NVL2(l_zip4ascii, (l_zip4ascii ||'-'|| l_zip4ascii), NULL))  -- zone7 crapp-2087
                     , (l_codefips || l_zip4min || '-' || l_nextzip4)    -- code_fips
                     , l_zip4min
                     , l_nextzip4
                     , l_stj
                   );
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build zone tree ranges - gis_zone_tree_tmp', paction=>1, puser=>l_user);

        -- Build Zone Tree for Zip5s
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build zone tree Zip5s - gis_zone_tree_tmp', paction=>0, puser=>l_user);
        INSERT INTO gis_zone_tree_tmp
            (merchant_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, code_fips, stj_flag)
            (SELECT DISTINCT
                    l_merchantid
                    , l_zone1name
                    , l_zone2name
                    , SUBSTR(UPPER(state_name), 1, 50)  state_name
                    , SUBSTR(UPPER(county_name), 1, 50) county_name
                    , SUBSTR(UPPER(city_name), 1, 50)   city_name
                    , zip
                    , code_fips
                    , CASE WHEN geo_area = 'District' THEN 1 ELSE 0 END stj_flag
             FROM   vgeo_polygons_search_etl
             WHERE  plus4_range IS NULL
                    AND zip IS NOT NULL
                    AND next_rid IS NULL
                    AND state_code = stcode_i
             );
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build zone tree Zip5s - gis_zone_tree_tmp', paction=>1, puser=>l_user);


        -- Build Zone Tree for Cities with no Zip
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build zone tree for Cities no Zip - gis_zone_tree_tmp', paction=>0, puser=>l_user);
        INSERT INTO gis_zone_tree_tmp
            (merchant_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, code_fips, stj_flag) -- zone_6_name -- crapp-3094, removed since Zip is NULL
            (
             SELECT DISTINCT
                    l_merchantid
                    , l_zone1name
                    , l_zone2name
                    , SUBSTR(UPPER(state_name), 1, 50)  state_name
                    , SUBSTR(UPPER(county_name), 1, 50) county_name
                    , SUBSTR(UPPER(city_name), 1, 50)   city_name
                    --, zip             -- crapp-3094, removed since Zip is NULL - was creating dupes in data
                    , code_fips
                    , CASE WHEN geo_area = 'District' THEN 1 ELSE 0 END stj_flag
             FROM   vgeo_polygons_search_etl
             WHERE  zip IS NULL
                    AND next_rid IS NULL
                    AND state_code = stcode_i
             );
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build zone tree for Cities no Zip - gis_zone_tree_tmp', paction=>1, puser=>l_user);


        -- Build Zone Tree for Cities Only --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build zone tree City|County|State only - gis_zone_tree_tmp', paction=>0, puser=>l_user);
        INSERT INTO gis_zone_tree_tmp
            (merchant_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, code_fips, stj_flag)
            (
             SELECT DISTINCT
                    l_merchantid
                    , l_zone1name
                    , l_zone2name
                    , SUBSTR(UPPER(state_name), 1, 50)  state_name
                    , SUBSTR(UPPER(county_name), 1, 50) county_name
                    , SUBSTR(UPPER(city_name), 1, 50)   city_name
                    , (state_fips||county_fips||city_fips) code_fips
                    , 0 stj_flag
             FROM   geo_usps_lookup s   -- crapp-4072, changed from view: vgeo_polygons_search_etl
             WHERE  state_code = stcode_i
                    AND NOT EXISTS ( SELECT 1   -- crapp-3094, added to reduce duplicates
                                     FROM   gis_zone_tree_tmp z
                                     WHERE      z.zone_3_name = SUBSTR(UPPER(s.state_name), 1, 50)
                                            AND z.zone_4_name = SUBSTR(UPPER(s.county_name), 1, 50)
                                            AND z.zone_5_name = SUBSTR(UPPER(s.city_name), 1, 50)
                                            AND z.code_fips   = (s.state_fips||s.county_fips||s.city_fips)
                                            AND z.zone_6_name IS NULL
                                   )
             );
        COMMIT;


        -- Build Zone Tree for Counties Only --
        INSERT INTO gis_zone_tree_tmp
            (merchant_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, code_fips, stj_flag)
            (
             SELECT DISTINCT
                    l_merchantid
                    , l_zone1name
                    , l_zone2name
                    , SUBSTR(UPPER(state_name), 1, 50)  state_name
                    , SUBSTR(UPPER(county_name), 1, 50) county_name
                    , (state_fips||county_fips)  code_fips
                    , 0 stj_flag
             FROM   geo_usps_lookup    -- crapp-4072, changed from view: vgeo_polygons_search_etl
             WHERE  state_code = stcode_i
             );
        COMMIT;


        -- Build Zone Tree for State Only --
        INSERT INTO gis_zone_tree_tmp
            (merchant_id, zone_1_name, zone_2_name, zone_3_name, code_fips, stj_flag)
            (
             SELECT DISTINCT
                    l_merchantid
                    , l_zone1name
                    , l_zone2name
                    , SUBSTR(UPPER(state_name), 1, 50)  state_name
                    , state_fips  code_fips
                    , 0 stj_flag
             FROM   geo_usps_lookup    -- crapp-4072, changed from view: vgeo_polygons_search_etl
             WHERE  state_code = stcode_i
                    AND ROWNUM = 1
             );
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_tree_tmp_n1 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_tree_tmp_n2 REBUILD';   -- 05/25/17, added
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build zone tree City|County|State only - gis_zone_tree_tmp', paction=>1, puser=>l_user);


        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Update stats - gis_zone_tree_tmp', paction=>0, puser=>l_user);
            DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_tree_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Update stats - gis_zone_tree_tmp', paction=>1, puser=>l_user);

        -- Determine Bottom-Up Terminates or Top-Down based on Zone Authorities --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Execute push_gis_zone_authorities', paction=>0, puser=>l_user);
            push_gis_zone_authorities(stcode_i=>stcode_i, tag_grp_i=>l_tag_grp, instance_i=>l_instance);  -- crapp-3025, changed to local variables
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Execute push_gis_zone_authorities', paction=>1, puser=>l_user);


        -- Set the Reverse_Flag and Terminate_Flag to indicate Bottom-Up --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Set flags for bottom-up - gis_zone_tree_tmp', paction=>0, puser=>l_user);
        FOR b IN bottom_up LOOP
            UPDATE gis_zone_tree_tmp
                SET default_flag    = NULL,
                    reverse_flag    = 'Y',
                    terminator_flag = 'Y'
            WHERE     zone_3_name = b.zone_3_name
                  AND zone_4_name = b.zone_4_name
                  AND zone_5_name = b.zone_5_name
                  AND zone_6_name = b.zone_6_name
                  AND zone_7_name = b.zone_7_name
                  AND zone_7_name IS NOT NULL;
                /*
                  AND NVL(zone_5_name, 'zone5') = NVL(b.zone_5_name, 'zone5') -- crapp-2536, added NVL statements
                  AND NVL(zone_6_name, 'zone6') = NVL(b.zone_6_name, 'zone6')
                  AND NVL(zone_7_name, 'zone7') = NVL(b.zone_7_name, 'zone7');
                  --AND zone_7_name IS NOT NULL;  -- crapp-2536, removed
                */
            -- crapp-2087/2267 - set Zone6 to Bottom-Up for Fake Zip9s --
            IF ASCII(b.zone_7_name) BETWEEN 65 AND 90 THEN
                UPDATE gis_zone_tree_tmp
                    SET default_flag    = NULL,
                        reverse_flag    = 'Y',
                        terminator_flag = 'Y'
                WHERE     zone_7_name IS NULL
                      AND zone_3_name = b.zone_3_name
                      AND zone_4_name = b.zone_4_name
                      AND zone_5_name = b.zone_5_name
                      AND zone_6_name = b.zone_6_name;
            END IF;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Set flags for bottom-up - gis_zone_tree_tmp', paction=>1, puser=>l_user);


        -- Set the Reverse_Flag to indicate Top-Down --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Set flags for top-down - gis_zone_tree_tmp', paction=>0, puser=>l_user);
        FOR d IN top_down LOOP
            UPDATE gis_zone_tree_tmp t
                SET default_flag    = NULL,
                    reverse_flag    = 'N',
                    terminator_flag = 'N'
            WHERE     t.zone_3_name = d.zone_3_name
                  AND t.zone_4_name = d.zone_4_name
                  AND t.zone_5_name = d.zone_5_name
                  AND t.zone_6_name = d.zone_6_name
                  AND t.zone_7_name = d.zone_7_name
                  AND t.reverse_flag IS NULL
                  AND t.zone_7_name IS NOT NULL;
                /*
                  AND NVL(t.zone_5_name, 'zone5') = NVL(d.zone_5_name, 'zone5') -- crapp-2536, added NVL statements
                  AND NVL(t.zone_6_name, 'zone6') = NVL(d.zone_6_name, 'zone6')
                  AND NVL(t.zone_7_name, 'zone7') = NVL(d.zone_7_name, 'zone7')
                  AND t.reverse_flag IS NULL;
                  --AND t.zone_7_name IS NOT NULL;  -- crapp-2536, removed
                */
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Set flags for top-down - gis_zone_tree_tmp', paction=>1, puser=>l_user);


        -- Remove Zip4 ranges for the Default Zip5 records --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get list of defaults - gis_defaults_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_defaults_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_defaults_tmp_n1 UNUSABLE'; -- crapp-3406
        INSERT INTO gis_defaults_tmp
            (zone_3_name, zone_4_name, zone_5_name, zone_6_name, default_flag)
            SELECT /*+index(p geo_polygons_un)*/
                   DISTINCT
                   UPPER(u.state_name)    state_name
                   , UPPER(u.county_name) county_name
                   , UPPER(u.city_name)   city_name
                   , u.zip
                   , CASE WHEN u.override_rank = 1 THEN 'Y' ELSE NULL END default_flag
            FROM  geo_usps_lookup u    -- 06/17/15 changed table crapp-1418
                  JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
                  JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                                    AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
            WHERE u.state_code = stcode_i
                  AND DECODE(NVL(SUBSTR(u.zip9,6,4), 'XXXX'), 'XXXX', 0, 1) = 0;  -- zip4 IS NULL
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX gis_defaults_tmp_n1 REBUILD'; -- crapp-3406
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_defaults_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get list of defaults - gis_defaults_tmp', paction=>1, puser=>l_user);


        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Update defaults - gis_zone_tree_tmp', paction=>0, puser=>l_user);
        -- crapp-3406 - set flag so we keep the zip9 ranges --
        FOR d IN defaultzips_crossborder LOOP
            UPDATE gis_zone_tree_tmp z
                SET z.default_flag = 'C'
            WHERE     z.zone_4_name = d.zone_4_name
                  AND z.zone_5_name = d.zone_5_name
                  AND z.zone_6_name = d.zone_6_name
                  AND z.zone_7_name IS NOT NULL;
        END LOOP;
        COMMIT;


        FOR d IN defaultzips LOOP
            UPDATE gis_zone_tree_tmp z
                SET zone_7_name      = NULL,
                    zone_7_id        = NULL,
                    zone_7_level_id  = NULL,
                    zone_7_parent_id = NULL,
                    code_fips        = SUBSTR(code_fips, 1, 15),
                    range_min        = NULL,
                    range_max        = NULL
            WHERE     z.zone_4_name = d.zone_4_name
                  AND z.zone_5_name = d.zone_5_name
                  AND z.zone_6_name = d.zone_6_name
                  AND z.zone_7_name IS NOT NULL
                  AND z.reverse_flag IS NULL
                  AND z.default_flag IS NULL;   -- crapp-3406, added to exclude crossborder zips
        END LOOP;
        COMMIT;


        -- crapp-3406 - clear flag on crossborder zip ranges --
        UPDATE gis_zone_tree_tmp
            SET default_flag = NULL
        WHERE default_flag = 'C';
        COMMIT;


        FOR d IN defaultzips LOOP
            UPDATE gis_zone_tree_tmp z
                SET z.default_flag = 'Y'
            WHERE     z.zone_4_name = d.zone_4_name
                  AND z.zone_5_name = d.zone_5_name
                  AND z.zone_6_name = d.zone_6_name
                  AND z.zone_7_name IS NULL;
        END LOOP;
        COMMIT;


        -- Set Default Flag on Multi-City
        FOR d IN defaultmulticity LOOP
            UPDATE gis_zone_tree_tmp z
                SET z.default_flag = d.default_flag
            WHERE     z.zone_3_name = d.zone_3_name
                  AND z.zone_4_name = d.zone_4_name
                  AND z.zone_5_name = d.zone_5_name
                  AND z.zone_6_name IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Update defaults - gis_zone_tree_tmp', paction=>1, puser=>l_user);


        -- Set the Reverse_Flag to indicate Top-Down on remaining tree
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Cleanup flags - gis_zone_tree_tmp', paction=>0, puser=>l_user);
        UPDATE gis_zone_tree_tmp
            SET reverse_flag = 'N'
        WHERE  zone_7_name IS NULL
            AND reverse_flag IS NULL;
        COMMIT;

        UPDATE gis_zone_tree_tmp
            SET reverse_flag    = 'N',
                terminator_flag = 'N'
        WHERE  zone_7_name IS NOT NULL
            AND reverse_flag IS NULL;
        COMMIT;

        UPDATE gis_zone_tree_tmp
            SET default_flag = 'N'
        WHERE  zone_7_name IS NULL
            AND zone_6_name IS NOT NULL
            AND default_flag IS NULL;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Cleanup flags - gis_zone_tree_tmp', paction=>1, puser=>l_user);


        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Remove illegitimate Zip9s - gis_zone_tree_tmp', paction=>0, puser=>l_user); -- crapp-2087
        FOR r IN removezip9s_tree LOOP
            UPDATE gis_zone_tree_tmp z
                SET zone_7_id        = NULL,
                    zone_7_name      = NULL,
                    zone_7_level_id  = NULL,
                    zone_7_parent_id = NULL,
                    code_fips        = SUBSTR(code_fips, 1, 15),
                    range_min        = NULL,
                    range_max        = NULL,
                    terminator_flag  = r.terminator_flag,
                    default_flag     = r.default_flag
            WHERE     z.zone_4_name = r.zone_4_name
                  AND z.zone_5_name = r.zone_5_name
                  AND z.zone_6_name = r.zone_6_name
                  AND z.zone_7_name = r.zone_7_name;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Remove illegitimate Zip9s - gis_zone_tree_tmp', paction=>1, puser=>l_user);


        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Remove illegitimate Zip9s - gis_authorities_tmp', paction=>0, puser=>l_user); -- crapp-2087
        FOR r IN removezip9s_auth LOOP
            UPDATE gis_authorities_tmp z
                SET zone_7_id        = NULL,
                    zone_7_name      = NULL,
                    zone_7_level_id  = NULL,
                    code_fips        = SUBSTR(code_fips, 1, 15),
                    range_min        = NULL,
                    range_max        = NULL,
                    terminator_flag  = NULL
            WHERE     z.zone_4_name = r.zone_4_name
                  AND z.zone_5_name = r.zone_5_name
                  AND z.zone_6_name = r.zone_6_name
                  AND z.zone_7_name = r.zone_7_name;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Remove illegitimate Zip9s - gis_authorities_tmp', paction=>1, puser=>l_user);


        -- Push to GIS_ZTREE_TMP --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Push to gis_ztree_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_ztree_tmp DROP STORAGE';
        INSERT INTO gis_ztree_tmp
            ( merchant_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name,
              code_2char, code_fips, reverse_flag, terminator_flag, default_flag, range_min, range_max, creation_date
            )
            SELECT DISTINCT
                   merchant_id
                   , zone_1_name
                   , zone_2_name
                   , zone_3_name
                   , zone_4_name
                   , zone_5_name
                   , zone_6_name
                   , zone_7_name
                   , code_2char
                   , code_fips
                   , reverse_flag
                   , terminator_flag
                   , default_flag
                   , range_min
                   , range_max
                   , SYSDATE creation_date
            FROM   gis_zone_tree_tmp;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Push to gis_ztree_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild stats - gis_ztree_tmp', paction=>0, puser=>l_user);
            DBMS_STATS.gather_table_stats(vcurrent_schema, 'GIS_ZTREE_TMP', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild stats - gis_ztree_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'push_gis_zone_tree, tag_grp_id = '||l_tag_grp||', instance_id = '||l_instance, paction=>1, puser=>l_user);
    END push_gis_zone_tree;



    PROCEDURE push_gis_zone_authorities(stcode_i IN VARCHAR2, tag_grp_i IN NUMBER, instance_i IN NUMBER) IS -- 09/28/17 crapp-4072

        l_merchantid     NUMBER            := 2;  -- 'Sabrix US Tax Data'
        l_zone1name      VARCHAR2(10 CHAR) := 'WORLD';
        l_zone2name      VARCHAR2(25 CHAR) := 'UNITED STATES';
        l_rec            NUMBER := 0;
        l_stj            NUMBER(1,0) := 0;
        l_uniquearea     VARCHAR2(1000 CHAR);
        l_statename      VARCHAR2(50 CHAR);
        l_county         VARCHAR2(50 CHAR);
        l_city           VARCHAR2(50 CHAR);
        l_codefips       VARCHAR2(25 CHAR);
        l_sql            VARCHAR2(3000 CHAR);
        l_schema         VARCHAR2(10 CHAR);
        l_default        CHAR(1);
        l_zip            CHAR(5);
        l_zip4min        CHAR(4);
        l_nextzip4       CHAR(4);
        l_zip4ascii      CHAR(4);
        l_nextzip4_ascii NUMBER;
        l_firstpass      BOOLEAN := TRUE;
        l_user           NUMBER := -204;
        l_telco_tggrp    NUMBER;
        l_pID            NUMBER := gis_etl_process_log_sq.nextval;
        l_hlvl           NUMBER;    -- crapp-4072
        vcurrent_schema  VARCHAR2(50);


        TYPE t_counties IS VARRAY(5) OF VARCHAR(3);
        v_county_start t_counties;
        v_county_end   t_counties;

        TYPE t_zones IS TABLE OF gis_zone_authorities_tmp%ROWTYPE;
        v_zones  t_zones;

        TYPE t_stj IS TABLE OF gis_zone_stj_areas_tmp%ROWTYPE;
        v_stj  t_stj;

        TYPE t_authcnts IS TABLE OF gis_zone_auth_counts_tmp%ROWTYPE;
        v_authcnts  t_authcnts;

        TYPE t_authcnts2 IS TABLE OF gis_zone_auth_counts2_tmp%ROWTYPE;
        v_authcnts2  t_authcnts2;

        TYPE t_authcntstage IS TABLE OF gis_zone_auth_counts_stage%ROWTYPE;
        v_authcntstage  t_authcntstage;

        TYPE t_authnozips IS TABLE OF gis_zone_auth_nozip_tmp%ROWTYPE;
        v_authnozips  t_authnozips;

        TYPE t_bustage IS TABLE OF gis_zone_auth_bustage_tmp%ROWTYPE;
        v_bustage  t_bustage;

        TYPE t_budetail IS TABLE OF gis_zone_auth_budetail_tmp%ROWTYPE;
        v_budetail  t_budetail;

        TYPE t_authstage IS TABLE OF gis_zone_auth_stage_tmp%ROWTYPE;
        v_authstage  t_authstage;

        TYPE t_auths IS TABLE OF gis_zone_authorities_tmp%ROWTYPE;
        v_auths  t_auths;

        TYPE t_arealist IS TABLE OF gis_area_list_tmp%ROWTYPE;
        v_arealist  t_arealist;

        TYPE t_authupdt IS TABLE OF gis_zone_auth_updates_tmp%ROWTYPE;
        v_authupdt  t_authupdt;

        TYPE t_jurisauth IS TABLE OF gis_zone_juris_auths_tmp%ROWTYPE;
        v_jurisauth  t_jurisauth;

        TYPE t_areastage IS TABLE OF gis_area_stage_tmp%ROWTYPE;
        v_areastage  t_areastage;

        TYPE r_geoarea IS RECORD
        (
          state_code       gis_area_list_tmp.state_code%TYPE,
          official_name    gis_area_list_tmp.official_name%TYPE,
          geo_polygon_rid  gis_area_list_tmp.rid%TYPE,
          geo_area         gis_area_list_tmp.geo_area%TYPE,
          stj_flag         gis_area_list_tmp.stj_flag%TYPE
        );
        TYPE t_geoarea IS TABLE OF r_geoarea;
        v_geoarea t_geoarea;

        -- crapp-2357 --
        TYPE r_geoarea_upd IS RECORD
        (
          state_code     gis_area_list_tmp.state_code%TYPE,
          unique_area    gis_area_list_tmp.unique_area%TYPE,
          official_name  gis_area_list_tmp.official_name%TYPE,
          geo_area       gis_area_list_tmp.geo_area%TYPE,
          poly_rid       gis_area_list_tmp.rid%TYPE,
          upd_flag       gis_area_list_tmp.geoarea_updated%TYPE
        );
        TYPE t_geoarea_upd IS TABLE OF r_geoarea_upd;
        v_geoarea_upd t_geoarea_upd;

        TYPE t_dtl IS TABLE OF gis_zone_detail_tmp%ROWTYPE;     -- 06/08/17
        v_dtl  t_dtl;

        -- crapp-4072 --
        TYPE r_zoneauths IS RECORD
        (
          zone_3_name       gis_zone_authorities_tmp.zone_3_name%TYPE,
          zone_4_name       gis_zone_authorities_tmp.zone_4_name%TYPE,
          zone_5_name       gis_zone_authorities_tmp.zone_5_name%TYPE,
          zone_6_name       gis_zone_authorities_tmp.zone_6_name%TYPE,
          zone_7_name       gis_zone_authorities_tmp.zone_7_name%TYPE,
          authority_name    gis_zone_authorities_tmp.authority_name%TYPE
        );
        TYPE t_zoneauths IS TABLE OF r_zoneauths;
        v_zoneauths t_zoneauths;

        /*
        -- crapp-2536 --
        TYPE r_bu_pct IS RECORD
        (
           state_code       gis_zone_auth_bu_rollup_pct.state_code%TYPE
          ,authority_name   gis_zone_auth_bu_rollup_pct.authority_name%TYPE
          ,zone_3_name      gis_zone_auth_bu_rollup_pct.zone_3_name%TYPE
          ,zone_4_name      gis_zone_auth_bu_rollup_pct.zone_4_name%TYPE
          ,zone_5_name      gis_zone_auth_bu_rollup_pct.zone_5_name%TYPE
          ,level_count      gis_zone_auth_bu_rollup_pct.zipcnt%TYPE
          ,total_count      gis_zone_auth_bu_rollup_pct.totalzipcnt%TYPE
          ,pct              gis_zone_auth_bu_rollup_pct.zippct%TYPE
        );
        TYPE t_bu_pct IS TABLE OF r_bu_pct;
        v_bu_pct t_bu_pct;
        */

        -- 09/27/17 - Updated for performance - crapp-4072 --
        CURSOR detail(stcd VARCHAR2) IS
            WITH areas AS
                (
                 SELECT DISTINCT state_code, area_id, unique_area
                 FROM   vgeo_unique_areas2
                 WHERE  state_code = stcd
                ),
                usps AS
                (
                SELECT  /*+parallel(u,4)*/
                        DISTINCT
                        state_code
                        , SUBSTR(UPPER(state_name), 1, 50)  state_name
                        , SUBSTR(UPPER(county_name), 1, 50) county_name
                        , SUBSTR(UPPER(city_name), 1, 50)   city_name
                        , zip
                        , zip9
                        , SUBSTR(zip9, 6, 4) zip4
                        , CASE WHEN override_rank = 1 THEN 'Y' ELSE NULL END default_flag
                        , (state_fips||county_fips||city_fips||NVL(zip, '')) code_fips
                        , area_id
                        , geo_polygon_id
                FROM    geo_usps_lookup u
                WHERE   state_code = stcd
                ),
                poly AS
                (
                SELECT  /*+index(p geo_polygons_un)*/
                        DISTINCT
                        u.state_code
                        , u.state_name
                        , u.county_name
                        , u.city_name
                        , u.zip
                        , u.zip9
                        , u.zip4
                        , u.default_flag
                        , u.code_fips
                        , ac.NAME geo_area
                        , u.area_id
                        , p.rid
                FROM    usps u
                        JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
                        JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                                          AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
                        JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
                        JOIN geo_area_categories ac ON (hl.geo_area_category_id = ac.id)
                WHERE   u.state_code = stcd
                        AND p.next_rid IS NULL
                )
                SELECT    u1.state_code
                        , u1.state_name
                        , u1.county_name
                        , u1.city_name
                        , u1.zip
                        , u1.zip9
                        , u1.zip4
                        , u1.default_flag
                        , u1.code_fips
                        , u1.geo_area
                        , gua.unique_area
                        , u1.rid
                FROM    poly u1
                        JOIN areas gua ON ( u1.state_code  = gua.state_code
                                            AND u1.area_id = gua.area_id
                                          );


        -- crapp-4072 - performance changes --
        CURSOR detail_no_overrides(st_i VARCHAR2, countystart_i VARCHAR2, countyend_i VARCHAR2) IS
            SELECT /*+index(g gis_zone_detail_tmp_n4)*/
                     g.unique_area
                   , NVL(d.stj_flag, 0) stj_flag
                   , g.state_name
                   , g.county_name
                   , g.city_name
                   , g.zip
                   , NVL2(geo_poly_id, NULL, g.zip4) zip4
                   , g.default_flag
                   , g.code_fips
                   , g.state_code
                   , jpa.jurisdiction_id
                   , jpa.official_name
                   , jpa.rid
                   , jpa.nkid
                   , g.geo_area
                   , NULL geoarea_updated
            FROM   gis_zone_detail_tmp g
                   JOIN gis_zone_mapped_auths_tmp jpa ON (g.rid = jpa.geo_polygon_rid)
                   JOIN jurisdictions j ON (jpa.jurisdiction_nkid = j.nkid)
                   LEFT JOIN gis_zone_stj_areas_tmp d ON ( g.unique_area = d.unique_area
                                                           AND g.zip9 = d.zip9)
                   LEFT JOIN ( SELECT a.geo_poly_id, a.geo_poly_rid, p.geo_area_key
                               FROM   vgeo_poly_attributes a
                                      JOIN geo_polygons p ON (a.geo_poly_id = p.id)
                               WHERE  attribute_name = 'Restrict Zip+4 Load to Determination'
                                      AND VALUE = 'Y'
                             ) pa ON (g.unique_area LIKE ('%'||pa.geo_area_key||'%'))
            WHERE  g.state_code = st_i
                   AND g.county_name BETWEEN countystart_i AND countyend_i
                   AND g.zip4 IS NOT NULL
                   --AND g.geo_area <> 'State'  -- crapp-3793, removed
                   AND g.default_flag = 'Y'
                   AND j.nkid IN (SELECT /*+index(tt gis_zone_auth_tags_tmp_n1)*/ ref_nkid FROM gis_zone_auth_tags_tmp tt)
                   AND j.next_rid IS NULL
                   AND NOT EXISTS ( SELECT 1
                                    FROM   gis_zone_areas_tmp o
                                    WHERE      g.unique_area = o.unique_area
                                           AND g.state_code  = o.state_code
                                  );


        -- 08/31/17 - performance changes --
        CURSOR detail_w_overrides(st_i VARCHAR2, countystart_i VARCHAR2, countyend_i VARCHAR2) IS
            WITH detail AS
                ( SELECT  /*+index(g gis_zone_detail_tmp_n4)*/ -- crapp-2911, using updated index N4 instead of N2
                          DISTINCT
                          g.unique_area
                        , g.geo_area
                        , g.state_name
                        , g.county_name
                        , g.city_name
                        , g.zip
                        , g.zip9
                        , NVL2(geo_poly_id, NULL, g.zip4) zip4
                        , g.default_flag
                        , g.code_fips
                        , g.state_code
                        , g.rid             -- crapp-2357
                        , p.nkid            -- crapp-2357
                  FROM  gis_zone_detail_tmp g
                        JOIN geo_polygons p ON (g.rid = p.rid
                                                AND p.next_rid IS NULL
                                               )
                        LEFT JOIN ( SELECT a.geo_poly_id, a.geo_poly_rid, p.geo_area_key
                                    FROM   vgeo_poly_attributes a
                                           JOIN geo_polygons p ON (a.geo_poly_id = p.id)
                                    WHERE  attribute_name = 'Restrict Zip+4 Load to Determination'
                                           AND VALUE = 'Y'
                                   ) pa ON (g.unique_area LIKE ('%'||pa.geo_area_key||'%'))
                  WHERE   g.state_code = st_i
                          AND g.county_name BETWEEN countystart_i AND countyend_i
                          AND g.zip4 IS NOT NULL
                          AND g.default_flag = 'Y'
                )
                SELECT  /*+index(z gis_zone_detail_tmp_n1)*/
                        d.unique_area
                        , NVL(sa.stj_flag, 0) stj_flag
                        , d.state_name
                        , d.county_name
                        , d.city_name
                        , d.zip
                        , d.zip4
                        , d.default_flag
                        , d.code_fips
                        , d.state_code
                        , o.jurisdiction_id
                        , o.official_name
                        , d.rid     -- o.unique_area_rid   rid      -- 02/17/16 crapp-2357 changed to Polygon RID
                        , d.nkid    -- o.unique_area_nkid  nkid     -- 02/17/16 crapp-2357 changed to Polygon NKID
                        , d.geo_area
                        , NULL geoarea_updated
                FROM    detail d
                        JOIN gis_zone_areas_tmp o ON (     d.unique_area = o.unique_area
                                                       AND d.state_code  = o.state_code
                                                       AND d.geo_area    = o.effective_level
                                                     )
                        LEFT JOIN gis_zone_stj_areas_tmp sa ON ( d.unique_area = sa.unique_area
                                                                 AND d.zip9 = sa.zip9)
                WHERE   o.jurisdiction_nkid IN (SELECT /*+index(tt gis_zone_auth_tags_tmp_n1)*/ ref_nkid FROM gis_zone_auth_tags_tmp tt);


        -- 09/08/17 - performance changes --
        CURSOR dtl_overrides_nozip4(st_i VARCHAR2) IS
            SELECT  DISTINCT
                    g.unique_area
                    , NVL(d.stj_flag, 0) stj_flag
                    , g.state_name
                    , g.county_name
                    , g.city_name
                    , g.zip
                    , g.zip4
                    , g.default_flag
                    , g.code_fips
                    , g.state_code
                    , o.jurisdiction_id
                    , o.official_name
                    , g.rid     -- o.unique_area_rid   rid      -- 02/17/16 crapp-2357 changed to Polygon RID
                    , p.nkid    -- o.unique_area_nkid  nkid     -- 02/17/16 crapp-2357 changed to Polygon NKID
                    , g.geo_area
                    , NULL geoarea_updated
            FROM    --TABLE(gis.F_GetZoneDetailFeed(st_i)) g    -- 09/25/15 - converted to Piped Feed  -- 09/08/17, removed
                    (   -- 09/08/17, replaces Piped function --
                        SELECT *
                        FROM   gis_zone_detail_tmp
                        WHERE  state_code = st_i
                               AND zip IS NOT NULL       -- 10/01/15 crapp-2087
                               AND zip4 IS NULL
                               --AND geo_area <> 'State' -- crapp-3793, removed
                               AND unique_area NOT IN (SELECT unique_area FROM gis_area_stage_tmp)  -- crapp-3766, exclude areas with Zip4 values
                    ) g
                    JOIN geo_polygons p ON (g.rid = p.rid
                                            AND p.next_rid IS NULL
                                           )
                    JOIN gis_zone_areas_tmp o ON (     g.unique_area = o.unique_area       -- Overrides --
                                                   AND g.state_code  = o.state_code
                                                   AND g.geo_area    = o.effective_level
                                                 )
                    LEFT JOIN gis_zone_stj_areas_tmp d ON ( g.unique_area = d.unique_area )
            WHERE   o.jurisdiction_nkid IN (SELECT /*+index(tt GIS_ZONE_AUTH_TAGS_tmp_N1)*/ ref_nkid FROM gis_zone_auth_tags_tmp tt);  -- crapp-3766, exclude areas with Zip4 values


        -- 09/08/17 - performance changes --
        CURSOR dtl_overrides_nozip(st_i VARCHAR2) IS
            SELECT  DISTINCT
                    g.unique_area
                    , NVL(d.stj_flag, 0) stj_flag
                    , g.state_name
                    , g.county_name
                    , g.city_name
                    , g.zip
                    , g.zip4
                    , g.default_flag
                    , g.code_fips
                    , g.state_code
                    , o.jurisdiction_id
                    , o.official_name
                    , g.rid
                    , p.nkid
                    , g.geo_area
                    , NULL geoarea_updated
            FROM    --TABLE(gis.F_GetZoneDetailFeed(stcode_i)) g    -- 09/08/17, removed
                    (   -- 09/08/17, replaces Piped function --
                        SELECT *
                        FROM   gis_zone_detail_tmp
                        WHERE  state_code = st_i
                               AND zip IS NULL
                               --AND geo_area <> 'State' -- crapp-3793, removed
                               AND unique_area NOT IN (SELECT unique_area FROM gis_area_stage_tmp)  -- crapp-3766, exclude areas with Zip4 values
                    ) g
                    JOIN geo_polygons p ON (g.rid = p.rid
                                            AND p.next_rid IS NULL
                                           )
                    JOIN gis_zone_areas_tmp o ON (     g.unique_area = o.unique_area       -- Overrides --
                                                   AND g.state_code  = o.state_code
                                                   AND g.geo_area    = o.effective_level
                                                 )
                    LEFT JOIN gis_zone_stj_areas_tmp d ON ( g.unique_area = d.unique_area )
            WHERE   o.jurisdiction_nkid IN (SELECT /*+index(tt gis_zone_auth_tags_tmp_n1)*/ ref_nkid FROM gis_zone_auth_tags_tmp tt);


        -- 09/08/17 - performance changes --
        CURSOR dtl_nooverride_nozip4(st_i VARCHAR2, countystart_i VARCHAR2, countyend_i VARCHAR2) IS
            WITH stjs AS
                ( SELECT DISTINCT state_code, unique_area, zip9, stj_flag
                  FROM   gis_zone_stj_areas_tmp
                  WHERE  zip9 IS NOT NULL
                )
            SELECT  /*+index(jpa gis_zone_mapped_auths_tmp_n1) index(ua gis_zone_ua_areas_tmp_n1)*/
                    DISTINCT
                    g.unique_area
                    , NVL(d.stj_flag, 0) stj_flag
                    , g.state_name
                    , g.county_name
                    , g.city_name
                    , g.zip
                    , g.zip4
                    , g.default_flag
                    , g.code_fips
                    , g.state_code
                    , jpa.jurisdiction_id
                    , jpa.official_name
                    , jpa.rid
                    , jpa.nkid
                    , 'District' geo_area
            FROM    --TABLE(gis.F_GetZoneDetailFeed(stcode_i)) g    -- 09/08/17, removed
                    (   -- 09/08/17, replaces Piped function --
                        SELECT *
                        FROM   gis_zone_detail_tmp
                        WHERE  state_code = st_i
                               AND county_name BETWEEN countystart_i AND countyend_i
                               AND zip4 IS NOT NULL
                               AND default_flag = 'Y'
                    ) g
                    JOIN gis_zone_mapped_auths_tmp jpa ON (g.state_code = jpa.state_code
                                                           AND g.rid = jpa.geo_polygon_rid)
                    JOIN gis_zone_unique_areas_tmp ua ON (g.state_code = ua.state_code
                                                          AND g.unique_area = ua.unique_area)
                    LEFT JOIN stjs d ON (g.unique_area = d.unique_area
                                         AND g.zip9 = d.zip9)
            WHERE   jpa.jurisdiction_nkid IN (SELECT ref_nkid FROM gis_zone_auth_tags_tmp);


        -- crapp-4072 - performance changes --
        CURSOR juris_ranges(st_i VARCHAR2) IS
            SELECT /*+parallel(a,4)*/
                   DISTINCT
                   unique_area
                   , NULL stj_flag
                   , state_name
                   , county_name
                   , city_name
                   , zip
                   , zip4
                   , NULL default_flag
                   , CASE WHEN ASCII(zip4) BETWEEN 65 AND 90 THEN ASCII(zip4)                            -- crapp-2087
                          WHEN ASCII(SUBSTR(zip4,3,2)) BETWEEN 65 AND 90 THEN ASCII(SUBSTR(zip4,3,2))    -- crapp-3304
                          ELSE NULL
                     END zip4_ascii
                   , state_code
                   , NULL jurisdiction_id
                   , official_name
                   , NULL rid
                   , NULL nkid
                   , geo_area
             FROM  gis_area_list_tmp a
             WHERE state_code = st_i;


        CURSOR zip4tree IS
            SELECT  /*+parallel(a,4)*/ -- crapp-4072
                    DISTINCT stj_flag, state_code, state_name, county_name, city_name, zip
                    , zip4, default_flag, code_fips, unique_area
                    , CASE WHEN ASCII(zip4) BETWEEN 65 AND 90 THEN ASCII(zip4)                          -- crapp-2087
                           WHEN ASCII(SUBSTR(zip4,3,2)) BETWEEN 65 AND 90 THEN ASCII(SUBSTR(zip4,3,2))  -- crapp-3304
                           ELSE NULL END zip4_ascii
            FROM    gis_area_list_tmp a
            ORDER BY zip, zip4, county_name, city_name, unique_area;


        -- 1 - Cursor to clean-up NULL zip Districts --
        CURSOR cleanupnulls IS
            SELECT DISTINCT
                   z.zone_3_name
                   , z.zone_4_name
                   , z.zone_5_name
                   , z.zone_6_name
                   , z.zone_7_name
                   , z.authority_name
            FROM   gis_zone_authorities_tmp z
                   JOIN ( SELECT DISTINCT
                                 zone_3_name
                                 , zone_4_name
                                 , zone_5_name
                                 , zone_6_name
                                 , authority_name
                          FROM   gis_zone_authorities_tmp
                          WHERE  geo_area = 'District'
                                 AND zone_7_name IS NOT NULL
                        ) a ON (     z.zone_3_name = a.zone_3_name
                                 AND z.zone_4_name = a.zone_4_name
                                 AND z.zone_5_name = a.zone_5_name
                                 AND z.authority_name = a.authority_name
                               )
            WHERE  z.zone_6_name IS NULL
            ORDER BY z.authority_name;


        -- 2.1 - Cursor to attach Authorities at City Level - 100% of County/City - District -- 07/02/15 - crapp-1874
        CURSOR attach_city IS
            SELECT  DISTINCT
                    t.zone_3_name, t.zone_4_name, t.zone_5_name, t.zone_6_name, t.zone_7_name, t.authority_name, t.geo_area
            FROM    gis_zone_authorities_tmp t
                    JOIN gis_zone_auth_counts_stage c ON (     t.zone_3_name = c.zone_3_name
                                                           AND t.zone_4_name = c.zone_4_name
                                                           AND t.zone_5_name = c.zone_5_name
                                                           AND t.authority_name = c.authority_name
                                                         )
                    LEFT JOIN gis_zone_auth_budetail_tmp b ON (     t.zone_3_name = b.zone_3_name
                                                                AND t.zone_4_name = b.zone_4_name
                                                                AND t.zone_5_name = b.zone_5_name
                                                                AND t.zone_6_name = b.zone_6_name
                                                                AND t.zone_7_name = b.zone_7_name
                                                                AND t.authority_name = b.authority_name
                                                              )
            WHERE   c.zippct = 1
                    AND b.zone_3_name IS NULL;   -- crapp-2159 - Exclude Bottom-Up areas


        -- 2.2 - crapp-1812 --
        -- Cursor to update Zone Tree records for Authorities in remainder of >= 70% in County/City/Zip (make Bottom-Up) - District
        CURSOR attach_bu IS
            SELECT /*+index(t gis_zone_auth_tmp_n2)*/   -- 05/04/17 added index
                   DISTINCT
                   t.zone_3_name, t.zone_4_name, t.zone_5_name, t.zone_6_name, t.zone_7_name, t.authority_name, t.geo_area, t.range_min, t.range_max
            FROM   gis_zone_authorities_tmp t
                   JOIN gis_zone_auth_budetail_tmp bu ON (     t.zone_3_name = bu.zone_3_name
                                                           AND t.zone_4_name = bu.zone_4_name
                                                           AND t.zone_5_name = bu.zone_5_name
                                                           AND t.zone_6_name = bu.zone_6_name
                                                           AND t.zone_7_name = bu.zone_7_name
                                                           AND t.authority_name = bu.authority_name
                                                         )
            WHERE  t.zone_7_name IS NOT NULL
            ORDER BY t.authority_name
                    , t.zone_6_name
                    , t.zone_7_name
                    , t.zone_4_name
                    , t.zone_5_name;


        -- 2.3 - Cursor to attach Authorities at Zip - > 70% and < 100% - District -- 07/01/15 - crapp-1872
        CURSOR attach_zip IS
            SELECT DISTINCT
                   t.zone_3_name, t.zone_4_name, t.zone_5_name, t.zone_6_name, t.zone_7_name, t.authority_name
            FROM   gis_zone_authorities_tmp t
                   JOIN (
                        SELECT  DISTINCT
                                r.authority_name
                                , r.zone_3_name
                                , r.zone_4_name
                                , r.zone_5_name
                                , r.zone_6_name
                                , r.zone_7_name
                        FROM    gis_zone_auth_counts_tmp r
                                JOIN ( SELECT DISTINCT
                                              zone_3_name
                                              , zone_4_name
                                              , zone_5_name
                                              , zone_6_name
                                              , authority_name
                                              , zippct
                                       FROM   gis_zone_auth_counts2_tmp
                                       WHERE  zippct > 0.7 AND zippct < 1
                                     ) td ON (     r.zone_3_name = td.zone_3_name
                                               AND r.zone_4_name = td.zone_4_name
                                               AND r.zone_5_name = td.zone_5_name
                                               AND r.zone_6_name = td.zone_6_name
                                               AND r.authority_name = td.authority_name
                                             )
                        ) z ON (     t.zone_3_name = z.zone_3_name
                                 AND t.zone_4_name = z.zone_4_name
                                 AND t.zone_5_name = z.zone_5_name
                                 AND t.zone_6_name = z.zone_6_name
                                 AND t.zone_7_name = z.zone_7_name
                                 AND t.authority_name = z.authority_name
                               )
            WHERE  t.processed IS NULL;


        -- 2.4 - Cursor to attach Authorities at Zip Level - 100% of County/City/Zip - District -- 07/01/15 - crapp-1872 -- 07/16/15 moved up a step
        CURSOR attach_zip_100pct IS
            SELECT  DISTINCT
                    zone_3_name, zone_4_name, zone_5_name, zone_6_name, NVL(zone_7_name, 'zone7') zone_7_name, authority_name, geo_area
            FROM    gis_zone_auth_updates_tmp;


        -- 2.45 - Cursor to attach Authorities at City Level - 100% UA city/county combo - City -- crapp-3195
        CURSOR attach_zip_100pct_city IS
            SELECT DISTINCT t.*
            FROM   ( SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                     FROM   gis_zone_authorities_tmp
                     WHERE  zone_6_name IS NOT NULL
                            AND zone_7_name IS NULL
                            AND processed IS NOT NULL
                            --AND geo_area = 'District'
                   ) t
                   JOIN (
                         SELECT   zone_3_name
                                , zone_4_name
                                , zone_5_name
                                , zone_6_name
                                , authority_name
                                , COUNT(DISTINCT (zone_4_name||'|'||zone_5_name)) total_area_count
                         FROM   gis_zone_authorities_tmp z
                         WHERE  zone_6_name IS NOT NULL
                                AND zone_7_name IS NULL
                                AND processed IS NOT NULL
                                AND NOT EXISTS ( -- crapp-4039 --
                                                SELECT 1
                                                FROM   gis_zone_auth_counts_stage s
                                                WHERE      s.zone_3_name = z.zone_3_name
                                                       AND s.zone_4_name = z.zone_4_name
                                                       AND s.zone_5_name = z.zone_5_name
                                                       AND s.authority_name = z.authority_name
                                                       AND s.zippct != 1
                                               )
                                AND NOT EXISTS ( -- crapp-4039 - Exclude Bottom up areas --
                                                SELECT 1
                                                FROM   gis_zone_auth_budetail_tmp b
                                                WHERE      b.zone_3_name = z.zone_3_name
                                                       AND b.zone_4_name = z.zone_4_name
                                                       AND b.zone_5_name = z.zone_5_name
                                                       AND b.zone_6_name = z.zone_6_name
                                                       AND b.authority_name = z.authority_name
                                               )
                         GROUP BY zone_3_name
                                , zone_4_name
                                , zone_5_name
                                , zone_6_name
                                , authority_name
                        ) c ON (     t.zone_3_name = c.zone_3_name
                                 AND t.zone_4_name = c.zone_4_name
                                 AND t.zone_5_name = c.zone_5_name
                                 AND t.zone_6_name = c.zone_6_name
                                 AND t.authority_name = c.authority_name
                               )
            MINUS   -- exclude authorities with bottom-up ranges
            SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
            FROM   gis_zone_auth_budetail_tmp;


        -- 3 - Cursor for Authorities in Entire Zip - County -- updated 07/09/15 to exclude Bottom-Up ranges - crapp-1863 - 07/20/15 moved to before step 2.5
        CURSOR entirecountyzip IS
            SELECT DISTINCT t.*
            FROM   ( SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                     FROM   gis_zone_authorities_tmp
                     WHERE  geo_area = 'County'
                            AND zone_5_name IS NOT NULL     -- 05/26/15 changed from zone6
                   ) t
                   JOIN ( SELECT zone_3_name
                                 , zone_4_name
                                 , zone_5_name
                                 , zone_6_name
                                 , authority_name
                          FROM   gis_zone_auth_counts2_tmp
                          --WHERE  zippct = 1       -- 07/08/15 removed per crapp-1883
                        ) c ON (     t.zone_3_name = c.zone_3_name
                                 AND t.zone_4_name = c.zone_4_name
                                 AND t.zone_5_name = c.zone_5_name
                                 AND t.authority_name = c.authority_name
                               )
            MINUS   -- added 07/09/15 to exclude authorities with bottom-up ranges
            SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
            FROM   gis_zone_auth_budetail_tmp;


        /* -- Removed 10/07/16 - per Coco until crapp-3038 can be implemented
        -- 3.1 - Cursor for Authorities in Entire County - District -- crapp-2613 07/18/16, crapp-2936 08/31/16
        CURSOR entirecountydistrict IS
            SELECT DISTINCT t.*
            FROM   ( SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                     FROM   gis_zone_authorities_tmp
                     WHERE  zone_5_name IS NOT NULL
                            AND zone_6_name IS NULL
                            --AND geo_area = 'District' -- not sure if we need to filter by this or not
                   ) t
                   JOIN (
                         SELECT cac.zone_3_name, cac.zone_4_name, c.citycount, COUNT(DISTINCT cac.zone_5_name) cityauthcount, cac.authority_name
                         FROM   gis_zone_auth_counts2_tmp cac
                                JOIN (
                                      SELECT zone_3_name, zone_4_name, COUNT(DISTINCT zone_5_name) citycount
                                      FROM   gis_zone_auth_counts2_tmp
                                      GROUP BY zone_3_name, zone_4_name
                                     ) c ON (cac.zone_3_name = c.zone_3_name
                                         AND cac.zone_4_name = c.zone_4_name)
                         GROUP BY cac.zone_3_name, cac.zone_4_name, c.citycount, cac.authority_name
                        ) c ON (     t.zone_3_name = c.zone_3_name
                                 AND t.zone_4_name = c.zone_4_name
                                 AND t.authority_name = c.authority_name
                                 AND c.citycount = cityauthcount
                               )
            MINUS
            SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
            FROM   gis_zone_auth_budetail_tmp;
        */


        -- 4 - Cursor for Authorities in Entire Zip - City -- updated 07/09/15 to exclude Bottom-Up ranges - crapp-1863 - 07/20/15 moved to before step 2.5
        CURSOR entirecityzip IS
            SELECT DISTINCT t.*
            FROM   ( SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                     FROM   gis_zone_authorities_tmp
                     WHERE  geo_area = 'City'
                            AND zone_5_name IS NOT NULL     -- 07/07/15 changed from zone6 to match County version
                   ) t
                   JOIN ( SELECT zone_3_name
                                 , zone_4_name
                                 , zone_5_name
                                 , zone_6_name
                                 , authority_name
                          FROM   gis_zone_auth_counts2_tmp
                          --WHERE  zippct = 1       -- 07/08/15 removed per crapp-1883
                        ) c ON (     t.zone_3_name = c.zone_3_name
                                 AND t.zone_4_name = c.zone_4_name
                                 AND t.zone_5_name = c.zone_5_name
                                 AND t.authority_name = c.authority_name
                               )
            MINUS   -- added 07/09/15 to exclude authorities with bottom-up ranges
            SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
            FROM   gis_zone_auth_budetail_tmp;


        -- 4.1 - Cursor for Authorities NOT in 100% of County/City - No Zip -- crapp-3094
        CURSOR notcountycity_nozip IS
            SELECT DISTINCT t.*
            FROM   ( SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                     FROM   gis_zone_authorities_tmp
                     WHERE  zone_5_name IS NOT NULL
                            AND zone_6_name IS NULL
                   ) t
                   JOIN ( SELECT zone_3_name
                                 , zone_4_name
                                 , zone_5_name
                                 , authority_name
                          FROM   gis_zone_auth_nozip_tmp
                          WHERE  areapct <> 1
                        ) c ON (     t.zone_3_name = c.zone_3_name
                                 AND t.zone_4_name = c.zone_4_name
                                 AND t.zone_5_name = c.zone_5_name
                                 AND t.authority_name = c.authority_name
                               );


        -- 4.2 - Cursor for Authorities in 100% County/City - No Zip - Orphans -- crapp-3094
        CURSOR countycitynozip_orphan IS
            SELECT DISTINCT
                   a.zone_3_name
                   , a.zone_4_name
                   , a.zone_5_name
                   , a.authority_name
            FROM   gis_zone_authorities_tmp a
                   LEFT JOIN gis_zone_auth_nozip_tmp nz ON (    a.zone_3_name = nz.zone_3_name
                                                            AND a.zone_4_name = nz.zone_4_name
                                                            AND a.zone_5_name = nz.zone_5_name
                                                            AND a.authority_name = nz.authority_name
                                                           )
            WHERE a.zone_5_name IS NOT NULL
                  AND a.zone_6_name IS NULL
                  AND a.geo_area = 'District'
                  AND a.processed IS NULL
                  AND nz.zone_3_name IS NULL -- Determine Orphans
            ORDER BY a.authority_name, a.zone_4_name, a.zone_5_name;


        -- 4.3 - Cursor to remove Orphaned Authorities - 0% of Zip4s -- crapp-3035
        CURSOR remove_orphans IS
            SELECT  DISTINCT
                    t.zone_3_name, t.zone_4_name, t.zone_5_name, t.zone_6_name, t.zone_7_name, t.authority_name, t.geo_area
            FROM    gis_zone_authorities_tmp t
                    JOIN gis_zone_auth_counts2_tmp c ON (     t.zone_3_name = c.zone_3_name
                                                          AND t.zone_4_name = c.zone_4_name
                                                          AND t.zone_5_name = c.zone_5_name
                                                          AND t.zone_6_name = c.zone_6_name
                                                          AND t.authority_name = c.authority_name
                                                        )
            WHERE   c.zippct = 0
                    AND t.zone_7_name IS NULL;


        -- 4.4 - Cursor for Authorities in 100% County/City - No Zip - Not Orphans -- crapp-3248
        CURSOR countycitynozip_notorphaned IS
            SELECT DISTINCT
                   a.zone_3_name
                   , a.zone_4_name
                   , a.zone_5_name
                   , a.authority_name
            FROM   gis_zone_authorities_tmp a
                   JOIN gis_zone_auth_nozip_tmp nz ON (    a.zone_3_name = nz.zone_3_name
                                                       AND a.zone_4_name = nz.zone_4_name
                                                       AND a.zone_5_name = nz.zone_5_name
                                                       AND a.authority_name = nz.authority_name
                                                      )
            WHERE a.zone_5_name IS NOT NULL
                  AND a.zone_6_name IS NULL
                  AND a.geo_area = 'District'
                  AND a.processed IS NULL
                  AND nz.areacnt = 1
                  AND EXISTS (  -- 08/30/17
                              SELECT 1
                              FROM   (
                                      SELECT state_name       zone_3_name
                                             , official_name  authority_name
                                             , COUNT(DISTINCT unique_area) total_area_count
                                      FROM   gis_area_list_tmp
                                      GROUP BY state_name
                                               , official_name
                                       HAVING COUNT(DISTINCT unique_area) = 1
                                     ) ga
                              WHERE      ga.zone_3_name    = a.zone_3_name
                                     AND ga.authority_name = a.authority_name
                             )
            ORDER BY a.authority_name, a.zone_4_name, a.zone_5_name;


        -- 2.31 - Cursor to remove Zip Level attachments causing double-mapping where UAs are bottom-up (excluding crossborder areas) -- 02/08/16 - crapp-2303
        -- 03/11/16 - crapp-2432 - moved from after step 2.3 to after step 4
        CURSOR remove_zip IS
            SELECT  a.zone_3_name, a.zone_4_name, a.zone_5_name, a.zone_6_name, a.zone_7_name, a.unique_area, t.official_name authority_name
            FROM    gis_area_list_tmp t
                    JOIN gis_zone_authority_range_tmp a ON (    t.unique_area = a.unique_area
                                                            AND t.state_name  = a.zone_3_name
                                                            AND t.county_name = a.zone_4_name
                                                            AND t.city_name   = a.zone_5_name
                                                            AND NVL(t.zip, 'no_zip') = NVL(a.zone_6_name, 'no_zip')
                                                            AND CASE WHEN t.zip4 IS NOT NULL AND ASCII(t.zip4) < 65   -- crapp-2087
                                                                     THEN TO_NUMBER(t.zip4)
                                                                     ELSE -1
                                                                END BETWEEN NVL(a.range_min, -1) AND NVL(a.range_max, -1)
                                                )
            WHERE   a.unique_area IN (SELECT DISTINCT unique_area
                                      FROM   gis_zone_areas_orig_tmp
                                      WHERE  UPPER(unique_area) NOT LIKE '%CROSSBORDER%') -- Exclude Crossborder areas
                    AND a.zone_7_name IS NULL
            ORDER BY a.unique_area, a.zone_6_name;


        -- 2.5 - Cursor to attach Authorities at Zip4 - < 70% - Top Down - District -- updated 07/01/15 - crapp-1872 - 07/20/15 moved to after step 3
        CURSOR attach_td IS
            SELECT DISTINCT
                   t.zone_3_name, t.zone_4_name, t.zone_5_name, t.zone_6_name, t.zone_7_name, t.authority_name
            FROM   gis_zone_authorities_tmp t
                   JOIN gis_zone_auth_bustage_tmp td ON (     t.zone_3_name = td.zone_3_name
                                                          AND t.zone_4_name = td.zone_4_name
                                                          AND t.zone_5_name = td.zone_5_name
                                                          AND t.zone_6_name = td.zone_6_name
                                                          AND t.zone_7_name = td.zone_7_name
                                                          --AND t.authority_name = td.authority_name   -- 07/15/15 removed
                                                        )
            WHERE  t.zone_7_name IS NOT NULL
                   AND t.processed IS NULL;


        -- 2.6 - Cursor to clear the already processed County/City/District default values -- 06/09/15
        CURSOR cleardefaults IS
            SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, authority_name, geo_area
            FROM   gis_zone_authorities_tmp
            WHERE  processed IS NOT NULL
            ORDER BY zone_4_name, zone_5_name, zone_6_name;


        -- 2.7 -- Cursor to remove Multipoint Districts that are not the default -- crapp-2400
        CURSOR multipoint IS
            SELECT state_code, state_name, county_name, city_name, zip, unique_area
            FROM   (
                    SELECT DISTINCT state_code, state_name, county_name, city_name, zip, zip9, default_flag df, unique_area
                    FROM   gis_zone_detail_tmp
                    WHERE  zip9 IS NOT NULL
                        AND default_flag IS NULL
                        AND NVL(REGEXP_COUNT(unique_area, '\|'),0) > 2  -- UAs with Districts
                   ) d
            GROUP BY state_code, state_name, county_name, city_name, zip, unique_area
            HAVING COUNT(zip9) = 1
            ORDER BY zip, unique_area;


        -- 5 - Cursor to Determine the Default Zip --
        CURSOR defaultzip IS
            SELECT  *
            FROM    ( SELECT /*+index(p geo_polygons_un) index(u geo_usps_lookup_i6)*/  -- 09/06/16 added index I6 for performance
                             DISTINCT
                             u.state_code
                            , UPPER(u.state_name)  state_name
                            , UPPER(u.county_name) county_name
                            , UPPER(u.city_name)   city_name
                            , u.zip
                            , CASE WHEN u.override_rank = 1 THEN 'Y' ELSE NULL END default_flag
                      FROM  geo_usps_lookup u
                            JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
                            JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                                              AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
                      WHERE u.state_code = stcode_i
                            AND DECODE(NVL(SUBSTR(u.zip9,6,4), 'XXXX'), 'XXXX', 0, 1) = 0   -- zip4 IS NULL
                    )
            WHERE   default_flag = 'Y'
            ORDER BY county_name, city_name, zip;


        -- 6 - Cursor to update flags on remaining Bottom-Up Terminated authorities --
        CURSOR bottom_up_rem IS
            SELECT DISTINCT
                   a.zone_3_name
                   , a.zone_4_name
                   , a.zone_5_name
                   , a.zone_6_name
                   , a.zone_7_name
            FROM   gis_zone_authorities_tmp a
            WHERE  reverse_flag = 'Y'
                   AND processed IS NOT NULL;


        -- 6.5 - Cursor for Authorities at State Level --
        CURSOR entirestate IS
            SELECT DISTINCT t.*
            FROM   ( SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                     FROM   gis_zone_authorities_tmp
                     WHERE  geo_area = 'State'
                            AND zone_6_name IS NOT NULL
                            AND reverse_flag IS NULL
                            AND processed IS NULL
                   ) t
                   JOIN ( SELECT zone_3_name
                                 , zone_4_name
                                 , zone_5_name
                                 , zone_6_name
                                 , authority_name
                          FROM   gis_zone_auth_counts2_tmp
                        ) c ON (     t.zone_3_name = c.zone_3_name
                                 AND t.zone_4_name = c.zone_4_name
                                 AND t.zone_5_name = c.zone_5_name
                                 AND t.zone_6_name = c.zone_6_name
                                 AND t.authority_name = c.authority_name
                               )
            MINUS   -- added 07/09/15 to exclude authorities with bottom-up ranges
            SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
            FROM   gis_zone_auth_budetail_tmp;


        -- 7 - Cursor to determine which Authorities are associated at the City level -- crapp-1377
        CURSOR citylevel IS
            SELECT  DISTINCT
                    authority_name
                    , zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , zone_6_name
                    , geo_area
            FROM    gis_zone_authorities_tmp
            WHERE   zone_7_name IS NULL
                    AND authority_name NOT LIKE '%DISTRICT%'
                    AND processed IS NOT NULL -- 09/08/17
                    AND geo_area = 'City';


        -- 7.5 - Cursor to determine which Authorities are associated at the City level and Double Mapped -- 04/26/16 - crapp-2539
        CURSOR citylevelatzip IS
            SELECT  DISTINCT
                    authority_name
                    , zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , geo_area
            FROM    gis_zone_authorities_tmp
            WHERE   zone_6_name IS NULL
                    AND authority_name NOT LIKE '%DISTRICT%'
                    AND geo_area = 'City';


        -- 8 - Cursor to determine which Authorities are associated at the County level -- crapp-1377
        CURSOR countylevel IS
            SELECT  DISTINCT
                    authority_name
                    , zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , zone_6_name
                    , geo_area
            FROM    gis_zone_authorities_tmp
            WHERE   zone_7_name IS NULL
                    AND authority_name NOT LIKE '%DISTRICT%'
                    AND geo_area = 'County';


        -- 8.5 - Cursor to determine which Authorities are associated at the County level and Double Mapped -- 03/17/16 - crapp-2443
        CURSOR countylevelatzip IS
            SELECT  DISTINCT
                    authority_name
                    , zone_3_name
                    , zone_4_name
                    , geo_area
            FROM    gis_zone_authorities_tmp
            WHERE   zone_5_name IS NULL
                    AND geo_area = 'County';


        -- 9 - Cursor to determine which Authorities are associated at the District level -- crapp-1377
        CURSOR districtlevel IS
            SELECT  DISTINCT
                    authority_name
                    , zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , zone_6_name
            FROM    gis_zone_authorities_tmp
            WHERE   zone_7_name IS NOT NULL
                    AND geo_area = 'District'
            MINUS   -- added 07/14/15 to exclude authorities associated at Zip due to percentage > 70% and < 100%
            SELECT DISTINCT authority_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name
            FROM   gis_zone_auth_counts2_tmp
            WHERE  zippct > 0.7;


        -- 10 - Cursor to determine which Authorities are associated at the State level - 03/09/15 - crapp-1377
        CURSOR statelevel IS
            SELECT  DISTINCT
                    authority_name
                    , zone_3_name
            FROM    gis_zone_authorities_tmp
            WHERE   geo_area = 'State';


        -- 11 - Cursor to sync Flags for processed District records  --
        CURSOR updateflags IS
            SELECT  DISTINCT
                    authority_name
                    , zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , zone_6_name
                    , reverse_flag
                    , default_flag
                    , terminator_flag
            FROM    gis_zone_authorities_tmp
            WHERE   geo_area = 'District'
                    AND processed IS NOT NULL
                    AND reverse_flag = 'N'
                    AND zone_7_name IS NULL
            ORDER BY authority_name
                    , zone_4_name
                    , zone_5_name
                    , zone_6_name;


        -- 12 - Cursor to remove non-processed records  -- crapp-2212
        CURSOR notprocessed IS
            SELECT  DISTINCT
                    zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , zone_6_name
                    , zone_7_name
                    , authority_name
                    , processed
                    , geo_area
            FROM    gis_zone_authorities_tmp
            WHERE   processed IS NULL
                    AND zone_6_name IS NOT NULL
                    AND zone_7_name IS NULL
            ORDER BY zone_4_name
                    , zone_5_name
                    , authority_name;


        -- 12.1 - Cursor to remove non-processed orphaned records -- crapp-3248
        CURSOR notprocessed_orphans IS
            SELECT DISTINCT t.*
            FROM   ( SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                     FROM   gis_zone_authorities_tmp
                     WHERE  zone_6_name IS NULL
                            AND processed IS NULL
                            AND geo_area = 'District'
                   ) t
                   JOIN (
                         SELECT  state_name     zone_3_name
                               , county_name    zone_4_name
                               , COUNT(DISTINCT unique_area) total_area_count
                         FROM  gis_area_list_tmp
                         WHERE zip IS NULL
                               AND city_name IS NOT NULL
                         GROUP BY state_name
                                , county_name
                         HAVING COUNT(DISTINCT unique_area) = 1
                        ) c ON (     t.zone_3_name = c.zone_3_name
                                 AND t.zone_4_name = c.zone_4_name
                               )
            WHERE EXISTS (
                          SELECT 1
                          FROM   (
                                  SELECT state_name       zone_3_name
                                         , county_name    zone_4_name
                                         , official_name  authority_name
                                         , COUNT(DISTINCT unique_area) total_area_count
                                  FROM   gis_area_list_tmp
                                  GROUP BY state_name
                                           , county_name
                                           , official_name
                                   HAVING COUNT(DISTINCT unique_area) = 1
                                 ) ga
                          WHERE      ga.zone_3_name = t.zone_3_name
                                 AND ga.zone_4_name = t.zone_4_name
                                 AND ga.authority_name = t.authority_name
                         );

    BEGIN

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'push_gis_zone_authorities, tag_grp_i = '||tag_grp_i||', instance_i = '||instance_i, paction=>0, puser=>l_user);

        -- CRAPP-3174, Dynamic extraction of schema name to reference tables where needed
        SELECT SYS_CONTEXT( 'userenv', 'current_schema' ) INTO vcurrent_schema FROM dual;

        -- Get Determination schema name based on instance value --
        SELECT schema_name
        INTO   l_schema
        FROM   vetl_instance_groups
        WHERE  gis_flag = 'Y'
               AND tdr_etl_instance_id = instance_i;

        -- Get list of Jurisdictions with the appropriate Tag Group
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdictions by Tag Group - gis_zone_auth_tags_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_auth_tags_tmp DROP STORAGE';

        -- Determination US
        IF instance_i = 1 THEN
            INSERT INTO gis_zone_auth_tags_tmp
                (ref_nkid, tagcnt)
                SELECT  ref_nkid,
                        COUNT(*) tagcnt
                FROM    tag_group_tags tv
                        JOIN  ( SELECT jt.ref_nkid,
                                       listagg(tag.name,',') WITHIN GROUP (ORDER BY tag.name) tag_list
                                FROM   ( SELECT DISTINCT
                                                ref_nkid
                                                ,tag_id
                                         FROM   jurisdiction_tags
                                       ) jt
                                       JOIN tags tag ON (tag.id = jt.tag_id)
                                       JOIN jurisdictions j ON (jt.ref_nkid = j.nkid)
                                WHERE  next_rid IS NULL   -- crapp-1396
                                       AND tag.tag_type_id NOT IN (SELECT ID FROM tag_types WHERE NAME LIKE '%USER%') -- crapp-3576, exclude USER tags = 5
                                GROUP BY jt.ref_nkid
                              ) e on (e.tag_list = tv.tag_list)
                WHERE   tv.tag_group_id IN (
                                            SELECT tag_group_id
                                            FROM   tag_group_tags
                                            WHERE     tag_group_name LIKE 'Determination%United States'
                                                   OR tag_list LIKE 'Determination%Retail%United States'   -- crapp-3966 include Retail
                                           )
                GROUP BY ref_nkid;
            COMMIT;

        -- If processing Telco, HOT, or GIS ONLY, we need to include all jurisdictions with a minimum of the US/Determination tags -- crapp-3082
        ELSE
            INSERT INTO gis_zone_auth_tags_tmp
                (ref_nkid, tagcnt)
                SELECT  ref_nkid,
                        COUNT(*) tagcnt
                FROM    tag_group_tags tv
                        JOIN  ( SELECT jt.ref_nkid,
                                       listagg(tag.name,',') WITHIN GROUP (ORDER BY tag.name) tag_list
                                FROM   ( SELECT DISTINCT
                                                ref_nkid
                                                ,tag_id
                                         FROM   jurisdiction_tags
                                       ) jt
                                       JOIN tags tag ON (tag.id = jt.tag_id)
                                       JOIN jurisdictions j ON (jt.ref_nkid = j.nkid)
                                WHERE  next_rid IS NULL
                                       AND tag.tag_type_id NOT IN (SELECT ID FROM tag_types WHERE NAME LIKE '%USER%') -- crapp-3576, exclude USER tags = 5
                                GROUP BY jt.ref_nkid
                              ) e on (e.tag_list = tv.tag_list)
                WHERE   tv.tag_group_id IN (SELECT tag_group_id FROM tag_group_tags WHERE tag_list LIKE 'Determination%United States')  -- crapp-3082
                        AND NOT EXISTS (SELECT 1
                                        FROM   gis_zone_auth_tags_tmp a
                                        WHERE  a.ref_nkid = e.ref_nkid
                                       )
                GROUP BY ref_nkid;
            COMMIT;
        END IF;
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_auth_tags_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdictions by Tag Group - gis_zone_auth_tags_tmp', paction=>1, puser=>l_user);



        -- Determine Areas with Jurisdiction Overrides --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine area overrides - gis_zone_areas_tmp', paction=>0, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'   - Clear table - gis_zone_juris_areas_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_juris_areas_tmp DROP STORAGE';   -- crapp-2157 Staging table for MAX geo_area
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_juris_areas_tmp_n1 UNUSABLE';       -- crapp-3268, new index
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'   - Clear table - gis_zone_juris_areas_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'   - Staging table - gis_zone_juris_areas_tmp', paction=>0, puser=>l_user);
        INSERT INTO gis_zone_juris_areas_tmp
            (state_code, unique_area_id, unique_area, hierarchy_level, geo_area)
            (
              SELECT   a.state_code
                     , a.unique_area_id
                     , a.unique_area
                     , a.hierarchy_level
                     , gac.NAME
              FROM   (
                       SELECT s.state_code, s.unique_area_id, s.unique_area, MAX(gp.hierarchy_level_id) hierarchy_level
                       FROM   vgeo_unique_area_search s
                              JOIN vunique_area_polygons uap ON (s.rid = uap.unique_area_rid)
                              JOIN geo_polygons gp ON (uap.poly_nkid = gp.nkid      -- crapp-3523, changed to table from view (vgeo_polygons)
                                                       AND gp.next_rid IS NULL)
                       WHERE  s.state_code = stcode_i
                       GROUP BY s.state_code, s.unique_area_id, s.unique_area
                     ) a
                     JOIN hierarchy_levels hl ON (a.hierarchy_level = hl.id)
                     JOIN geo_area_categories gac ON (hl.geo_area_category_id = gac.id)
            );
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'   - Staging table - gis_zone_juris_areas_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'   - Rebuild index and stats - gis_zone_juris_areas_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_juris_areas_tmp_n1 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_juris_areas_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'   - Rebuild index and stats - gis_zone_juris_areas_tmp', paction=>1, puser=>l_user);

        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_areas_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_areas_tmp_n1 UNUSABLE';
        INSERT INTO gis_zone_areas_tmp
            (unique_area_id, unique_area_rid, unique_area_nkid, official_name, jurisdiction_id, jurisdiction_nkid, unique_area, state_code, effective_level)
            WITH overrides AS   -- crapp-3268, modified query to use WITH for overrides
                (
                    SELECT DISTINCT
                           a.unique_area_id
                           , a.unique_area_nkid
                           , a.unique_area_rid
                           , a.value_id
                           , a.value
                           , ga.unique_area                -- crapp-3523
                           , ga.state_code                 -- crapp-3523
                           , ga.geo_area effective_level   -- crapp-2432
                    FROM   vunique_area_attributes a
                           JOIN gis_zone_juris_areas_tmp ga ON (a.unique_area_id = ga.unique_area_id) -- crapp-2157
                    WHERE  a.attribute_id = 18 -- NAME = 'Jurisdiction Override'
                           AND a.next_rid IS NULL
                )
                SELECT  DISTINCT
                        uaa.unique_area_id
                        , uaa.unique_area_rid
                        , uaa.unique_area_nkid
                        , uaa.VALUE  official_name
                        , j.id       jurisdiction_id -- crapp-2099 changed from "uaa.value_id" which is now the Jurisdiction.NKID
                        , j.nkid     jurisdiction_nkid
                        , uaa.unique_area      -- crapp-3523, changed from guas
                        , uaa.state_code       -- crapp-3523, changed from guas
                        , uaa.effective_level
                FROM    overrides uaa
                        --JOIN vgeo_unique_area_search guas ON (uaa.unique_area_id = guas.unique_area_id) -- crapp-3523, removed
                        JOIN jurisdictions j ON (uaa.value_id = j.nkid)
                WHERE   j.next_rid IS NULL
                        AND uaa.state_code = stcode_i;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine area overrides - gis_zone_areas_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_zone_areas_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_areas_tmp_n1 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_areas_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_zone_areas_tmp', paction=>1, puser=>l_user);


        -- Get STJ Count --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get stj count - gis_zone_stj_areas_tmp', paction=>0, puser=>l_user);

        -- 09/09/16 -- added check of existing data (table updated during Push_GIS_Zone_Tree procedure contains same data)
        SELECT COUNT(1) cnt INTO l_rec FROM gis_zone_stj_areas_tmp WHERE state_code = stcode_i;
        IF l_rec = 0 THEN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_stj_areas_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_stj_areas_tmp_n1 UNUSABLE';

            SELECT  hl.id
            INTO    l_hlvl
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON (hl.geo_area_category_id = g.id)
                    JOIN hierarchy_definitions hd ON (hl.hierarchy_definition_id = hd.id)
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'District';

            WITH zips AS
                (
                 SELECT u.state_code
                        , u.zip9
                        , u.area_id
                 FROM   geo_usps_lookup u
                        JOIN geo_polygons p ON (u.geo_polygon_id = p.id)
                 WHERE  u.state_code = stcode_i
                        AND DECODE(NVL(SUBSTR(u.zip9,6,4), 'XXXX'), 'XXXX', 0, 1) = 1   -- zip4 is not null
                        AND p.hierarchy_level_id = l_hlvl --'District'
                        AND p.next_rid IS NULL
                ),
               areas AS
                (
                 SELECT state_code
                        , zip9
                        , unique_area
                        , area_id
                 FROM   vgeo_unique_areas2
                 WHERE  state_code = stcode_i
                        AND zip9 IS NOT NULL
                )
                SELECT  DISTINCT
                        z.state_code
                        , a.unique_area
                        , 1 stj_flag
                        , z.zip9
                BULK COLLECT INTO v_stj
                FROM    zips z
                        JOIN areas a ON (    z.state_code = a.state_code
                                         AND z.zip9       = a.zip9
                                         AND z.area_id    = a.area_id
                                        );

            FORALL i IN v_stj.first..v_stj.last
                INSERT INTO gis_zone_stj_areas_tmp
                VALUES v_stj(i);
            COMMIT;

            v_stj := t_stj();
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_stj_areas_tmp_n1 REBUILD';
            DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_stj_areas_tmp', cascade => TRUE);
        END IF;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get stj count - gis_zone_stj_areas_tmp', paction=>1, puser=>l_user);


        -- Build temp table of GIS Zip data --

        -- 06/08/17 -- added check of existing data (table updated during PUSH_GIS_ZONE_TREE procedure contains same data)
        SELECT COUNT(1) cnt INTO l_rec FROM gis_zone_detail_tmp WHERE state_code = stcode_i;
        IF l_rec = 0 THEN

            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_zone_detail_tmp', paction=>0, puser=>l_user);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_detail_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n2 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n3 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n4 UNUSABLE';
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_zone_detail_tmp', paction=>1, puser=>l_user);

            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get zip data detail - gis_zone_detail_tmp', paction=>0, puser=>l_user);
            OPEN detail(stcode_i);
            LOOP
                FETCH detail BULK COLLECT INTO v_dtl LIMIT 25000;

                FORALL d IN 1..v_dtl.COUNT
                    INSERT INTO gis_zone_detail_tmp
                    VALUES v_dtl(d);
                COMMIT;

                EXIT WHEN detail%NOTFOUND;
            END LOOP;
            COMMIT;
            CLOSE detail;

            v_dtl := t_dtl();
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get zip data detail - gis_zone_detail_tmp', paction=>1, puser=>l_user);

            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_zone_detail_tmp', paction=>0, puser=>l_user);
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n2 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n3 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_detail_tmp_n4 REBUILD';
            DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_detail_tmp', cascade => TRUE);
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_zone_detail_tmp', paction=>1, puser=>l_user);
        END IF;


        -- 11/04/15 - created staging table for Mapped Jurisdictions - Using table in place of view vJuris_Geo_Areas for performance
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build mapped Jurisdiction staging table - gis_zone_mapped_auths_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_mapped_auths_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_mapped_auths_tmp_n1 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_mapped_auths_tmp_n2 UNUSABLE';

        INSERT INTO gis_zone_mapped_auths_tmp
            (state_code, official_name, jurisdiction_id, jurisdiction_nkid, rid, nkid, geo_polygon_rid)
            SELECT  DISTINCT state_code, official_name, jurisdiction_id, jurisdiction_nkid, rid, nkid, geo_polygon_rid
            FROM    vjuris_geo_areas
            WHERE   state_code = stcode_i;
        COMMIT;

        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_mapped_auths_tmp_n1 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_mapped_auths_tmp_n2 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_mapped_auths_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build mapped Jurisdiction staging table - gis_zone_mapped_auths_tmp', paction=>1, puser=>l_user);


        -- Determine original Jurisdiction Associations for Unique Areas replaced with Overrides - to be attached as Bottom-Up -- 08/28/15 - crapp-2029
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine orig Jurisdictions replaced by overrides - gis_zone_areas_orig_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_areas_orig_tmp DROP STORAGE';

        -- 10/27/15 - Added staging table for performance
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_detail_stage_tmp DROP STORAGE';
        INSERT INTO gis_zone_detail_stage_tmp
            (state_code, state_name, unique_area, rid)
            SELECT  DISTINCT
                    state_code
                    , state_name
                    , unique_area
                    , rid
            FROM    gis_zone_detail_tmp
            WHERE   state_code = stcode_i
                    AND zip9 IS NOT NULL
                    AND default_flag = 'Y'    -- 03/12/15 - only want default zip4s (determination can't handle multi-point)
                    AND unique_area IN (SELECT DISTINCT unique_area FROM gis_zone_areas_tmp);
        COMMIT;

        INSERT INTO gis_zone_areas_orig_tmp
            (state_code, jurisdiction_id, official_name, rid, nkid, unique_area)
            SELECT
                    DISTINCT
                    g.state_code
                    , jpa.jurisdiction_id
                    , jpa.official_name
                    , jpa.rid
                    , jpa.nkid
                    , g.unique_area
            FROM    gis_zone_detail_stage_tmp g
                    JOIN gis_zone_mapped_auths_tmp jpa ON (g.rid = jpa.geo_polygon_rid           -- 11/04/15 using table instead of view vjuris_geo_areas
                                                           AND g.state_code = jpa.state_code)    -- 10/26/15 added join condition for performance
                    JOIN jurisdictions j ON (jpa.jurisdiction_nkid = j.nkid)                     -- 08/06/15 changed from (jpa.jurisdiction_id = j.nkid)
                    LEFT JOIN ( SELECT a.geo_poly_id, a.geo_poly_rid, p.geo_area_key
                                FROM   vgeo_poly_attributes a
                                       JOIN geo_polygons p ON (a.geo_poly_id = p.id)
                                WHERE  attribute_name = 'Restrict Zip+4 Load to Determination'
                                       AND VALUE = 'Y'
                               ) pa ON (g.unique_area LIKE ('%'||pa.geo_area_key||'%'))
            WHERE   jpa.state_code = stcode_i
                    AND j.next_rid IS NULL      -- 05/19/15 added
                    AND j.nkid IN (SELECT ref_nkid FROM gis_zone_auth_tags_tmp)
                    AND NOT EXISTS ( SELECT 1
                                     FROM   gis_zone_areas_tmp o
                                     WHERE      g.unique_area = o.unique_area
                                            AND g.state_code  = o.state_code
                                            AND jpa.jurisdiction_nkid = o.jurisdiction_nkid       -- added crapp-2099
                                            --AND jpa.jurisdiction_id = o.jurisdiction_id         -- removed crapp-2099
                                   );
        COMMIT;
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_areas_orig_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine orig Jurisdictions replaced by overrides - gis_zone_areas_orig_tmp', paction=>1, puser=>l_user);


        -- 12/16/15 -- crapp-2211 - Crossborder States
        IF stcode_i IN ('AR', 'DC', 'IA', 'KY', 'MO', 'OH', 'SD', 'WA') THEN
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine Crossborder Jurisdictions, to be made Bottom-Up - gis_zone_areas_orig_tmp', paction=>0, puser=>l_user);

            INSERT INTO gis_zone_areas_orig_tmp
                (state_code, jurisdiction_id, official_name, rid, nkid, unique_area)
                SELECT  DISTINCT
                        g.state_code
                        , jpa.jurisdiction_id
                        , jpa.official_name
                        , jpa.rid
                        , jpa.nkid
                        , g.unique_area
                FROM    gis_zone_detail_tmp g
                        JOIN gis_zone_mapped_auths_tmp jpa ON (    g.rid = jpa.geo_polygon_rid
                                                               AND g.state_code = jpa.state_code
                                                               AND g.state_code <> SUBSTR(jpa.official_name, 1, 2)   -- Crossborder Jurisdictions - crapp-2211
                                                              )
                        JOIN jurisdictions j ON (jpa.jurisdiction_nkid = j.nkid)
                        LEFT JOIN ( SELECT a.geo_poly_id, a.geo_poly_rid, p.geo_area_key
                                    FROM   vgeo_poly_attributes a
                                           JOIN geo_polygons p ON (a.geo_poly_id = p.id)
                                    WHERE  attribute_name = 'Restrict Zip+4 Load to Determination'
                                           AND VALUE = 'Y'
                                   ) pa ON (g.unique_area LIKE ('%'||pa.geo_area_key||'%'))
                WHERE   jpa.state_code = stcode_i
                        AND g.zip9 IS NOT NULL
                        AND g.default_flag = 'Y'
                        AND j.next_rid IS NULL
                        AND j.nkid IN (SELECT ref_nkid FROM gis_zone_auth_tags_tmp)
                        AND NOT EXISTS ( SELECT 1
                                         FROM   gis_zone_areas_orig_tmp o    -- Not already in the Replacement table
                                         WHERE      g.unique_area = o.unique_area
                                                AND g.state_code  = o.state_code
                                                AND jpa.jurisdiction_nkid = o.nkid
                                       );

            COMMIT;
            DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_areas_orig_tmp', cascade => TRUE);
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine Crossborder Jurisdictions, to be made Bottom-Up - gis_zone_areas_orig_tmp', paction=>1, puser=>l_user);
        END IF; -- Crossborder State Specific Code


        -- Get Zipcode detail for Jurisdictions with no Overrides --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_area_list_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_area_list_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n1 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n2 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n3 UNUSABLE';
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_area_list_tmp', paction=>1, puser=>l_user);

        -- 11/02/15 - converted to collection and county loop for tablespace issue
        -- Splitting into Multiple County ranges for inserts
        v_county_start := t_counties('', '', '', '', '');
        v_county_end   := t_counties('', '', '', '', '');
        v_county_start(1) := 'A';
        v_county_end(1)   := 'EZZ';
        v_county_start(2) := 'F';
        v_county_end(2)   := 'JZZ';
        v_county_start(3) := 'K';
        v_county_end(3)   := 'OZZ';
        v_county_start(4) := 'P';
        v_county_end(4)   := 'TZZ';
        v_county_start(5) := 'U';
        v_county_end(5)   := 'ZZZ';

        FOR i IN 1..5 LOOP
            gis_etl_p(l_pID, stcode_i, ' - Get Jurisdiction zip detail no overrides '||v_county_start(i)||' to '||v_county_end(i)||' - gis_area_list_tmp', 0, l_user);

            -- crapp-4072 - changed to a limited fetch loop --
            OPEN detail_no_overrides(stcode_i, v_county_start(i), v_county_end(i));
            LOOP
                FETCH detail_no_overrides BULK COLLECT INTO v_arealist LIMIT 100000;

                FORALL i IN 1..v_arealist.COUNT
                    INSERT INTO gis_area_list_tmp
                    VALUES v_arealist(i);
                COMMIT;

                EXIT WHEN detail_no_overrides%NOTFOUND;
            END LOOP;
            COMMIT;

            CLOSE detail_no_overrides;
            v_arealist := t_arealist();
            gis_etl_p(l_pID, stcode_i, ' - Get Jurisdiction zip detail no overrides '||v_county_start(i)||' to '||v_county_end(i)||' - gis_area_list_tmp', 1, l_user);
        END LOOP;


        -- Get Zipcode detail for Jurisdictions with Overrides --
        -- Changed to a County/Merge Loop due to an out of memory error - crapp-2534 --
        -- Changed back to Collection Insert for performance - crapp-2911 --
        FOR i IN 1..5 LOOP
            gis_etl_p(l_pID, stcode_i, ' - Get Jurisdiction zip detail with overrides '||v_county_start(i)||' to '||v_county_end(i)||' - gis_area_list_tmp', 0, l_user);

            -- 08/31/17 - changed to a limited fetch loop to fix memory issues --
            OPEN detail_w_overrides(stcode_i, v_county_start(i), v_county_end(i));
            LOOP
                FETCH detail_w_overrides BULK COLLECT INTO v_arealist LIMIT 100000;

                FORALL i IN 1..v_arealist.COUNT
                    INSERT INTO gis_area_list_tmp
                    VALUES v_arealist(i);
                COMMIT;

                EXIT WHEN detail_w_overrides%NOTFOUND;
            END LOOP;
            COMMIT;

            CLOSE detail_w_overrides;
            v_arealist := t_arealist();
            gis_etl_p(l_pID, stcode_i, ' - Get Jurisdiction zip detail with overrides '||v_county_start(i)||' to '||v_county_end(i)||' - gis_area_list_tmp', 1, l_user);
        END LOOP;


        -- Get US Jurisdictions with no Overrides  - Federal Level --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdiction zip detail no overrides (Fed) - gis_area_list_tmp', paction=>0, puser=>l_user);
        INSERT INTO gis_area_list_tmp
            (unique_area, geo_area, stj_flag, state_name, county_name, city_name, zip, zip4, default_flag, code_fips, state_code,
             jurisdiction_id, official_name, rid, nkid)
            SELECT  DISTINCT
                    gp.geo_area_key unique_area
                    , gp.geo_area
                    , 0 stj_flag
                    , TRIM(SUBSTR(UPPER(gp.geo_area_key), 7, 50)) state_name
                    , NULL county_name
                    , NULL city_name
                    , NULL zip
                    , NULL zip4
                    , NULL default_flag
                    , SUBSTR(gp.geo_area_key, 4, 2) code_fips
                    , SUBSTR(gp.geo_area_key, 1, 2) state_code
                    , jpa.id jurisdiction_id
                    , jpa.official_name
                    , jpa.rid
                    , jpa.nkid
            FROM    vgeo_polygons gp
                    JOIN (
                           SELECT *
                           FROM   jurisdictions
                           WHERE  official_name LIKE 'US - %'
                                  AND next_rid IS NULL
                                  AND nkid NOT IN ( -- crapp-3570, exclude US - NO TAX STATES
                                                    SELECT DISTINCT ja.juris_nkid
                                                    FROM  vjurisdiction_attributes ja
                                                    WHERE ja.attribute_id = 9
                                                          AND ja.VALUE LIKE '%NO TAX%'
                                                  )
                         ) jpa ON (SUBSTR(gp.geo_area_key, 1, 2) = SUBSTR(jpa.official_name, 1, 2))
            WHERE   SUBSTR(gp.geo_area_key, 1, 2) = 'US'
                    AND gp.geo_area = 'Country'
                    AND gp.next_rid IS NULL
                    AND NOT EXISTS ( SELECT 1
                                     FROM   gis_zone_areas_tmp o
                                     WHERE  gp.geo_area_key = o.unique_area
                                            AND SUBSTR(gp.geo_area_key, 1, 2) = o.state_code
                                            AND gp.geo_area = o.effective_level
                                   );
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdiction zip detail no overrides (Fed) - gis_area_list_tmp', paction=>1, puser=>l_user);


        -- Get detail for Jurisdiction Mappings with no Overrides - No Zip4 -- CRAPP-1465
        -- crapp-3766 - Create staging table to exclude No Zip/Zip4 areas already in GIS_AREA_LIST_TMP --
        gis_etl_p(l_pID, stcode_i, ' - Clear table - gis_area_stage_tmp', 0, l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_area_stage_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_area_stage_tmp_n1 UNUSABLE';
        gis_etl_p(l_pID, stcode_i, ' - Clear table - gis_area_stage_tmp', 1, l_user);

        gis_etl_p(l_pID, stcode_i, ' - Get distinct list of Unique Areas - gis_area_stage_tmp', 0, l_user);
        INSERT INTO gis_area_stage_tmp
            (state_code, unique_area)
            SELECT /*+parallel(a,4)*/
                   DISTINCT
                   state_code
                   , unique_area
            FROM   gis_area_list_tmp a
            WHERE  state_code = stcode_i
                   AND unique_area != 'XX'; -- crapp-4072, updated WHERE clause
        COMMIT;
        gis_etl_p(l_pID, stcode_i, ' - Get distinct list of Unique Areas - gis_area_stage_tmp', 1, l_user);

        FOR i IN 1..5 LOOP
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdictions no overrides (no zip4) '||v_county_start(i)||' to '||v_county_end(i)||' - gis_area_list_tmp', paction=>0, puser=>l_user);

            -- 02/25/16 -- crapp-2268 - Removed from NOT EXISTS WHERE condition --  'AND g.geo_area    = o.effective_level '||
            -- 08/11/16 -- converted to Collection insert from MERGE for performance improvements
            WITH stjs AS
                ( SELECT DISTINCT state_code, unique_area, stj_flag
                  FROM   gis_zone_stj_areas_tmp
                )
            SELECT  /*+index(g gis_zone_detail_tmp_n4)*/
                    DISTINCT
                    g.unique_area
                    , NVL(d.stj_flag, 0) stj_flag
                    , g.state_name
                    , g.county_name
                    , g.city_name
                    , g.zip
                    , g.zip4
                    , g.default_flag
                    , g.code_fips
                    , g.state_code
                    , jpa.jurisdiction_id
                    , jpa.official_name
                    , jpa.rid
                    , jpa.nkid
                    , g.geo_area
                    , NULL geoarea_updated
            BULK COLLECT INTO v_arealist
            FROM    gis_zone_detail_tmp g
                    JOIN gis_zone_mapped_auths_tmp jpa ON (g.rid = jpa.geo_polygon_rid
                                                           AND g.state_code = jpa.state_code)
                    JOIN jurisdictions j ON (jpa.jurisdiction_nkid = j.nkid)
                    LEFT JOIN stjs d ON (g.unique_area = d.unique_area
                                         AND g.state_code = d.state_code)
            WHERE   g.state_code = stcode_i
                    AND g.county_name BETWEEN v_county_start(i) AND v_county_end(i)
                    AND g.zip IS NOT NULL
                    AND g.zip4 IS NULL
                    --AND g.geo_area <> 'State' -- crapp-3793, removed
                    AND j.nkid IN (SELECT /*+index(tt gis_zone_auth_tags_tmp_n1)*/ ref_nkid FROM gis_zone_auth_tags_tmp tt)
                    AND j.next_rid IS NULL
                    AND NOT EXISTS ( SELECT 1
                                     FROM   gis_zone_areas_tmp o
                                     WHERE      g.unique_area = o.unique_area
                                            AND g.state_code  = o.state_code
                                   )
                    AND g.unique_area NOT IN (SELECT unique_area FROM gis_area_stage_tmp);  -- crapp-3766, exclude areas with Zip4 values

            FORALL i IN v_arealist.first..v_arealist.last
                INSERT INTO gis_area_list_tmp
                VALUES v_arealist(i);
            COMMIT;

            v_arealist := t_arealist();
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdictions no overrides (no zip4) '||v_county_start(i)||' to '||v_county_end(i)||' - gis_area_list_tmp', paction=>1, puser=>l_user);
        END LOOP;


        -- crapp-3766 - Create staging table to exclude No Zip/Zip4 areas already in GIS_AREA_LIST_TMP --
        gis_etl_p(l_pID, stcode_i, ' - Get distinct list of Unique Areas - gis_area_stage_tmp', 0, l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_area_stage_tmp DROP STORAGE';
        INSERT INTO gis_area_stage_tmp
            (state_code, unique_area)
            SELECT /*+parallel(a,4)*/
                   DISTINCT
                   state_code
                   , unique_area
            FROM   gis_area_list_tmp a
            WHERE  state_code = stcode_i
                   AND unique_area != 'XX'; -- crapp-4072, updated WHERE clause
        COMMIT;
        gis_etl_p(l_pID, stcode_i, ' - Get distinct list of Unique Areas - gis_area_stage_tmp', 1, l_user);


        -- Get detail for Jurisdiction Mappings with no Overrides - No Zip -- crapp-3094
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdictions no overrides (no zip) - gis_area_list_tmp', paction=>0, puser=>l_user);

        WITH stjs AS
            ( SELECT DISTINCT state_code, unique_area, stj_flag
              FROM   gis_zone_stj_areas_tmp
            )
        SELECT  /*+index(g gis_zone_detail_tmp_n4)*/
                DISTINCT
                g.unique_area
                , NVL(d.stj_flag, 0) stj_flag
                , g.state_name
                , g.county_name
                , g.city_name
                , g.zip
                , g.zip4
                , g.default_flag
                , g.code_fips
                , g.state_code
                , jpa.jurisdiction_id
                , jpa.official_name
                , jpa.rid
                , jpa.nkid
                , g.geo_area
                , NULL geoarea_updated
        BULK COLLECT INTO v_arealist
        FROM    gis_zone_detail_tmp g
                JOIN gis_zone_mapped_auths_tmp jpa ON (g.rid = jpa.geo_polygon_rid
                                                       AND g.state_code = jpa.state_code)
                JOIN jurisdictions j ON (jpa.jurisdiction_nkid = j.nkid)
                LEFT JOIN stjs d ON (g.unique_area = d.unique_area
                                     AND g.state_code = d.state_code)
        WHERE   g.state_code = stcode_i
                AND g.zip IS NULL
                --AND g.geo_area <> 'State' -- crapp-3793, removed
                AND j.nkid IN (SELECT /*+index(tt gis_zone_auth_tags_tmp_n1)*/ ref_nkid FROM gis_zone_auth_tags_tmp tt)
                AND j.next_rid IS NULL
                AND NOT EXISTS ( SELECT 1
                                 FROM   gis_zone_areas_tmp o
                                 WHERE      g.unique_area = o.unique_area
                                        AND g.state_code  = o.state_code
                               )
                AND g.unique_area NOT IN (SELECT unique_area FROM gis_area_stage_tmp);  -- crapp-3766, exclude areas with Zip4 values

        FORALL i IN v_arealist.first..v_arealist.last
            INSERT INTO gis_area_list_tmp
            VALUES v_arealist(i);
        COMMIT;

        v_arealist := t_arealist();
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdictions no overrides (no zip) - gis_area_list_tmp', paction=>1, puser=>l_user);


        -- crapp-3766 - Create staging table to exclude No Zip/Zip4 areas already in GIS_AREA_LIST_TMP --
        gis_etl_p(l_pID, stcode_i, ' - Get distinct list of Unique Areas - gis_area_stage_tmp', 0, l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_area_stage_tmp DROP STORAGE';
        INSERT INTO gis_area_stage_tmp
            (state_code, unique_area)
            SELECT /*+parallel(a,4)*/
                   DISTINCT
                   state_code
                   , unique_area
            FROM   gis_area_list_tmp a
            WHERE  state_code = stcode_i
                   AND unique_area != 'XX'; -- crapp-4072, updated WHERE clause
        COMMIT;
        gis_etl_p(l_pID, stcode_i, ' - Get distinct list of Unique Areas - gis_area_stage_tmp', 1, l_user);


        -- Get detail for Jurisdiction Mappings with Overrides - No Zip4 -- CRAPP-1465
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdictions with overrides (no zip4) - gis_area_list_tmp', paction=>0, puser=>l_user);

        -- 09/08/17 - changed to a Limited Fetch Loop, replacing Piped Function --
        OPEN dtl_overrides_nozip4(stcode_i);
        LOOP
            FETCH dtl_overrides_nozip4 BULK COLLECT INTO v_arealist LIMIT 25000;

            FORALL d IN 1..v_arealist.COUNT
                INSERT INTO gis_area_list_tmp
                VALUES v_arealist(d);
            COMMIT;

            EXIT WHEN dtl_overrides_nozip4%NOTFOUND;
        END LOOP;
        COMMIT;

        CLOSE dtl_overrides_nozip4;
        v_arealist := t_arealist();
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdictions with overrides (no zip4) - gis_area_list_tmp', paction=>1, puser=>l_user);


        -- crapp-3766 - Create staging table to exclude No Zip/Zip4 areas already in GIS_AREA_LIST_TMP --
        gis_etl_p(l_pID, stcode_i, ' - Get distinct list of Unique Areas - gis_area_stage_tmp', 0, l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_area_stage_tmp DROP STORAGE';
        INSERT INTO gis_area_stage_tmp
            (state_code, unique_area)
            SELECT /*+parallel(a,4)*/
                   DISTINCT
                   state_code
                   , unique_area
            FROM   gis_area_list_tmp a
            WHERE  state_code = stcode_i
                   AND unique_area != 'XX'; -- crapp-4072, updated WHERE clause
        COMMIT;
        gis_etl_p(l_pID, stcode_i, ' - Get distinct list of Unique Areas - gis_area_stage_tmp', 1, l_user);


        -- Get detail for Jurisdiction Mappings with Overrides - No Zip -- crapp-3094
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdictions with overrides (no zip) - gis_area_list_tmp', paction=>0, puser=>l_user);

        -- 09/08/17 - changed to a Limited Fetch Loop, replacing Piped Function --
        OPEN dtl_overrides_nozip(stcode_i);
        LOOP
            FETCH dtl_overrides_nozip BULK COLLECT INTO v_arealist LIMIT 25000;

            FORALL d IN 1..v_arealist.COUNT
                INSERT INTO gis_area_list_tmp
                VALUES v_arealist(d);
            COMMIT;

            EXIT WHEN dtl_overrides_nozip%NOTFOUND;
        END LOOP;
        COMMIT;

        CLOSE dtl_overrides_nozip;
        v_arealist := t_arealist();
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Jurisdictions with overrides (no zip) - gis_area_list_tmp', paction=>1, puser=>l_user);


        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_area_list_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n1 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n2 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n3 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_area_list_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_area_list_tmp', paction=>1, puser=>l_user);


        -- Override Jurisdiction Effective Level for authorities not associated to a specific boundary -- crapp-2125 - 10/23/15
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Override effective_level (Step 1) - gis_area_list_tmp', paction=>0, puser=>l_user);
        UPDATE gis_area_list_tmp
            SET geo_area = 'District',
                stj_flag = 1
        WHERE official_name IN (
                                SELECT DISTINCT official_name FROM gis_zone_areas_tmp
                                MINUS
                                SELECT DISTINCT official_name FROM gis_zone_mapped_auths_tmp WHERE state_code = stcode_i
                               );
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Override effective_level (Step 1) - gis_area_list_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Override effective_level (Step 2) - gis_area_list_tmp', paction=>0, puser=>l_user);
        -- 10/30/15 changed to a collection update
        SELECT  DISTINCT
                j.state_code
                , j.official_name
                , j.geo_polygon_rid
                , g.NAME geo_area
                , CASE WHEN g.NAME = 'District' THEN 1 ELSE 0 END stj_flag
        BULK COLLECT INTO v_geoarea
        FROM    gis_zone_mapped_auths_tmp j
                JOIN geo_polygons p ON (j.geo_polygon_rid = p.rid)
                JOIN hierarchy_levels h ON (p.hierarchy_level_id = h.id)
                JOIN geo_area_categories g ON (h.geo_area_category_id = g.id)
        WHERE  state_code = stcode_i;

        FORALL i IN 1..v_geoarea.COUNT
            UPDATE  gis_area_list_tmp
                    SET geo_area = v_geoarea(i).geo_area,
                        stj_flag = v_geoarea(i).stj_flag,
                        geoarea_updated = 1                 -- 02/18/16 - crapp-2357
            WHERE  state_code = v_geoarea(i).state_code
                   AND official_name = v_geoarea(i).official_name
                   AND rid = v_geoarea(i).geo_polygon_rid;  -- 02/16/16 - crapp-2357
        COMMIT;

        v_geoarea := t_geoarea();
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Override effective_level (Step 2) - gis_area_list_tmp', paction=>1, puser=>l_user);


        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Override effective_level (Step 2.5) - gis_area_list_tmp', paction=>0, puser=>l_user);
        -- 02/18/16 - crapp-2357
        SELECT  DISTINCT
                state_code
                , unique_area
                , official_name
                , geo_area
                , rid
                , geoarea_updated
        BULK COLLECT INTO v_geoarea_upd
        FROM    gis_area_list_tmp
        WHERE   state_code = stcode_i
                AND geoarea_updated = 1;

        FORALL i IN 1..v_geoarea_upd.COUNT
            UPDATE  gis_area_list_tmp
                    SET geo_area = v_geoarea_upd(i).geo_area,
                        geoarea_updated = 1
            WHERE  state_code        = v_geoarea_upd(i).state_code
                   AND unique_area   = v_geoarea_upd(i).unique_area
                   AND official_name = v_geoarea_upd(i).official_name
                   AND rid          <> v_geoarea_upd(i).poly_rid
                   AND geoarea_updated IS NULL;
        COMMIT;

        v_geoarea_upd := t_geoarea_upd();
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Override effective_level (Step 2.5) - gis_area_list_tmp', paction=>1, puser=>l_user);


        -- Make sure Areas with Districts are flagged correctly
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Override effective_level (Step 3) - gis_area_list_tmp', paction=>0, puser=>l_user);
        UPDATE gis_area_list_tmp
            SET stj_flag = 1
        WHERE unique_area IN (
                              SELECT DISTINCT unique_area
                              FROM   gis_area_list_tmp
                              WHERE  geo_area = 'District'
                             );
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Override effective_level (Step 3) - gis_area_list_tmp', paction=>1, puser=>l_user);


        -- ******************* --
        -- State Specific Code --
        -- ******************* --
        IF stcode_i = 'TX' THEN
            -- crapp-2086/2091 --
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Unique Area Polygons - gis_zone_ua_poly_tmp', paction=>0, puser=>l_user);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_ua_poly_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_ua_poly_tmp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_ua_poly_tmp_n2 UNUSABLE';

            INSERT INTO gis_zone_ua_poly_tmp
                (state_code, unique_area, id, rid, nkid, next_rid)
                SELECT /*+index(u geo_unique_area_polygons_n1) index(a geo_unique_areas_pk) index(p geo_polygons_pk)*/
                     DISTINCT gua.state_code
                              ,gua.unique_area
                              ,a.id
                              ,a.rid
                              ,a.nkid
                              ,a.next_rid
                FROM  geo_unique_area_polygons u
                      JOIN geo_unique_areas a ON (u.unique_area_id = a.id)
                      JOIN (SELECT DISTINCT state_code, area_id, unique_area
                            FROM   vgeo_unique_areas2
                            WHERE  state_code = stcode_i
                           ) gua ON (a.area_id = gua.area_id);
            COMMIT;

            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_ua_poly_tmp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_ua_poly_tmp_n2 REBUILD';
            DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_ua_poly_tmp', cascade => TRUE);
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get Unique Area Polygons - gis_zone_ua_poly_tmp', paction=>1, puser=>l_user);


            -- crapp-2086/2091 --
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get UAs with no overrides and only 1 geo_area association - gis_zone_unique_areas_tmp', paction=>0, puser=>l_user);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_unique_areas_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_ua_areas_tmp_n1 UNUSABLE';

            INSERT INTO gis_zone_unique_areas_tmp
                (state_code, unique_area)
                SELECT  state_code, unique_area
                FROM
                    (
                    SELECT  /*+index(m gis_zone_mapped_auths_tmp_n1)*/
                            DISTINCT
                            ua.state_code, ua.unique_area, ua.rid, ua.nkid, uap.polygon, p.geo_area, uap.poly_rid, uap.poly_nkid, m.official_name
                    FROM    gis_zone_ua_poly_tmp ua
                            JOIN vunique_area_polygons uap ON (ua.rid = uap.unique_area_rid)
                            JOIN vgeo_polygons p ON (uap.poly_nkid = p.nkid)
                            JOIN gis_zone_mapped_auths_tmp m ON (uap.poly_rid = m.geo_polygon_rid)
                            LEFT JOIN gis_zone_areas_tmp o   ON (ua.unique_area = o.unique_area)
                    WHERE   p.next_rid IS NULL
                            AND o.state_code IS NULL    -- No overrides
                    )
                GROUP BY state_code, unique_area
                HAVING COUNT(DISTINCT geo_area) = 1;
            COMMIT;

            EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_ua_areas_tmp_n1 REBUILD';
            DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_unique_areas_tmp', cascade => TRUE);
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get UAs with no overrides and only 1 geo_area association - gis_zone_unique_areas_tmp', paction=>1, puser=>l_user);


            -- crapp-2086/2091 --
            EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n2 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n3 UNUSABLE';

            FOR i IN 1..5 LOOP
                gis_etl_p(l_pID, stcode_i, ' - Get Jurisdiction detail with no overrides and only 1 geo_area association '||v_county_start(i)||' to '||v_county_end(i)||' - gis_area_list_tmp', 0, l_user);

                EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_area_stage_tmp DROP STORAGE';
                EXECUTE IMMEDIATE 'ALTER INDEX gis_area_stage_tmp_n1 UNUSABLE'; -- crapp-4072

                -- 09/08/17 - changed to a Limited Fetch Loop, replacing Piped Function --
                OPEN dtl_nooverride_nozip4(stcode_i, v_county_start(i), v_county_end(i));
                LOOP
                    FETCH dtl_nooverride_nozip4 BULK COLLECT INTO v_areastage LIMIT 25000;

                    FORALL d IN 1..v_areastage.COUNT
                        INSERT INTO gis_area_stage_tmp
                        VALUES v_areastage(d);
                    COMMIT;

                    EXIT WHEN dtl_nooverride_nozip4%NOTFOUND;
                END LOOP;
                COMMIT;
                EXECUTE IMMEDIATE 'ALTER INDEX gis_area_stage_tmp_n1 REBUILD'; -- crapp-4072

                CLOSE dtl_nooverride_nozip4;
                v_areastage := t_areastage();

                INSERT INTO gis_area_list_tmp
                    (unique_area, stj_flag, state_name, county_name, city_name, zip, zip4, default_flag,
                     code_fips, state_code, jurisdiction_id, official_name, rid, nkid, geo_area)
                    SELECT  unique_area
                            , stj_flag
                            , state_name
                            , county_name
                            , city_name
                            , zip
                            , zip4
                            , default_flag
                            , code_fips
                            , state_code
                            , jurisdiction_id
                            , official_name
                            , rid
                            , nkid
                            , geo_area
                    FROM    gis_area_stage_tmp s
                    WHERE NOT EXISTS ( SELECT 1
                                       FROM   gis_area_list_tmp t
                                       WHERE      t.state_code    = s.state_code
                                              AND t.official_name = s.official_name
                                              AND t.unique_area   = s.unique_area
                                              AND t.zip  = s.zip
                                              AND t.zip4 = s.zip4
                                     );

                COMMIT;
                gis_etl_p(l_pID, stcode_i, ' - Get Jurisdiction detail with no overrides and only 1 geo_area association '||v_county_start(i)||' to '||v_county_end(i)||' - gis_area_list_tmp', 1, l_user);
            END LOOP;

            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats (TX) - gis_area_list_tmp', paction=>0, puser=>l_user);
            EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n2 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX gis_area_list_tmp_n3 REBUILD';
            DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_area_list_tmp', cascade => TRUE);
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats (TX) - gis_area_list_tmp', paction=>1, puser=>l_user);
        END IF; -- TX only code
        -- ******************* --



        -- Determine if Jurisdictions are not Published -- 08/07/15 crapp-1985
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine if Jurisdictions are not Published - gis_zone_juris_auths_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_juris_auths_tmp DROP STORAGE';

        -- Jurisdictions with Different Names --
        IF instance_i = 1 THEN   -- crapp-3082, changed to instance_i from tag_grp_i
            WITH auths AS
               (
                SELECT /*+index(j jurisdiction_identifiers_un) index(t gis_zone_auth_tags_tmp_n1) index(m mp_juris_auths_c1)*/
                       TRIM(stcode_i) state_code
                       , m.nkid
                       , m.authority_uuid
                       , j.official_name gis_name
                       ,  NVL(a.NAME, 'none') etl_name
                FROM   gis_zone_auth_tags_tmp t
                       JOIN jurisdictions j ON (t.ref_nkid = j.nkid)
                       LEFT JOIN sbxtax.mp_juris_auths m ON (t.ref_nkid = m.nkid)
                       JOIN sbxtax.tb_authorities a ON (m.authority_uuid = a.uuid)
                WHERE  j.next_rid IS NULL
               )
               , juris AS -- crapp-2078
               (
                SELECT DISTINCT
                       l.official_name
                       , l.jurisdiction_id
                       , j.nkid
                FROM   gis_area_list_tmp l
                       JOIN jurisdictions j ON (l.jurisdiction_id = j.id)
               )
                SELECT a.*
                BULK COLLECT INTO v_jurisauth
                FROM   auths a
                       JOIN juris o ON (a.nkid = o.nkid)
                WHERE  gis_name <> etl_name;

            FORALL i IN v_jurisauth.first..v_jurisauth.last
                INSERT INTO gis_zone_juris_auths_tmp
                VALUES v_jurisauth(i);
            COMMIT;

            v_jurisauth := t_jurisauth();
        ELSE
            WITH auths AS
               (
                SELECT /*+index(j jurisdiction_identifiers_un) index(t gis_zone_auth_tags_tmp_n1) index(m mp_juris_auths_c1)*/
                       TRIM(stcode_i) state_code
                       , m.nkid
                       , m.authority_uuid
                       , j.official_name gis_name
                       ,  NVL(a.NAME, 'none') etl_name
                FROM   gis_zone_auth_tags_tmp t
                       JOIN jurisdictions j ON (t.ref_nkid = j.nkid)
                       LEFT JOIN sbxtax4.mp_juris_auths m ON (t.ref_nkid = m.nkid)
                       JOIN sbxtax4.tb_authorities a ON (m.authority_uuid = a.uuid)
                WHERE  j.next_rid IS NULL
               )
               , juris AS -- crapp-2078
               (
                SELECT DISTINCT
                       l.official_name
                       , l.jurisdiction_id
                       , j.nkid
                FROM   gis_area_list_tmp l
                       JOIN jurisdictions j ON (l.jurisdiction_id = j.id)
               )
                SELECT a.*
                BULK COLLECT INTO v_jurisauth
                FROM   auths a
                       JOIN juris o ON (a.nkid = o.nkid)
                WHERE  gis_name <> etl_name;

            FORALL i IN v_jurisauth.first..v_jurisauth.last
                INSERT INTO gis_zone_juris_auths_tmp
                VALUES v_jurisauth(i);
            COMMIT;

            v_jurisauth := t_jurisauth();
        END IF;

        -- Jurisdictions Not Published -- crapp-2244
        IF instance_i = 1 THEN   -- crapp-3082, changed to instance_i from tag_grp_i

            -- Not published based on Jurisdiction NKID --
            WITH auths AS
               (
                SELECT /*+index(j jurisdiction_identifiers_un) index(t gis_zone_auth_tags_tmp_n1) index(j1 jurisdiction_identifiers_un)*/
                       TRIM(stcode_i) state_code
                       , m.nkid
                       , m.authority_uuid
                       , j.official_name  gis_name
                       , NVL(a.NAME, 'none')  etl_name
                FROM   gis_zone_auth_tags_tmp t
                       LEFT JOIN jurisdictions j ON (t.ref_nkid = j.nkid)
                       LEFT JOIN sbxtax.mp_juris_auths m ON (t.ref_nkid = m.nkid)
                       LEFT JOIN sbxtax.tb_authorities a ON (m.authority_uuid = a.uuid)
                WHERE  j.next_rid IS NULL
                       AND j.status < 2
                       AND j.official_name NOT LIKE 'US -%'  -- exclude US jurisdictions since they are applied automatically on Bottom Up only
               )
               , juris AS -- crapp-2078
               (
                SELECT DISTINCT
                       l.official_name
                       , l.jurisdiction_id
                       , j.nkid
                FROM   gis_area_list_tmp l
                       JOIN jurisdictions j ON (l.jurisdiction_id = j.id)
               )
                SELECT d.*
                BULK COLLECT INTO v_jurisauth
                FROM   auths d
                       JOIN  juris o ON (d.nkid = o.nkid)
                WHERE  gis_name <> etl_name
                       AND NOT EXISTS ( SELECT 1
                                        FROM   gis_zone_juris_auths_tmp g
                                        WHERE  g.nkid = d.nkid
                                               AND NVL(g.authority_uuid, -1) = NVL(d.authority_uuid, -1)
                                               AND g.gis_name = d.gis_name
                                      );

            FORALL i IN v_jurisauth.first..v_jurisauth.last
                INSERT INTO gis_zone_juris_auths_tmp
                VALUES v_jurisauth(i);
            COMMIT;

            v_jurisauth := t_jurisauth();

            -- Not published based on Jurisdiction name -- crapp-3636
            WITH auths AS
               (
                SELECT /*+index(j jurisdiction_identifiers_un) index(t gis_zone_auth_tags_tmp_n1) index(j1 jurisdiction_identifiers_un)*/
                       TRIM(stcode_i) state_code
                       , m.nkid
                       , m.authority_uuid
                       , j.official_name  gis_name
                       , NVL(a.NAME, 'none')  etl_name
                FROM   gis_zone_auth_tags_tmp t
                       LEFT JOIN jurisdictions j ON (t.ref_nkid = j.nkid)
                       LEFT JOIN sbxtax.mp_juris_auths m ON (t.ref_nkid = m.nkid)
                       LEFT JOIN sbxtax.tb_authorities a ON (m.authority_uuid = a.uuid)
                WHERE  j.next_rid IS NULL
                       AND j.status < 2
                       AND j.official_name NOT LIKE 'US -%'  -- exclude US jurisdictions since they are applied automatically on Bottom Up only
               )
               , juris AS -- crapp-2078
               (
                SELECT DISTINCT
                       l.official_name
                       , l.jurisdiction_id
                       , j.nkid
                FROM   gis_area_list_tmp l
                       JOIN jurisdictions j ON (l.jurisdiction_id = j.id)
               )
                SELECT d.*
                BULK COLLECT INTO v_jurisauth
                FROM   auths d
                       JOIN  juris o ON (d.gis_name = o.official_name)
                WHERE  gis_name <> etl_name
                       AND d.nkid IS NULL
                       AND NOT EXISTS ( SELECT 1
                                        FROM   gis_zone_juris_auths_tmp g
                                        WHERE  g.nkid = d.nkid
                                               AND NVL(g.authority_uuid, -1) = NVL(d.authority_uuid, -1)
                                               AND g.gis_name = d.gis_name
                                      );

            FORALL i IN v_jurisauth.first..v_jurisauth.last
                INSERT INTO gis_zone_juris_auths_tmp
                VALUES v_jurisauth(i);
            COMMIT;

            v_jurisauth := t_jurisauth();
        ELSE
            -- Not published based on Jurisdiction NKID --
            WITH auths AS
               (
                SELECT /*+index(j jurisdiction_identifiers_un) index(t gis_zone_auth_tags_tmp_n1) index(j1 jurisdiction_identifiers_un)*/
                       TRIM(stcode_i) state_code
                       , m.nkid
                       , m.authority_uuid
                       , j.official_name  gis_name
                       , NVL(a.NAME, 'none')  etl_name
                FROM   gis_zone_auth_tags_tmp t
                       LEFT JOIN jurisdictions j ON (t.ref_nkid = j.nkid)
                       LEFT JOIN sbxtax4.mp_juris_auths m ON (t.ref_nkid = m.nkid)
                       LEFT JOIN sbxtax4.tb_authorities a ON (m.authority_uuid = a.uuid)
                WHERE  j.next_rid IS NULL
                       AND j.status < 2
                       AND j.official_name NOT LIKE 'US -%'  -- exclude US jurisdictions since they are applied automatically on Bottom Up only
               )
               , juris AS -- crapp-2078
               (
                SELECT DISTINCT
                       l.official_name
                       , l.jurisdiction_id
                       , j.nkid
                FROM   gis_area_list_tmp l
                       JOIN jurisdictions j ON (l.jurisdiction_id = j.id)
               )
                SELECT d.*
                BULK COLLECT INTO v_jurisauth
                FROM   auths d
                       JOIN  juris o ON (d.nkid = o.nkid)
                WHERE  gis_name <> etl_name
                       AND NOT EXISTS ( SELECT 1
                                        FROM   gis_zone_juris_auths_tmp g
                                        WHERE  g.nkid = d.nkid
                                               AND NVL(g.authority_uuid, -1) = NVL(d.authority_uuid, -1)
                                               AND g.gis_name = d.gis_name
                                      );

            FORALL i IN v_jurisauth.first..v_jurisauth.last
                INSERT INTO gis_zone_juris_auths_tmp
                VALUES v_jurisauth(i);
            COMMIT;

            v_jurisauth := t_jurisauth();

            -- Not pulished based on Jurisdiction name -- crapp-3636
            WITH auths AS
               (
                SELECT /*+index(j jurisdiction_identifiers_un) index(t gis_zone_auth_tags_tmp_n1) index(j1 jurisdiction_identifiers_un)*/
                       TRIM(stcode_i) state_code
                       , m.nkid
                       , m.authority_uuid
                       , j.official_name  gis_name
                       , NVL(a.NAME, 'none')  etl_name
                FROM   gis_zone_auth_tags_tmp t
                       LEFT JOIN jurisdictions j ON (t.ref_nkid = j.nkid)
                       LEFT JOIN sbxtax4.mp_juris_auths m ON (t.ref_nkid = m.nkid)
                       LEFT JOIN sbxtax4.tb_authorities a ON (m.authority_uuid = a.uuid)
                WHERE  j.next_rid IS NULL
                       AND j.status < 2
                       AND j.official_name NOT LIKE 'US -%'  -- exclude US jurisdictions since they are applied automatically on Bottom Up only
               )
               , juris AS -- crapp-2078
               (
                SELECT DISTINCT
                       l.official_name
                       , l.jurisdiction_id
                       , j.nkid
                FROM   gis_area_list_tmp l
                       JOIN jurisdictions j ON (l.jurisdiction_id = j.id)
               )
                SELECT d.*
                BULK COLLECT INTO v_jurisauth
                FROM   auths d
                       JOIN  juris o ON (d.gis_name = o.official_name)
                WHERE  gis_name <> etl_name
                       AND d.nkid IS NULL
                       AND NOT EXISTS ( SELECT 1
                                        FROM   gis_zone_juris_auths_tmp g
                                        WHERE  g.nkid = d.nkid
                                               AND NVL(g.authority_uuid, -1) = NVL(d.authority_uuid, -1)
                                               AND g.gis_name = d.gis_name
                                      );

            FORALL i IN v_jurisauth.first..v_jurisauth.last
                INSERT INTO gis_zone_juris_auths_tmp
                VALUES v_jurisauth(i);
            COMMIT;

            v_jurisauth := t_jurisauth();
        END IF;

        SELECT COUNT(*)
        INTO  l_rec
        FROM  gis_zone_juris_auths_tmp;

        IF l_rec != 0 THEN
            gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'  - Found '||l_rec||' Jurisdictions that are not Published - gis_zone_juris_auths_tmp', paction=>3, puser=>l_user);
        END IF;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine if Jurisdictions are not Published - gis_zone_juris_auths_tmp', paction=>1, puser=>l_user);





        -- ********************** --
        -- Start processing Zones --
        -- ********************** --

        -- Changed where StateName is being pulled from - crapp-2645
        SELECT DISTINCT state_name
        INTO   l_statename
        FROM   gis_zone_detail_tmp
        WHERE  state_code = stcode_i;

        -- Build Zone Tree for Zip4s --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build zone tree ranges - gis_zone_authority_range_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_authority_range_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_range_tmp_n1 UNUSABLE';
        FOR t IN zip4tree LOOP <<zip4tree_loop>>

            IF l_firstpass THEN -- first pass
                l_firstpass    := FALSE;
                l_uniquearea   := t.unique_area;
                l_county       := t.county_name;
                l_city         := t.city_name;
                l_default      := t.default_flag;
                l_codefips     := t.code_fips;
                l_stj          := t.stj_flag;
                l_zip          := t.zip;
                l_zip4min      := t.zip4;

                IF t.zip4_ascii BETWEEN 65 AND 90 THEN      -- crapp-2087 ('A' and 'Z')
                    l_zip4ascii      := t.zip4;
                    l_nextzip4_ascii := TO_NUMBER(t.zip4_ascii + 1);

                    l_zip4min  := NULL; -- crapp-2740
                    l_nextzip4 := NULL; -- crapp-2740
                ELSE
                    l_nextzip4 := LPAD( TO_CHAR( TO_NUMBER(l_zip4min + 1) ), 4, '0');

                    l_zip4ascii      := NULL;   -- crapp-2740
                    l_nextzip4_ascii := NULL;   -- crapp-2740
                END IF;

            ELSE
                -- Determine the if the Zip Range needs to updated
                IF     l_uniquearea <> t.unique_area
                    OR l_county   <> t.county_name
                    OR l_city     <> t.city_name
                    OR NVL(l_default, 'N')  <> NVL(t.default_flag, 'N')
                    OR l_zip      <> t.zip                              -- added crapp-2090
                    OR l_nextzip4 <> NVL(t.zip4,'XXXX')                 -- crapp-2484, changed from t.zip4
                    OR l_nextzip4_ascii <> t.zip4_ascii THEN

                    l_nextzip4 := LPAD( TO_CHAR( TO_NUMBER(l_nextzip4 - 1) ), 4, '0');      -- decrement by one

                    INSERT INTO gis_zone_authority_range_tmp
                        (merchant_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name,
                         code_fips, range_min, range_max, reverse_flag, terminator_flag, stj_flag, unique_area, default_flag)
                        VALUES ( l_merchantid
                                 , l_zone1name
                                 , l_zone2name
                                 , l_statename
                                 , l_county
                                 , l_city
                                 , l_zip
                                 , NVL2(l_zip4min, (l_zip4min ||'-'|| l_nextzip4), NVL2(l_zip4ascii, (l_zip4ascii ||'-'|| l_zip4ascii), NULL))  -- zone7
                                 , NVL2(l_zip4min, (l_codefips || l_zip4min ||'-'|| l_nextzip4), l_codefips)
                                 , l_zip4min
                                 , l_nextzip4
                                 , 'N'
                                 , 'N'
                                 , l_stj
                                 , l_uniquearea
                                 , l_default
                               );

                    IF t.zip4_ascii BETWEEN 65 AND 90 THEN      -- crapp-2087 ('A' and 'Z')
                        l_zip4min  := NULL;
                        l_nextzip4 := NULL;

                        l_zip4ascii      := t.zip4;
                        l_nextzip4_ascii := TO_NUMBER(t.zip4_ascii + 1);
                    ELSE
                        l_zip4min  := t.zip4;
                        l_nextzip4 := LPAD( TO_CHAR( TO_NUMBER(l_zip4min + 1) ), 4, '0');

                        l_zip4ascii      := NULL;
                        l_nextzip4_ascii := NULL;
                    END IF;

                    l_uniquearea   := t.unique_area;
                    l_county       := t.county_name;
                    l_city         := t.city_name;
                    l_zip          := t.zip;
                    l_codefips     := t.code_fips;
                    l_stj          := t.stj_flag;
                    l_default      := t.default_flag;
                ELSE

                    l_nextzip4 := LPAD( TO_CHAR( TO_NUMBER(l_nextzip4 + 1) ), 4, '0');      -- calc next zip in range
                    l_nextzip4_ascii := TO_NUMBER(l_nextzip4_ascii + 1);                    -- crapp-2087

                END IF;
            END IF;

        END LOOP zip4tree_loop;
        COMMIT;


        -- End of Loop, so output last range record
        l_nextzip4 := LPAD( TO_CHAR( TO_NUMBER(l_nextzip4 - 1) ), 4, '0');            -- decrement by one

        INSERT INTO gis_zone_authority_range_tmp
            (merchant_id, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name,
             code_fips, range_min, range_max, stj_flag, unique_area, default_flag)
            VALUES ( l_merchantid
                     , l_zone1name
                     , l_zone2name
                     , l_statename
                     , l_county
                     , l_city
                     , l_zip
                     , NVL2(l_zip4min, (l_zip4min ||'-'|| l_nextzip4), NVL2(l_zip4ascii, (l_zip4ascii ||'-'|| l_zip4ascii), NULL))  -- zone7
                     , NVL2(l_zip4min, (l_codefips || l_zip4min ||'-'|| l_nextzip4), l_codefips)  -- code_fips
                     , l_zip4min
                     , l_nextzip4
                     , l_stj
                     , l_uniquearea
                     , l_default
                   );
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Build zone tree ranges - gis_zone_authority_range_tmp', paction=>1, puser=>l_user);


        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_zone_authority_range_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_range_tmp_n1 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_authority_range_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_zone_authority_range_tmp', paction=>1, puser=>l_user);


        -- Update the table stats on the primary temp table --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Update stats - gis_area_list_tmp', paction=>0, puser=>l_user);
            DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_area_list_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Update stats - gis_area_list_tmp', paction=>1, puser=>l_user);


        -- Associate Jurisdictions to Zip Ranges --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_area_stage_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_area_stage_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_area_stage_tmp_n1 UNUSABLE'; -- crapp-4072
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_area_stage_tmp', paction=>1, puser=>l_user);

        -- 04/25/17 - added stage table to improve performance - crapp-4072, changed to Limited Bulk Collect loop --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Associate Juris to ranges (stage table) - gis_area_stage_tmp', paction=>0, puser=>l_user);
        OPEN juris_ranges(stcode_i);
        LOOP
            FETCH juris_ranges BULK COLLECT INTO v_areastage LIMIT 50000;

            FORALL r IN 1..v_areastage.COUNT
                INSERT INTO gis_area_stage_tmp
                VALUES v_areastage(r);
            COMMIT;

            EXIT WHEN juris_ranges%NOTFOUND;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Associate Juris to ranges (stage table) - gis_area_stage_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes/stats - gis_area_stage_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'ALTER INDEX gis_area_stage_tmp_n1 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_area_stage_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes/stats - gis_area_stage_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_authorities_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_tmp_n1 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_tmp_n2 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_tmp_n3 UNUSABLE';
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Clear table - gis_zone_authorities_tmp', paction=>1, puser=>l_user);

        -- crapp-4072 - added for performance --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Associate Juris to ranges (no zip) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        INSERT INTO gis_zone_authorities_tmp
            (
              merchant_id
            , zone_1_name
            , zone_2_name
            , zone_3_name
            , zone_4_name
            , zone_5_name
            , zone_6_name
            , zone_7_name
            , tax_parent_zone
            , code_2char
            , code_fips
            , reverse_flag
            , terminator_flag
            , default_flag
            , range_min
            , range_max
            , authority_name
            , stj_flag
            , geo_area
            , processed
            )
            SELECT /*+parallel(a,4) index(a gis_zone_auth_range_tmp_n1)*/
                   DISTINCT
                   a.merchant_id
                   ,a.zone_1_name
                   ,a.zone_2_name
                   ,a.zone_3_name
                   ,a.zone_4_name
                   ,a.zone_5_name
                   ,a.zone_6_name
                   ,a.zone_7_name
                   ,NULL tax_parent_zone
                   ,a.code_2char
                   ,a.code_fips
                   ,NULL reverse_flag
                   ,NULL terminator_flag
                   ,a.default_flag
                   ,a.range_min
                   ,a.range_max
                   ,z.official_name authority_name
                   ,a.stj_flag
                   ,z.geo_area
                   ,NULL processed
            FROM   (
                     SELECT state_code, state_name, county_name, city_name, zip, zip4, unique_area, official_name, geo_area, code_fips AS zip4_ascii
                     FROM   gis_area_stage_tmp
                     WHERE  zip IS NULL
                   ) z
                   JOIN gis_zone_authority_range_tmp a ON (     z.unique_area = a.unique_area
                                                            AND z.state_name  = a.zone_3_name
                                                            AND z.county_name = a.zone_4_name
                                                            AND z.city_name   = a.zone_5_name
                                                            AND a.zone_6_name IS NULL
                                                          );
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Associate Juris to ranges (no zip) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- crapp-4072 - added for performance --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Associate Juris to ranges (FOUR zip4) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        INSERT INTO gis_zone_authorities_tmp
            (
              merchant_id
            , zone_1_name
            , zone_2_name
            , zone_3_name
            , zone_4_name
            , zone_5_name
            , zone_6_name
            , zone_7_name
            , tax_parent_zone
            , code_2char
            , code_fips
            , reverse_flag
            , terminator_flag
            , default_flag
            , range_min
            , range_max
            , authority_name
            , stj_flag
            , geo_area
            , processed
            )
            SELECT /*+index(a gis_zone_auth_range_tmp_n1)*/
                   DISTINCT
                   a.merchant_id
                   ,a.zone_1_name
                   ,a.zone_2_name
                   ,a.zone_3_name
                   ,a.zone_4_name
                   ,a.zone_5_name
                   ,a.zone_6_name
                   ,a.zone_7_name
                   ,NULL tax_parent_zone
                   ,a.code_2char
                   ,a.code_fips
                   ,NULL reverse_flag
                   ,NULL terminator_flag
                   ,a.default_flag
                   ,a.range_min
                   ,a.range_max
                   ,z.official_name authority_name
                   ,a.stj_flag
                   ,z.geo_area
                   ,NULL processed
            FROM   (
                     SELECT state_code, state_name, county_name, city_name, zip, zip4, unique_area, official_name, geo_area, -1 zip4_ascii
                     FROM   gis_area_stage_tmp
                     WHERE  zip IS NOT NULL
                            AND zip4 IS NOT NULL AND code_fips IS NOT NULL
                   ) z
                   JOIN gis_zone_authority_range_tmp a ON (     z.unique_area = a.unique_area
                                                            AND z.state_name  = a.zone_3_name
                                                            AND z.county_name = a.zone_4_name
                                                            AND z.city_name   = a.zone_5_name
                                                            AND z.zip         = a.zone_6_name
                                                            AND z.zip4_ascii BETWEEN NVL(a.range_min, -1) AND NVL(a.range_max, -1)
                                                          );
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Associate Juris to ranges (FOUR zip4) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- crapp-4072 - updated for performance --
        FOR i IN 1..5 LOOP
            gis_etl_p(l_pID, stcode_i, ' - Associate Juris to ranges (with zips) '||v_county_start(i)||' to '||v_county_end(i)||' - gis_zone_authorities_tmp', 0, l_user);
            INSERT INTO gis_zone_authorities_tmp
                (
                  merchant_id
                , zone_1_name
                , zone_2_name
                , zone_3_name
                , zone_4_name
                , zone_5_name
                , zone_6_name
                , zone_7_name
                , tax_parent_zone
                , code_2char
                , code_fips
                , reverse_flag
                , terminator_flag
                , default_flag
                , range_min
                , range_max
                , authority_name
                , stj_flag
                , geo_area
                , processed
                )
                SELECT /*+parallel(a,4) index(a gis_zone_auth_range_tmp_n1)*/
                       DISTINCT
                       a.merchant_id
                       ,a.zone_1_name
                       ,a.zone_2_name
                       ,a.zone_3_name
                       ,a.zone_4_name
                       ,a.zone_5_name
                       ,a.zone_6_name
                       ,a.zone_7_name
                       ,NULL tax_parent_zone
                       ,a.code_2char
                       ,a.code_fips
                       ,NULL reverse_flag
                       ,NULL terminator_flag
                       ,a.default_flag
                       ,a.range_min
                       ,a.range_max
                       ,z.official_name authority_name
                       ,a.stj_flag
                       ,z.geo_area
                       ,NULL processed
                FROM   (
                         SELECT state_code, state_name, county_name, city_name, zip, zip4, unique_area, official_name, geo_area, code_fips zip4_ascii
                         FROM   gis_area_stage_tmp
                         WHERE  zip IS NOT NULL
                                AND zip4 IS NOT NULL AND code_fips IS NULL
                                AND county_name BETWEEN v_county_start(i) AND v_county_end(i)
                       ) z
                       JOIN gis_zone_authority_range_tmp a ON (     z.unique_area = a.unique_area
                                                                AND z.state_name  = a.zone_3_name
                                                                AND z.county_name = a.zone_4_name
                                                                AND z.city_name   = a.zone_5_name
                                                                AND z.zip         = a.zone_6_name
                                                                AND TO_NUMBER(z.zip4) BETWEEN NVL(a.range_min, -1) AND NVL(a.range_max, -1)
                                                              );
            COMMIT;
            gis_etl_p(l_pID, stcode_i, ' - Associate Juris to ranges (with zips) '||v_county_start(i)||' to '||v_county_end(i)||' - gis_zone_authorities_tmp', 1, l_user);
        END LOOP;


        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_tmp_n1 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_tmp_n2 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_tmp_n3 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_authorities_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- ************************************** --
        -- Determine Counts used in Parse process --
        -- ************************************** --


        -- 2.x -- 07/06/15 - crapp-1812
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine District County/City distribution - gis_zone_auth_counts_stage', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_auth_counts_stage DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_cnts_stage_n1 UNUSABLE';
        WITH authcounts AS
            (
             SELECT state_name
                    , county_name
                    , city_name
                    , official_name
                    , COUNT( DISTINCT unique_area) area_count
             FROM   gis_area_list_tmp
             WHERE  geo_area = 'District'
                    AND unique_area NOT IN (SELECT DISTINCT unique_area FROM gis_zone_areas_orig_tmp) -- crapp-2029
                    AND zip IS NOT NULL -- crapp-3094
             GROUP BY state_name
                    , county_name
                    , city_name
                    , official_name
            ),
            areacounts AS
            (
             SELECT   UPPER(state_name)  state_name
                    , UPPER(county_name) county_name
                    , UPPER(city_name)   city_name
                    , COUNT(DISTINCT unique_area) total_area_count
             FROM   vgeo_unique_areas2
             WHERE  state_code = stcode_i
                    AND zip IS NOT NULL
                    AND unique_area NOT IN (SELECT DISTINCT unique_area FROM gis_zone_areas_orig_tmp) -- crapp-2029
             GROUP BY state_name
                    , county_name
                    , city_name
            ),
            pct AS
            (
             SELECT DISTINCT
                    a.official_name      authority_name
                    , a.state_name       zone_3_name
                    , a.county_name      zone_4_name
                    , a.city_name        zone_5_name
                    , a.area_count       rangecnt
                    , c.total_area_count zip4count
                    , ROUND( (a.area_count / c.total_area_count) , 4) zippct
             FROM   authcounts a
                    JOIN areacounts c ON (     a.state_name  = c.state_name
                                           AND a.county_name = c.county_name
                                           AND a.city_name   = c.city_name
                                         )
            )
             SELECT NULL unique_area
                    , zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , rangecnt
                    , zip4count
                    , zippct
                    , authority_name
             BULK COLLECT INTO v_authcntstage
             FROM   pct;

        FORALL i IN v_authcntstage.first..v_authcntstage.last
            INSERT INTO gis_zone_auth_counts_stage
            VALUES v_authcntstage(i);
        COMMIT;

        v_authcntstage := t_authcntstage();

        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_cnts_stage_n1 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_auth_counts_stage', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine District County/City distribution - gis_zone_auth_counts_stage', paction=>1, puser=>l_user);


        -- 2.x -- updated 07/01/15 - crapp-1872
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine District Zip distribution - gis_zone_auth_counts_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_auth_counts_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_cnts_tmp_n1 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_cnts_tmp_n2 UNUSABLE';
        WITH authzips AS
            (
             SELECT state_name
                    , county_name
                    , city_name
                    , zip
                    , official_name
                    , COUNT( DISTINCT zip4) zip_count
                    , unique_area
             FROM   gis_area_list_tmp
             WHERE  unique_area NOT IN (SELECT DISTINCT unique_area FROM gis_zone_areas_orig_tmp) -- crapp-2029
             GROUP BY state_name
                    , county_name
                    , city_name
                    , zip
                    , official_name
                    , unique_area
            ),
            cnyzips AS
            (
             SELECT zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , zone_6_name
                    , SUM((TO_NUMBER(range_max) - TO_NUMBER(range_min)) + 1) total_zip_count
             FROM   gis_zone_tree_tmp
             WHERE  zone_7_name IS NOT NULL
             GROUP BY zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , zone_6_name
            ),
            ranges AS
            (
             SELECT DISTINCT
                    zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, unique_area
             FROM   gis_zone_authority_range_tmp
             WHERE  zone_7_name IS NOT NULL
            ),
            pct AS
            (
             SELECT DISTINCT
                    a.official_name     authority_name
                    , a.state_name      zone_3_name
                    , a.county_name     zone_4_name
                    , a.city_name       zone_5_name
                    , a.zip             zone_6_name
                    , a.zip_count       rangecnt
                    , c.total_zip_count zip4count
                    , ROUND( (a.zip_count / c.total_zip_count) , 4) zippct
                    , a.unique_area     unique_area
             FROM   authzips a
                    JOIN cnyzips c ON (     a.state_name  = c.zone_3_name
                                        AND a.county_name = c.zone_4_name
                                        AND a.city_name   = c.zone_5_name
                                        AND a.zip         = c.zone_6_name
                                      )
            )
             SELECT p.authority_name
                    , p.zone_3_name
                    , p.zone_4_name
                    , p.zone_5_name
                    , p.zone_6_name
                    , r.zone_7_name
                    , p.unique_area
                    , p.rangecnt
                    , p.zip4count
                    , p.zippct
             BULK COLLECT INTO v_authcnts
             FROM   pct p
                    JOIN ranges r ON (     p.zone_3_name = r.zone_3_name
                                       AND p.zone_4_name = r.zone_4_name
                                       AND p.zone_5_name = r.zone_5_name
                                       AND p.zone_6_name = r.zone_6_name
                                       AND p.unique_area = r.unique_area
                                     );

        FORALL i IN v_authcnts.first..v_authcnts.last
            INSERT INTO gis_zone_auth_counts_tmp
            VALUES v_authcnts(i);
        COMMIT;

        v_authcnts := t_authcnts();

        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_cnts_tmp_n1 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_cnts_tmp_n2 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_auth_counts_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine District Zip distribution - gis_zone_auth_counts_tmp', paction=>1, puser=>l_user);


        -- 2.x -- updated 07/01/15 - crapp-1872
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine Zip distribution without area - gis_zone_auth_counts2_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_auth_counts2_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_cnts2_tmp_n1 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_cnts2_tmp_n2 UNUSABLE';
        WITH authzips AS
            (
             SELECT state_name
                    , county_name
                    , city_name
                    , zip
                    , official_name
                    , COUNT( DISTINCT zip4) zip_count
             FROM   gis_area_list_tmp
             WHERE  unique_area NOT IN (SELECT DISTINCT unique_area FROM gis_zone_areas_orig_tmp) -- crapp-1881/2029
             GROUP BY state_name
                    , county_name
                    , city_name
                    , zip
                    , official_name
            ),
            cnyzips AS
            (
             SELECT zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , zone_6_name
                    , SUM((TO_NUMBER(range_max) - TO_NUMBER(range_min)) + 1) total_zip_count
             FROM   gis_zone_tree_tmp
             WHERE  zone_7_name IS NOT NULL
             GROUP BY zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , zone_6_name
            )
             SELECT DISTINCT
                    a.official_name     authority_name
                    , a.state_name      zone_3_name
                    , a.county_name     zone_4_name
                    , a.city_name       zone_5_name
                    , a.zip             zone_6_name
                    , a.zip_count       rangecnt
                    , c.total_zip_count zip4count
                    , ROUND( (a.zip_count / c.total_zip_count) , 4) zippct
             BULK COLLECT INTO v_authcnts2
             FROM   authzips a
                    JOIN cnyzips c ON (     a.state_name  = c.zone_3_name
                                        AND a.county_name = c.zone_4_name
                                        AND a.city_name   = c.zone_5_name
                                        AND a.zip         = c.zone_6_name
                                      );

        FORALL i IN v_authcnts2.first..v_authcnts2.last
            INSERT INTO gis_zone_auth_counts2_tmp
            VALUES v_authcnts2(i);
        COMMIT;

        v_authcnts2 := t_authcnts2();

        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_cnts2_tmp_n1 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_cnts2_tmp_n2 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_auth_counts2_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine Zip distribution without area - gis_zone_auth_counts2_tmp', paction=>1, puser=>l_user);


        -- 2.x -- updated 07/01/15 - crapp-1872
        -- Range detail table used in Top-Down process - < 70% --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get range detail for top-down process - < 70% - gis_zone_auth_bustage_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_auth_bustage_tmp DROP STORAGE';

        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bustage_tmp_n1 UNUSABLE';
        SELECT  DISTINCT
                r.authority_name
                , r.zone_3_name
                , r.zone_4_name
                , r.zone_5_name
                , r.zone_6_name
                , r.zone_7_name
                , r.unique_area
        BULK COLLECT INTO v_bustage
        FROM    gis_zone_auth_counts_tmp r
                JOIN ( SELECT DISTINCT
                              zone_3_name
                              , zone_4_name
                              , zone_5_name
                              , zone_6_name
                              , authority_name
                              , zippct
                       FROM   gis_zone_auth_counts2_tmp
                       WHERE  zippct < 0.7
                     ) td ON (     r.zone_3_name = td.zone_3_name
                               AND r.zone_4_name = td.zone_4_name
                               AND r.zone_5_name = td.zone_5_name
                               AND r.zone_6_name = td.zone_6_name
                               AND r.authority_name = td.authority_name
                             )
        WHERE   r.zippct < 0.7
                AND r.unique_area NOT IN (SELECT DISTINCT unique_area FROM gis_zone_areas_orig_tmp); -- crapp-2029

        FORALL i IN v_bustage.first..v_bustage.last
            INSERT INTO gis_zone_auth_bustage_tmp
            VALUES v_bustage(i);
        COMMIT;

        v_bustage := t_bustage();
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bustage_tmp_n1 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_auth_bustage_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get range detail for top-down process - < 70% - gis_zone_auth_bustage_tmp', paction=>1, puser=>l_user);


        -- 2.x -- updated 07/15/15 - crapp-1883
        -- Range detail table used in Bottom-up process - > 70% and < 100% - Make remainder Bottom-Up --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get range detail for bottom-up process - > 70% and < 100% - Make remainder Bottom-Up - gis_zone_auth_budetail_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_auth_budetail_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_budetail_tmp_n1 UNUSABLE';     -- 05/25/17, added

        -- crapp-4072 - added for performance --
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_auth_stage_tmp DROP STORAGE';
        INSERT INTO gis_zone_auth_stage_tmp
            (
             state_code
             , official_name
             , county_name
             , city_name
             , geo_area
            )
             SELECT DISTINCT            -- Limit to only Districts
                    state_code
                    , official_name
                    , county_name
                    , city_name
                    , geo_area
             FROM   gis_area_list_tmp
             WHERE  geo_area = 'District';
        COMMIT;

        SELECT DISTINCT
               r.authority_name
               , r.zone_3_name
               , r.zone_4_name
               , r.zone_5_name
               , r.zone_6_name
               , r.zone_7_name
               , r.unique_area
        BULK COLLECT INTO v_budetail
        FROM   gis_zone_auth_counts_tmp r
               JOIN ( SELECT DISTINCT
                             zone_3_name
                             , zone_4_name
                             , zone_5_name
                             , zone_6_name
                             , authority_name
                             , zippct
                      FROM   gis_zone_auth_counts2_tmp c
                             JOIN gis_zone_auth_stage_tmp a ON (     c.zone_4_name = a.county_name -- crapp-4072, changed to staging table
                                                                 AND c.zone_5_name = a.city_name
                                                                 AND c.authority_name = a.official_name
                                                               )
                      WHERE  zippct > 0.7 AND zippct < 1
                    ) td ON (     r.zone_3_name = td.zone_3_name
                              AND r.zone_4_name = td.zone_4_name
                              AND r.zone_5_name = td.zone_5_name
                              AND r.zone_6_name = td.zone_6_name
                              AND r.authority_name <> td.authority_name
                            )
        WHERE  r.zippct < 0.7;

        FORALL i IN v_budetail.first..v_budetail.last
            INSERT INTO gis_zone_auth_budetail_tmp
            VALUES v_budetail(i);
        COMMIT;

        v_budetail := t_budetail();
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get range detail for bottom-up process - > 70% and < 100% - Make remainder Bottom-Up - gis_zone_auth_budetail_tmp', paction=>1, puser=>l_user);


        -- 2.x -- 08/31/15 - crapp-2029
        -- Append to range detail table used in Bottom-up process - Authorities that were replaced by Jurisdiction overrides --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get range detail for bottom-up process - Auths replaced by overrides - gis_zone_auth_budetail_tmp', paction=>0, puser=>l_user);
        WITH authzips AS
            (
             SELECT DISTINCT
                    state_name      zone_3_name
                    , county_name   zone_4_name
                    , city_name     zone_5_name
                    , zip           zone_6_name
                    , official_name authority_name
                    , unique_area
             FROM   gis_area_list_tmp
             WHERE  unique_area IN (SELECT DISTINCT unique_area FROM gis_zone_areas_orig_tmp)
            ),
            ranges AS
            (
             SELECT DISTINCT
                    zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, unique_area
             FROM   gis_zone_authority_range_tmp
             WHERE  zone_7_name IS NOT NULL
            )
             SELECT a.authority_name
                    , a.zone_3_name
                    , a.zone_4_name
                    , a.zone_5_name
                    , a.zone_6_name
                    , r.zone_7_name
                    , a.unique_area
             BULK COLLECT INTO v_budetail
             FROM   authzips a
                    JOIN ranges r ON (     a.zone_3_name = r.zone_3_name
                                       AND a.zone_4_name = r.zone_4_name
                                       AND a.zone_5_name = r.zone_5_name
                                       AND a.zone_6_name = r.zone_6_name
                                       AND a.unique_area = r.unique_area
                                     );

        FORALL i IN v_budetail.first..v_budetail.last
            INSERT INTO gis_zone_auth_budetail_tmp
            VALUES v_budetail(i);
        COMMIT;

        v_budetail := t_budetail();
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_budetail_tmp_n1 REBUILD';     -- 05/25/17, added
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_auth_budetail_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Get range detail for bottom-up process - Auths replaced by overrides - gis_zone_auth_budetail_tmp', paction=>1, puser=>l_user);


        -- 2.x -- crapp-3094
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine District County/City distribution - no Zips - gis_zone_auth_nozip_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_auth_nozip_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_nozip_tmp_n1 UNUSABLE';
        WITH authcounts AS
            (
             SELECT state_name
                    , county_name
                    , city_name
                    , official_name
                    , COUNT( DISTINCT unique_area) area_count
             FROM   gis_area_list_tmp
             WHERE  unique_area NOT IN (SELECT DISTINCT unique_area FROM gis_zone_areas_orig_tmp) -- crapp-2029
                    AND zip IS NULL
                    --AND geo_area = 'District' -- not restricting by GeoArea
             GROUP BY state_name
                    , county_name
                    , city_name
                    , official_name
            ),
            areacounts AS
            (
             SELECT UPPER(state_name) state_name
                    , UPPER(county_name) county_name
                    , UPPER(city_name)   city_name
                    , COUNT(DISTINCT unique_area) total_area_count
             FROM   vgeo_unique_areas2
             WHERE  state_code = stcode_i
                    AND zip IS NULL
                    AND unique_area NOT IN (SELECT DISTINCT unique_area FROM gis_zone_areas_orig_tmp) -- crapp-2029
             GROUP BY state_name
                    , county_name
                    , city_name
            ),
            pct AS
            (
             SELECT DISTINCT
                    a.official_name      authority_name
                    , a.state_name       zone_3_name
                    , a.county_name      zone_4_name
                    , a.city_name        zone_5_name
                    , a.area_count       areacnt
                    , c.total_area_count totalcount
                    , ROUND( (a.area_count / c.total_area_count) , 4) areapct
             FROM   authcounts a
                    JOIN areacounts c ON (     a.state_name  = c.state_name
                                           AND a.county_name = c.county_name
                                           AND a.city_name   = c.city_name
                                         )
            )
             SELECT p.zone_3_name
                    , p.zone_4_name
                    , p.zone_5_name
                    , p.areacnt
                    , p.totalcount
                    , p.areapct
                    , p.authority_name
             BULK COLLECT INTO v_authnozips
             FROM   pct p
                    LEFT JOIN gis_zone_auth_counts_stage z ON (    p.zone_3_name = z.zone_3_name
                                                               AND p.zone_4_name = z.zone_4_name
                                                               AND p.zone_5_name = z.zone_5_name
                                                               --AND p.authority_name = z.authority_name  -- crapp-3190/3191 removed
                                                              )
             WHERE  z.zone_3_name IS NULL; -- Excluding areas where there are Zips

        FORALL i IN v_authnozips.first..v_authnozips.last
            INSERT INTO gis_zone_auth_nozip_tmp
            VALUES v_authnozips(i);
        COMMIT;

        v_authnozips := t_authnozips();
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_nozip_tmp_n1 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_auth_nozip_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Determine District County/City distribution - no Zips - gis_zone_auth_nozip_tmp', paction=>1, puser=>l_user);



        -- ******************* --
        -- Start Parse Process --
        -- ******************* --


        -- 1 --
        -- Delete NULL District records created in error
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 1) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN cleanupnulls LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE  zone_3_name = c.zone_3_name
                   AND zone_4_name = c.zone_4_name
                   AND zone_5_name = c.zone_5_name
                   AND authority_name = c.authority_name
                   AND zone_6_name IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 1) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 2.1 -- crapp-1874/1883
        -- Attach Authority to City where within 100% of County/City - Districts
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.1) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN attach_city LOOP
            UPDATE /*+index (t gis_zone_auth_tmp_n1)*/ gis_zone_authorities_tmp t
                SET   zone_6_id        = NULL
                    , zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 10)    -- City
                    , reverse_flag     = 'N'
                    , terminator_flag  = NULL
                    , default_flag     = NULL
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 2.1
            WHERE   zone_3_name = c.zone_3_name
                AND zone_4_name = c.zone_4_name
                AND zone_5_name = c.zone_5_name
                AND zone_6_name = c.zone_6_name
                AND NVL(zone_7_name, 'zone7') = NVL(c.zone_7_name, 'zone7')
                AND authority_name = c.authority_name
                AND geo_area = c.geo_area;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.1) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 2.2 -- crapp-1812/1883
        -- Update Zone Tree records for Authorities in remainder of >= 70% in County/City/Zip (make Bottom-Up)
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.2) - gis_zone_authorities_tmp - gis_zone_tree_tmp', paction=>0, puser=>l_user);
        FOR b IN attach_bu LOOP <<but_loop>>
            -- Update Zone Tree --
            UPDATE  gis_zone_tree_tmp
                SET reverse_flag    = 'Y',
                    terminator_flag = 'Y',
                    default_flag    = NULL
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND zone_6_name = b.zone_6_name
                AND range_min   = b.range_min
                AND range_max   = b.range_max;

            -- Update Zone Auth Tree --
            UPDATE /*+index (t gis_zone_auth_tmp_n1)*/ gis_zone_authorities_tmp t
                SET reverse_flag    = 'Y',
                    terminator_flag = 'Y',
                    default_flag    = NULL,
                    processed       = 2.2
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND zone_6_name = b.zone_6_name
                AND zone_7_name = b.zone_7_name
                AND authority_name = b.authority_name;
        END LOOP but_loop;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.2) - gis_zone_authorities_tmp - gis_zone_tree_tmp', paction=>1, puser=>l_user);


        -- 2.3 -- crapp-1812/1883
        -- Attach Authorities to Zip in > 70% and < 100% of County/City/Zip (Top Down - make remainder Bottom-Up - step 2.2)
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.3) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR z IN attach_zip LOOP
            UPDATE /*+index (t gis_zone_auth_tmp_n1)*/ gis_zone_authorities_tmp t
                SET   zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 15)    -- Zip
                    , reverse_flag     = 'N'
                    , terminator_flag  = 'N'
                    , default_flag     = NULL
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 2.3
            WHERE   zone_3_name = z.zone_3_name
                AND zone_4_name = z.zone_4_name
                AND zone_5_name = z.zone_5_name
                AND zone_6_name = z.zone_6_name
                AND zone_7_name = z.zone_7_name
                AND authority_name = z.authority_name;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.3) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 2.4 -- crapp-1812/1863/1883 -- 07/23/15 changed to collection for performance
        -- Attach Authority to Zip where within 100% of County/City/Zip - Districts
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.4) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_zone_auth_updates_tmp DROP STORAGE';
        WITH pct AS
            (
             SELECT DISTINCT
                    r.authority_name
                    , r.zone_3_name
                    , r.zone_4_name
                    , r.zone_5_name
                    , r.zone_6_name
                    , r.zone_7_name
             FROM   gis_zone_auth_counts_tmp r
                    JOIN ( SELECT DISTINCT
                                  zone_3_name
                                  , zone_4_name
                                  , zone_5_name
                                  , zone_6_name
                                  , authority_name
                                  , zippct
                           FROM   gis_zone_auth_counts2_tmp
                           WHERE  zippct = 1
                         ) td ON (     r.zone_3_name = td.zone_3_name
                                   AND r.zone_4_name = td.zone_4_name
                                   AND r.zone_5_name = td.zone_5_name
                                   AND r.zone_6_name = td.zone_6_name
                                   AND r.authority_name = td.authority_name
                                 )
            )
            SELECT  DISTINCT
                    t.zone_3_name, t.zone_4_name, t.zone_5_name, t.zone_6_name, t.zone_7_name, t.authority_name, t.geo_area
            BULK COLLECT INTO v_authupdt
            FROM    gis_zone_authorities_tmp t
                    JOIN pct z ON (    t.zone_3_name = z.zone_3_name
                                   AND t.zone_4_name = z.zone_4_name
                                   AND t.zone_5_name = z.zone_5_name
                                   AND t.zone_6_name = z.zone_6_name
                                   AND t.zone_7_name = z.zone_7_name
                                   AND t.authority_name = z.authority_name
                                  )
            WHERE   t.geo_area = 'District'
                    AND t.processed IS NULL
            ORDER BY t.zone_4_name, t.zone_5_name, t.zone_6_name, t.zone_7_name, t.authority_name;

        FORALL i IN v_authupdt.first..v_authupdt.last
            INSERT INTO gis_zone_auth_updates_tmp
            VALUES v_authupdt(i);
        COMMIT;

        v_authupdt := t_authupdt();

        FOR c IN attach_zip_100pct LOOP
            UPDATE gis_zone_authorities_tmp
                SET   zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 15)    -- Zip
                    , reverse_flag     = 'N'
                    , terminator_flag  = NULL
                    , default_flag     = NULL
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 2.4
            WHERE   zone_3_name = c.zone_3_name
                AND zone_4_name = c.zone_4_name
                AND zone_5_name = c.zone_5_name
                AND zone_6_name = c.zone_6_name
                AND NVL(zone_7_name, 'zone7') = c.zone_7_name
                AND authority_name = c.authority_name
                AND geo_area = c.geo_area;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.4) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 2.45 - crapp-3195
        -- Attach Authority to City where Authority is within 100% of County/City - Districts
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.45) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN attach_zip_100pct_city LOOP
            UPDATE gis_zone_authorities_tmp
                SET   zone_6_id        = NULL
                    , zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 10)    -- City
                    , reverse_flag     = 'N'
                    , terminator_flag  = NULL
                    , default_flag     = NULL
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 2.45
            WHERE   zone_3_name = c.zone_3_name
                AND zone_4_name = c.zone_4_name
                AND zone_5_name = c.zone_5_name
                AND zone_6_name = c.zone_6_name
                AND authority_name = c.authority_name
                AND zone_7_name IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.45) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 3 --
        -- NULL records where Authority is within entire County - crapp-1883 - 07/20/15 moved to between 2.4/2.5
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 3) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        OPEN entirecountyzip;   -- crapp-4072, changed to limited fetch loop --
        LOOP
            FETCH entirecountyzip BULK COLLECT INTO v_zoneauths LIMIT 75000;

            FORALL c IN 1..v_zoneauths.COUNT
                UPDATE /*+index (t gis_zone_auth_tmp_n1)*/ gis_zone_authorities_tmp t
                    SET   zone_5_id        = NULL   -- Added zone_5 back in 02/27/15
                        , zone_5_name      = NULL
                        , zone_5_level_id  = NULL
                        , zone_5_parent_id = NULL
                        , zone_6_id        = NULL
                        , zone_6_name      = NULL
                        , zone_6_level_id  = NULL
                        , zone_6_parent_id = NULL
                        , zone_7_id        = NULL
                        , zone_7_name      = NULL
                        , zone_7_level_id  = NULL
                        , zone_7_parent_id = NULL
                        , code_fips        = SUBSTR(code_fips, 1, 5)    -- County
                        , reverse_flag     = NULL
                        , terminator_flag  = NULL
                        , default_flag     = NULL
                        , range_min        = NULL
                        , range_max        = NULL
                        , processed        = 3
                WHERE   zone_3_name = v_zoneauths(c).zone_3_name
                    AND zone_4_name = v_zoneauths(c).zone_4_name
                    AND zone_5_name = v_zoneauths(c).zone_5_name
                    AND NVL(zone_6_name, 'zone6') = NVL(v_zoneauths(c).zone_6_name, 'zone6')
                    AND NVL(zone_7_name, 'zone7') = NVL(v_zoneauths(c).zone_7_name, 'zone7')
                    AND authority_name = v_zoneauths(c).authority_name
                    AND processed IS NULL;
            COMMIT;

            EXIT WHEN entirecountyzip%NOTFOUND;
        END LOOP;
        COMMIT;
        CLOSE entirecountyzip;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 3) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        /* -- Removed 10/07/16 - per Coco until crapp-3038 can be implemented
        -- 3.1 --
        -- NULL records where Authority is within entire County - District Level - crapp-2613, crapp-2936
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 3.1) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN entirecountydistrict LOOP
            UPDATE --+index (t gis_zone_auth_tmp_n1)-- gis_zone_authorities_tmp t
                SET   zone_5_id        = NULL
                    , zone_5_name      = NULL
                    , zone_5_level_id  = NULL
                    , zone_5_parent_id = NULL
                    , zone_6_id        = NULL
                    , zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 5)    -- County
                    , reverse_flag     = NULL
                    , terminator_flag  = NULL
                    , default_flag     = NULL
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 3.1
            WHERE   zone_3_name = c.zone_3_name
                AND zone_4_name = c.zone_4_name
                AND zone_5_name = c.zone_5_name
                AND NVL(zone_6_name, 'zone6') = NVL(c.zone_6_name, 'zone6')
                AND NVL(zone_7_name, 'zone7') = NVL(c.zone_7_name, 'zone7')
                AND authority_name = c.authority_name;
                --AND processed IS NULL; -- could possibly be processed in an earlier step, so ignoring for now
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 3.1) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);
        */


        -- 4 --
        -- NULL records where Authority is within entire Zip - City Level - crapp-1883
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 4) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN entirecityzip LOOP <<cityzip_loop>>
            UPDATE /*+index (t gis_zone_auth_tmp_n1)*/ gis_zone_authorities_tmp t
                SET   zone_6_id        = NULL
                    , zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 10)    -- City
                    , reverse_flag     = NULL
                    , terminator_flag  = NULL
                    , default_flag     = NULL
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 4
            WHERE   zone_3_name = c.zone_3_name
                AND zone_4_name = c.zone_4_name
                AND zone_5_name = c.zone_5_name
                AND NVL(zone_6_name, 'zone6') = NVL(c.zone_6_name, 'zone6')
                AND NVL(zone_7_name, 'zone7') = NVL(c.zone_7_name, 'zone7')
                AND authority_name = c.authority_name
                AND processed IS NULL;
        END LOOP cityzip_loop;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 4) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 4.1 -- crapp-3094
        -- Remove attachments from Areas with No Zip and not 100% within County/City combination
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 4.1) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR nz IN notcountycity_nozip LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE   zone_3_name = nz.zone_3_name
                AND zone_4_name = nz.zone_4_name
                AND zone_5_name = nz.zone_5_name
                AND authority_name = nz.authority_name
                AND zone_6_name IS NULL
                AND NVL(processed, -1) != 4;  -- crapp-3964, added to exclude areas rolled up to City Level with Zip9s
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 4.1) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 4.2 -- crapp-3094
        -- Remove attachments from Areas with No Zip and Orphans
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 4.2) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR nzo IN countycitynozip_orphan LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE   zone_3_name = nzo.zone_3_name
                AND zone_4_name = nzo.zone_4_name
                AND zone_5_name = nzo.zone_5_name
                AND authority_name = nzo.authority_name
                AND zone_6_name IS NULL
                AND NVL(processed, -1) != 4;  -- crapp-3964, added to exclude areas rolled up to City Level with Zip9s
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 4.2) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 4.3 -- crapp-3035
        -- Remove Orphaned authorities - 0% of Zip4s
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 4.3) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR ro IN remove_orphans LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE   zone_3_name = ro.zone_3_name
                AND zone_4_name = ro.zone_4_name
                AND zone_5_name = ro.zone_5_name
                AND zone_6_name = ro.zone_6_name
                AND authority_name = ro.authority_name
                AND zone_7_name IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 4.3) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 4.4 --
        -- NULL records where Authority is within entire County/City with No Zip - City Level - crapp-3248
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 4.4) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN countycitynozip_notorphaned LOOP
            UPDATE /*+index (t gis_zone_auth_tmp_n1)*/ gis_zone_authorities_tmp t
                SET   zone_6_id        = NULL
                    , zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 10)    -- City
                    , reverse_flag     = NULL
                    , terminator_flag  = NULL
                    , default_flag     = NULL
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 4.4
            WHERE   zone_3_name = c.zone_3_name
                AND zone_4_name = c.zone_4_name
                AND zone_5_name = c.zone_5_name
                AND zone_6_name IS NULL
                AND authority_name = c.authority_name
                AND processed IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 4.4) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 2.31 -- 02/08/16 -- crapp-2303  -- 03/11/16 - crapp-2432 - moved from after step 2.3 to after step 4
        -- Remove Zip Level attachments causing double-mapping where UAs are bottom-up - Excluding Cross Border areas (limited in cursor)
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.31) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR z IN remove_zip LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE   zone_3_name = z.zone_3_name
                AND zone_4_name = z.zone_4_name
                AND zone_5_name = z.zone_5_name
                AND zone_6_name = z.zone_6_name
                AND authority_name = z.authority_name
                AND zone_7_name IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.31) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 2.5 -- crapp-1812/1883
        -- Set records for Authorities in < 70% of County/City/Zip (leave at Zip4 - Top Down) - Districts
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.5) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN attach_td LOOP
            UPDATE /*+index (t gis_zone_auth_tmp_n1)*/ gis_zone_authorities_tmp t
                SET   reverse_flag     = 'N'
                    , terminator_flag  = 'N'
                    , default_flag     = NULL
                    , processed        = 2.5
            WHERE   zone_3_name = c.zone_3_name
                AND zone_4_name = c.zone_4_name
                AND zone_5_name = c.zone_5_name
                AND zone_6_name = c.zone_6_name
                AND zone_7_name = c.zone_7_name
                AND authority_name = c.authority_name;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.5) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 2.6 --
        -- NULL Default_Flag for Processed County/City/District records - 06/09/15
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.6) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN cleardefaults LOOP
            UPDATE /*+index (t gis_zone_auth_tmp_n1)*/ gis_zone_authorities_tmp t
                SET   reverse_flag     = NULL
                    , terminator_flag  = NULL
                    , default_flag     = NULL
                    , processed        = 2.61
            WHERE   zone_3_name = c.zone_3_name
                AND zone_4_name = c.zone_4_name
                AND zone_5_name IS NULL
                AND authority_name = c.authority_name
                AND geo_area  = 'County'
                AND processed IS NULL;

            UPDATE /*+index (t gis_zone_auth_tmp_n1)*/ gis_zone_authorities_tmp t
                SET   reverse_flag     = NULL
                    , terminator_flag  = NULL
                    , default_flag     = NULL
                    , processed        = 2.62
            WHERE   zone_3_name = c.zone_3_name
                AND zone_4_name = c.zone_4_name
                AND zone_5_name = c.zone_5_name
                AND zone_6_name IS NULL
                AND authority_name = c.authority_name
                AND geo_area  = 'City'
                AND processed IS NULL;

            UPDATE /*+index (t gis_zone_auth_tmp_n1)*/ gis_zone_authorities_tmp t
                SET   reverse_flag     = NULL
                    , terminator_flag  = NULL
                    , default_flag     = NULL
                    , processed        = 2.63
            WHERE   zone_3_name = c.zone_3_name
                AND zone_4_name = c.zone_4_name
                AND zone_5_name = c.zone_5_name
                AND zone_6_name = c.zone_6_name
                AND zone_7_name IS NULL
                AND authority_name = c.authority_name
                AND geo_area  = 'District'
                AND processed IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.6) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 2.7 -- 03/07/16 - crapp-2400
        -- Remove Multipoint Districts that are not the default
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.7) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR m IN multipoint LOOP
            DELETE  FROM gis_zone_authorities_tmp
            WHERE   zone_3_name = m.state_name
                AND zone_4_name = m.county_name
                AND zone_5_name = m.city_name
                AND zone_6_name = m.zip
                AND zone_7_name IS NULL
                AND processed IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 2.7) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 5 --
        -- NULL records where Zip is Default and No STJs exist --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 5) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR d IN defaultzip LOOP <<default_loop>>
            UPDATE gis_zone_authorities_tmp
                    SET   zone_7_id        = NULL
                        , zone_7_name      = NULL
                        , zone_7_level_id  = NULL
                        , zone_7_parent_id = NULL
                        , code_fips        = SUBSTR(code_fips, 1, 15)    -- Zip
                        , reverse_flag     = 'N'
                        , terminator_flag  = NULL
                        , default_flag     = 'Y'
                        , range_min        = NULL
                        , range_max        = NULL
                        , processed        = 5
            WHERE       zone_4_name = d.county_name
                    AND zone_5_name = d.city_name
                    AND NVL(zone_6_name, 'nozip') = NVL(d.zip, 'nozip') -- 05/21/15 added
                    --AND zone_7_name IS NOT NULL                       -- 05/21/15 removed
                    AND NVL(reverse_flag, 'N') != 'Y'                   -- 07/15/15 added
                    AND stj_flag = 0;

            -- Set Default for No Zip/Zip Only records -- 06/09/15
            UPDATE gis_zone_authorities_tmp
                    SET   reverse_flag     = 'N'
                        , terminator_flag  = NULL
                        , default_flag     = 'Y'
                        , processed        = 5
            WHERE       zone_4_name = d.county_name
                    AND zone_5_name = d.city_name
                    AND NVL(zone_6_name, 'nozip') = NVL(d.zip, 'nozip')
                    AND zone_7_name IS NULL;
        END LOOP default_loop;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 5) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 6 -- 03/25/15
        -- Update remaining Bottom-Up records
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 6) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR b IN bottom_up_rem LOOP
            UPDATE gis_zone_authorities_tmp
                SET default_flag    = NULL,
                    reverse_flag    = 'Y',
                    terminator_flag = 'Y'
            WHERE     zone_7_name IS NOT NULL
                  AND zone_3_name = b.zone_3_name
                  AND zone_4_name = b.zone_4_name
                  AND zone_5_name = b.zone_5_name
                  AND zone_6_name = b.zone_6_name
                  AND zone_7_name = b.zone_7_name
                  AND reverse_flag IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 6) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 6.5 --
        -- NULL records where Authority is within entire State - added 10/21/15
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 6.5) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR s IN entirestate LOOP
            UPDATE /*+index(t gis_zone_auth_tmp_n1)*/ gis_zone_authorities_tmp t
                SET   zone_4_id        = NULL
                    , zone_4_name      = NULL
                    , zone_4_level_id  = NULL
                    , zone_4_parent_id = NULL
                    , zone_5_id        = NULL
                    , zone_5_name      = NULL
                    , zone_5_level_id  = NULL
                    , zone_5_parent_id = NULL
                    , zone_6_id        = NULL
                    , zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 2)    -- State
                    , reverse_flag     = 'N'
                    , terminator_flag  = NULL
                    , default_flag     = NULL
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 6.5
            WHERE   zone_3_name = s.zone_3_name
                AND zone_4_name = s.zone_4_name
                AND zone_5_name = s.zone_5_name
                AND NVL(zone_6_name, 'zone6') = NVL(s.zone_6_name, 'zone6')
                AND NVL(zone_7_name, 'zone7') = NVL(s.zone_7_name, 'zone7')
                AND authority_name = s.authority_name
                AND processed IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 6.5) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 7 --
        -- Delete City Authorities that are associated at lower levels -- 03/06/15 - crapp-1377
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 7) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN citylevel LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE  authority_name  = c.authority_name
                   AND zone_3_name = c.zone_3_name
                   AND zone_4_name = c.zone_4_name
                   AND zone_5_name = c.zone_5_name
                   AND zone_6_name = NVL(c.zone_6_name, 'zone6')
                   AND NVL(reverse_flag, 'N') <> 'Y'
                   AND geo_area = 'City';
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 7) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 7.5 --
        -- Delete City Authorities that are associated at lower levels - double mapped -- 04/26/16 - crapp-2539
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 7.5) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN citylevelatzip LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE  authority_name  = c.authority_name
                   AND zone_3_name = c.zone_3_name
                   AND zone_4_name = c.zone_4_name
                   AND zone_5_name = c.zone_5_name
                   AND zone_6_name IS NOT NULL
                   AND NVL(reverse_flag, 'N') <> 'Y';
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 7.5) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 8 --
        -- Delete County Authorities that are associated at lower levels -- 03/09/15 - crapp-1377
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 8) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN countylevel LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE  authority_name  = c.authority_name
                   AND zone_3_name = c.zone_3_name
                   AND zone_4_name = c.zone_4_name
                   AND zone_5_name IS NOT NULL      -- changed 04/01/15
                   AND NVL(zone_6_name, 'zone6') = NVL(c.zone_6_name, 'zone6')
                   AND NVL(reverse_flag, 'N') <> 'Y'
                   AND geo_area = c.geo_area;       -- 03/11/16 crapp-2432
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 8) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 8.5 --
        -- Delete County Authorities that are associated at lower levels - double mapped -- 03/17/16 - crapp-2443
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 8.5) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR c IN countylevelatzip LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE  authority_name  = c.authority_name
                   AND zone_3_name = c.zone_3_name
                   AND zone_4_name = c.zone_4_name
                   AND zone_5_name IS NOT NULL
                   AND NVL(reverse_flag, 'N') <> 'Y';
                   --AND processed > 3    -- County Level attachment step   -- crapp-2475, removed
                   --AND geo_area = c.geo_area;                             -- crapp-2475, removed
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 8.5) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 9 --
        -- Delete District Authorities that are associated at lower levels and not Bottom-Up -- 03/09/15 - crapp-1377
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 9) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR d IN districtlevel LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE  authority_name  = d.authority_name
                   AND zone_3_name = d.zone_3_name
                   AND zone_4_name = d.zone_4_name
                   AND zone_5_name = d.zone_5_name
                   AND zone_6_name = d.zone_6_name
                   AND zone_7_name IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 9) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 10 --
        -- Delete State Authorities that are associated at lower levels and not Bottom-Up -- 03/09/15 - crapp-1377
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 10) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR s IN statelevel LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE  authority_name  = s.authority_name
                   AND zone_3_name = s.zone_3_name
                   AND zone_4_name IS NOT NULL
                   --AND zone_7_name IS NULL        -- 11/09/15 removed crapp-2086
                   AND NVL(reverse_flag, 'N') <> 'Y';
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Parse mappings (Step 10) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- Associate City/County Level to Bottom-Up records -- updated 07/15/15 to use collection
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Associate missing bottom-up (City|County|District) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        WITH bu AS
            (
             SELECT DISTINCT
                    c.zone_3_name
                    , c.zone_4_name
                    , c.zone_5_name
                    , c.zone_6_name
                    , c.zone_7_name
                    , c.authority_name
             FROM   gis_zone_auth_counts_tmp c
                    JOIN gis_zone_auth_budetail_tmp b ON (    c.zone_3_name = b.zone_3_name
                                                          AND c.zone_4_name = b.zone_4_name
                                                          AND c.zone_5_name = b.zone_5_name
                                                          AND c.zone_6_name = b.zone_6_name
                                                          AND c.zone_7_name = b.zone_7_name
                                                          AND c.authority_name <> b.authority_name
                                                         )
             WHERE  c.zippct < 0.7
                    AND NOT EXISTS ( SELECT 1       -- 07/15/15 added
                                     FROM   gis_zone_authorities_tmp t
                                     WHERE      t.zone_3_name = c.zone_3_name
                                            AND t.zone_4_name = c.zone_4_name
                                            AND t.zone_5_name = c.zone_5_name
                                            AND t.zone_6_name = c.zone_6_name
                                            AND t.zone_7_name = c.zone_7_name
                                            AND t.authority_name = c.authority_name
                                   )
            )
            SELECT  DISTINCT
                      a.merchant_id
                    , a.zone_1_id
                    , a.zone_1_name
                    , a.zone_1_level_id
                    , a.zone_2_id
                    , a.zone_2_name
                    , a.zone_2_level_id
                    , a.zone_3_id
                    , a.zone_3_name
                    , a.zone_3_level_id
                    , a.zone_4_id
                    , a.zone_4_name
                    , a.zone_4_level_id
                    , a.zone_4_parent_id
                    , a.zone_5_id
                    , a.zone_5_name
                    , a.zone_5_level_id
                    , a.zone_5_parent_id
                    , a.zone_6_id
                    , a.zone_6_name
                    , a.zone_6_level_id
                    , a.zone_6_parent_id
                    , a.zone_7_id
                    , a.zone_7_name
                    , a.zone_7_level_id
                    , a.zone_7_parent_id
                    , a.tax_parent_zone
                    , a.code_2char
                    , a.code_fips
                    , a.reverse_flag
                    , a.terminator_flag
                    , a.default_flag
                    , a.range_min
                    , a.range_max
                    , z.authority_name
                    , NULL stj_flag
                    , a.geo_area
                    , 0 proccessed
            BULK COLLECT INTO v_auths
            FROM    gis_zone_authorities_tmp a
                    JOIN bu z ON (    a.zone_3_name = z.zone_3_name
                                  AND a.zone_4_name = z.zone_4_name
                                  AND a.zone_5_name = z.zone_5_name
                                  AND a.zone_6_name = z.zone_6_name
                                  AND a.zone_7_name = z.zone_7_name
                                  AND a.authority_name <> z.authority_name
                                 )
            WHERE   a.zone_7_name IS NOT NULL
                    AND a.reverse_flag = 'Y';

        FORALL i IN v_auths.first..v_auths.last
            INSERT INTO gis_zone_authorities_tmp
            VALUES v_auths(i);
        COMMIT;

        v_auths := t_auths();
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Associate missing bottom-up (City|County|District) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- Associate Federal Level to Bottom-Up records --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Associate bottom-up (Fed) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);

        -- 10/21/15 - converted to collection
        SELECT  /*+ index(z gis_area_list_tmp_n2) index(a gis_zone_auth_tmp_n3)*/
                DISTINCT
                a.merchant_id
                , a.zone_1_id
                , a.zone_1_name
                , a.zone_1_level_id
                , a.zone_2_id
                , a.zone_2_name
                , a.zone_2_level_id
                , NULL zone_3_id        -- crapp-3793
                , l_statename
                , NULL zone_3_level_id  -- crapp-3793
                , a.zone_4_id
                , a.zone_4_name
                , a.zone_4_level_id
                , a.zone_4_parent_id
                , a.zone_5_id
                , a.zone_5_name
                , a.zone_5_level_id
                , a.zone_5_parent_id
                , a.zone_6_id
                , a.zone_6_name
                , a.zone_6_level_id
                , a.zone_6_parent_id
                , a.zone_7_id
                , a.zone_7_name
                , a.zone_7_level_id
                , a.zone_7_parent_id
                , a.tax_parent_zone
                , a.code_2char
                , a.code_fips
                , a.reverse_flag
                , a.terminator_flag
                , a.default_flag
                , a.range_min
                , a.range_max
                , z.official_name authority_name
                , NULL stj_flag
                , z.geo_area        -- 10/06/17, changed from "a."
                , 0.1 processed     -- crapp-3248, added
        BULK COLLECT INTO v_zones
        FROM    gis_zone_authorities_tmp a
                JOIN gis_area_list_tmp z ON (a.zone_3_name = l_statename)
        WHERE   z.geo_area = 'Country'
                AND a.zone_7_name IS NOT NULL
                AND a.reverse_flag = 'Y';

        FORALL i IN v_zones.first..v_zones.last
            INSERT INTO gis_zone_authorities_tmp
            VALUES v_zones(i);
        COMMIT;

        v_zones := t_zones();
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_zone_authorities_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Associate bottom-up (Fed) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 11 --
        -- Clean-up Flags
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Cleanup remaining flags (Step 11) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);

        -- Update remaining defaults
        UPDATE gis_zone_authorities_tmp
            SET default_flag = 'N'
        WHERE zone_6_name IS NOT NULL
              AND zone_7_name IS NULL
              AND default_flag IS NULL;
        COMMIT;

        -- Clear invalid ID columns -- added 10/23/15
        UPDATE gis_zone_authorities_tmp
            SET zone_7_id       = NULL,
                zone_7_level_id = NULL
        WHERE zone_7_name IS NULL;
        COMMIT;

        FOR f IN updateflags LOOP   -- 06/16/15
            UPDATE gis_zone_authorities_tmp
                SET reverse_flag    = f.reverse_flag,
                    default_flag    = f.default_flag,
                    terminator_flag = f.terminator_flag
            WHERE     zone_3_name = f.zone_3_name
                  AND zone_4_name = f.zone_4_name
                  AND zone_5_name = f.zone_5_name
                  AND zone_6_name = f.zone_6_name
                  AND authority_name = f.authority_name
                  AND reverse_flag IS NULL;
        END LOOP;

        -- Update Top-Down -- updated 07/15/15
        UPDATE gis_zone_authorities_tmp
            SET terminator_flag = 'N'
        WHERE reverse_flag = 'N'
              AND zone_6_name IS NOT NULL   -- 07/17/15 added
              AND terminator_flag IS NULL;
        COMMIT;

        -- Update Top-Down - City Level -- 02/09/16
        UPDATE gis_zone_authorities_tmp
            SET reverse_flag    = 'N',
                terminator_flag = NULL
        WHERE zone_5_name IS NOT NULL
              AND zone_6_name  IS NULL
              AND reverse_flag IS NULL;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Cleanup remaining flags (Step 11) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 12 --
        -- Remove records that have not been processed -- crapp-2212
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Remove records that have not been processed (Step 12) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR p IN notprocessed LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE      zone_3_name = p.zone_3_name
                   AND zone_4_name = p.zone_4_name
                   AND zone_5_name = p.zone_5_name
                   AND zone_6_name = p.zone_6_name
                   AND NVL(zone_7_name, 'zone7') = NVL(p.zone_7_name, 'zone7')  -- 02/02/16 crapp-2267
                   AND geo_area    = p.geo_area
                   AND authority_name = p.authority_name
                   AND processed IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Remove records that have not been processed (Step 12) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        -- 12.1 --
        -- Remove non-processed orphans -- crapp-3248
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Remove non-processed orphans (Step 12.1) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);
        FOR p IN notprocessed_orphans LOOP
            DELETE FROM gis_zone_authorities_tmp
            WHERE      zone_3_name = p.zone_3_name
                   AND zone_4_name = p.zone_4_name
                   AND zone_5_name = p.zone_5_name
                   AND NVL(zone_6_name, 'zone6') = NVL(p.zone_6_name, 'zone6')
                   AND NVL(zone_7_name, 'zone7') = NVL(p.zone_7_name, 'zone7')
                   AND authority_name = p.authority_name
                   AND processed IS NULL;
        END LOOP;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Remove non-processed orphans (Step 12.1) - gis_zone_authorities_tmp', paction=>1, puser=>l_user);


        /*
        -- 12.2 --
        -- Process BUTZ to Higher Zones -- crapp-2356
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Process BUTZ to Higher Zones (Step 12.2) - gis_zone_authorities_tmp', paction=>0, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'   - Build stage table - gis_zone_auth_bu_rollup_tmp', paction=>0, puser=>l_user);
        truncate_drop_table(table_name_i=>'gis_zone_auth_bu_rollup_tmp', status_i=>'TRUNC', owner_i=>'CONTENT_REPO');
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bu_rollup_tmp_n1 UNUSABLE';
        INSERT INTO gis_zone_auth_bu_rollup_tmp
            (
               zone_3_name
             , zone_4_name
             , zone_5_name
             , zone_6_name
             , zone_7_name
             , authority_name
            )
            SELECT DISTINCT t.*
            FROM   ( SELECT DISTINCT zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, authority_name
                     FROM   gis_zone_authorities_tmp
                     WHERE  zone_7_name IS NOT NULL
                            AND reverse_flag = 'Y'
                   ) t
                   JOIN (
                         SELECT  DISTINCT
                                 a.state_name    zone_3_name
                               , a.county_name   zone_4_name
                               , a.city_name     zone_5_name
                               , a.zip           zone_6_name
                               , a.official_name authority_name
                         FROM  gis_area_list_tmp a
                               JOIN gis_zone_areas_tmp o ON (a.state_code = o.state_code
                                                             AND a.unique_area = o.unique_area
                                                             AND a.official_name = o.official_name)
                               JOIN gis_zone_areas_orig_tmp r ON (a.state_code = r.state_code
                                                                  AND a.unique_area = r.unique_area)
                         WHERE EXISTS (
                                        SELECT 1
                                        FROM   gis_zone_auth_budetail_tmp b
                                        WHERE      b.zone_3_name = a.state_name
                                               AND b.zone_4_name = a.county_name
                                               AND b.zone_5_name = a.city_name
                                               AND b.zone_6_name = a.zip
                                               AND b.authority_name = a.official_name
                                      )
                        ) c ON (     t.zone_3_name = c.zone_3_name
                                 AND t.zone_4_name = c.zone_4_name
                                 AND t.zone_5_name = c.zone_5_name
                                 AND t.zone_6_name = c.zone_6_name
                                 AND t.authority_name = c.authority_name
                               );
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bu_rollup_tmp_n1 REBUILD';
        gis_etl_p(l_pID, stcode_i, '   - Build stage table - gis_zone_auth_bu_rollup_tmp', 1, l_user);

        gis_etl_p(l_pID, stcode_i, '   - Determine Zip4 level percentages for overrides (Step 12.21) - gis_zone_auth_bu_rollup_pct', 0, l_user); -- crapp-2536
        truncate_drop_table(table_name_i=> 'GIS_ZONE_AUTH_BU_ROLLUP_PCT', status_i=> 'TRUNC', owner_i=> 'CONTENT_REPO');
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bu_rollup_pct_n1 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bu_rollup_pct_n2 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bu_rollup_pct_n3 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bu_rollup_pct_n4 UNUSABLE';

        INSERT INTO gis_zone_auth_bu_rollup_pct
            (
                state_code
              , authority_name
              , zone_3_name
              , zone_4_name
              , zone_5_name
              , zone_6_name
              , rangecnt
              , totalzip4cnt
              , zip4pct
            )
            WITH authzips AS
                (
                 SELECT state_code
                        , state_name
                        , county_name
                        , city_name
                        , zip
                        , official_name
                        , COUNT( DISTINCT zip4) zip_count
                 FROM   gis_area_list_tmp
                 WHERE  unique_area IN (SELECT DISTINCT unique_area FROM gis_zone_areas_orig_tmp) -- include override areas
                 GROUP BY state_code
                        , state_name
                        , county_name
                        , city_name
                        , zip
                        , official_name
                ),
                cnyzips AS
                (
                 SELECT zone_3_name
                        , zone_4_name
                        , zone_5_name
                        , zone_6_name
                        , SUM((TO_NUMBER(range_max) - TO_NUMBER(range_min)) + 1) total_zip_count
                 FROM   gis_zone_tree_tmp
                 WHERE  zone_7_name IS NOT NULL
                 GROUP BY zone_3_name
                        , zone_4_name
                        , zone_5_name
                        , zone_6_name
                )
                 SELECT DISTINCT
                        a.state_code
                        , a.official_name   authority_name
                        , a.state_name      zone_3_name
                        , a.county_name     zone_4_name
                        , a.city_name       zone_5_name
                        , a.zip             zone_6_name
                        , a.zip_count       rangecnt
                        , c.total_zip_count zip4count
                        , ROUND( (a.zip_count / c.total_zip_count) , 4) pct
                 FROM   authzips a
                        JOIN cnyzips c ON (     a.state_name  = c.zone_3_name
                                            AND a.county_name = c.zone_4_name
                                            AND a.city_name   = c.zone_5_name
                                            AND a.zip         = c.zone_6_name
                                          );
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bu_rollup_pct_n1 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bu_rollup_pct_n2 REBUILD';
        gis_etl_p(l_pID, stcode_i, '   - Determine Zip4 level percentages for overrides (Step 12.21) - gis_zone_auth_bu_rollup_pct', 1, l_user);

        gis_etl_p(l_pID, stcode_i, '   - Determine Zip level percentages for overrides (Step 12.22) - gis_zone_auth_bu_rollup_pct', 0, l_user); -- crapp-2536
        WITH authcities AS
            (
             SELECT state_code
                    , state_name
                    , county_name
                    , city_name
                    , official_name
                    , COUNT( DISTINCT zip) zip_count
             FROM   gis_area_list_tmp
             WHERE  unique_area IN (SELECT DISTINCT unique_area FROM gis_zone_areas_orig_tmp) -- include only override areas
             GROUP BY state_code
                    , state_name
                    , county_name
                    , city_name
                    , official_name
            ),
            cnyzips AS
            (
             SELECT zone_3_name
                    , zone_4_name
                    , zone_5_name
                    , COUNT(DISTINCT zone_6_name) total_zip_count
             FROM   gis_zone_tree_tmp
             WHERE  zone_6_name IS NOT NULL
             GROUP BY zone_3_name
                    , zone_4_name
                    , zone_5_name
            )
             SELECT DISTINCT
                    a.state_code
                    , a.official_name   authority_name
                    , a.state_name      zone_3_name
                    , a.county_name     zone_4_name
                    , a.city_name       zone_5_name
                    , a.zip_count       level_count
                    , c.total_zip_count totalcount
                    , ROUND( (a.zip_count / c.total_zip_count) , 4) pct
             BULK COLLECT INTO v_bu_pct
             FROM   authcities a
                    JOIN cnyzips c ON (     a.state_name  = c.zone_3_name
                                        AND a.county_name = c.zone_4_name
                                        AND a.city_name   = c.zone_5_name
                                      );

        FORALL p IN 1..v_bu_pct.COUNT
            UPDATE /*+index(b gis_zone_auth_bu_rollup_n1) gis_zone_auth_bu_rollup_pct b
                SET zipcnt      = v_bu_pct(p).level_count,
                    totalzipcnt = v_bu_pct(p).total_count,
                    zippct      = v_bu_pct(p).pct
            WHERE     b.state_code     = v_bu_pct(p).state_code
                  AND b.zone_4_name    = v_bu_pct(p).zone_4_name
                  AND b.zone_5_name    = v_bu_pct(p).zone_5_name
                  AND b.authority_name = v_bu_pct(p).authority_name;
        COMMIT;
        v_bu_pct := t_bu_pct();
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bu_rollup_pct_n3 REBUILD';
        gis_etl_p(l_pID, stcode_i, '   - Determine Zip level percentages for overrides (Step 12.22) - gis_zone_auth_bu_rollup_pct', 1, l_user);


        gis_etl_p(l_pID, stcode_i, '   - Determine City level percentages for overrides (Step 12.23) - gis_zone_auth_bu_rollup_pct', 0, l_user); -- crapp-2536
        WITH authcities AS
            (
             SELECT state_code
                    , state_name
                    , county_name
                    , official_name
                    , COUNT( DISTINCT city_name) city_count
             FROM   gis_area_list_tmp
             WHERE  unique_area IN (SELECT DISTINCT unique_area FROM gis_zone_areas_orig_tmp) -- include override areas
             GROUP BY state_code
                    , state_name
                    , county_name
                    , official_name
            ),
            cities AS
            (
             SELECT zone_3_name
                    , zone_4_name
                    , COUNT(DISTINCT zone_5_name) total_city_count
             FROM   gis_zone_tree_tmp
             WHERE  zone_6_name IS NOT NULL
             GROUP BY zone_3_name
                    , zone_4_name
            )
             SELECT DISTINCT
                    a.state_code
                    , a.official_name    authority_name
                    , a.state_name       zone_3_name
                    , a.county_name      zone_4_name
                    , NULL               zone_5_name
                    , a.city_count       level_count
                    , c.total_city_count total_count
                    , ROUND( (a.city_count / c.total_city_count) , 4) pct
             BULK COLLECT INTO v_bu_pct
             FROM   authcities a
                    JOIN cities c ON (     a.state_name  = c.zone_3_name
                                       AND a.county_name = c.zone_4_name
                                      );

        FORALL p IN 1..v_bu_pct.COUNT
            UPDATE /*+index(b gis_zone_auth_bu_rollup_n1) gis_zone_auth_bu_rollup_pct b
                SET citycnt      = v_bu_pct(p).level_count,
                    totalcitycnt = v_bu_pct(p).total_count,
                    citypct      = v_bu_pct(p).pct
            WHERE     b.state_code     = v_bu_pct(p).state_code
                  AND b.zone_4_name    = v_bu_pct(p).zone_4_name
                  AND b.authority_name = v_bu_pct(p).authority_name;
        COMMIT;
        v_bu_pct := t_bu_pct();
        EXECUTE IMMEDIATE 'ALTER INDEX gis_zone_auth_bu_rollup_pct_n4 REBUILD';
        gis_etl_p(l_pID, stcode_i, '   - Determine City level percentages for overrides (Step 12.23) - gis_zone_auth_bu_rollup_pct', 1, l_user);


        gis_etl_p(l_pID, stcode_i, '   - Process BUTZ to Zip Level (Step 12.24) - gis_zone_authorities_tmp', 0, l_user); -- crapp-2536
        FOR b IN (
                  -- Determine roll-up to Zip level and remain as BUTZ --
                  SELECT b.*
                  FROM   gis_zone_auth_bu_rollup_tmp b
                         JOIN gis_zone_auth_bu_rollup_pct p ON (     b.zone_3_name = p.zone_3_name
                                                                 AND b.zone_4_name = p.zone_4_name
                                                                 AND b.zone_5_name = p.zone_5_name
                                                                 AND b.zone_6_name = p.zone_6_name
                                                                 AND b.authority_name = p.authority_name
                                                               )
                         JOIN ( -- include only Zips that have 100% of their authorities contained in the zone --
                                SELECT zone_3_name
                                       , zone_4_name
                                       , zone_5_name
                                       , zone_6_name
                                       , MIN(NVL(zip4pct,1)) zip4pct
                                FROM gis_zone_auth_bu_rollup_pct
                                GROUP BY zone_3_name, zone_4_name, zone_5_name, zone_6_name
                                HAVING MIN(NVL(zip4pct,1)) = 1
                              ) c ON (     b.zone_3_name = c.zone_3_name
                                       AND b.zone_4_name = c.zone_4_name
                                       AND b.zone_5_name = c.zone_5_name
                                       AND b.zone_6_name = c.zone_6_name
                                     )
                  WHERE b.authority_name IN (
                                             SELECT DISTINCT z.authority_name
                                             FROM   gis_zone_auth_bu_rollup_tmp z
                                                    JOIN (
                                                          SELECT zone_3_name
                                                                 , zone_4_name
                                                                 , zone_5_name
                                                                 , zone_6_name
                                                                 , RANK( ) OVER( PARTITION BY zone_3_name, zone_4_name, zone_5_name ORDER BY auth_count) auth_rank
                                                          FROM (
                                                                SELECT zone_3_name
                                                                       , zone_4_name
                                                                       , zone_5_name
                                                                       , zone_6_name
                                                                       , COUNT(DISTINCT authority_name) auth_count
                                                                FROM   gis_zone_auth_bu_rollup_tmp
                                                                GROUP BY zone_3_name, zone_4_name, zone_5_name, zone_6_name
                                                               )
                                                         ) r ON (    z.zone_3_name = r.zone_3_name
                                                                 AND z.zone_4_name = r.zone_4_name
                                                                 AND z.zone_5_name = r.zone_5_name
                                                                 AND z.zone_6_name = r.zone_6_name
                                                                )
                                             WHERE r.auth_rank = 1
                                            )
                        AND p.state_code = stcode_i
                        AND NVL(p.zip4pct, 1) = 1
                  --ORDER BY b.zone_4_name, b.zone_5_name, b.zone_6_name, b.zone_7_name, b.authority_name
                 )
        LOOP
            UPDATE /*+index (t gis_zone_auth_tmp_n1) gis_zone_authorities_tmp t
                SET   zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 15)    -- Zip
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 12.24
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND zone_6_name = b.zone_6_name
                AND zone_7_name = b.zone_7_name
                AND authority_name = b.authority_name
                AND processed IS NOT NULL;

            -- Move US Authorities to correct level --
            UPDATE /*+index (t gis_zone_auth_tmp_n1) gis_zone_authorities_tmp t
                SET   zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 15)    -- Zip
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 12.24
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND zone_6_name = b.zone_6_name
                AND zone_7_name = b.zone_7_name
                AND processed = 0.1;

            -- Clear Zone Tree Reverse Flag --
            UPDATE /*+index (t gis_zone_tree_tmp_n2) gis_zone_tree_tmp t
                SET   reverse_flag     = NULL
                    , terminator_flag  = NULL
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND zone_6_name = b.zone_6_name
                AND zone_7_name = b.zone_7_name;
        END LOOP;
        COMMIT;
        gis_etl_p(l_pID, stcode_i, '   - Process BUTZ to Zip Level (Step 12.24) - gis_zone_authorities_tmp', 1, l_user);


        gis_etl_p(l_pID, stcode_i, '   - Process BUTZ to City Level (Step 12.25) - gis_zone_authorities_tmp', 0, l_user); -- crapp-2536
        FOR b IN (
                  -- Determine roll-up to City level and remain as BUTZ --
                  SELECT b.*
                  FROM   gis_zone_auth_bu_rollup_tmp b
                         JOIN gis_zone_auth_bu_rollup_pct p ON (     b.zone_3_name = p.zone_3_name
                                                                 AND b.zone_4_name = p.zone_4_name
                                                                 AND b.zone_5_name = p.zone_5_name
                                                                 AND b.zone_6_name = p.zone_6_name
                                                                 AND b.authority_name = p.authority_name
                                                               )
                         JOIN ( -- include only Zips that have 100% of their authorities contained in the zone --
                                SELECT zone_3_name
                                       , zone_4_name
                                       , zone_5_name
                                       --, zone_6_name
                                       , MIN(NVL(zip4pct,1)) zip4pct
                                FROM gis_zone_auth_bu_rollup_pct
                                GROUP BY zone_3_name, zone_4_name, zone_5_name--, zone_6_name   -- removed 10/25/17
                                HAVING MIN(NVL(zip4pct,1)) = 1
                              ) c ON (     b.zone_3_name = c.zone_3_name
                                       AND b.zone_4_name = c.zone_4_name
                                       AND b.zone_5_name = c.zone_5_name
                                       --AND b.zone_6_name = c.zone_6_name
                                     )
                  WHERE b.authority_name IN (
                                             SELECT DISTINCT z.authority_name
                                             FROM   gis_zone_auth_bu_rollup_tmp z
                                                    JOIN (
                                                          SELECT zone_3_name
                                                                 , zone_4_name
                                                                 , zone_5_name
                                                                 , RANK( ) OVER( PARTITION BY zone_3_name, zone_4_name ORDER BY auth_count) auth_rank
                                                          FROM (
                                                                SELECT zone_3_name
                                                                       , zone_4_name
                                                                       , zone_5_name
                                                                       , COUNT(DISTINCT authority_name) auth_count
                                                                FROM   gis_zone_auth_bu_rollup_tmp
                                                                GROUP BY zone_3_name, zone_4_name, zone_5_name, zone_6_name
                                                               )
                                                         ) r ON (    z.zone_3_name = r.zone_3_name
                                                                 AND z.zone_4_name = r.zone_4_name
                                                                 AND z.zone_5_name = r.zone_5_name
                                                                )
                                             WHERE r.auth_rank = 1
                                            )
                        AND p.state_code = stcode_i
                        AND p.zippct = 1
                        AND NVL(p.zip4pct, 1) = 1
                  --ORDER BY b.zone_4_name, b.zone_5_name, b.zone_6_name, b.zone_7_name, b.authority_name
                 )
        LOOP
            UPDATE /*+index (t gis_zone_auth_tmp_n1) gis_zone_authorities_tmp t
                SET   zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 10)    -- City
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 12.25
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND zone_6_name = b.zone_6_name
                AND authority_name = b.authority_name
                AND processed IS NOT NULL;

            -- Move US Authorities to correct level --
            UPDATE /*+index (t gis_zone_auth_tmp_n1) gis_zone_authorities_tmp t
                SET   zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 10)    -- City
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 12.25
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND zone_6_name = b.zone_6_name
                AND geo_area = 'Country'
                AND processed IS NOT NULL;

            -- Clear Zone Tree Reverse Flag --
            UPDATE /*+index (t gis_zone_tree_tmp_n2) gis_zone_tree_tmp t
                SET   reverse_flag     = NULL
                    , terminator_flag  = NULL
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND zone_6_name = b.zone_6_name
                AND zone_7_name = b.zone_7_name;
        END LOOP;
        COMMIT;
        gis_etl_p(l_pID, stcode_i, '   - Process BUTZ to City Level (Step 12.25) - gis_zone_authorities_tmp', 1, l_user);


        gis_etl_p(l_pID, stcode_i, '   - Process BUTZ to County Level (Step 12.26) - gis_zone_authorities_tmp', 0, l_user); -- crapp-2536
        FOR b IN (
                  -- Determine roll-up to County level and remain as BUTZ --
                  SELECT b.*
                  FROM   gis_zone_auth_bu_rollup_tmp b
                         JOIN gis_zone_auth_bu_rollup_pct p ON (    b.zone_3_name = p.zone_3_name
                                                                AND b.zone_4_name = p.zone_4_name
                                                                AND b.zone_5_name = p.zone_5_name
                                                                AND b.zone_6_name = p.zone_6_name
                                                                AND b.authority_name = p.authority_name
                                                              )
                         JOIN ( -- include only Counties that have 100% of their cities rolled to City level to avoid double-mapping --
                                SELECT zone_3_name
                                       , zone_4_name
                                       , authority_name
                                       , MIN(zippct) zippct
                                FROM gis_zone_auth_bu_rollup_pct
                                GROUP BY zone_3_name, zone_4_name, authority_name
                                HAVING MIN(zippct) = 1
                              ) c ON (     b.zone_3_name = c.zone_3_name
                                       AND b.zone_4_name = c.zone_4_name
                                       AND b.authority_name = c.authority_name
                                     )
                  WHERE b.authority_name IN (
                                             SELECT DISTINCT z.authority_name
                                             FROM   gis_zone_auth_bu_rollup_tmp z
                                                    JOIN (
                                                          SELECT zone_3_name
                                                                 , zone_4_name
                                                                 , zone_5_name
                                                                 , RANK( ) OVER( PARTITION BY zone_3_name, zone_4_name ORDER BY auth_count) auth_rank
                                                          FROM (
                                                                SELECT zone_3_name
                                                                       , zone_4_name
                                                                       , zone_5_name
                                                                       , COUNT(DISTINCT authority_name) auth_count
                                                                FROM   gis_zone_auth_bu_rollup_tmp
                                                                GROUP BY zone_3_name, zone_4_name, zone_5_name, zone_6_name
                                                               )
                                                         ) r ON (    z.zone_3_name = r.zone_3_name
                                                                 AND z.zone_4_name = r.zone_4_name
                                                                 AND z.zone_5_name = r.zone_5_name
                                                                )
                                             WHERE r.auth_rank = 1
                                            )
                        AND p.state_code = stcode_i
                        AND p.citypct = 1
                        AND p.zippct  = 1
                        AND NVL(p.zip4pct, 1) = 1
                  --ORDER BY b.zone_4_name, b.zone_5_name, b.zone_6_name, b.zone_7_name, b.authority_name
                 )
        LOOP
            UPDATE /*+index (t gis_zone_auth_tmp_n1) gis_zone_authorities_tmp t
                SET   zone_5_id        = NULL
                    , zone_5_name      = NULL
                    , zone_5_level_id  = NULL
                    , zone_5_parent_id = NULL
                    , zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 5)    -- County
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 12.26
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND authority_name = b.authority_name
                AND processed IS NOT NULL;

            -- Move US Authorities to correct level --
            UPDATE /*+index (t gis_zone_auth_tmp_n1) gis_zone_authorities_tmp t
                SET   zone_5_id        = NULL
                    , zone_5_name      = NULL
                    , zone_5_level_id  = NULL
                    , zone_5_parent_id = NULL
                    , zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 5)    -- County
                    , range_min        = NULL
                    , range_max        = NULL
                    , processed        = 12.26
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND geo_area = 'Country'
                AND processed IS NOT NULL;

            -- Clear Zone Tree Reverse Flag --
            UPDATE /*+index (t gis_zone_tree_tmp_n2) gis_zone_tree_tmp t
                SET   reverse_flag     = NULL
                    , terminator_flag  = NULL
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND zone_6_name = b.zone_6_name
                AND zone_7_name = b.zone_7_name;
        END LOOP;
        COMMIT;
        gis_etl_p(l_pID, stcode_i, '   - Process BUTZ to County Level (Step 12.26) - gis_zone_authorities_tmp', 1, l_user);


        gis_etl_p(l_pID, stcode_i, '   - Process BUTZ to TD at City Level (Step 12.27) - gis_zone_authorities_tmp', 0, l_user); -- crapp-2536
        FOR b IN (
                  -- Determine roll-up to City level and switch to Top-Down --
                  SELECT b.*
                  FROM   gis_zone_auth_bu_rollup_tmp b
                         JOIN gis_zone_auth_bu_rollup_pct p ON (    b.zone_3_name = p.zone_3_name
                                                                AND b.zone_4_name = p.zone_4_name
                                                                AND b.zone_5_name = p.zone_5_name
                                                                AND b.zone_6_name = p.zone_6_name
                                                                AND b.authority_name = p.authority_name
                                                              )
                         JOIN ( -- include only Counties that have 100% of their cities rolled to City level to avoid double-mapping --
                                SELECT zone_3_name
                                       , zone_4_name
                                       , authority_name
                                       , MIN(zippct) zippct
                                FROM gis_zone_auth_bu_rollup_pct
                                GROUP BY zone_3_name, zone_4_name, authority_name
                                HAVING MIN(zippct) = 1
                              ) c ON (     b.zone_3_name = c.zone_3_name
                                       AND b.zone_4_name = c.zone_4_name
                                       AND b.authority_name = c.authority_name
                                     )
                  WHERE b.authority_name IN (
                                             SELECT DISTINCT z.authority_name
                                             FROM   gis_zone_auth_bu_rollup_tmp z
                                                    JOIN (
                                                          SELECT zone_3_name
                                                                 , zone_4_name
                                                                 , zone_5_name
                                                                 , RANK( ) OVER( PARTITION BY zone_3_name, zone_4_name ORDER BY auth_count) auth_rank
                                                          FROM (
                                                                SELECT zone_3_name
                                                                       , zone_4_name
                                                                       , zone_5_name
                                                                       , COUNT(DISTINCT authority_name) auth_count
                                                                FROM   gis_zone_auth_bu_rollup_tmp
                                                                GROUP BY zone_3_name, zone_4_name, zone_5_name, zone_6_name
                                                               )
                                                         ) r ON (    z.zone_3_name = r.zone_3_name
                                                                 AND z.zone_4_name = r.zone_4_name
                                                                 AND z.zone_5_name = r.zone_5_name
                                                                )
                                             WHERE r.auth_rank > 1
                                            )
                        AND p.state_code = stcode_i
                        AND p.citypct < 1  -- Exclusive overrides not covering 100% of the zone --
                        AND p.zippct  = 1
                        AND NVL(p.zip4pct, 1) = 1
                        AND EXISTS ( -- Make sure we have rolled zones up to County Level --
                                     SELECT 1
                                     FROM   gis_zone_authorities_tmp gz
                                     WHERE  processed = 12.26
                                            AND gz.zone_3_name = b.zone_3_name
                                            AND gz.zone_4_name = b.zone_4_name
                                   )
                  --ORDER BY b.zone_4_name, b.zone_5_name, b.zone_6_name, b.zone_7_name, b.authority_name
                 )
        LOOP
            UPDATE /*+index (t gis_zone_auth_tmp_n1) gis_zone_authorities_tmp t
                SET   zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 10)    -- City
                    , range_min        = NULL
                    , range_max        = NULL
                    , reverse_flag     = 'N'
                    , terminator_flag  = NULL
                    , processed        = 12.27
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND authority_name = b.authority_name
                AND processed IS NOT NULL;

            -- Move US Authorities to correct level --
            UPDATE /*+index (t gis_zone_auth_tmp_n1) gis_zone_authorities_tmp t
                SET   zone_6_name      = NULL
                    , zone_6_level_id  = NULL
                    , zone_6_parent_id = NULL
                    , zone_7_id        = NULL
                    , zone_7_name      = NULL
                    , zone_7_level_id  = NULL
                    , zone_7_parent_id = NULL
                    , code_fips        = SUBSTR(code_fips, 1, 10)    -- City
                    , range_min        = NULL
                    , range_max        = NULL
                    , reverse_flag     = 'N'
                    , terminator_flag  = NULL
                    , processed        = 12.27
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND geo_area = 'Country'
                AND processed IS NOT NULL;

            -- Clear Zone Tree Reverse Flag --
            UPDATE /*+index (t gis_zone_tree_tmp_n2) gis_zone_tree_tmp t
                SET   reverse_flag     = NULL
                    , terminator_flag  = NULL
            WHERE   zone_3_name = b.zone_3_name
                AND zone_4_name = b.zone_4_name
                AND zone_5_name = b.zone_5_name
                AND zone_6_name = b.zone_6_name
                AND zone_7_name = b.zone_7_name;
        END LOOP;
        COMMIT;
        gis_etl_p(l_pID, stcode_i, '   - Process BUTZ to TD at City Level (Step 12.27) - gis_zone_authorities_tmp', 1, l_user);
        gis_etl_p(l_pID, stcode_i, ' - Process BUTZ to Higher Zones (Step 12.2) - gis_zone_authorities_tmp', 1, l_user);
        */


        -- Push to GIS_AUTHORITIES_TMP to be used in Determination --
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Push to gis_authorities_tmp', paction=>0, puser=>l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_authorities_tmp DROP STORAGE';
        INSERT INTO gis_authorities_tmp
            (
                merchant_id
                , zone_1_name
                , zone_2_name
                , zone_3_name
                , zone_4_name
                , zone_5_name
                , zone_6_name
                , zone_7_name
                , code_2char
                , code_fips
                , reverse_flag
                , terminator_flag
                , default_flag
                , range_min
                , range_max
                , authority_name
                , creation_date
            )
            SELECT DISTINCT
                   merchant_id
                   , zone_1_name
                   , zone_2_name
                   , zone_3_name
                   , zone_4_name
                   , zone_5_name
                   , zone_6_name
                   , zone_7_name
                   , code_2char
                   , code_fips
                   , reverse_flag
                   , terminator_flag
                   , default_flag
                   , range_min
                   , range_max
                   , authority_name
                   , SYSDATE creation_date
            FROM   gis_zone_authorities_tmp;
        COMMIT;
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Push to gis_authorities_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Update stats - gis_authorities_tmp', paction=>0, puser=>l_user);
            DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_authorities_tmp', cascade => TRUE);
        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>' - Update stats - gis_authorities_tmp', paction=>1, puser=>l_user);

        gis_etl_p(pid=>l_pID, pstate=>stcode_i, ppart=>'push_gis_zone_authorities, tag_grp_i = '||tag_grp_i||', instance_i = '||instance_i, paction=>1, puser=>l_user);
    END push_gis_zone_authorities;



    PROCEDURE push_gis_ua_taxids(stcode_i IN VARCHAR2, instance_grp_i IN NUMBER) IS -- 09/14/17 - crapp-3996/3997
        l_fips          VARCHAR2(2 CHAR);   -- crapp-3055
        l_schema        VARCHAR2(25 CHAR);
        l_sql           VARCHAR2(500 CHAR);
        vcurrent_schema VARCHAR2(50);
        l_rec           NUMBER := 0;
        l_user          NUMBER := -204;
        l_pID           NUMBER := gis_etl_process_log_sq.nextval;
        l_merchant      NUMBER;
        l_instance      NUMBER;    -- 04/17/17 crapp-3025
        l_tag_grp       NUMBER;    -- 04/17/17 crapp-3025 (replaces tag_grp_i)
        dupe_taxids     EXCEPTION; -- crapp-2367

        TYPE t_areaauths IS TABLE OF gis_tb_comp_area_authorities%ROWTYPE;
        v_areaauths  t_areaauths;

        TYPE t_compareas IS TABLE OF gis_tb_compliance_areas_tmp%ROWTYPE;
        v_compareas t_compareas;


        CURSOR dupes IS -- crapp-3996, updated
            SELECT  a.state_code
                    , a.tax_area_id
                    , MIN(a.effective_zone_level_id)   old_level_id     -- crapp-3996, added MIN
                    , MIN(a.effective_zone_level_id)+1 new_level_id     -- crapp-3996, added MIN
                    , MIN(a.associated_area_count) area_count           -- crapp-3996, added
                    , MAX(a.tax_areaid_startdate)  startdate
                    , MAX(a.tax_areaid_enddate)    enddate
                    , MAX(a.etl_date) etl_date
                    , COUNT(*) cnt
            FROM    gis_tb_compliance_areas_tmp a
            WHERE   a.tax_areaid_enddate IS NULL
            GROUP BY  a.state_code
                    , a.tax_area_id
            HAVING COUNT(*) > 1
            ORDER BY a.tax_area_id;


        CURSOR enddated_boundaries IS -- crapp-3902
            SELECT /*+index(m geo_usps_mv_i1) index(p geo_polygons_pk)*/
                   DISTINCT
                   a.state_code
                   , a.area_id
                   , au.nkid_list
            FROM   geo_usps_mv_staging a
                   JOIN geo_unique_areas ua ON (ua.area_id = a.area_id)
                   JOIN geo_unique_area_polygons guap ON (ua.id = guap.unique_area_id)
                   JOIN geo_polygons gp ON (guap.geo_polygon_id = gp.id)
                   JOIN (
                         SELECT DISTINCT
                                state_code
                                , area_id
                                , LISTAGG(nkid,'|') WITHIN GROUP (ORDER BY authority_name) nkid_list
                         FROM   gis_tb_comp_area_authorities
                         GROUP BY state_code, area_id
                        ) au ON (a.state_code = au.state_code
                                 AND a.area_id = au.area_id)
            WHERE  a.state_code = stcode_i
                   AND gp.end_date IS NOT NULL;    -- Only end-dated boundaries


        CURSOR enddated_taxareas IS -- crapp-3996
            SELECT DISTINCT
                   TRIM(stcode_i) state_code
                   , gua.area_id
                   , gua.start_date
                   , gua.end_date
                   , uaa.VALUE tax_area_id
                   , TO_DATE(uaa.start_date,'mm/dd/yyyy') tax_areaid_startdate
                   , TO_DATE(uaa.end_date,'mm/dd/yyyy')   tax_areaid_enddate
            FROM   vunique_area_attributes uaa
                   JOIN geo_unique_areas gua ON (uaa.unique_area_nkid = gua.nkid)
            WHERE  attribute_id = 21  -- Internal Tax Area ID
                   AND uaa.end_date IS NOT NULL
                   AND SUBSTR(gua.area_id, 1, 2) = (SELECT DISTINCT SUBSTR(area_id, 1, 2) FROM gis_tb_compliance_areas_tmp)
                   AND NOT EXISTS (
                                    SELECT 1
                                    FROM   gis_tb_compliance_areas tca
                                    WHERE      tca.area_id = gua.area_id
                                           AND tca.tax_area_id = uaa.VALUE
                                           AND tca.tax_areaid_startdate = TO_DATE(uaa.start_date,'mm/dd/yyyy')
                                           AND tca.tax_areaid_enddate   = TO_DATE(uaa.end_date,'mm/dd/yyyy')
                                  )
            ORDER BY gua.area_id, uaa.VALUE;

    BEGIN
        gis_etl_p(l_pID, stcode_i, 'push_gis_ua_taxids, instance_grp_i = '||instance_grp_i, 0, l_user);

        -- CRAPP-3174, Dynamic extraction of schema name to reference tables where needed
        SELECT SYS_CONTEXT( 'userenv', 'current_schema' ) INTO vcurrent_schema FROM dual;

        -- 04/17/17 crapp-3025
        SELECT tdr_etl_instance_id, tdr_etl_tag_group_id, schema_name
        INTO   l_instance, l_tag_grp, l_schema
        FROM   vetl_instance_groups
        WHERE  gis_flag = 'Y'
               AND instance_group_id = instance_grp_i;

        l_sql := 'SELECT merchant_id
                  FROM '||l_schema||'.tb_merchants
                  WHERE  name = ''Sabrix US Tax Data''';
        EXECUTE IMMEDIATE l_sql INTO l_merchant;


        -- Get list of Jurisdictions with the appropriate Tag Group
        gis_etl_p(l_pID, stcode_i, ' - Get Jurisdictions by Tag Group - gis_tb_comp_tags_tmp', 0, l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_tb_comp_tags_tmp DROP STORAGE';
        INSERT INTO gis_tb_comp_tags_tmp
            (ref_nkid, tagcnt)
            SELECT  ref_nkid,
                    COUNT(*) tagcnt
            FROM    tag_group_tags tv
                    JOIN  ( SELECT jt.ref_nkid,
                                   listagg(tag.name,',') WITHIN GROUP (ORDER BY tag.name) tag_list
                            FROM   ( SELECT DISTINCT
                                            ref_nkid
                                            ,tag_id
                                     FROM   jurisdiction_tags
                                   ) jt
                                   JOIN tags tag ON (tag.id = jt.tag_id)
                                   JOIN jurisdictions j ON (jt.ref_nkid = j.nkid)
                            WHERE  next_rid IS NULL
                                   AND tag.tag_type_id NOT IN (SELECT ID FROM tag_types WHERE NAME LIKE '%USER%') -- crapp-3576, exclude USER tags = 5
                            GROUP BY jt.ref_nkid
                          ) e on (e.tag_list = tv.tag_list)
            WHERE   tv.tag_group_id IN (    -- 10/19/17 - added Retail --
                                        SELECT tag_group_id
                                        FROM   tag_group_tags
                                        WHERE     tag_group_name LIKE 'Determination%United States'
                                               OR tag_list LIKE 'Determination%Retail%United States'   -- crapp-3966 include Retail
                                       )
            GROUP BY ref_nkid;
        COMMIT;
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_tb_comp_tags_tmp', cascade => TRUE);
        gis_etl_p(l_pID, stcode_i, ' - Get Jurisdictions by Tag Group - gis_tb_comp_tags_tmp', 1, l_user);


        -- Get list of Mapped Jurisdictions --
        gis_etl_p(l_pID, stcode_i, ' - Build mapped Jurisdiction staging table - gis_tb_comp_mapped_auths_tmp', 0, l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_tb_comp_mapped_auths_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_tb_comp_mp_auths_tmp_n1 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_tb_comp_mp_auths_tmp_n2 UNUSABLE';

        INSERT INTO gis_tb_comp_mapped_auths_tmp
            (state_code, official_name, jurisdiction_id, jurisdiction_nkid, rid, nkid, geo_polygon_rid)
            SELECT  DISTINCT state_code, official_name, jurisdiction_id, jurisdiction_nkid, rid, nkid, geo_polygon_rid
            FROM    vjuris_geo_areas
            WHERE   state_code = stcode_i
                    AND poly_end_date IS NULL;  -- 07/20/17, added to eliminate the mappings on end-dated boundaries
        COMMIT;

        EXECUTE IMMEDIATE 'ALTER INDEX gis_tb_comp_mp_auths_tmp_n1 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_tb_comp_mp_auths_tmp_n2 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_tb_comp_mapped_auths_tmp', cascade => TRUE);
        gis_etl_p(l_pID, stcode_i, ' - Build mapped Jurisdiction staging table - gis_tb_comp_mapped_auths_tmp', 1, l_user);


        -- Get list of compliance areas --
        gis_etl_p(l_pID, stcode_i, ' - Get initial list of compliance areas - gis_tb_comp_areas_tmp', 0, l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_tb_compliance_areas DROP STORAGE';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_tb_compliance_areas_tmp DROP STORAGE';    -- crapp-2367 - staging table

        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_tb_comp_areas_tmp DROP STORAGE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_tb_comp_areas_tmp_n1 UNUSABLE';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_tb_comp_areas_tmp_n2 UNUSABLE';

        -- crapp-2365 (ensure UA exists) --
        INSERT INTO gis_tb_comp_areas_tmp
            (state_code, area_id, unique_area, associated_area_count, start_date, end_date, nkid)
            SELECT DISTINCT
                   gua.state_code
                   , gua.area_id
                   , REPLACE(gua.unique_area,'','''''') unique_area
                   , NVL(REGEXP_COUNT(gua.unique_area, '\|'),0) associated_area_count  -- Does not include the State Level
                   , ua.start_date
                   , ua.end_date
                   , ua.nkid
            FROM   vgeo_unique_areas2 gua
                   JOIN geo_unique_areas ua ON (gua.area_id = ua.area_id)
            WHERE  gua.state_code = stcode_i;
                   -- Excluding duplicates --
                   /*
                   AND gua.area_id NOT IN ( '37-101-74580'          -- crapp-3160
                                          );
                   */
        COMMIT;
        gis_etl_p(l_pID, stcode_i, ' - Get initial list of compliance areas - gis_tb_comp_areas_tmp', 1, l_user);

        gis_etl_p(l_pID, stcode_i, ' - Rebuild indexes and stats - gis_tb_comp_areas_tmp', 0, l_user);
        EXECUTE IMMEDIATE 'ALTER INDEX gis_tb_comp_areas_tmp_n1 REBUILD';
        EXECUTE IMMEDIATE 'ALTER INDEX gis_tb_comp_areas_tmp_n2 REBUILD';
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_tb_comp_areas_tmp', cascade => TRUE);
        gis_etl_p(l_pID, stcode_i, ' - Rebuild indexes and stats - gis_tb_comp_areas_tmp', 1, l_user);


        gis_etl_p(l_pID, stcode_i, ' - Get TaxID information - gis_tb_compliance_areas_tmp', 0, l_user);
        WITH polys AS
            (
              SELECT *
              FROM   (
                      SELECT /*+index(m geo_usps_mv_i1) index(p geo_polygons_pk)*/
                             DISTINCT
                             a.area_id
                             , MAX(gp.start_date) poly_startdate
                             , MAX(gp.end_date)   poly_enddate
                      FROM   geo_usps_mv_staging a
                             JOIN geo_unique_areas ua ON (ua.area_id = a.area_id)
                             JOIN geo_unique_area_polygons guap ON (ua.id = guap.unique_area_id)
                             JOIN geo_polygons gp ON (guap.geo_polygon_id = gp.id)
                      WHERE  a.state_code = stcode_i
                             and gp.end_date IS NULL    -- 07/20/17 - Exclude the end-dated boundaries
                      GROUP BY a.area_id
                     )
              --WHERE  poly_enddate IS NULL -- Exclude Areas that have a polygon with an End Date -- 01/13/16 - 07/20/17, moved to boundary level
            )
           , hlevel AS
            (
              SELECT /*+index(m geo_usps_mv_i1)*/
                     state_code
                     , area_id
                     , MAX(hierarchy_level_id) hlevel
              FROM   geo_usps_mv_staging
              WHERE  state_code = stcode_i
              GROUP BY state_code, area_id
            )
           , taxids AS
            (
              SELECT DISTINCT
                     gua.area_id
                     , gua.start_date
                     , gua.end_date
                     , uaa.unique_area_nkid
                     , uaa.VALUE tax_area_id
                     , TO_DATE(uaa.start_date,'mm/dd/yyyy') tax_areaid_startdate
                     , TO_DATE(uaa.end_date,'mm/dd/yyyy')   tax_areaid_enddate
              FROM   vunique_area_attributes uaa
                     JOIN geo_unique_areas gua ON (uaa.unique_area_nkid = gua.nkid)
                     JOIN gis_tb_comp_areas_tmp ca ON (gua.area_id = ca.area_id) -- crapp-2365 (ensure UA exists)
              WHERE  attribute_id = 21  -- Internal Tax Area ID
                     AND uaa.end_date IS NULL
            )
            SELECT  DISTINCT
                    mvua.state_code
                    , mvua.area_id
                    , mvua.unique_area
                    , xid.tax_area_id
                    , edt.poly_startdate  tax_areaid_startdate  -- crapp-2274
                    , edt.poly_enddate    tax_areaid_enddate    -- crapp-2274
                    , mvua.associated_area_count
                    , hl.hlevel*-1 effective_zone_level_id
                    , l_merchant merchant_id
                    , mvua.start_date
                    , mvua.end_date
                    , SYSDATE etl_date
            BULK COLLECT INTO v_compareas
            FROM    gis_tb_comp_areas_tmp mvua                  -- crapp-2365
                    JOIN hlevel hl ON (mvua.area_id = hl.area_id)
                    JOIN polys edt  ON (mvua.area_id = edt.area_id)
                    JOIN taxids xid ON (mvua.nkid = xid.unique_area_nkid)   -- crapp-2366
            WHERE   mvua.associated_area_count > 1
                    AND xid.tax_areaid_enddate IS NULL;

        FORALL i IN v_compareas.first..v_compareas.last
            INSERT INTO gis_tb_compliance_areas_tmp     -- crapp-2367 - using staging table to check for dupes
            VALUES v_compareas(i);
        COMMIT;

        v_compareas := t_compareas();
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_tb_compliance_areas_tmp', cascade => TRUE);
        gis_etl_p(l_pID, stcode_i, ' - Get TaxID information - gis_tb_compliance_areas_tmp', 1, l_user);


        -- Remove duplicates from Compliance Area List - State Specific -- crapp-2367
        --IF stcode_i IN ('GU','PR', 'LA') THEN -- crapp-3996, removed state specific logic
            gis_etl_p(l_pID, stcode_i, ' - Process duplicate compliance areas - gis_tb_compliance_areas', 0, l_user);
            FOR d IN dupes LOOP

                IF stcode_i NOT IN ('GU','PR') THEN
                    SELECT COUNT(1)
                    INTO  l_rec
                    FROM  gis_tb_compliance_areas_tmp ca
                    WHERE ca.state_code = d.state_code
                          AND ca.tax_area_id = d.tax_area_id
                          AND ca.associated_area_count = d.area_count
                          AND ca.effective_zone_level_id = d.new_level_id;

                    -- Check to see if we have an Lower Level area already available -- crapp-3996
                    IF l_rec = 1 THEN
                        INSERT INTO gis_tb_compliance_areas
                            (state_code, area_id, unique_area, tax_area_id, tax_areaid_startdate, tax_areaid_enddate, associated_area_count,
                             effective_zone_level_id, merchant_id, start_date, end_date, etl_date
                            )
                            SELECT  DISTINCT
                                    tca.state_code
                                    , tca.area_id
                                    , tca.unique_area
                                    , tca.tax_area_id
                                    , d.startdate
                                    , d.enddate
                                    , tca.associated_area_count
                                    , tca.effective_zone_level_id
                                    , tca.merchant_id
                                    , d.startdate
                                    , d.enddate
                                    , d.etl_date
                            FROM    gis_tb_compliance_areas_tmp tca
                            WHERE       tca.state_code  = d.state_code
                                    AND tca.tax_area_id = d.tax_area_id
                                    AND tca.associated_area_count   = d.area_count
                                    AND tca.effective_zone_level_id = d.new_level_id
                                    AND NOT EXISTS (
                                                     SELECT 1
                                                     FROM   gis_tb_compliance_areas ca
                                                     WHERE  ca.state_code = tca.state_code
                                                            AND ca.tax_area_id = tca.tax_area_id
                                                   );
                    ELSE
                        -- Create a lower level area based on the Original Effective Level and Associated Area Count --
                        SELECT COUNT(1)
                        INTO  l_rec
                        FROM  gis_tb_compliance_areas_tmp ca
                        WHERE ca.state_code = d.state_code
                              AND ca.tax_area_id = d.tax_area_id
                              AND ca.associated_area_count   = d.area_count
                              AND ca.effective_zone_level_id = d.old_level_id;

                        IF l_rec = 1 THEN
                            INSERT INTO gis_tb_compliance_areas
                                (state_code, area_id, unique_area, tax_area_id, tax_areaid_startdate, tax_areaid_enddate, associated_area_count,
                                 effective_zone_level_id, merchant_id, start_date, end_date, etl_date
                                )
                                SELECT  DISTINCT
                                        tca.state_code
                                        , tca.area_id
                                        , tca.unique_area
                                        , tca.tax_area_id
                                        , d.startdate
                                        , d.enddate
                                        , tca.associated_area_count
                                        , tca.effective_zone_level_id
                                        , tca.merchant_id
                                        , d.startdate
                                        , d.enddate
                                        , d.etl_date
                                FROM    gis_tb_compliance_areas_tmp tca
                                WHERE       tca.state_code  = d.state_code
                                        AND tca.tax_area_id = d.tax_area_id
                                        AND tca.associated_area_count   = d.area_count
                                        AND tca.effective_zone_level_id = d.old_level_id
                                        AND NOT EXISTS (
                                                         SELECT 1
                                                         FROM   gis_tb_compliance_areas ca
                                                         WHERE  ca.state_code = tca.state_code
                                                                AND ca.tax_area_id = tca.tax_area_id
                                                       );
                        ELSE
                            -- Create a lower level area based on the new Effective Level and Associated Area Count --
                            INSERT INTO gis_tb_compliance_areas
                                (state_code, area_id, unique_area, tax_area_id, tax_areaid_startdate, tax_areaid_enddate, associated_area_count,
                                 effective_zone_level_id, merchant_id, start_date, end_date, etl_date
                                )
                                SELECT  DISTINCT
                                        tca.state_code
                                        , SUBSTR(tca.area_id, 1, INSTR(tca.area_id, '-', 1, tca.associated_area_count)-1) new_area_id
                                        , SUBSTR(tca.unique_area, 1, INSTR(tca.unique_area, '|', 1, tca.associated_area_count)-1) new_unique_area
                                        , tca.tax_area_id
                                        , d.startdate
                                        , d.enddate
                                        , tca.associated_area_count - 1
                                        , d.new_level_id
                                        , tca.merchant_id
                                        , d.startdate
                                        , d.enddate
                                        , d.etl_date
                                FROM    gis_tb_compliance_areas_tmp tca
                                WHERE       tca.state_code  = d.state_code
                                        AND tca.tax_area_id = d.tax_area_id
                                        AND NOT EXISTS (
                                                         SELECT 1
                                                         FROM   gis_tb_compliance_areas ca
                                                         WHERE  ca.state_code = tca.state_code
                                                                AND ca.tax_area_id = tca.tax_area_id
                                                       );
                        END IF;
                    END IF;

                ELSIF stcode_i IN ('GU', 'PR') THEN
                    -- Check for existance of area
                    INSERT INTO gis_tb_compliance_areas
                        (state_code, area_id, unique_area, tax_area_id, tax_areaid_startdate, tax_areaid_enddate, associated_area_count,
                         effective_zone_level_id, merchant_id, start_date, end_date, etl_date
                        )
                        SELECT  DISTINCT
                                state_code
                                , SUBSTR(area_id, 1, INSTR(area_id, '-', 1, associated_area_count)-1) new_area_id
                                , SUBSTR(unique_area, 1, INSTR(unique_area, '|', 1, associated_area_count)-1) new_unique_area
                                , tax_area_id
                                , d.startdate
                                , d.enddate
                                , associated_area_count - 1
                                , d.new_level_id
                                , merchant_id
                                , d.startdate
                                , d.enddate
                                , d.etl_date
                        FROM    gis_tb_compliance_areas_tmp
                        WHERE   state_code = d.state_code
                                AND tax_area_id = d.tax_area_id;
                END IF; -- ('GU','PR')
            END LOOP;
            COMMIT;
            gis_etl_p(l_pID, stcode_i, ' - Process duplicate compliance areas - gis_tb_compliance_areas', 1, l_user);
        --END IF; -- ('GU', 'PR', 'LA')


        -- Load remaining Tax Areas --
        gis_etl_p(l_pID, stcode_i, ' - Process distinct list of compliance areas - gis_tb_compliance_areas', 0, l_user);
        INSERT INTO gis_tb_compliance_areas
            (state_code, area_id, unique_area, tax_area_id, tax_areaid_startdate, tax_areaid_enddate, associated_area_count,
             effective_zone_level_id, merchant_id, start_date, end_date, etl_date
            )
            SELECT  DISTINCT
                    state_code
                    , area_id
                    , unique_area
                    , tax_area_id
                    , tax_areaid_startdate
                    , tax_areaid_enddate
                    , associated_area_count
                    , effective_zone_level_id
                    , merchant_id
                    , start_date
                    , end_date
                    , etl_date
            FROM    gis_tb_compliance_areas_tmp
            WHERE   tax_area_id NOT IN (SELECT DISTINCT tax_area_id FROM gis_tb_compliance_areas)
                    AND tax_areaid_enddate IS NULL;
        COMMIT;

        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_tb_compliance_areas', cascade => TRUE);
        gis_etl_p(l_pID, stcode_i, ' - Process distinct list of compliance areas - gis_tb_compliance_areas', 1, l_user);


        -- Get list of areas with overrides -- crapp-3160 -- created area staging table to improve performance and tablespace issues
        gis_etl_p(l_pID, stcode_i, ' - Get list of areas - gis_tb_comp_juris_areas_tmp', 0, l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_tb_comp_juris_areas_tmp DROP STORAGE';
        INSERT INTO gis_tb_comp_juris_areas_tmp
            (state_code, unique_area_id, unique_area)
            SELECT /*+index(a geo_unique_areas_pk)*/
                   DISTINCT
                   ua.state_code
                   , a.id unique_area_id
                   , ua.unique_area
            FROM   geo_unique_areas a
                   JOIN (SELECT DISTINCT state_code, area_id, unique_area
                         FROM vgeo_unique_areas2
                         WHERE state_code = stcode_i
                        ) ua ON (a.area_id = ua.area_id);
        COMMIT;
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_tb_comp_juris_areas_tmp', cascade => TRUE);
        gis_etl_p(l_pID, stcode_i, ' - Get list of areas - gis_tb_comp_juris_areas_tmp', 1, l_user);


        -- crapp-3160 -- created override staging table to improve performance and tablespace issues
        gis_etl_p(l_pID, stcode_i, ' - Get list of area overrides - gis_tb_comp_auth_overrides_tmp', 0, l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_tb_comp_auth_overrides_tmp DROP STORAGE';
        INSERT INTO gis_tb_comp_auth_overrides_tmp
            (state_code, unique_area_id, unique_area_nkid, unique_area_rid, official_name, unique_area, juris_nkid)
            SELECT  DISTINCT
                    guas.state_code
                    , uaa.unique_area_id
                    , uaa.unique_area_nkid
                    , uaa.unique_area_rid
                    , REPLACE(j.official_name,'''','''''') official_name  -- uaa.VALUE
                    , guas.unique_area
                    , j.nkid     juris_nkid
            FROM    vunique_area_attributes uaa
                    JOIN vgeo_unique_area_search guas ON (uaa.unique_area_id = guas.unique_area_id)
                    JOIN jurisdictions j ON (uaa.value_id = j.nkid)
                    JOIN gis_tb_comp_juris_areas_tmp ga ON (uaa.unique_area_id = ga.unique_area_id)
            WHERE   uaa.attribute_id = 18   -- name = 'Jurisdiction Override'
                    AND uaa.next_rid IS NULL
                    AND j.next_rid IS NULL
                    AND j.nkid IN (SELECT ref_nkid FROM gis_tb_comp_tags_tmp) -- restrict to Tag Group -- 09/21/16
                    AND guas.state_code = stcode_i;
        COMMIT;
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_tb_comp_auth_overrides_tmp', cascade => TRUE);
        gis_etl_p(l_pID, stcode_i, ' - Get list of area overrides - gis_tb_comp_auth_overrides_tmp', 1, l_user);


        -- Get list of compliance area authorities --
        gis_etl_p(l_pID, stcode_i, ' - Get list of compliance area authorities - gis_tb_comp_area_authorities', 0, l_user);
        EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_tb_comp_area_authorities DROP STORAGE';

        SELECT  DISTINCT
                j.state_code
                , tca.area_id       -- crapp-3654, changed from: a.area_id
                , uaa2.VALUE tax_area_id
                , REPLACE(NVL(jo.official_name, j.official_name),'','''''') authority_name
                , COALESCE(jo.juris_nkid, j.nkid) nkid
                , SYSDATE etl_date
        BULK COLLECT INTO v_areaauths
        FROM    gis_tb_comp_mapped_auths_tmp j
                JOIN vunique_area_polygons p ON (j.geo_polygon_rid = p.poly_rid)
                JOIN geo_unique_areas a ON (p.unique_area_rid = a.rid
                                            AND a.next_rid IS NULL)
                LEFT JOIN gis_tb_comp_auth_overrides_tmp jo ON (p.unique_area_rid = jo.unique_area_rid)   -- overrides
                LEFT JOIN vunique_area_attributes uaa2 ON ( uaa2.unique_area_nkid = a.nkid
                                                            AND uaa2.attribute_id = 21
                                                            AND uaa2.end_date IS NULL   -- 01/15/16
                                                            AND uaa2.next_rid IS NULL
                                                          )
                --JOIN gis_tb_compliance_areas tca ON (uaa2.VALUE = tca.tax_area_id)         -- crapp-3654, added
                JOIN gis_tb_compliance_areas tca ON (a.area_id = tca.area_id)         -- crapp-3654, added -- crapp-3997, changed to AREA_ID from TAX_AREA_ID
        WHERE   j.state_code = stcode_i
                AND j.jurisdiction_nkid IN (SELECT ref_nkid FROM gis_tb_comp_tags_tmp);   -- restrict to Tag Group
                --AND uaa2.VALUE IN (SELECT DISTINCT tax_area_id FROM gis_tb_compliance_areas);  -- crapp-2368, crapp-3654 - changed to tax_area_id from area_id

        FORALL i IN 1..v_areaauths.COUNT
            INSERT INTO gis_tb_comp_area_authorities
            VALUES v_areaauths(i);
        COMMIT;

        v_areaauths := t_areaauths();
        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_tb_comp_area_authorities', cascade => TRUE);
        gis_etl_p(l_pID, stcode_i, ' - Get list of compliance area authorities - gis_tb_comp_area_authorities', 1, l_user);


        -- Process Areas with End-Dated boundaries and remove if needed -- crapp-3902
        gis_etl_p(l_pID, stcode_i, ' - Areas with End-Dated boundaries and remove if needed', 0, l_user);
        FOR d IN enddated_boundaries LOOP
            SELECT COUNT(1)
            INTO   l_rec
            FROM   (
                    SELECT state_code
                           , area_id
                           , LISTAGG(nkid,'|') WITHIN GROUP (ORDER BY authority_name) authlist
                    FROM   gis_tb_comp_area_authorities
                    GROUP BY state_code, area_id
                   ) caa
            WHERE  caa.state_code = d.state_code
                   AND caa.authlist = d.nkid_list
                   AND caa.area_id != d.area_id;

            IF l_rec > 0 THEN
                dbms_output.put_line('Removing area_id: '||d.area_id);

                -- Remove Compliance Authority records --
                DELETE FROM gis_tb_comp_area_authorities
                WHERE  area_id = d.area_id;

                -- Remove Compliance Area record --
                DELETE FROM gis_tb_compliance_areas
                WHERE  area_id = d.area_id;
            END IF;
        END LOOP;
        COMMIT;
        gis_etl_p(l_pID, stcode_i, ' - Areas with End-Dated boundaries and remove if needed', 1, l_user);


        -- Load End-Dated Tax Area ID records -- crapp-3996
        gis_etl_p(l_pID, stcode_i, ' - Process end-dated Tax_Area_IDs - gis_tb_compliance_areas', 0, l_user);
        FOR d IN enddated_taxareas LOOP
            INSERT INTO gis_tb_compliance_areas
                (state_code
                 , area_id
                 , tax_area_id
                 , tax_areaid_startdate
                 , tax_areaid_enddate
                 , merchant_id
                 , start_date
                 , end_date
                )
                VALUES
                    (
                        d.state_code
                        , d.area_id
                        , d.tax_area_id
                        , d.tax_areaid_startdate
                        , d.tax_areaid_enddate
                        , l_merchant
                        , d.start_date
                        , d.end_date
                    );

            -- Update Start Date of New Tax Area ID record for AREA_ID if exists with a new Tax Area ID --
            SELECT COUNT(1) cnt
            INTO   l_rec
            FROM   gis_tb_compliance_areas ca
            WHERE  ca.state_code = d.state_code
                   AND ca.area_id = d.area_id
                   AND ca.tax_area_id != d.tax_area_id
                   AND ca.end_date IS NULL;

            IF l_rec != 0 THEN
                dbms_output.put_line('Updating StartDate: '||d.area_id||' - start date - '||d.tax_areaid_enddate);
                UPDATE gis_tb_compliance_areas ca
                    SET start_date = d.tax_areaid_enddate + 1,
                        tax_areaid_startdate = d.tax_areaid_enddate + 1
                WHERE     ca.state_code = d.state_code
                      AND ca.area_id    = d.area_id
                      AND ca.start_date = d.start_date
                      AND ca.tax_area_id != d.tax_area_id
                      AND ca.end_date IS NULL;
            END IF;
        END LOOP;
        COMMIT;

        DBMS_STATS.gather_table_stats(vcurrent_schema, 'gis_tb_compliance_areas', cascade => TRUE);
        gis_etl_p(l_pID, stcode_i, ' - Process end-dated Tax_Area_IDs - gis_tb_compliance_areas', 1, l_user);

        -- Data Check to ensure no duplicate Tax_Area_ID values continue into the rest of the ETL process -- crapp-2367
        gis_etl_p(l_pID, stcode_i, ' - Duplicate Tax_Area_ID data check - gis_tb_comp_area_dupe_tmp', 0, l_user);
        --EXECUTE IMMEDIATE 'TRUNCATE TABLE gis_tb_comp_area_dupe_tmp DROP STORAGE';
        -- crapp-3654, changed to DELETE to retain state records --
        DELETE FROM gis_tb_comp_area_dupe_tmp
        WHERE  state_code = stcode_i;
        COMMIT;

        INSERT INTO gis_tb_comp_area_dupe_tmp
            SELECT  DISTINCT
                    a.state_code
                    , a.area_id
                    , a.unique_area
                    , a.tax_area_id
                    , a.tax_areaid_startdate
                    , a.tax_areaid_enddate
                    , a.associated_area_count
                    , a.effective_zone_level_id
                    , a.merchant_id
                    , a.start_date
                    , a.end_date
                    , a.etl_date
            FROM    gis_tb_compliance_areas a
                    JOIN ( SELECT state_code
                                  , tax_area_id
                                  --, start_date            -- crapp-3654
                                  --, end_date
                                  , COUNT(*) dupes
                           FROM   gis_tb_compliance_areas
                           WHERE  state_code = stcode_i
                                  AND end_date IS NULL
                                  AND tax_areaid_enddate IS NULL    -- crapp-3996
                           GROUP BY state_code, tax_area_id--, start_date, end_date -- crapp-3654
                           HAVING COUNT(*) > 1
                         ) d ON (    a.tax_area_id = d.tax_area_id
                                 AND a.state_code  = d.state_code
                                )
            WHERE  a.state_code = stcode_i;
        COMMIT;

        SELECT COUNT(*)
        INTO   l_rec
        FROM   gis_tb_comp_area_dupe_tmp
        WHERE  state_code = stcode_i;

        IF l_rec != 0 THEN
            gis_etl_p(l_pID, stcode_i, '  - Found '||l_rec||' areas with a duplicate Tax_Area_ID value - gis_tb_comp_area_dupe_tmp', 3, l_user);
            gis_etl_p(l_pID, stcode_i, ' - Duplicate Tax_Area_ID data check - gis_tb_comp_area_dupe_tmp', 1, l_user);
            RAISE dupe_taxids;
        END IF;
        gis_etl_p(l_pID, stcode_i, ' - Duplicate Tax_Area_ID data check - gis_tb_comp_area_dupe_tmp', 1, l_user);
        gis_etl_p(l_pID, stcode_i, 'push_gis_ua_taxids, instance_grp_i = '||instance_grp_i, 1, l_user);

    EXCEPTION WHEN dupe_taxids THEN
        gis_etl_p(l_pID, stcode_i, 'push_gis_ua_taxids - Failed with duplicate Tax_Area_ID values', 3, l_user);
        gis_etl_p(l_pID, stcode_i, 'push_gis_ua_taxids, instance_grp_i = '||instance_grp_i, 1, l_user);
        --errlogger.report_and_stop(204,'GIS ETL found Duplicate Tax_Area_ID values - gis_tb_comp_area_dupe_tmp');

        errlogger.report_and_go(204,'GIS ETL found Duplicate Tax_Area_ID values - gis_tb_comp_area_dupe_tmp'); -- crapp-3654, changed to REPORT_AND_GO
    END push_gis_ua_taxids;


    PROCEDURE delete_boundary
        (
            geo_polygon_id_i IN NUMBER,
            --geo_polygon_rid_i IN NUMBER,
            success_o OUT NUMBER
        )
    IS
        l_polygon_rid NUMBER := geo_polygon_id_i;
        l_polygon_id NUMBER;
        l_st_code   VARCHAR2(4);
        l_usps NUMBER := 0;
        l_rec  NUMBER := 0;
		l_geo_area_key	VARCHAR2(100);        

        CURSOR poly IS
            SELECT  id, geo_area_key, start_date, end_date, entered_by, entered_date, rid, nkid
            FROM    content_repo.geo_polygons
            WHERE   rid = geo_polygon_id_i;
    BEGIN
		success_o := 0;
        -- getting state code for the given boundary.
        SELECT id,geo_area_key INTO l_polygon_id,l_geo_area_key
        FROM content_repo.geo_polygons
        WHERE rid = l_polygon_rid;

        /*SELECT DISTINCT state_code INTO l_st_code
        FROM content_repo.geo_usps_lookup
        WHERE geo_polygon_id = l_polygon_id; */
		
		SELECT SUBSTR(l_geo_area_key,1,INSTR(l_geo_area_key,'-')-1) INTO l_st_code from dual;

        -- Remove Attributes --
        FOR d IN poly LOOP
            DELETE FROM content_repo.gis_usps_attributes
            WHERE  geo_polygon_usps_id IN (SELECT id
                                           FROM   content_repo.geo_polygon_usps
                                           WHERE  state_code = l_st_code
                                                  AND geo_polygon_id = d.id
                                          );

            l_rec := l_rec + (SQL%ROWCOUNT);
        END LOOP;

        dbms_output.put_line('USPS attributes removed: '||l_rec);
        l_rec := 0;

        -- Remove USPS records --
        FOR d IN poly LOOP
            DELETE FROM content_repo.geo_polygon_usps
            WHERE  state_code = l_st_code
                   AND geo_polygon_id = d.id;

            l_rec := l_rec + (SQL%ROWCOUNT);
            l_usps := l_rec;
        END LOOP;

        dbms_output.put_line('USPS records removed: '||l_rec);
        l_rec := 0;

        -- Remove Lookup records --
        FOR d IN poly LOOP
            DELETE FROM content_repo.geo_usps_lookup
            WHERE  state_code = l_st_code
                   AND geo_polygon_id = d.id;

            l_rec := l_rec + (SQL%ROWCOUNT);
        END LOOP;

        dbms_output.put_line('USPS Lookup records removed: '||l_rec);
        l_rec := 0;


        -- Remove MV Stage records --
        FOR d IN poly LOOP
            DELETE FROM content_repo.geo_usps_mv_staging
            WHERE  state_code = l_st_code
                   AND rid  = d.rid
                   AND nkid = d.nkid;

            l_rec := l_rec + (SQL%ROWCOUNT);
        END LOOP;

        dbms_output.put_line('USPS MV Staging records removed: '||l_rec);
        l_rec := 0;

        -- Update ACTION value in Issue Log --
        FOR d IN poly LOOP
            UPDATE content_repo.geo_poly_issue_log
                SET action = TO_CHAR(SYSDATE,'mm/dd/yyyy HH24:MI:SS')||' - Deleted duplicate Boundary - Per CRAPP-3471'   -- Update descript to reference JIRA
            WHERE state_code = l_st_code
                  AND geo_polygon_id = d.id
                  AND action IS NULL;

            l_rec := l_rec + (SQL%ROWCOUNT);
        END LOOP;

        dbms_output.put_line('Polygon Issue Log records updated: '||l_rec);
        l_rec := 0;


        -- Remove Boundary record --
        FOR d IN poly LOOP
            dbms_output.put_line('GeoAreaKey= '||d.geo_area_key||' ID= '||d.id||' RID= '||d.rid||' NKID= '||d.nkid );

            -- Remove Change Log records --
            DELETE FROM content_repo.geo_poly_ref_chg_logs
            WHERE  rid = d.rid;

            -- Remove Mapped Boundary records --
            DELETE FROM content_repo.juris_geo_areas
            WHERE  geo_polygon_id = d.id
                   AND rid = d.rid;

            -- Remove Unique Area Polygon records --
            DELETE FROM content_repo.geo_unique_area_polygons
            WHERE  geo_polygon_id = d.id;

            -- Remove Polygon Tag records --
            DELETE FROM content_repo.geo_polygon_tags
            WHERE  ref_nkid = d.nkid;

            -- Remove Revisions --
            DELETE FROM content_repo.geo_poly_ref_revisions
            WHERE  id = d.rid
                   AND nkid = d.nkid;

            -- Remove Polygons --
            DELETE FROM content_repo.geo_polygons
            WHERE  id = d.id
                   AND rid = d.rid;

            l_rec := l_rec + (SQL%ROWCOUNT);
        END LOOP;
        dbms_output.put_line('Change Log/Revision/Polygon records removed: '||l_rec);
        l_rec := 0;
        dbms_output.put_line ('l_usps = '|| l_usps);
        success_o := 1;
    EXCEPTION
            WHEN others THEN
                ROLLBACK;
                errlogger.report_and_stop(SQLCODE,SQLERRM);
    END delete_boundary;

END gis;
/