CREATE OR REPLACE PACKAGE BODY content_repo."TAX"
IS
FUNCTION get_revision (
    rid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER
IS
        l_new_rid NUMBER;
        l_curr_rid NUMBER;
        l_juris_id NUMBER;
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
            FROM jurisdiction_tax_revisions jr
            WHERE EXISTS (
                SELECT 1
                FROM jurisdiction_tax_revisions jr2
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

            INSERT INTO jurisdiction_tax_revisions(nkid,  entered_by)
            VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
            UPDATE jurisdiction_tax_revisions SET next_rid = l_new_rid WHERE id = l_curr_rid;
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
        l_juris_id NUMBER :=entity_id_io;
        l_nkid NUMBER := entity_nkid_i;
        l_status NUMBER;
        l_curr_rid NUMBER;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN
        --TODO: check for one that already exists
        --check for an existing revision
        IF (l_juris_id IS NOT NULL AND l_nkid IS NOT NULL) THEN
            -- this is just a new Tax
            --let's be sure
            SELECT max(id)
            INTO l_new_rid
            FROM jurisdiction_tax_revisions
            WHERE nkid = l_nkid;
            IF (l_new_rid IS NULL) THEN
                INSERT INTO jurisdiction_tax_revisions(nkid, entered_by)
                VALUES (l_nkid,  entered_by_i) RETURNING id INTO l_new_rid;
            END IF;
        ELSE
            --this is a child record, need to get entity nkid
            SELECT j.nkid
            INTO l_nkid
            FROM juris_tax_impositions j
            WHERE j.id = entity_id_io;
            --now get the current revision
            SELECT jr.id, jr.status, jr.nkid
            INTO l_curr_rid, l_status, l_nkid
            FROM jurisdiction_tax_revisions jr
            WHERE jr.nkid = l_nkid
            AND jr.next_rid IS NULL;
            IF l_status IN (0,1) THEN
                l_new_rid := l_curr_rid;
            ELSE
                INSERT INTO jurisdiction_tax_revisions(nkid, entered_by)
                VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
                UPDATE jurisdiction_tax_revisions SET next_rid = l_new_rid WHERE id = l_curr_rid;
            END IF;
        END IF;
        entity_id_io := l_juris_id;
        retval := l_new_rid;
        RETURN retval;
    END get_revision;

FUNCTION get_revision_taxout (
    entity_id_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER
IS
        l_new_rid NUMBER;
        l_jts_id NUMBER;
        l_nkid NUMBER;
        l_status NUMBER;
        l_curr_rid NUMBER;
        retval NUMBER := -1;
        RETURN NUMBER;
    BEGIN

            --this is a child record, need to get entity nkid
            SELECT jtr.nkid
            INTO l_nkid
            FROM jurisdiction_tax_revisions jtr
            --JOIN juris_tax_impositions jti on (jti.nkid = jtr.nkid)
            JOIN tax_outlines tou on (tou.rid = jtr.id)
            WHERE tou.id = entity_id_i;
            --now get the current revision
            SELECT jr.id, jr.status, jr.nkid
            INTO l_curr_rid, l_status, l_nkid
            FROM jurisdiction_tax_revisions jr
            WHERE jr.nkid = l_nkid
            AND jr.next_rid IS NULL;
            IF l_status IN (0,1) THEN
                l_new_rid := l_curr_rid;
            ELSE
                INSERT INTO jurisdiction_tax_revisions(nkid, entered_by)
                VALUES (l_nkid, entered_by_i) RETURNING id INTO l_new_rid;
                UPDATE jurisdiction_tax_revisions SET next_rid = l_new_rid WHERE id = l_curr_rid;
            END IF;
        retval := l_new_rid;
        RETURN retval;
    END get_revision_taxout;

/** 10/31/2014 Return only the current revision. No insert of new */
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
            FROM jurisdiction_tax_revisions jr
            WHERE EXISTS (
                SELECT 1
                FROM jurisdiction_tax_revisions jr2
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

    PROCEDURE unique_check(juris_nkid_i IN NUMBER, ref_code_i IN VARCHAR2, nkid_i IN NUMBER)
    IS
        l_count number;
    BEGIN
        select count(*)
        INTO l_count
        from juris_tax_impositions
        where reference_code = ref_code_i
        and nkid != nvl(nkid_i,0)
        and abs(status) != 3
        and jurisdiction_nkid = juris_nkid_i;

        IF (l_count > 0) THEN
           raise_application_Error( errnums.en_duplicate_key,'Duplicate error: Reference Code provided already exists for another Tax in this Jurisdiction.');
        END IF;
    END unique_check;
END;
/