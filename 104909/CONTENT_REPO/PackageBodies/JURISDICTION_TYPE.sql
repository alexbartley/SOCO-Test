CREATE OR REPLACE PACKAGE BODY content_repo.JURISDICTION_TYPE
IS

/* Lookup the current revision: What is the Mid-Tier using to say it was deleted and return to search page?*/
FUNCTION get_current_revision (p_nkid IN NUMBER) RETURN NUMBER
IS
        l_curr_rid NUMBER;
        l_juris_id NUMBER;
        l_nkid NUMBER;
        l_nrid NUMBER;
        l_status NUMBER := -1;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN
        IF (p_nkid IS NOT NULL) THEN
            SELECT jr.id, jr.status, jr.nkid
            INTO l_curr_rid, l_status, l_nkid
            FROM jurisdiction_type_revisions jr
            WHERE EXISTS (
                SELECT 1
                FROM jurisdiction_type_revisions jr2
                WHERE jr.nkid = jr2.nkid
                AND jr2.nkid = p_nkid
                )
            AND jr.next_rid IS NULL;
            retval := l_curr_rid;
        END IF;
        RETURN retval;
        EXCEPTION
            WHEN no_data_found THEN
                ERRLOGGER.REPORT_AND_GO(SQLCODE, 'Revision no longer exists.');
                RETURN 0; --ignore error and return no RID, this means that the last change in revision was deleted an so the revision no longer exists

    END get_current_revision;

PROCEDURE XMLProcess_Form_JurisType(sx IN CLOB, update_success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER) IS

  juris_type_rec xmlformjuristype := xmlformjuristype(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
  tag_list xmlform_tags_tt := xmlform_tags_tt();

  CLBTemp    CLOB;
  RecCount NUMBER :=0;
  l_upd_success NUMBER := 0;
BEGIN
  CLBTemp:= TO_CHAR(sx);

/* 20170502: Limit to 250 chars even if the name or description is longer
This is a test to show that we COULD change the jursdiction type table instead of UI
if needed. (Duplicates, Determination, ETL - yes, covered and talked about.)
TEST ONLY
substr(extractvalue(column_value, '/juristype/ame'),0,250) name,
*/

        -- Jurisdiction_Type Header details
        SELECT
            extractvalue(column_value, '/juristype/id') id,
            extractvalue(column_value, '/juristype/rid') rid,
            extractvalue(column_value, '/juristype/name') name,
            extractvalue(column_value, '/juristype/start_date') start_Date,
            extractvalue(column_value, '/juristype/end_date') end_date,
            extractvalue(column_value, '/juristype/nkid') nkid,
            extractvalue(column_value, '/juristype/description') description,
            extractvalue(column_value, '/juristype/start_date') start_date,
            extractvalue(column_value, '/juristype/end_date') end_date,
            extractvalue(column_value, '/juristype/entered_by') entered_by,
            extractvalue(column_value, '/juristype/modified') modified,
            extractvalue(column_value, '/juristype/deleted') deleted
        INTO
            juris_type_rec.id, juris_type_rec.rid, juris_type_rec.name, juris_type_rec.start_date, juris_type_rec.end_date,
            juris_type_rec.nkid, juris_type_rec.description, juris_type_rec.start_date, juris_type_rec.end_date, juris_type_rec.entered_by, juris_type_rec.modified,
            juris_type_rec.deleted
        FROM TABLE(XMLSequence(XMLTYPE(CLBTemp).extract('/juristype'))) t;

    -- Tags
    FOR itags IN (SELECT
        h.tag_id,
        h.deleted,
        h.status
    FROM XMLTABLE ('/juristype/tag'
                        PASSING XMLTYPE(sx)
                        COLUMNS tag_id   NUMBER PATH 'tag_id',
                                deleted   NUMBER PATH 'deleted',
                                status   NUMBER PATH 'status'
                                ) h
          )
    LOOP
      tag_list.extend;
      tag_list( tag_list.last ):=xmlform_tags(
      12,
      juris_type_rec.nkid,
      juris_type_rec.entered_by,
      itags.tag_id,
      itags.deleted,
      itags.status);
    end loop;

    update_full(juris_type_rec, tag_list, rid_o, nkid_o);
    l_upd_success := 1;
    update_success := l_upd_success;

EXCEPTION
        WHEN others THEN
            ROLLBACK;
            --RAISE;
            ERRLOGGER.REPORT_AND_STOP(SQLCODE, 'Form data invalid. '||sqlerrm);
END XMLProcess_Form_JurisType;

PROCEDURE update_full (
    details_i IN xmlformjuristype,
    tag_list IN xmlform_tags_tt,
    rid_o OUT NUMBER,
    nkid_o OUT NUMBER
    )
IS
    l_juris_type_pk NUMBER := details_i.id;

    --either passed to procedure or set here
BEGIN
DBMS_OUTPUT.Put_Line( details_i.rid );

    /* current rid_o:=details_i.rid;   -- default on update only from XML
       current nkid_o:=details_i.nkid; -- default on update only from XML */

    IF (NVL(details_i.modified,0) = 1) THEN
        jurisdiction_type.update_record(
            id_io => l_juris_type_pk,
            name_i => details_i.name,
            description_i => details_i.description,
            start_date_i => details_i.start_date,
            end_Date_i => details_i.end_date,
            entered_by_i => details_i.entered_By,
            nkid_o => nkid_o,
            rid_o => rid_o
            );

    END IF;
    IF (nkid_o IS NULL) THEN
        SELECT nkid
        INTO nkid_o
        FROM jurisdiction_types
        WHERE id = l_juris_type_pk;
    END IF;

       --rid_o := jurisdiction_type.get_revision(NVL(rid_o,details_i.rid),details_i.entered_By);
    rid_o := get_current_revision(p_nkid=> nkid_o);

    -- Handle tags
    tags_registry.tags_entry(tag_list, nkid_o);

EXCEPTION
    WHEN errnums.child_exists THEN
        ROLLBACK;
        errlogger.report_and_stop (SQLCODE,'Requested delete but child records exist.');
    WHEN others THEN
        ROLLBACK;
        --RAISE;
        errlogger.report_and_stop (SQLCODE,'Update of jurisdiction type failed.');
END update_full;

PROCEDURE update_record (
    id_io IN OUT NUMBER,
    name_i IN VARCHAR2,
    description_i IN VARCHAR2,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER,
    nkid_o OUT NUMBER,
    rid_o OUT NUMBER
    )
       IS
        l_juris_type_pk NUMBER := id_io;
        l_name jurisdiction_types.name%TYPE := name_i;
        l_description jurisdiction_types.description%TYPE := description_i;
        l_start_date jurisdiction_types.start_date%TYPE := start_date_i;
        l_end_date jurisdiction_types.end_date%TYPE := end_date_i;
        l_entered_by NUMBER := entered_by_i;
        --l_nkid NUMBER;
        --l_rid NUMBER;
        l_status NUMBER := -1;
        l_current_pending NUMBER;
    BEGIN
        --business validation
        IF (TRIM(l_name) IS NULL) THEN
            RAISE errnums.missing_req_val;
        END IF;

DBMS_OUTPUT.Put_Line( 'l_juris_type_pk:'||l_juris_type_pk );

        IF (l_juris_type_pk IS NOT NULL) THEN
            UPDATE jurisdiction_types ji
            SET
                ji.name = l_name,
                ji.description = l_description,
                ji.start_date = l_start_date,
                ji.end_date = l_end_date,
                ji.entered_by = l_entered_by
            WHERE ji.id = l_juris_type_pk
            RETURNING nkid INTO nkid_o;
        ELSE
            INSERT INTO jurisdiction_types(
                name,
                description,
                start_date,
                end_date,
                entered_by,
                status
            ) VALUES (
                l_name,
                l_description,
                l_start_date,
                l_end_date,
                l_entered_by,
                0
                )
            RETURNING rid, id, nkid INTO rid_o, l_juris_type_pk, nkid_o;

        END IF;

        id_io :=l_juris_type_pk;
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
END update_record;


/**
 *  Copy jurisdiction_type with detail information + selected data
 *  5/1/14 : added copy_contacts
 */
PROCEDURE copy (
    rid_io IN OUT NUMBER,
    nkid_io OUT NUMBER,
    new_name_i IN VARCHAR2,
    copy_reg_i IN NUMBER,
    copy_details_i IN NUMBER,
    copy_contacts in NUMBER,
    entered_by_i IN NUMBER
    )
    IS
        l_copy_attributes NUMBER := 0;
        --l_admin_pk NUMBER := id_io;
        l_rid NUMBER := rid_io;
        l_nkid NUMBER;
        l_new_juris_type_pk NUMBER;
        l_new_name jurisdiction_types.name%TYPE := new_name_i;
        l_entered_by NUMBER := entered_by_i;
        l_new_juris_type jurisdiction_types%ROWTYPE;
    BEGIN

        --IF NVL(1,0) = 1 THEN
           select *
           into l_new_juris_type
           from jurisdiction_types a2
           where id = (
                SELECT max(a.id)
                FROM jurisdiction_type_revisions ar
                join jurisdiction_types a on (a.nkid = ar.nkid)
                where ar.id = rid_io
                and a.rid <= ar.id
                );
            IF (l_new_juris_type.name = TRIM(l_new_name)) THEN
                RAISE errnums.duplicate_key;
            END IF;

            update_record(
              l_new_juris_type_pk,
              l_new_name,
              l_new_juris_type.description,
              l_new_juris_type.start_date,
              l_new_juris_type.end_date,
              l_entered_by,
              l_nkid,
              rid_io);
              nkid_io := l_nkid;
        --END IF;
        rid_io := jurisdiction_type.get_revision(entity_id_io => l_new_juris_type_pk, entity_nkid_i => null, entered_by_i => l_entered_by);
    EXCEPTION
        WHEN errnums.duplicate_key THEN
            errlogger.report_and_stop (errnums.en_duplicate_key,'Unable to create copy because the new name is the same as the old name.');
        WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,SQLERRM);
    END copy;

PROCEDURE delete_revision
       (
       revision_id_i IN NUMBER,
       deleted_by_i IN NUMBER,
       success_o OUT NUMBER
       )
       IS
        l_rid NUMBER := revision_id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_juris_type_pk NUMBER;
        l_status NUMBER;
        --l_submit_id NUMBER := submit_delete_id.nextval;
    BEGIN
        success_o := 0;
        --Get status to validate that it's a deleteable record
        --Get revision ID to delete all depedent records by
        SELECT status
        INTO l_status
        FROM jurisdiction_type_revisions
        where id = l_rid;
        IF (l_status = 0) THEN

         --Remove record
            UPDATE jurisdiction_types ai
            SET ai.next_rid = NULL
            WHERE ai.next_rid = l_rid;

            UPDATE jurisdiction_type_revisions ai
            SET ai.next_rid = NULL
            WHERE ai.next_rid = l_rid;
            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'JURISDICTION_TYPES', aa.id
                FROM jurisdiction_types aa
                WHERE aa.rid = l_rid
            );


            DELETE FROM jurisdiction_types ai WHERE ai.rid = l_rid;

            --Remove Revision record
            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) VALUES ('JURISDICTION_TYPE_REVISIONS',l_rid);
            DELETE FROM juris_type_chg_logs ac WHERE ac.rid = l_rid;
            DELETE FROM jurisdiction_type_revisions ar WHERE ar.id = l_rid;

            INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
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
            success_o := 0;
            errlogger.report_and_go(errnums.en_cannot_delete_record,'Record could not be deleted because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END delete_revision;

    /*
    || prc: delete_revision
    || Overloaded
    || Reset status, remove revision, remove documentations
    */
    PROCEDURE delete_revision
       (
       resetAll IN Number,
       revision_id_i IN NUMBER,
       deleted_by_i IN NUMBER,
       success_o OUT NUMBER
       )
       IS
        l_rid NUMBER := revision_id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_juris_pk NUMBER;
        l_status NUMBER;
        l_cit_count number;
        --l_submit_id NUMBER := submit_delete_id.nextval;

        l_stat_cnt NUMBER := 0; -- crapp-2749
    BEGIN
        success_o := 0;

        if resetAll = 1 then
          SELECT COUNT(status)
          INTO l_stat_cnt
          FROM jurisdiction_type_revisions
          WHERE id = l_rid;

          IF l_stat_cnt > 0 THEN -- crapp-2749
              SELECT status
              INTO l_status
              FROM jurisdiction_type_revisions
              WHERE id = l_rid;

              IF (l_status = 1) THEN
                reset_status(revision_id_i=>revision_id_i, reset_by_i=>deleted_by_i, success_o=>success_o);
                -- {{Any option if failed?}}
              End If; -- status

              Delete From juris_type_chg_vlds
              Where juris_type_chg_log_id in
              (Select id From juris_type_chg_logs
                Where rid=l_rid);

              IF SQL%NOTFOUND THEN
                DBMS_OUTPUT.PUT_LINE('No validations to remove');
              END IF;
          END IF; -- l_stat_cnt
        end if; -- resetAll

        --Get status to validate that it's a deleteable record
        --Get revision ID to delete all depedent records by
        SELECT COUNT(status)
        INTO l_stat_cnt
        FROM jurisdiction_type_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN -- crapp-2749
            SELECT status
            INTO l_status
            FROM jurisdiction_type_revisions
            WHERE id = l_rid;

            IF (l_status = 0) THEN
                --Remove dependent Attributes
                --Reset prior revisions to current
                --Remove record
                UPDATE jurisdiction_types ai
                SET ai.next_rid = NULL
                WHERE ai.next_rid = l_rid;

                UPDATE jurisdiction_type_revisions ai
                SET ai.next_rid = NULL
                WHERE ai.next_rid = l_rid;
                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'JURISDICTION_TYPES', aa.id
                    FROM jurisdiction_types aa
                    WHERE aa.rid = l_rid
                );
                DELETE FROM jurisdiction_types ai WHERE ai.rid = l_rid;

                --Remove Revision record
                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) VALUES ('JURISDICTION_TYPE_REVISIONS',l_rid);
                DELETE FROM juris_type_chg_logs ac WHERE ac.rid = l_rid;
                DELETE FROM jurisdiction_type_revisions ar WHERE ar.id = l_rid;

                INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
                    SELECT table_name, primary_key, l_deleted_by
                    FROM tmp_delete
                );
                COMMIT;
                success_o := 1;
            ELSE
                RAISE errnums.cannot_delete_record;
            END IF;
        ELSE
            success_o := 1; -- returning success since there was nothing to remove
        END IF; -- l_stat_cnt

      /* For now we only have one option; reset or not */
    EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_go(errnums.en_cannot_delete_record,'Record could not be deleted because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END delete_revision; -- Overloaded 1


--Will update tax registration if it exists, and will add it if id_io is null
FUNCTION get_revision (
    rid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER
IS
        l_new_rid NUMBER;
        l_curr_rid NUMBER;
        l_juris_type_id NUMBER;
        l_nkid NUMBER;
        l_nrid NUMBER;
        l_status NUMBER := -1;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN

        IF (rid_i IS NOT NULL) THEN
            --this is for existing records,
            --they will have existing revision records
            --doesn't matter if it's published or not,
            --just looking for the current revision
            SELECT jr.id, jr.status, jr.nkid
            INTO l_curr_rid, l_status, l_nkid
            FROM jurisdiction_type_revisions jr
            WHERE EXISTS (
                SELECT 1
                FROM jurisdiction_type_revisions jr2
                WHERE jr.nkid = jr2.nkid
                AND jr2.id = rid_i
                )
            AND jr.next_rid IS NULL;
        END IF;
        IF l_status IN (0,1) THEN
            --This record is already in a pending state.
            --Return its current RID
            retval := l_curr_rid;
        ELSE
            --The current version has been published, create a new one.
            --First, expire the previous version
            INSERT INTO jurisdiction_type_revisions(nkid,  entered_by)
            VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
            UPDATE jurisdiction_type_revisions SET next_rid = l_new_rid WHERE id = l_curr_rid;
            retval := l_new_rid;
        END IF;
        RETURN retval;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN 0; --ignore error and return no RID, this means that the last change in revision was deleted an so the revision no longer exists
    END get_revision;

FUNCTION get_revision (
    entity_id_io IN OUT NUMBER,
    entity_nkid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER
IS
        l_new_rid NUMBER;
        l_juris_type_id NUMBER :=entity_id_io;
        l_nkid NUMBER := entity_nkid_i;
        l_status NUMBER;
        l_curr_rid NUMBER;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN
        --check for an existing revision
        IF (l_juris_type_id IS NOT NULL AND l_nkid IS NOT NULL) THEN
            -- this is just a new Administrator
            INSERT INTO jurisdiction_type_revisions(nkid,  entered_by)
            VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
            retval := l_new_rid;
        ELSE
            --this is a child record, need to get entity nkid
            SELECT a.nkid
            INTO l_nkid
            FROM jurisdiction_types a
            WHERE a.id = entity_id_io;

            SELECT ar.id, ar.status, ar.nkid
            INTO l_curr_rid, l_status, l_nkid
            FROM jurisdiction_type_revisions ar
            WHERE ar.nkid = l_nkid
            AND ar.next_rid IS NULL;
            IF l_status IN (0,1) THEN
                l_new_rid := l_curr_rid;
            ELSE
                INSERT INTO jurisdiction_type_revisions(nkid, entered_by)
                VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
                UPDATE jurisdiction_type_revisions SET next_rid = l_new_rid WHERE id = l_curr_rid;
            END IF;
        END IF;
        entity_id_io := l_juris_type_id;
        retval := l_new_rid;
        RETURN retval;
    END get_revision;

    PROCEDURE unique_check(name_i IN VARCHAR2, nkid_i IN NUMBER)
    IS
        l_count number;
    BEGIN
        select count(*)
        INTO l_count
        from jurisdiction_types
        where name = name_i
        and nkid != nvl(nkid_i,0)
        and abs(status) != 3;

        IF (l_count > 0) THEN
           raise_application_Error( errnums.en_duplicate_key,'Duplicate error: Name provided already exists for another Jurisdiction Types');
        END IF;
    END unique_check;


    PROCEDURE reset_status
       (
       revision_id_i IN NUMBER,
       reset_by_i IN NUMBER,
       success_o OUT NUMBER
       )
       IS
        l_rid NUMBER := revision_id_i;
        l_reset_by NUMBER := reset_by_i;
        l_juris_pk NUMBER;
        l_status NUMBER;
        setVal NUMBER := 0;

        l_stat_cnt NUMBER := 0; -- crapp-2749
    BEGIN
        success_o := 0;
        --Get status to validate that it's a record that can be reset

        SELECT COUNT(status)
        INTO l_stat_cnt
        FROM jurisdiction_type_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN
            SELECT status
            INTO l_status
            FROM jurisdiction_type_revisions
            WHERE id = l_rid;

            IF (l_status = 1) THEN
                --Reset status
                UPDATE jurisdiction_types ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                --Reset status
                UPDATE jurisdiction_type_revisions ji
                SET ji.status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.id = l_rid;

                COMMIT;
                success_o := 1;
            ELSE
                RAISE errnums.cannot_delete_record;
            END IF;
        END IF; -- l_stat_cnt

    EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            errlogger.report_and_stop(errnums.en_cannot_delete_record,'Record status could not be changed because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END reset_status;


END ;
/