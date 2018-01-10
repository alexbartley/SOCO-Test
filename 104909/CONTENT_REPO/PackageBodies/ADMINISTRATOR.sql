CREATE OR REPLACE PACKAGE BODY content_repo."ADMINISTRATOR"
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
            FROM administrator_revisions jr
            WHERE EXISTS (
                SELECT 1
                FROM administrator_revisions jr2
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

PROCEDURE XMLProcess_Form_Admin1(sx IN CLOB, update_success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER) IS

  admin_rec XMLFormAdministrator := XMLFormAdministrator(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
  l_attributes XMLForm_Admin_Attr_TT := XMLForm_Admin_Attr_TT();
  l_registrations XMLForm_Admin_Tax_Reg_TT := XMLForm_Admin_Tax_Reg_TT();
  tag_list xmlform_tags_tt := xmlform_tags_tt();

  CLBTemp    CLOB;
  RecCount NUMBER :=0;
  l_upd_success NUMBER := 0;
BEGIN
  CLBTemp:= TO_CHAR(sx);

        -- Administrator Header details
        SELECT
            extractvalue(column_value, '/admin/id') id,
            extractvalue(column_value, '/admin/rid') rid,
            extractvalue(column_value, '/admin/name') name,
            extractvalue(column_value, '/admin/start_date') start_Date,
            extractvalue(column_value, '/admin/end_date') end_date,
            extractvalue(column_value, '/admin/nkid') nkid,
            extractvalue(column_value, '/admin/description') description,
            extractvalue(column_value, '/admin/requires_registration') req_reg,
            extractvalue(column_value, '/admin/collects_tax') collects_tax,
            extractvalue(column_value, '/admin/notes') notes,
            extractvalue(column_value, '/admin/administrator_type_id') administrator_type_id,
            extractvalue(column_value, '/admin/entered_by') entered_by,
            extractvalue(column_value, '/admin/modified') modified,
            extractvalue(column_value, '/admin/deleted') deleted
        INTO
            admin_rec.id, admin_rec.rid, admin_rec.name, admin_rec.start_date, admin_rec.end_date,
            admin_rec.nkid, admin_rec.description, admin_rec.requires_registration, admin_rec.collects_tax,
            admin_rec.notes, admin_rec.administrator_type_id, admin_rec.entered_by, admin_rec.modified,
            admin_rec.deleted
        FROM TABLE(XMLSequence(XMLTYPE(CLBTemp).extract('/admin'))) t;

        -- Attributes
            FOR att IN (
                SELECT
                    extractvalue(column_value, '/attribute/id') id,
                    extractvalue(column_value, '/attribute/rid') rid,
                    extractvalue(column_value, '/attribute/attribute_id') attribute_id,
                    extractvalue(column_value, '/attribute/value') value,
                    extractvalue(column_value, '/attribute/start_date') start_date,
                    extractvalue(column_value, '/attribute/end_date') end_date,
                    extractvalue(column_value, '/attribute/nkid') nkid,
                    extractvalue(column_value, '/attribute/modified') modified,
                    extractvalue(column_value, '/attribute/deleted') deleted
                FROM TABLE(XMLSequence(XMLTYPE(CLBTemp).extract('/admin/attributes/attribute'))) t
            ) LOOP

                l_attributes.EXTEND;
                l_attributes(l_attributes.last) :=
                XMLFormAdministratorAttrib(
                    att.id,
                    att.rid,
                    admin_rec.id,
                    att.attribute_id,
                    att.value,
                    att.start_date,
                    att.end_date,
                    admin_rec.entered_by,
                    att.nkid,
                    att.modified,
                    att.deleted
                    );
            END LOOP;

        -- Tax_registrations
            FOR reg IN (
                SELECT
                    extractvalue(column_value, '/registration/id') id,
                    extractvalue(column_value, '/registration/rid') rid,
                    extractvalue(column_value, '/registration/registration_mask') registration_mask,
                    extractvalue(column_value, '/registration/start_date') start_date,
                    extractvalue(column_value, '/registration/end_date') end_date,
                    extractvalue(column_value, '/registration/nkid') nkid,
                    extractvalue(column_value, '/registration/modified') modified,
                    extractvalue(column_value, '/registration/deleted') deleted
                FROM TABLE(XMLSequence(XMLTYPE(CLBTemp).extract('/admin/registration'))) t
            ) LOOP

                l_registrations.EXTEND;
                l_registrations(l_registrations.last) :=
                XMLFormTaxRegistration(
                    reg.id,
                    reg.rid,--nv tax reg form updated to have rid
                    admin_rec.id,
                    reg.registration_mask,
                    reg.start_date,
                    reg.end_date,
                    admin_rec.entered_by,
                    reg.nkid,--nv also updated tax reg form to have nkid
                    reg.deleted,
                    reg.modified
                    );
            END LOOP;

    -- Tags
    FOR itags IN (SELECT
        h.tag_id,
        h.deleted,
        h.status
    FROM XMLTABLE ('/admin/tag'
                        PASSING XMLTYPE(sx)
                        COLUMNS tag_id   NUMBER PATH 'tag_id',
                                deleted   NUMBER PATH 'deleted',
                                status   NUMBER PATH 'status'
								) h
          )
    LOOP
      tag_list.extend;
      tag_list( tag_list.last ):=xmlform_tags(
      1,
      admin_rec.nkid,
      admin_rec.entered_by,
      itags.tag_id,
      itags.deleted,
      itags.status);
    end loop;

    administrator.update_full(admin_rec, l_attributes, l_registrations, tag_list, rid_o, nkid_o);
    l_upd_success := 1;
    update_success := l_upd_success;

EXCEPTION
        WHEN others THEN
            ROLLBACK;
            --RAISE;
            ERRLOGGER.REPORT_AND_STOP(SQLCODE, 'Form data invalid. '||sqlerrm);
END XMLProcess_Form_Admin1;

PROCEDURE update_full (
    details_i IN XMLFormAdministrator,
    att_list_i IN XMLForm_Admin_Attr_TT,
    atr_list_i IN XMLForm_Admin_Tax_Reg_TT,
    tag_list IN xmlform_tags_tt,
    rid_o OUT NUMBER,
    nkid_o OUT NUMBER
    )
IS
    l_admin_pk NUMBER := details_i.id;
    l_att_pk NUMBER;
    l_atr_pk NUMBER; --admin tax registrations

    --either passed to procedure or set here
BEGIN
DBMS_OUTPUT.Put_Line( details_i.rid );

    /* current rid_o:=details_i.rid;   -- default on update only from XML
       current nkid_o:=details_i.nkid; -- default on update only from XML */

    IF (NVL(details_i.modified,0) = 1) THEN
        administrator.update_record(
            id_io => l_admin_pk,
            name_i => details_i.name,
            description_i => details_i.description,
            start_date_i => details_i.start_date,
            end_Date_i => details_i.end_date,
            requires_registration_i => details_i.requires_registration,
            collects_tax_i => details_i.collects_tax,
            notes_i => details_i.notes,
            admin_type_id_i => details_i.administrator_type_id,
            entered_by_i => details_i.entered_By,
            nkid_o => nkid_o,
            rid_o => rid_o
            );

    END IF;
    IF (nkid_o IS NULL) THEN
        SELECT nkid
        INTO nkid_o
        FROM administrators
        WHERE id = l_admin_pk;
    END IF;

    FOR att IN 1..att_list_i.COUNT LOOP
        l_att_pk := att_list_i(att).id;
        IF (NVL(att_list_i(att).deleted,0) = 1)  THEN
            remove_attribute(id_i => l_att_pk,deleted_by_i => details_i.entered_By);

        ELSIF (NVL(att_list_i(att).modified,0) = 1) THEN
            administrator.update_attribute(
                id_io => l_att_pk,
                administrator_id_i => l_admin_pk,
                attribute_id_i => att_list_i(att).attribute_id,
                value_i => att_list_i(att).value,
                start_date_i => att_list_i(att).start_date,
                end_date_i => att_list_i(att).end_date,
                entered_by_i => details_i.entered_By
                );
        END IF;
    END LOOP;

    --tax registrations are basically attributes that can be added in multiples if the user desires
    FOR atr IN 1..atr_list_i.COUNT LOOP
        l_atr_pk := atr_list_i(atr).id;
        IF (NVL(atr_list_i(atr).deleted,0) = 1)  THEN
            remove_tax_registration(id_i => l_atr_pk,deleted_by_i => details_i.entered_By);
        ELSIF (NVL(atr_list_i(atr).modified,0) = 1) THEN
            administrator.update_tax_registration(
                id_io => l_atr_pk,
                administrator_id_i => l_admin_pk,
                registration_mask_i => atr_list_i(atr).registration_mask,
                start_date_i => atr_list_i(atr).start_date,
                end_date_i => atr_list_i(atr).end_date,
                entered_by_i => details_i.entered_By
                );
        END IF;
    END LOOP;

    --rid_o := ADMINISTRATOR.get_revision(NVL(rid_o,details_i.rid),details_i.entered_By);
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
        errlogger.report_and_stop (SQLCODE,'Update of administrator failed.');
END update_full;

PROCEDURE update_record (
    id_io IN OUT NUMBER,
    name_i IN VARCHAR2,
    description_i IN VARCHAR2,
    start_date_i IN DATE,
    end_date_i IN DATE,
    requires_registration_i IN NUMBER,
    collects_tax_i IN NUMBER,
    notes_i IN VARCHAR2,
    admin_type_id_i IN NUMBER,
    entered_by_i IN NUMBER,
    nkid_o OUT NUMBER,
    rid_o OUT NUMBER
    )
       IS
        l_admin_pk NUMBER := id_io;
        l_name administrators.name%TYPE := name_i;
        l_description administrators.description%TYPE := description_i;
        l_start_date administrators.start_date%TYPE := start_date_i;
        l_end_date administrators.end_date%TYPE := end_date_i;
        l_requires_registration NUMBER := requires_registration_i;
        l_collects_tax NUMBER := collects_tax_i;
        l_notes administrators.notes%TYPE := notes_i;
        l_admin_type_id NUMBER := admin_type_id_i;
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

DBMS_OUTPUT.Put_Line( 'l_admin_pk:'||l_admin_pk );

        IF (l_admin_pk IS NOT NULL) THEN
            UPDATE administrators ji
            SET
                ji.name = l_name,
                ji.description = l_description,
                ji.start_date = l_start_date,
                ji.end_date = l_end_date,
                ji.entered_by = l_entered_by,
                ji.requires_registration = l_requires_registration,
                ji.collects_tax = l_collects_tax,
                ji.notes = l_notes,
                ji.administrator_type_id = l_admin_type_id
            WHERE ji.id = l_admin_pk
            RETURNING nkid INTO nkid_o;
        ELSE
            INSERT INTO administrators(
                name,
                description,
                start_date,
                end_date,
                entered_by,
                administrator_type_id,
                requires_registration,
                collects_tax,
                notes
            ) VALUES (
                l_name,
                l_description,
                l_start_date,
                l_end_date,
                l_entered_by,
                l_admin_type_id,
                l_requires_registration,
                l_collects_tax,
                l_notes
                )
            RETURNING rid, id, nkid INTO rid_o, l_admin_pk, nkid_o;

        END IF;

        id_io :=l_admin_pk;
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
 *  Copy Administrator with detail information + selected data
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
        l_new_admin_pk NUMBER;
        l_new_admin_att_pk NUMBER;
        l_new_tax_reg_pk NUMBER;
        l_new_name administrators.name%TYPE := new_name_i;
        l_entered_by NUMBER := entered_by_i;
        l_new_admin administrators%ROWTYPE;
        l_new_admin_att administrator_attributes%ROWTYPE;
    BEGIN

        --IF NVL(1,0) = 1 THEN
           select *
           into l_new_admin
           from administrators a2
           where id = (
                SELECT max(a.id)
                FROM administrator_revisions ar
                join administrators a on (a.nkid = ar.nkid)
                where ar.id = rid_io
                and a.rid <= ar.id
                );
            IF (l_new_admin.name = TRIM(l_new_name)) THEN
                RAISE errnums.duplicate_key;
            END IF;

            administrator.update_record(
              l_new_admin_pk,
              l_new_name,
              l_new_admin.description,
              l_new_admin.start_date,
              l_new_admin.end_date,
              l_new_admin.requires_registration,
              l_new_admin.collects_tax,
              l_new_admin.notes,
              l_new_admin.administrator_type_id,
              l_entered_by,
              l_nkid,
              rid_io);
              nkid_io := l_nkid;
        --END IF;
        IF NVL(l_copy_attributes,0) = 1 THEN
            FOR r IN (
                SELECT aa.attribute_id, aa.value, aa.start_date, aa.end_date
                FROM administrator_attributes aa
                JOIN administrators a ON (a.id = aa.administrator_id)
                WHERE a.nkid = l_new_admin.nkid
                AND aa.rid <= rid_io
                AND NVL(aa.next_rid,99999999) > rid_io
                ) LOOP
                administrator.update_attribute(l_new_admin_att_pk, l_new_admin_pk, r.attribute_id, r.value, r.start_date, r.end_date, l_entered_by);
                l_new_admin_att_pk := NULL;
            END LOOP;
        END IF;
        IF NVL(copy_reg_i,0) = 1 THEN
            FOR r IN (
                SELECT registration_mask, start_date, end_date
                FROM tax_registrations tr
                JOIN vadmin_ids a ON (a.id = tr.administrator_id)
                WHERE a.nkid = l_new_admin.nkid
                AND tr.rid <= rid_io
                AND NVL(tr.next_rid,99999999) > rid_io
                ) LOOP
            administrator.update_tax_registration(
                id_io => l_new_tax_reg_pk,
                administrator_id_i => l_new_admin_pk,
                registration_mask_i => r.registration_mask,
                start_date_i => r.start_date,
                end_date_i => r.end_date,
                entered_by_i => l_entered_by
                );
                l_new_tax_reg_pk := NULL;
            END LOOP;
        END IF;

        -- Copy Contacts PREP CODE  JIRA 482

        IF NVL(copy_contacts,0) = 1 THEN
            FOR r IN (
                SELECT ct.id, ct.source_id, ct.entered_date
                FROM administrator_contacts ct
                JOIN administrators ad ON (ad.id = ct.administrator_id)
                WHERE ad.nkid = l_new_admin.nkid
                AND ad.rid <= l_rid
                AND NVL(ad.next_rid,99999999) > l_rid
                ) LOOP
                --> Possible proc candidate:
                INSERT INTO administrator_contacts(administrator_id, source_id, entered_by)
                VALUES(l_new_admin_pk, r.source_id, l_entered_by);
            END LOOP;
        END IF;

        rid_io := ADMINISTRATOR.get_revision(entity_id_io => l_new_admin_pk, entity_nkid_i => null, entered_by_i => l_entered_by);
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
        l_admin_pk NUMBER;
        l_status NUMBER;
        --l_submit_id NUMBER := submit_delete_id.nextval;
    BEGIN
        success_o := 0;
        --Get status to validate that it's a deleteable record
        --Get revision ID to delete all depedent records by
        SELECT status
        INTO l_status
        FROM administrator_revisions
        where id = l_rid;
        IF (l_status = 0) THEN
            --Remove dependent Attributes
            --Reset prior revisions to current
            UPDATE administrator_attributes aa
            SET aa.next_rid = NULL
            WHERE aa.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'ADMINISTRATOR_ATTRIBUTES', aa.id
                FROM administrator_attributes aa
                WHERE aa.rid = l_rid
            );

            DELETE FROM administrator_attributes aa
            WHERE aa.rid = l_rid;

            UPDATE tax_registrations tr
            SET tr.next_rid = NULL
            WHERE tr.next_rid = l_rid;

            --nv
            INSERT INTO tmp_delete (table_name, primary_key) (
                      SELECT 'TAX_REGISTRATIONS', tr.id
                      FROM tax_registrations tr
                      WHERE tr.rid = l_rid
                  );
            --nv
            DELETE FROM tax_registrations tr
            WHERE tr.rid = l_rid;

            --Remove dependent Administrator mappings *** Administrator Contacs is currently only depenendency
            --Reset prior revisions to current
            UPDATE administrator_contacts ac
            SET ac.next_rid = NULL
            WHERE ac.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'ADMINISTRATOR_CONTACTS', ac.id
                FROM administrator_contacts ac
                WHERE ac.rid = l_rid
            );

            --Remove record
            UPDATE administrators ai
            SET ai.next_rid = NULL
            WHERE ai.next_rid = l_rid;

            UPDATE administrator_revisions ai
            SET ai.next_rid = NULL
            WHERE ai.next_rid = l_rid;
            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'ADMINISTRATORS', aa.id
                FROM administrators aa
                WHERE aa.rid = l_rid
            );


            DELETE FROM administrators ai WHERE ai.rid = l_rid;

            --Remove Revision record
            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) VALUES ('ADMINISTRATOR_REVISIONS',l_rid);
            DELETE FROM admin_chg_logs ac WHERE ac.rid = l_rid;
            DELETE FROM administrator_revisions ar WHERE ar.id = l_rid;

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
          FROM administrator_revisions
          WHERE id = l_rid;

          IF l_stat_cnt > 0 THEN -- crapp-2749
              SELECT status
              INTO l_status
              FROM administrator_revisions
              WHERE id = l_rid;

              IF (l_status = 1) THEN
                reset_status(revision_id_i=>revision_id_i, reset_by_i=>deleted_by_i, success_o=>success_o);
                -- {{Any option if failed?}}
              End If; -- status

              Delete From admin_chg_vlds
              Where admin_chg_log_id in
              (Select id From admin_chg_logs
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
        FROM administrator_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN -- crapp-2749
            SELECT status
            INTO l_status
            FROM administrator_revisions
            WHERE id = l_rid;

            IF (l_status = 0) THEN
                --Remove dependent Attributes
                --Reset prior revisions to current
                UPDATE administrator_attributes aa
                SET aa.next_rid = NULL
                WHERE aa.next_rid = l_rid;

                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'ADMINISTRATOR_ATTRIBUTES', aa.id
                    FROM administrator_attributes aa
                    WHERE aa.rid = l_rid
                );

                DELETE FROM administrator_attributes aa
                WHERE aa.rid = l_rid;

                UPDATE tax_registrations tr
                SET tr.next_rid = NULL
                WHERE tr.next_rid = l_rid;

                --nv
                INSERT INTO tmp_delete (table_name, primary_key) (
                          SELECT 'TAX_REGISTRATIONS', tr.id
                          FROM tax_registrations tr
                          WHERE tr.rid = l_rid
                      );
                --nv
                DELETE FROM tax_registrations tr
                WHERE tr.rid = l_rid;

                --Remove dependent Administrator mappings *** Administrator Contacs is currently only depenendency
                --Reset prior revisions to current
                UPDATE administrator_contacts ac
                SET ac.next_rid = NULL
                WHERE ac.next_rid = l_rid;

                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'ADMINISTRATOR_CONTACTS', ac.id
                    FROM administrator_contacts ac
                    WHERE ac.rid = l_rid
                );

                --Remove record
                UPDATE administrators ai
                SET ai.next_rid = NULL
                WHERE ai.next_rid = l_rid;

                UPDATE administrator_revisions ai
                SET ai.next_rid = NULL
                WHERE ai.next_rid = l_rid;
                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'ADMINISTRATORS', aa.id
                    FROM administrators aa
                    WHERE aa.rid = l_rid
                );
                DELETE FROM administrators ai WHERE ai.rid = l_rid;

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
                INSERT INTO tmp_delete (table_name, primary_key) VALUES ('ADMINISTRATOR_REVISIONS',l_rid);
                DELETE FROM admin_chg_logs ac WHERE ac.rid = l_rid;
                DELETE FROM administrator_revisions ar WHERE ar.id = l_rid;

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
PROCEDURE update_tax_registration (
    id_io IN OUT NUMBER,
    administrator_id_i IN NUMBER,
    registration_mask_i IN VARCHAR2,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER
    )
IS

    l_admin_tr_pk NUMBER := id_io;
    l_admin_pk NUMBER := administrator_id_i;
    l_registration_mask tax_registrations.registration_mask%TYPE := registration_mask_i;
    l_start_date tax_registrations.start_date%TYPE := start_date_i;
    l_end_date tax_registrations.end_date%TYPE := end_date_i;
    l_entered_by NUMBER := entered_by_i;
    l_nkid NUMBER;
    --l_rid NUMBER;
    l_status NUMBER := -1;
    l_current_pending NUMBER;
    BEGIN
        --business validation
        --nv added trim of mask
        IF (TRIM(l_registration_mask) IS NULL OR l_admin_pk IS NULL) THEN
            RAISE errnums.missing_req_val;
        END IF;

        IF (l_admin_tr_pk IS NOT NULL) THEN

            UPDATE tax_registrations tr
            SET tr.registration_mask = l_registration_mask, --nv
                tr.start_date = l_start_date,
                tr.end_date = l_end_date,
                tr.entered_by = l_entered_by
            WHERE tr.id = l_admin_tr_pk;
        ELSE
            --Insert new record into tax_registrations table
            INSERT INTO tax_registrations (
                administrator_id,
                registration_mask,
                start_date,
                end_date,
                entered_by --,
                --rid
            ) VALUES (
                l_admin_pk,
                l_registration_mask,
                l_start_date,
                l_end_date,
                l_entered_by --,
                --l_rid
            ) RETURNING id INTO l_admin_tr_pk;

        END IF;
    id_io :=l_admin_tr_pk;
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
END update_tax_registration;


PROCEDURE remove_tax_registration (
    id_i IN NUMBER,
    deleted_by_i IN NUMBER
    )
    IS
        l_tax_registration_id NUMBER := id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_admin_id NUMBER;
        l_rid NUMBER;
        l_nkid NUMBER;
    BEGIN

        INSERT INTO tmp_delete(table_name, primary_key) VALUES ('TAX_REGISTRATIONS',l_tax_registration_id);

        --rely on RLS policy to prevent locked records from being deleted
        --rely on FK constraint to prevent delete if there are dependent records
        DELETE FROM tax_registrations tr
        WHERE tr.id = l_tax_registration_id
        RETURNING rid, nkid INTO l_rid, l_nkid;
        INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
            SELECT table_name, primary_key, l_deleted_by
            FROM tmp_delete
        );
        --Update the administrator record's RID/NKID
        UPDATE tax_registrations atr
        SET next_Rid = NULL
        WHERE atr.next_rid = l_rid
        AND atr.nkid = l_nkid;
        EXCEPTION
            WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_i);
END remove_tax_registration;

PROCEDURE update_attribute (
    id_io IN OUT NUMBER,
    administrator_id_i IN NUMBER,
    attribute_id_i IN NUMBER,
    value_i IN VARCHAR2,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER
    )
   --
   IS
    l_admin_att_pk NUMBER := id_io;
    l_admin_pk NUMBER := administrator_id_i;
    l_attribute_id NUMBER := attribute_id_i;
    l_value administrator_attributes.value%TYPE := value_i;
    l_start_date administrator_attributes.start_date%TYPE := start_date_i;
    l_end_date administrator_attributes.end_date%TYPE := end_date_i;
    l_entered_by NUMBER := entered_by_i;
    l_nkid NUMBER;
    l_rid NUMBER;
    l_status NUMBER := -1;
    l_current_pending NUMBER;
    BEGIN
        --business validation
        IF (TRIM(l_value) IS NULL OR l_admin_pk IS NULL) THEN
            RAISE errnums.missing_req_val;
        END IF;

        IF (l_admin_att_pk IS NOT NULL) THEN
            UPDATE administrator_Attributes aa
            SET aa.value = l_value,
                aa.start_date = l_start_date,
                aa.end_date = l_end_date,
                aa.entered_by = l_entered_by
            WHERE aa.id = l_admin_att_pk;
        ELSE
            INSERT INTO administrator_attributes (
                administrator_id,
                attribute_id,
                value, start_date,
                end_date,
                entered_by,
                rid
            ) VALUES (
                l_admin_pk,
                l_attribute_id,
                l_value,
                l_start_date,
                l_end_date,
                l_entered_by,
                l_rid
            ) RETURNING id INTO l_admin_att_pk;
        END IF;
    id_io :=l_admin_att_pk;
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
END update_attribute;


PROCEDURE remove_attribute (
    id_i IN NUMBER,
    deleted_by_i IN NUMBER
    )
    IS
        l_admin_att_id NUMBER := id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_admin_id NUMBER;
        l_tax_desc_id NUMBER;
        l_rid NUMBER;
        l_nkid NUMBER;
    BEGIN

        INSERT INTO tmp_delete(table_name, primary_key) VALUES ('ADMINISTRATOR_ATTRIBUTES',l_admin_att_id);

        --rely on RLS policy to prevent locked records from being deleted
        --rely on FK constraint to prevent delete if there are dependent records
        DELETE FROM administrator_attributes aa
        WHERE aa.id = l_admin_att_id
        RETURNING rid, nkid INTO l_rid, l_nkid;
        INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
            SELECT table_name, primary_key, l_deleted_by
            FROM tmp_delete
        );
        UPDATE administrator_attributes ata
        SET next_Rid = NULL
        WHERE ata.next_rid = l_rid
        AND ata.nkid = l_nkid;
        EXCEPTION
            WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_i);
    END remove_attribute;



FUNCTION get_revision (
    rid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER
IS
        l_new_rid NUMBER;
        l_curr_rid NUMBER;
        l_admin_id NUMBER;
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
            FROM administrator_revisions jr
            WHERE EXISTS (
                SELECT 1
                FROM administrator_revisions jr2
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
            INSERT INTO administrator_revisions(nkid,  entered_by)
            VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
            UPDATE administrator_revisions SET next_rid = l_new_rid WHERE id = l_curr_rid;
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
        l_admin_id NUMBER :=entity_id_io;
        l_nkid NUMBER := entity_nkid_i;
        l_status NUMBER;
        l_curr_rid NUMBER;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN
        --check for an existing revision
        IF (l_admin_id IS NOT NULL AND l_nkid IS NOT NULL) THEN
            -- this is just a new Administrator
            INSERT INTO administrator_revisions(nkid,  entered_by)
            VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
            retval := l_new_rid;
        ELSE
            --this is a child record, need to get entity nkid
            SELECT a.nkid
            INTO l_nkid
            FROM administrators a
            WHERE a.id = entity_id_io;

            SELECT ar.id, ar.status, ar.nkid
            INTO l_curr_rid, l_status, l_nkid
            FROM administrator_revisions ar
            WHERE ar.nkid = l_nkid
            AND ar.next_rid IS NULL;
            IF l_status IN (0,1) THEN
                l_new_rid := l_curr_rid;
            ELSE
                INSERT INTO administrator_revisions(nkid, entered_by)
                VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
                UPDATE administrator_revisions SET next_rid = l_new_rid WHERE id = l_curr_rid;
            END IF;
        END IF;
        entity_id_io := l_admin_id;
        retval := l_new_rid;
        RETURN retval;
    END get_revision;

    PROCEDURE unique_check(name_i IN VARCHAR2, nkid_i IN NUMBER)
    IS
        l_count number;
    BEGIN
        select count(*)
        INTO l_count
        from administrators
        where name = name_i
        and nkid != nvl(nkid_i,0)
        and abs(status) != 3;

        IF (l_count > 0) THEN
           raise_application_Error( errnums.en_duplicate_key,'Duplicate error: Name provided already exists for another Administrator');
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
        FROM administrator_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN
            SELECT status
            INTO l_status
            FROM administrator_revisions
            WHERE id = l_rid;

            IF (l_status = 1) THEN
                --Reset status
                /*UPDATE administrator_attributes ja
                SET status = setVal,
                ja.entered_By = l_reset_by
                WHERE ja.rid = l_rid;*/

                --Reset status
                UPDATE administrators ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                --Reset status
                UPDATE administrator_revisions ji
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


END administrator;
/