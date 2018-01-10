CREATE OR REPLACE PACKAGE BODY content_repo.commodity
IS
/*
||
||
-- Revision History
--    Date            Author       Reason for Change
-- ----------------------------------------------------------------
--   09/25 CRAPP-3886              Delete_Revision procedure changed to account for linked taxabilities check
*/

	-- Function to check number of taxabilties linked with commodity revision.
	-- Accepts RID and checks if that revision any way is tied up with commodity changes.
	Function cnt_taxabilities_attachehd(comm_rid_i in number)
    return number
    is
        lcnt number := 0;
        lcomm_id number := 0;
    begin

        select id into lcomm_id from commodities where rid = comm_rid_i;
        select count(1) into lcnt from juris_tax_applicabilities where commodity_id = lcomm_id;

        return lcnt;

    exception
    when others then
        return 0;
    end;


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
            FROM commodity_revisions jr
            WHERE EXISTS (
                SELECT 1
                FROM commodity_revisions jr2
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

PROCEDURE XMLProcess_Form_Comm(sx IN CLOB, update_success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER) IS
  comm_rec XMLFormCommodity := XMLFormCommodity(NULL, NULL, NULL, NULL, NULL,
  NULL, NULL, NULL, NULL, NULL,
  NULL, NULL, NULL, NULL, NULL);
  l_commodities XMLFormComm_TT := XMLFormComm_TT();
  att_list XMLForm_CommAttr_TT := XMLForm_CommAttr_TT();
  tag_list xmlform_tags_tt := xmlform_tags_tt();
  CLBTemp  CLOB;
  RecCount NUMBER :=0;
  l_upd_success NUMBER := 0;
BEGIN
-- ? 8/25/2014 hm
CLBTemp:= TO_CHAR(sx);

--insert into dev_applicability_xml values ( sx, sysdate, 'COMMODITY' );
--commit;

        SELECT
            extractvalue(column_value, '/commodity/id') id,
            -- extractvalue(column_value, '/commodity/rid') rid,
            extractvalue(column_value, '/commodity/name') name,
            extractvalue(column_value, '/commodity/startDate') start_Date,
            extractvalue(column_value, '/commodity/endDate') end_date,
            extractvalue(column_value, '/commodity/nkid') nkid,
            extractvalue(column_value, '/commodity/description') description,
            extractvalue(column_value, '/commodity/enteredBy') enteredBy,
            extractvalue(column_value, '/commodity/modified') modified,
            extractvalue(column_value, '/commodity/deleted') deleted,
            extractvalue(column_value, '/commodity/parentId') parent_id,
            extractvalue(column_value, '/commodity/commodityCode') commodity_code,
            extractvalue(column_value, '/commodity/productTreeId') product_tree_id,
            extractvalue(column_value, '/commodity/ProductTreeShortName') product_tree_short_name,
            extractvalue(column_value, '/commodity/h_code') h_code
        INTO
            comm_rec.id, --comm_rec.rid,
            comm_rec.name, comm_rec.start_date, comm_rec.end_date,
            comm_rec.nkid,
            comm_rec.description,  comm_rec.entered_by, comm_rec.modified,
            comm_rec.deleted,
            comm_rec.parent_id,
            comm_rec.commodity_code,
            comm_rec.product_tree_id,
            comm_rec.product_tree_short_name,
            comm_rec.h_code
        FROM TABLE(XMLSequence(XMLTYPE(CLBTemp).extract('/commodity'))) t;

        -- Commodities Attributes
        /*FOR iattrib IN (SELECT
          h.uiuserid,
          h.recid,
          h.recrid,
          h.recnkid,
          h.value,
          h.attribute_id,
          TO_DATE (h.start_date) start_date,
          TO_DATE (h.end_date) end_date,
          h.modified,
          h.deleted,
          h.comm_id
          FROM XMLTABLE ('/commodity/attribute'
                        PASSING XMLTYPE(CLBTemp)
                        COLUMNS uiuserid   NUMBER PATH 'entered_by',
                                recid   NUMBER PATH 'id',
                                recrid   NUMBER PATH 'rid',
                                recnkid   NUMBER PATH 'nkid',
                                attribute_id NUMBER PATH 'attribute_id',
                                attribute_category_id NUMBER PATH 'attribute_category_id',
                                value   VARCHAR2 (128) PATH 'value',
                                start_date   VARCHAR2 (12) PATH 'start_date',
                                end_date   VARCHAR2 (12) PATH 'end_date',
                                modified NUMBER path 'modified',
                                deleted NUMBER path 'deleted',
                                comm_id NUMBER path 'commodity_id') h
          )
          LOOP
            att_list.extend;
            att_list( att_list.last ).uiuserid := iattrib.uiuserid;
            att_list( att_list.last ).recid := iattrib.recid;
            att_list( att_list.last ).recrid := iattrib.recrid;
            att_list( att_list.last ).recnkid  := iattrib.recnkid;

            att_list( att_list.last ).attribute_id := iattrib.attribute_id;
            att_list( att_list.last ).value := iattrib.value;
            att_list( att_list.last ).start_date :=iattrib.start_date;
            att_list( att_list.last ).end_date :=iattrib.end_date;
            att_list( att_list.last ).modified:=iattrib.modified;
            att_list( att_list.last ).deleted :=iattrib.deleted;
            att_list( att_list.last ).comm_id :=iattrib.comm_id;


          END LOOP;

*/

    -- Tags
    FOR itags IN (SELECT
        h.tag_id,
        h.deleted,
        h.status
    FROM XMLTABLE ('/commodity/publicationTags'
                        PASSING XMLTYPE(sx)
                        COLUMNS tag_id   NUMBER PATH 'tagId',
                                deleted   NUMBER PATH 'deleted',
                                status   NUMBER PATH 'modified'
                                ) h
          )
    LOOP
      tag_list.extend;
      tag_list( tag_list.last ):=xmlform_tags(
      5,
      comm_rec.nkid,
      comm_rec.entered_by,
      itags.tag_id,
      itags.deleted,
      0);
    end loop;

    commodity.update_full(comm_rec, --att_list,
    tag_list, rid_o, nkid_o);

   l_upd_success := 1;
    update_success := l_upd_success;
EXCEPTION
        WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,SQLERRM);
END XMLProcess_Form_Comm;

PROCEDURE update_full (
    details_i IN XMLFormCommodity,
    --att_list_i IN XMLForm_CommAttr_TT,
    tag_list IN xmlform_tags_tt,
    rid_o OUT NUMBER,
    nkid_o OUT NUMBER
    )
IS
    l_cg_pk NUMBER := details_i.id;
    l_comm_pk NUMBER;
    l_att_pk NUMBER;
    l_nkid_o NUMBER;
BEGIN

    IF (NVL(details_i.modified,0) = 1) THEN
        commodity.update_record(
            id_io => l_cg_pk,
            details_i => details_i,
            nkid_o => l_nkid_o,
            rid_o => rid_o
            );

    END IF;

    IF (nkid_o IS NULL) THEN
        SELECT nkid
        INTO nkid_o
        FROM commodities
        WHERE id = l_cg_pk;
    END IF;
/*
   -- Attributes
   FOR att IN 1..att_list_i.COUNT LOOP
     l_att_pk := att_list_i(att).recid;
     IF (NVL(att_list_i(att).deleted,0) = 1)  THEN
         remove_attribute(id_i => l_att_pk, deleted_by_i => details_i.entered_By);
     ELSIF (NVL(att_list_i(att).modified,0) = 1) THEN
         update_attribute(
             id_io => l_att_pk,
             comm_id_i => l_cg_pk,
             attribute_id_i => att_list_i(att).attribute_id,
             value_i => att_list_i(att).value,
             start_date_i => att_list_i(att).start_date,
             end_date_i => att_list_i(att).end_date,
             entered_by_i => details_i.entered_By
--             entered_by_i => att_list_i(att).uiuserid
         );
      END IF;
    END LOOP;
*/

    -- Handle tags
    tags_registry.tags_entry(tag_list, l_nkid_o);

    -- return current/new rid
    nkid_o := l_nkid_o;
    --rid_o := commodity.get_revision(NVL(rid_o,details_i.rid),details_i.entered_By);
    rid_o := get_current_revision(p_nkid=> nkid_o);
EXCEPTION
    WHEN errnums.child_exists THEN
        ROLLBACK;
        errlogger.report_and_stop (SQLCODE,'Requested delete but child records exist.');
    WHEN others THEN
        ROLLBACK;
        errlogger.report_and_stop (SQLCODE,'Update record failed.');
END update_full;


PROCEDURE update_record (
    id_io IN OUT NUMBER,
    details_i IN XMLFormCommodity,
    nkid_o OUT NUMBER,
    rid_o OUT NUMBER
    )
       IS
        l_cg_pk NUMBER := id_io;
        l_status NUMBER := -1;
        l_current_pending NUMBER;
        new_h_code commodities.h_code%TYPE;
        sParentH_Code commodities.h_code%TYPE;
        nTreeId NUMBER;
    BEGIN
        --business validation
        IF (TRIM(details_i.name) IS NULL) THEN
            RAISE errnums.missing_req_val;
        END IF;

        /* 8/25/2014: never update h_code. Last changes was in April 2014 */
        IF (l_cg_pk IS NOT NULL) THEN
            UPDATE commodities ji
            SET
                ji.name = details_i.name,
                ji.description = details_i.description,
                ji.start_date = details_i.start_date,
                ji.end_date = details_i.end_date,
                ji.entered_by = details_i.entered_by,
                ji.commodity_code = details_i.commodity_code
                --ji.h_code =  details_i.h_code
            WHERE ji.id = l_cg_pk
            RETURNING nkid INTO nkid_o;
        ELSE
              SELECT h_code, product_tree_id INTO sParentH_Code, nTreeId
              FROM commodities
              WHERE
              id = details_i.parent_id;
              -- if blank?

              SELECT xc_utils.fxvcommodityseq(sParentH_Code)
              INTO new_h_code
              FROM dual;

            INSERT INTO commodities (
                NAME,
                description,
                commodity_code,
                entered_by,
                product_tree_id,
                h_code,
                start_date,
                end_date
            ) VALUES (
                details_i.name,
                details_i.description,
                details_i.commodity_code,
                details_i.entered_by,
                nTreeId,
                new_h_code,
                details_i.start_date,
                details_i.end_date
            )
            RETURNING rid, id, nkid INTO rid_o, l_cg_pk, nkid_o;
        END IF;
        id_io :=l_cg_pk;

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


PROCEDURE delete_revision
       (
       revision_id_i IN NUMBER,
       deleted_by_i IN NUMBER,
       success_o OUT NUMBER,
       existsInGroups OUT CLOB
       )
       IS
        l_rid NUMBER := revision_id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_status NUMBER;
        clb_InGroups CLOB := '{}';
        lcnt_taxabilities number := 0;

    BEGIN
      success_o := 0;

        --Get status to validate that it's a deleteable record
        --Get revision ID to delete all depedent records by
        SELECT status
        INTO l_status
        FROM commodity_revisions
        where id = l_rid;

        lcnt_taxabilities := cnt_taxabilities_attachehd(revision_id_i);
        if lcnt_taxabilities > 0
        then
            raise errnums.cannot_delete_revision;
        end if;

        -- tnn: clg not using a count / passing a JSON.
        --clb_InGroups := fCommodityPartOf(l_rid);


        IF (l_status in ( 0, 1 )) THEN
            --Remove dependent Attributes
            /*
            UPDATE commodity_attributes aa
            SET aa.next_rid = NULL
            WHERE aa.next_rid = l_rid;

            DELETE FROM commodity_attributes ja
            WHERE ja.rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'COMMODITIES', aa.id
                FROM commodities aa
                WHERE aa.rid = l_rid
            );

            */
            --Reset prior revisions to current
            UPDATE commodities aa
            SET aa.next_rid = NULL
            WHERE aa.next_rid = l_rid;

            UPDATE commodity_revisions ai
            SET ai.next_rid = NULL
            WHERE ai.next_rid = l_rid;

            DELETE FROM commodities aa
            WHERE aa.rid = l_rid;

            --Remove Revision record
            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) VALUES ('COMMODITY_REVISIONS',l_rid);
            DELETE FROM comm_chg_logs ac WHERE ac.rid = l_rid;
            DELETE FROM commodity_revisions ar WHERE ar.id = l_rid;

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
        WHEN errnums.cannot_delete_revision THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_go(errnums.en_cannot_delete_revision,'Commodity revision has been linked to taxabilities. hence it can not be deleted.');
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            success_o := 0;  -- already set as default though.
            existsInGroups := clb_InGroups;
            errlogger.report_and_go(errnums.en_cannot_delete_record,'Record could not be deleted because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END delete_revision;


/*
PROCEDURE add_commodity (
    id_io IN OUT NUMBER,
    details_i IN XMLFormCommodity
    )
   --

   IS
    l_cgc_pk NUMBER := id_io;
    l_start_date commodities.start_date%TYPE := details_i.start_date;
    l_end_date commodities.end_date%TYPE := details_i.end_date;
    l_entered_by NUMBER := details_i.entered_by;
    l_nkid NUMBER;
    l_rid NUMBER;
    l_status NUMBER := -1;
    l_current_pending NUMBER;
    BEGIN
        IF (l_cgc_pk IS NOT NULL) THEN
            UPDATE commodities aa
            SET aa.start_date = l_start_date,
                aa.end_date = l_end_date,
                aa.entered_by = l_entered_by
            WHERE aa.id = l_cgc_pk;
        ELSE
            --dbms_output.put_line('inserting '||l_comm_group_pk||','||l_commodity_id);

            INSERT INTO commodities (
                NAME,
                description,
                commodity_code,
                entered_by,
                product_tree_id,
                h_code,
                start_date,
                end_date
            ) VALUES (
                details_i.name,
                details_i.description,
                details_i.commodity_code,
                l_entered_by,
                details_i.product_tree_id,
                details_i.h_code,
                l_start_date,
                l_end_date
            ) RETURNING id INTO l_cgc_pk;
            dbms_output.put_line('inserted '||l_cgc_pk);
        END IF;
    id_io :=l_cgc_pk;
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
END add_commodity;
*/

PROCEDURE remove_commodity (
    id_i IN NUMBER,
    deleted_by_i IN NUMBER
    )
    IS
        l_cgc_id NUMBER := id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_rid NUMBER;
        l_nkid NUMBER;
    BEGIN
        INSERT INTO tmp_delete(table_name, primary_key) VALUES ('COMMODITIES',l_cgc_id);

        --rely on RLS policy to prevent locked records from being deleted
        --rely on FK constraint to prevent delete if there are dependent records
        DELETE FROM commodities aa
        WHERE aa.id = l_cgc_id
        RETURNING rid, nkid INTO l_rid, l_nkid;
        INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
            SELECT table_name, primary_key, l_deleted_by
            FROM tmp_delete
        );
        UPDATE commodities ata
        SET next_Rid = NULL
        WHERE ata.next_rid = l_rid
        AND ata.nkid = l_nkid;
        -- ToDo:
        EXCEPTION
            WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_i);

    END remove_commodity;

FUNCTION get_revision (
    rid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER
IS
        l_new_rid NUMBER;
        l_curr_rid NUMBER;
        l_comm_group_id NUMBER;
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
            FROM commodity_revisions jr
            WHERE EXISTS (
                SELECT 1
                FROM commodity_revisions jr2
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
            INSERT INTO commodity_revisions(nkid,  entered_by)
            VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
            UPDATE commodity_revisions SET next_rid = l_new_rid WHERE id = l_curr_rid;
            retval := l_new_rid;
        END IF;
        RETURN retval;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
                RETURN retval; --ignore error and return no RID, this means that the last change in revision was deleted an so the revision no longer exists
    END get_revision;

FUNCTION get_revision (
    entity_id_io IN OUT NUMBER,
    entity_nkid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER
IS
        l_new_rid NUMBER;
        l_comm_group_id NUMBER :=entity_id_io;
        l_nkid NUMBER := entity_nkid_i;
        l_status NUMBER;
        l_curr_rid NUMBER;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN
        --check for an existing revision
        IF (l_comm_group_id IS NOT NULL AND l_nkid IS NOT NULL) THEN
            INSERT INTO commodity_revisions(nkid,  entered_by)
            VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
            retval := l_new_rid;
        ELSE
            --this is a child record, need to get entity nkid
            SELECT a.nkid
            INTO l_nkid
            FROM commodities a
            WHERE a.id = entity_id_io;


            SELECT ar.id, ar.status, ar.nkid
            INTO l_curr_rid, l_status, l_nkid
            FROM commodity_revisions ar
            WHERE ar.nkid = l_nkid
            AND ar.next_rid IS NULL;
            IF l_status IN (0,1) THEN
                l_new_rid := l_curr_rid;
            ELSE
                INSERT INTO commodity_revisions(nkid, entered_by)
                VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
                UPDATE commodity_revisions SET next_rid = l_new_rid WHERE id = l_curr_rid;
            END IF;
        END IF;
        entity_id_io := l_comm_group_id;
        retval := l_new_rid;
        RETURN retval;
    END get_revision;

PROCEDURE remove_attribute (
    id_i IN NUMBER,
    deleted_by_i IN NUMBER
    )
    IS
        l_comm_att_id NUMBER := id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_comm_id NUMBER;
        l_tax_desc_id NUMBER;
        l_rid NUMBER;
        l_nkid NUMBER;
    BEGIN
        INSERT INTO tmp_delete(table_name, primary_key) VALUES ('COMMODITY_ATTRIBUTES',l_comm_att_id);
        --rely on RLS policy to prevent locked records from being deleted
        --rely on FK constraint to prevent delete if there are dependent records
        DELETE FROM commodity_attributes cma
        WHERE cma.id = l_comm_att_id
        RETURNING rid, nkid INTO l_rid, l_nkid;

        INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
            SELECT table_name, primary_key, l_deleted_by
            FROM tmp_delete
        );
        UPDATE commodity_attributes cma
        SET next_Rid = NULL
        WHERE cma.next_rid = l_rid
        AND cma.nkid = l_nkid;

        EXCEPTION
            WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_i);
    END remove_attribute;


PROCEDURE update_attribute (
    id_io IN OUT NUMBER,
    comm_id_i IN NUMBER,
    attribute_id_i IN NUMBER,
    value_i IN VARCHAR2,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER
    )
   --
   IS
    l_comm_att_pk NUMBER := id_io;
    l_comm_pk NUMBER := comm_id_i;
    l_attribute_id NUMBER := attribute_id_i;
    l_value commodity_attributes.value%TYPE := value_i;
    l_start_date commodity_attributes.start_date%TYPE := start_date_i;
    l_end_date commodity_attributes.end_date%TYPE := end_date_i;
    l_entered_by NUMBER := entered_by_i;
    l_nkid NUMBER;
    l_rid NUMBER;
    l_status NUMBER := -1;
    l_current_pending NUMBER;


    BEGIN

        --business validation
        IF (TRIM(l_value) IS NULL OR l_comm_pk IS NULL) THEN
            RAISE errnums.missing_req_val;
        END IF;

        IF (l_comm_att_pk IS NOT NULL) THEN
            UPDATE commodity_attributes ja
            SET ja.value = l_value,
                ja.start_date = l_start_date,
                ja.end_date = l_end_date,
                ja.entered_by = l_entered_by
            WHERE ja.id = l_comm_att_pk;
        ELSE









            INSERT INTO commodity_attributes (
                commodity_id,
                attribute_id,
                value, start_date,
                end_date,
                entered_by,
                rid
            ) VALUES (
                l_comm_pk,
                l_attribute_id,
                l_value,
                l_start_date,
                l_end_date,
                l_entered_by,
                l_rid
            ) RETURNING id INTO l_comm_att_pk;
        END IF;
    id_io :=l_comm_att_pk;
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

    PROCEDURE unique_check(name_i IN VARCHAR2, prod_tree_i IN NUMBER, h_code_i VARCHAR2, nkid_i IN NUMBER)
    IS
        l_count number;
    BEGIN
        select count(*)
        INTO l_count
        from commodities
        where name = name_i
        and product_Tree_id = prod_tree_i
        and length(h_code) = length(h_code_i)
        and substr(h_code,1,length(h_code)-4) = substr(h_code_i,1,length(h_code_i)-4)
        and nkid != nvl(nkid_i,0)
        and abs(status) != 3;

        IF (l_count > 0) THEN
           raise_application_Error( errnums.en_duplicate_key,'Duplicate error: Name provided already exists for another Commodity.');
        END IF;
    END unique_check;

  /*
  || Add commodity to commodity group process
  || XML from MidTier, return success flag and log id to be used for Change Log
  || search.
  */
 /*
  Procedure add_associated_groups(sx in CLOB, success_o OUT number, log_id_o OUT number)
  is
    type CM_Header is record
    (
      comm_id number
    , comm_rid number
    , comm_nkid number
    , entered_by number
    , comm_grp_id number
    , comm_grp_nkid number
    , comm_grp_rid number
    );
    TYPE T_CM_Header IS TABLE OF CM_Header;
    recs_CM_Header T_CM_Header:=T_CM_Header();

    type CM_Groups is record
    (
      comm_grp_id number
    , comm_grp_rid number
    , comm_grp_nkid number
    );
    TYPE T_CM_Groups IS TABLE OF CM_Groups;
    recs_CM_Groups T_CM_Groups:=T_CM_Groups();

    process_id number;
    pStart_Date date;
    pEnd_Date date;
    ret_id number;
  begin
    process_id:=comm_copy_to_grp_sq.nextval;

    with t as (
    select xmltype(sx)
    xml from dual )
      SELECT
       cm.comm_id
      ,cm.comm_rid
      ,cm.comm_nkid
      ,cm.entered_by
      ,h.comm_grp_id
      ,h.comm_grp_nkid
      ,h.comm_grp_rid
    BULK COLLECT INTO recs_CM_Header
    FROM t,
    XMLTABLE('/commodity_associations'
    PASSING t.xml
    columns
       comm_id number path 'comm_id'
      ,comm_rid number path 'comm_rid'
      ,comm_nkid number path 'comm_nkid'
      ,entered_by number path 'entered_by') cm,
      XMLTable('for $i in /commodity_associations/commodity_groups return $i'
         passing t.xml
         columns
      comm_grp_id number path 'comm_grp_id',
      comm_grp_rid number path 'comm_grp_rid',
      comm_grp_nkid number path 'comm_grp_nkid'
    ) h;

  -- debug output
  for i in recs_CM_Header.First..recs_CM_Header.Last
  loop
    DBMS_OUTPUT.Put_Line(recs_CM_Header(i).comm_id);
    DBMS_OUTPUT.Put_Line(recs_CM_Header(i).comm_grp_rid);
  end loop;

  -- For now it is 1 master record for a commodity. Multiple can not be added.
  if recs_CM_Header(1).comm_id is not null then

    select x.start_date, x.end_date
    into pStart_Date, pEnd_Date
    from
    commodities x
    where x.id=recs_CM_Header(1).comm_id
    and x.next_rid is null;

    /*select x.start_date, x.end_date
    into pStart_Date, pEnd_Date
    from
    commodities x,
    commodities y
    where x.h_code=fcomm_hcodeRet(y.h_code)
    and y.id=recs_CM_Header(1).comm_id
    and x.product_tree_id = y.product_tree_id;*/

 /*   -- Add commodity to commodity group with start and end date
    for i in recs_CM_Header.First..recs_CM_Header.Last
    loop
      DBMS_OUTPUT.Put_Line( 'Call here...' );
      commodity_group.add_commodity(
         id_io=> ret_id,
         comm_group_id_i=> recs_CM_Header(i).comm_grp_id,
         commodity_id_i=> recs_CM_Header(1).comm_id,
         start_date_i=> pStart_Date,
         end_date_i=> pEnd_Date,
         entered_by_i=> recs_CM_Header(1).entered_by,
         p_nkid=> recs_CM_Header(i).comm_grp_nkid);


-- W
DBMS_OUTPUT.Put_Line( 'commodity_group.add_commodity(
         id_io=> ret_id,
         comm_group_id_i=> '||recs_CM_Header(i).comm_grp_id||',
         commodity_id_i=> '||recs_CM_Header(1).comm_id||',
         start_date_i=> '||pStart_Date||',
         end_date_i=> '||pEnd_Date||',
         entered_by_i=> '||recs_CM_Header(1).entered_by||',
         p_nkid=> '||recs_CM_Header(i).comm_grp_nkid||');');



         if ret_id<>0 then
           -- log ENTITY_ID comm_group_commodities
           Insert into comm_grp_added_comm_log
           values (process_id, sysdate, ret_id);
           --recs_CM_Header(i).comm_grp_rid);
         end if;
    end loop;
    success_o :=1;
    log_id_o := process_id;
  else
    -- nothing to work with
    -- return 0
    success_o :=0;
    log_id_o :=0;
  end if;

  end add_associated_groups;

*/

    /*
    *  Reset Status
    */
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

        l_stat_cnt NUMBER; -- crapp-2749
    BEGIN
        success_o := 0;
        --Get status to validate that it's a record that can be reset

        SELECT COUNT(status)
        INTO l_stat_cnt
        FROM commodity_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN
            SELECT status
            INTO l_status
            FROM commodity_revisions
            WHERE id = l_rid;

            IF (l_status = 1) THEN
                --genResetStatus(table_list,l_rid,l_reset_by);
                --Reset status
                UPDATE commodity_attributes ja
                SET status = setVal,
                ja.entered_By = l_reset_by
                WHERE ja.rid = l_rid;

                --Reset status
                UPDATE commodities ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                --Reset status
                UPDATE commodity_revisions ji
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
       success_o OUT NUMBER,
       existsInGroups OUT CLOB
       )
       IS
        l_rid NUMBER := revision_id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_juris_pk NUMBER;
        l_status NUMBER;
        l_cit_count number;
        clb_InGroups CLOB := '{}';
        lcnt_taxabilities number := 0;

        l_stat_cnt NUMBER; -- crapp-2749
    BEGIN
      success_o := 0;

      lcnt_taxabilities := cnt_taxabilities_attachehd(l_rid);
      if lcnt_taxabilities > 0
      then
        RAISE errnums.cannot_delete_revision;
      end if;

      -- Does the commodity belong to a group?
     -- clb_InGroups := fCommodityPartOf(l_rid);
      IF (dbms_lob.getlength(clb_InGroups) <= 3) THEN

          if resetAll = 1 then
              SELECT COUNT(status)
              INTO l_stat_cnt
              FROM commodity_revisions
              WHERE id = l_rid;

              IF l_stat_cnt > 0 THEN -- crapp-2749
                  SELECT status
                  INTO l_status
                  FROM commodity_revisions
                  WHERE id = l_rid;

                  IF (l_status = 1) THEN
                    reset_status(revision_id_i=>revision_id_i, reset_by_i=>deleted_by_i, success_o=>success_o);
                  End If; -- status

                  Delete From comm_chg_vlds
                  Where comm_chg_log_id in
                  (Select id From comm_chg_logs
                  Where rid=l_rid);

                  IF SQL%NOTFOUND THEN
                    DBMS_OUTPUT.PUT_LINE('No validations to remove');
                  END IF;
              END IF; -- l_stat_cnt
          end if; -- resetAll

          -- {Get status to validate that it's a deleteable record
          --  Get revision ID to delete all depedent records by }
          SELECT COUNT(status)
          INTO l_stat_cnt
          FROM commodity_revisions
          WHERE id = l_rid;

          IF l_stat_cnt > 0 THEN -- crapp-2749
            SELECT status
            INTO l_status
            FROM commodity_revisions
            where id = l_rid;

              IF (l_status = 0) THEN
                --Remove dependent attributes and reset prior revisions to current
                UPDATE commodity_attributes ja
                SET ja.next_rid = NULL
                WHERE ja.next_rid = l_rid;

                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'COMMODITY_ATTRIBUTES', ja.id
                    FROM commodity_attributes ja
                    WHERE ja.rid = l_rid
                );

                DELETE FROM commodity_attributes ja
                WHERE ja.rid = l_rid;

                UPDATE commodities ji
                SET ji.next_rid = NULL
                WHERE ji.next_rid = l_rid;

                UPDATE commodity_revisions ji
                SET ji.next_rid = NULL
                WHERE ji.next_rid = l_rid;

                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'COMMODITIES', ja.id
                    FROM commodities ja
                    WHERE ja.rid = l_rid
                );

                DELETE FROM commodities ji WHERE ji.rid = l_rid;

                if resetAll = 1 then
                  -- Simple count instead of Exception
                  Select count(*) INTO l_cit_count
                    From comm_chg_cits cit where cit.comm_chg_log_id
                    IN (Select id From comm_chg_logs jc where jc.rid = l_rid);

                  If l_cit_count > 0 Then
                     DELETE FROM comm_chg_cits cit where cit.comm_chg_log_id
                         IN (Select id From comm_chg_logs jc where jc.rid = l_rid);
                  End if;
                end if;

                --Remove Revision record
                INSERT INTO tmp_delete (table_name, primary_key) VALUES ('COMMODITY_REVISIONS',l_rid);
                DELETE FROM comm_chg_logs jc WHERE jc.rid = l_rid;
                DELETE FROM commodity_revisions jr WHERE jr.id = l_rid;

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
            RAISE errnums.cannot_delete_record;
          END IF;
        ELSE
            success_o := 1; -- returning success since there was nothing to remove
        END IF; -- l_stat_cnt

    EXCEPTION
        WHEN errnums.cannot_delete_revision THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_go(errnums.en_cannot_delete_revision,'Commodity revision has been linked to taxabilities. hence it can not be deleted.');
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_go(errnums.en_cannot_delete_record,'Record could not be deleted because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END delete_revision; -- Overloaded 1

END COMMODITY;
/