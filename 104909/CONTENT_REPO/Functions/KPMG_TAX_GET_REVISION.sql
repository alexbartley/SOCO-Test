CREATE OR REPLACE FUNCTION content_repo."KPMG_TAX_GET_REVISION" (
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
    END kpmg_tax_get_revision;
 
/