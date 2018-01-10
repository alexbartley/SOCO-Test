CREATE OR REPLACE PACKAGE BODY content_repo."REFERENCE_GROUP" 
IS

PROCEDURE delete_revision
       (
       revision_id_i IN NUMBER,
       deleted_by_i IN NUMBER,
       success_o OUT NUMBER
       )
       IS
        l_rid NUMBER := revision_id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_status NUMBER;
        --l_submit_id NUMBER := submit_delete_id.nextval;
    BEGIN
        success_o := 0;
        --Get status to validate that it's a deleteable record
        --Get revision ID to delete all depedent records by
        SELECT status
        INTO l_status
        FROM ref_group_revisions
        where id = l_rid;
        IF (l_status = 0) THEN
            --Remove dependent Attributes
            --Reset prior revisions to current
            UPDATE reference_items aa
            SET aa.next_rid = NULL
            WHERE aa.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'REFERENCE_ITEMS', aa.id
                FROM reference_items aa
                WHERE aa.rid = l_rid
            );

            DELETE FROM reference_items aa
            WHERE aa.rid = l_rid;



            --Remove record
            UPDATE reference_groups ai
            SET ai.next_rid = NULL
            WHERE ai.next_rid = l_rid;

            UPDATE ref_group_revisions ai
            SET ai.next_rid = NULL
            WHERE ai.next_rid = l_rid;
            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'REFERENCE_GROUPS', aa.id
                FROM reference_groups aa
                WHERE aa.rid = l_rid
            );


            DELETE FROM reference_groups ai WHERE ai.rid = l_rid;

            --Remove Revision record
            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) VALUES ('REF_GROUP_REVISIONS',l_rid);
            DELETE FROM ref_grp_chg_logs ac WHERE ac.rid = l_rid;
            DELETE FROM ref_group_revisions ar WHERE ar.id = l_rid;

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
            errlogger.report_and_stop(errnums.en_cannot_delete_record,'Record could not be deleted because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END delete_revision;


FUNCTION get_revision (
    rid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER
IS
        l_new_rid NUMBER;
        l_curr_rid NUMBER;
        l_ref_group_id NUMBER;
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
            FROM ref_group_revisions jr
            WHERE EXISTS (
                SELECT 1
                FROM ref_group_revisions jr2
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
            INSERT INTO ref_group_revisions(nkid,  entered_by)
            VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
            UPDATE ref_group_revisions SET next_rid = l_new_rid WHERE id = l_curr_rid;
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
        l_ref_group_id NUMBER :=entity_id_io;
        l_nkid NUMBER := entity_nkid_i;
        l_status NUMBER;
        l_curr_rid NUMBER;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN
        --check for an existing revision
        IF (l_ref_group_id IS NOT NULL AND l_nkid IS NOT NULL) THEN
            INSERT INTO ref_group_revisions(nkid,  entered_by)
            VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
            retval := l_new_rid;
        ELSE
            --this is a child record, need to get entity nkid
            SELECT a.nkid
            INTO l_nkid
            FROM reference_groups a
            WHERE a.id = entity_id_io;
            SELECT ar.id, ar.status, ar.nkid
            INTO l_curr_rid, l_status, l_nkid
            FROM ref_group_revisions ar
            WHERE ar.nkid = l_nkid
            AND ar.next_rid IS NULL;
            IF l_status IN (0,1) THEN
                l_new_rid := l_curr_rid;
            ELSE
                INSERT INTO ref_group_revisions(nkid, entered_by)
                VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
                UPDATE ref_group_revisions SET next_rid = l_new_rid WHERE id = l_curr_rid;
            END IF;
        END IF;
        entity_id_io := l_ref_group_id;
        retval := l_new_rid;
        RETURN retval;
    END get_revision;


PROCEDURE XMLProcess_Form_RefGrp(sx IN CLOB, update_success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER)
IS
 ref_grp_rec XMLFormReferenceGroup := XMLFormReferenceGroup(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
 l_ref_items XMLFormReferenceItem_TT := XMLFormReferenceItem_TT();
 tag_list xmlform_tags_tt := xmlform_tags_tt();
 RecCount NUMBER :=0;
 l_upd_success NUMBER := 0;
BEGIN
        SELECT
            extractvalue(column_value, '/reference_group/id') id,
            extractvalue(column_value, '/reference_group/rid') rid,
            extractvalue(column_value, '/reference_group/name') name,
            extractvalue(column_value, '/reference_group/start_date') start_Date,
            extractvalue(column_value, '/reference_group/end_date') end_date,
            extractvalue(column_value, '/reference_group/nkid') nkid,
            extractvalue(column_value, '/reference_group/description') description,
            extractvalue(column_value, '/reference_group/entered_by') entered_by,
            extractvalue(column_value, '/reference_group/modified') modified,
            extractvalue(column_value, '/reference_group/deleted') deleted
        INTO
            ref_grp_rec.id, ref_grp_rec.rid, ref_grp_rec.name, ref_grp_rec.start_date, ref_grp_rec.end_date,
            ref_grp_rec.nkid, ref_grp_rec.description,  ref_grp_rec.entered_by, ref_grp_rec.modified,
            ref_grp_rec.deleted
        FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/reference_group'))) t;

            FOR item IN (
                SELECT
                    extractvalue(column_value, '/item/id') id,
                    extractvalue(column_value, '/item/rid') rid,
                    extractvalue(column_value, '/item/value') value,
                    extractvalue(column_value, '/item/value_type') value_type,
                    extractvalue(column_value, '/item/ref_nkid') ref_nkid,
                    extractvalue(column_value, '/item/start_date') start_date,
                    extractvalue(column_value, '/item/end_date') end_date,
                    extractvalue(column_value, '/item/nkid') nkid,
                    extractvalue(column_value, '/item/modified') modified,
                    extractvalue(column_value, '/item/deleted') deleted
                FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/reference_group/item'))) t
            ) LOOP

                l_ref_items.EXTEND;
                l_ref_items(l_ref_items.last) :=
                XMLFormReferenceItem(
                    item.id,
                    item.rid,
                    ref_grp_rec.id,
                    item.value,
                    item.value_type,
                    item.ref_nkid,
                    item.start_date,
                    item.end_date,
                    item.nkid,
                    ref_grp_rec.entered_by,
                    item.modified,
                    item.deleted
                    );
            END LOOP;

    FOR itags IN (SELECT
        h.tag_id,
        h.deleted,
        h.status
    FROM XMLTABLE ('/reference_group/tag'
                        PASSING XMLTYPE(sx)
                        COLUMNS tag_id   NUMBER PATH 'tag_id',
                                deleted   NUMBER PATH 'deleted',
                                status   NUMBER PATH 'status'
								) h
          )
    LOOP
      tag_list.extend;
      tag_list( tag_list.last ):=xmlform_tags(
      9,
      ref_grp_rec.nkid,
      ref_grp_rec.entered_by,
      itags.tag_id,
      itags.deleted,
      0);
    end loop;

    reference_group.update_full(ref_grp_rec, l_ref_items, tag_list, rid_o, nkid_o);

  l_upd_success := 1;
  update_success := l_upd_success;
  -- commented out exception for full err message
  --EXCEPTION
       -- WHEN others THEN
       -- ROLLBACK;
       -- errlogger.report_and_stop (SQLCODE,'Update of reference items failed.');
       --     RAISE;
END XMLProcess_Form_RefGrp;


PROCEDURE update_full (
    details_i IN XMLFormReferenceGroup,
    item_list_i IN XMLFormReferenceItem_TT,
    tag_list IN xmlform_tags_tt,
    rid_o OUT NUMBER,
    nkid_o OUT NUMBER
    )
IS
    l_rg_pk NUMBER := details_i.id;
    l_ref_item_pk NUMBER;
BEGIN

    IF (NVL(details_i.modified,0) = 1) THEN
        reference_group.update_record(
            id_io => l_rg_pk,
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
        FROM reference_groups
        WHERE id = l_rg_pk;
    END IF;
    FOR item IN 1..item_list_i.COUNT LOOP
        l_ref_item_pk := item_list_i(item).id;
        IF (NVL(item_list_i(item).deleted,0) = 1)  THEN
            remove_ref_item(id_i => l_ref_item_pk,deleted_by_i => details_i.entered_By);

        ELSIF (NVL(item_list_i(item).modified,0) = 1) THEN
            reference_group.add_ref_item(
                id_io => l_ref_item_pk,
                ref_group_id_i => l_rg_pk,
                value_i => item_list_i(item).value,
                value_type_i => item_list_i(item).value_type,
                ref_nkid_i => item_list_i(item).ref_nkid,
                start_date_i => item_list_i(item).start_date,
                end_date_i => item_list_i(item).end_date,
                entered_by_i => details_i.entered_By
                );
        END IF;

    END LOOP;

    -- Handle tags
    tags_registry.tags_entry(tag_list, nkid_o);

    --rid_o := reference_group.get_revision(NVL(rid_o,details_i.rid),details_i.entered_By);
    --11/2/2014
    rid_o := get_current_revision(p_nkid=> nkid_o);
EXCEPTION
    WHEN errnums.child_exists THEN
        ROLLBACK;
        errlogger.report_and_stop (SQLCODE,'Requested delete but child records exist.');
    WHEN others THEN
        ROLLBACK;
        RAISE;
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
        l_rg_pk NUMBER := id_io;
        l_name reference_groups.name%TYPE := name_i;
        l_description reference_groups.description%TYPE := description_i;
        l_start_date reference_groups.start_date%TYPE := start_date_i;
        l_end_date reference_groups.end_date%TYPE := end_date_i;
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

        IF (l_rg_pk IS NOT NULL) THEN
        DBMS_OUTPUT.Put_Line('Before Upd:'||l_entered_by);
DBMS_OUTPUT.Put_Line( 'ID='||l_rg_pk );
            UPDATE reference_groups ji
            SET
                ji.name = l_name,
                ji.description = l_description,
                ji.start_date = l_start_date,
                ji.end_date = l_end_date,
                ji.entered_by = l_entered_by
            WHERE ji.id = l_rg_pk
            RETURNING nkid INTO nkid_o;
        ELSE
            INSERT INTO reference_groups(
                name,
                description,
                start_date,
                end_date,
                entered_by
            ) VALUES (
                l_name,
                l_description,
                l_start_date,
                l_end_date,
                l_entered_by
                )
            RETURNING rid, id, nkid INTO rid_o, l_rg_pk, nkid_o;

        END IF;

        id_io :=l_rg_pk;
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


PROCEDURE add_ref_item (
    id_io IN OUT NUMBER,
    ref_group_id_i IN NUMBER,
    value_i IN VARCHAR2,
    value_type_i IN VARCHAR2,
    ref_nkid_i IN NUMBER,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER
    )
   --

   IS
    l_ref_item_pk NUMBER := id_io;
    l_ref_group_pk NUMBER := ref_group_id_i;
    l_value reference_items.value%type := value_i;
    l_value_type reference_items.value_type%type := value_type_i;
    l_ref_nkid reference_items.ref_nkid%type := ref_nkid_i;
    l_start_date reference_items.start_date%TYPE := start_date_i;
    l_end_date reference_items.end_date%TYPE := end_date_i;
    l_entered_by NUMBER := entered_by_i;
    l_nkid NUMBER;
    l_rid NUMBER;
    l_status NUMBER := -1;
    l_current_pending NUMBER;
    BEGIN
DBMS_OUTPUT.Put_Line( 'Add ref item. Entered by:'||l_entered_by );

        --business validation
        IF (l_ref_group_pk IS NULL) THEN
            RAISE errnums.missing_req_val;
        END IF;

        IF (l_ref_item_pk IS NOT NULL) THEN
            UPDATE reference_items aa
            SET aa.start_date = l_start_date,
                aa.end_date = l_end_date,
                aa.entered_by = l_entered_by,
                aa.value = l_value
            WHERE aa.id = l_ref_item_pk;
        ELSE
            INSERT INTO reference_items (
                reference_group_id,
                value,
                value_type,
                ref_nkid,
                start_date,
                end_date,
                entered_by,
                rid
            ) VALUES (
                l_ref_group_pk,
                l_value,
                l_value_type,
                l_ref_nkid,
                l_start_date,
                l_end_date,
                l_entered_by,
                l_rid
            ) RETURNING id INTO l_ref_item_pk;
        END IF;
    id_io :=l_ref_item_pk;
EXCEPTION
    WHEN errnums.missing_req_val THEN
        ROLLBACK;
        errlogger.report_and_stop (errnums.en_missing_req_val,'Key elements missing for record.');
    WHEN errnums.cannot_update_record THEN
        ROLLBACK;
        errlogger.report_and_stop (errnums.en_cannot_update_record,'Record could not be updated because it does not match the pending record :)');
    WHEN others THEN
        ROLLBACK;
        errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_io);
END add_ref_item;


PROCEDURE remove_ref_item (
    id_i IN NUMBER,
    deleted_by_i IN NUMBER
    )
    IS
        l_ref_item_id NUMBER := id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_rid NUMBER;
        l_nkid NUMBER;
    BEGIN

        INSERT INTO tmp_delete(table_name, primary_key) VALUES ('REFERENCE_ITEMS',l_ref_item_id);

        --rely on RLS policy to prevent locked records from being deleted
        --rely on FK constraint to prevent delete if there are dependent records
        DELETE FROM reference_items aa
        WHERE aa.id = l_ref_item_id
        RETURNING rid, nkid INTO l_rid, l_nkid;
        INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
            SELECT table_name, primary_key, l_deleted_by
            FROM tmp_delete
        );
        UPDATE reference_items ata
        SET next_Rid = NULL
        WHERE ata.next_rid = l_rid
        AND ata.nkid = l_nkid;
        EXCEPTION
            WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_i);
    END remove_ref_item;


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
            FROM ref_group_revisions jr
            WHERE EXISTS (
                SELECT 1
                FROM ref_group_revisions jr2
                WHERE jr.nkid = jr2.nkid
                AND jr2.nkid = p_nkid
                )
            AND jr.next_rid IS NULL;
            retval := l_curr_rid;
        END IF;
        RETURN retval;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN 0; --ignore error and return no RID, this means that the last change in revision was deleted an so the revision no longer exists
    END get_current_revision;


    PROCEDURE unique_check(name_i IN VARCHAR2, nkid_i IN NUMBER)
    IS
        l_count number;
    BEGIN
        select count(*)
        INTO l_count
        from reference_groups
        where name = name_i
        and nkid != nvl(nkid_i,0)
        and abs(status) != 3;

        IF (l_count > 0) THEN
           raise_application_Error( errnums.en_duplicate_key,'Duplicate error: Name provided already exists for another Reference Group');
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
        FROM ref_group_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN
            SELECT status
            INTO l_status
            FROM ref_group_revisions
            WHERE id = l_rid;

            IF (l_status = 1) THEN
                --Reset status
                UPDATE reference_items ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                UPDATE reference_groups ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                --Reset status
                UPDATE ref_group_revisions ji
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
            FROM ref_group_revisions
            WHERE id = l_rid;

            IF l_stat_cnt > 0 THEN -- crapp-2749
                SELECT status
                INTO l_status
                FROM ref_group_revisions
                WHERE id = l_rid;
          
                IF (l_status = 1) THEN
                    reset_status(revision_id_i=>revision_id_i, reset_by_i=>deleted_by_i, success_o=>success_o);
                    -- {{Any option if failed?}}
                End If; -- status

                Delete From ref_grp_chg_vlds vld
                Where vld.ref_grp_chg_log_id in
                    (Select id From ref_grp_chg_logs
                     Where rid=l_rid);
          
                IF SQL%NOTFOUND THEN
                    DBMS_OUTPUT.PUT_LINE('No validations to remove');
                END IF;
            END IF; -- l_stat_cnt
        end if; -- resetAll

        SELECT COUNT(status)
        INTO l_stat_cnt
        FROM ref_group_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN -- crapp-2749
            SELECT status
            INTO l_status
            FROM ref_group_revisions
            where id = l_rid;

            IF (l_status = 0) THEN
                --Remove dependent Attributes
                --Reset prior revisions to current
                UPDATE reference_items aa
                SET aa.next_rid = NULL
                WHERE aa.next_rid = l_rid;

                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'REFERENCE_ITEMS', aa.id
                    FROM reference_items aa
                    WHERE aa.rid = l_rid
                );

                DELETE FROM reference_items aa
                WHERE aa.rid = l_rid;

                --Remove record
                UPDATE reference_groups ai
                SET ai.next_rid = NULL
                WHERE ai.next_rid = l_rid;

                UPDATE ref_group_revisions ai
                SET ai.next_rid = NULL
                WHERE ai.next_rid = l_rid;
                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'REFERENCE_GROUPS', aa.id
                    FROM reference_groups aa
                    WHERE aa.rid = l_rid
                );

                DELETE FROM reference_groups ai WHERE ai.rid = l_rid;

                if resetAll = 1 then
                    -- Simple count instead of Exception
                    Select count(*) INTO l_cit_count
                    From admin_chg_cits cit where cit.admin_chg_log_id
                    IN (Select id From admin_chg_logs jc where jc.rid = l_rid);
                    
                    If l_cit_count > 0 Then
                        DELETE FROM admin_chg_cits cit where cit.admin_chg_log_id
                        IN (Select id From admin_chg_logs jc where jc.rid = l_rid);
                    End if;
                end if;

                --Remove Revision record
                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) VALUES ('REF_GROUP_REVISIONS',l_rid);
                DELETE FROM ref_grp_chg_logs ac WHERE ac.rid = l_rid;
                DELETE FROM ref_group_revisions ar WHERE ar.id = l_rid;

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

END reference_group;
/