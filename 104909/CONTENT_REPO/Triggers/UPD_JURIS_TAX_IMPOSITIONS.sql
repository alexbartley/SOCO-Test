CREATE OR REPLACE TRIGGER content_repo."UPD_JURIS_TAX_IMPOSITIONS" FOR UPDATE ON content_repo.juris_tax_impositions REFERENCING
NEW AS NEW OLD AS OLD COMPOUND TRIGGER TYPE mod_records
IS
    TABLE OF JURIS_TAX_IMPOSITIONS%ROWTYPE;
pending_changes mod_records := mod_records();
--collection of record updates in this transaction
BEFORE EACH ROW
IS
    l_new JURIS_TAX_IMPOSITIONS%ROWTYPE;
l_changed BOOLEAN := FALSE;
BEGIN
    --check the entity fields for modification:
    --if a field was not modified, preserve the original value in the new record
    --Also, use flag to indicate whether or not this entity is being modified.
    IF updating('REFERENCE_CODE')
        AND
        :new.REFERENCE_CODE != :old.REFERENCE_CODE THEN
        l_new.REFERENCE_CODE := :NEW.REFERENCE_CODE;
l_changed := TRUE;
ELSE
    l_new.REFERENCE_CODE := :OLD.REFERENCE_CODE;
END IF;
IF updating('START_DATE')
    AND
    NVL(:new.start_date,'31-Dec-9999') != NVL(:old.start_date,'31-Dec-9999') THEN
    l_new.START_DATE := :NEW.START_DATE;
l_changed := TRUE;
ELSE
    l_new.START_DATE := :OLD.START_DATE;
END IF;
IF updating('END_DATE')
    AND
    NVL(:new.end_date,'31-Dec-9999') != NVL(:old.end_date,'31-Dec-9999') THEN
    l_new.END_DATE := :NEW.END_DATE;
l_changed := TRUE;
ELSE
    l_new.END_DATE := :OLD.END_DATE;
END IF;
IF updating('DESCRIPTION')
    AND
    NVL(:new.DESCRIPTION,'~~~') != NVL(:old.DESCRIPTION,'~~~') THEN
    l_new.DESCRIPTION := :NEW.DESCRIPTION;
l_changed := TRUE;
ELSE
    l_new.DESCRIPTION := :OLD.DESCRIPTION;
END IF;
IF updating('REVENUE_PURPOSE_ID')
    AND
    NVL(:new.REVENUE_PURPOSE_ID,-1) != NVL(:old.REVENUE_PURPOSE_ID,-1) THEN
    l_new.REVENUE_PURPOSE_ID := :NEW.REVENUE_PURPOSE_ID;
l_changed := TRUE;
ELSE
    l_new.REVENUE_PURPOSE_ID := :OLD.REVENUE_PURPOSE_ID;
END IF;
l_new.nkid := :OLD.nkid;
l_new.jurisdiction_id := :OLD.jurisdiction_id;
l_new.jurisdiction_nkid := :OLD.jurisdiction_nkid;
l_new.tax_description_id := :OLD.tax_description_id;
l_new.entered_by := :NEW.entered_by;
IF NOT l_changed
    AND
    (
        UPDATING('STATUS')
        OR
        UPDATING('NEXT_RID')
    )
    THEN
    --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By
    -- be changed)
    :new.status_modified_date := SYSTIMESTAMP;
ELSIF l_changed
    AND
    (
        UPDATING('STATUS')
        OR
        UPDATING('NEXT_RID')
    )
    THEN
    --if it has changed and the status has also changed, raise error, record and status cannot be
    -- modified at the same time
    RAISE errnums.cannot_update_record;
ELSIF l_changed THEN
    /*            IF (:new.jurisdiction_id != :old.jurisdiction_id
    OR :new.tax_description_id != :old.tax_description_id
    --OR :new.reference_code != :old.reference_code
    ) THEN
    RAISE errnums.cannot_update_record;
    END IF;
    */
    --get current pending revision
    l_new.rid := tax.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by);
--assign to new or current revision id
--regardless of updating or inserting, record gets a new timestamp
:NEW.entered_date := SYSTIMESTAMP;
--If a new revision id was created,
--abort the update (reset :NEW values) but preserve the new values to be inserted as a new record
IF (l_new.rid != :old.rid) THEN
    --add the new values to pending_changes
    l_new.id := pk_juris_tax_impositions.nextval;
l_new.next_rid := NULL;
--not assigned for new records
l_new.status := NULL;
--let insert trigger or default handle status
pending_changes.extend;
pending_changes(pending_changes.last) := l_new;
--reset the values, except next_rid
:NEW.id := :OLD.id;
:NEW.JURISDICTION_ID := :OLD.JURISDICTION_ID;
:NEW.JURISDICTION_NKID := :OLD.JURISDICTION_NKID;
:NEW.TAX_DESCRIPTION_ID := :OLD.TAX_DESCRIPTION_ID;
:NEW.REFERENCE_CODE := :OLD.REFERENCE_CODE;
:NEW.START_DATE := :OLD.START_DATE;
:NEW.END_DATE := :OLD.END_DATE;
:NEW.DESCRIPTION := :OLD.DESCRIPTION;
:NEW.REVENUE_PURPOSE_ID := :OLD.REVENUE_PURPOSE_ID;
:NEW.rid := :OLD.rid;
:NEW.nkid := :OLD.nkid;
:NEW.next_rid := l_new.rid;
--point the next_rid to the new revision
:NEW.status := :OLD.status;
:NEW.entered_by := :OLD.entered_by;
:NEW.entered_date := :OLD.entered_date;
:NEW.status_modified_date := :OLD.status_modified_date;
ELSE
    UPDATE
        juris_tax_chg_logs
    SET
        entered_by = :new.entered_by,
        entered_date = :new.entered_Date
    WHERE
        table_name = 'JURIS_TAX_IMPOSITIONS'
    AND primary_key = :old.id;
UPDATE
    tax_QR
SET
    qr = :new.reference_code,
    entered_by = :new.entered_by,
    entered_date = :new.entered_Date
WHERE
    table_name = 'JURIS_TAX_IMPOSITIONS'
AND ref_id = :old.id;
END IF;
END IF;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END BEFORE EACH ROW;
AFTER STATEMENT
IS
    l_pcc NUMBER := pending_changes.COUNT;
BEGIN
    IF l_pcc > 0 THEN
        FORALL r IN 1 .. l_pcc
        INSERT
        INTO
            JURIS_TAX_IMPOSITIONS
            (
                ID,
                JURISDICTION_ID,
                JURISDICTION_NKID,
                TAX_DESCRIPTION_ID,
                REFERENCE_CODE,
                revenue_purpose_id,
                START_DATE,
                END_DATE,
                DESCRIPTION,
                rid,
                nkid,
                entered_by
            )
            VALUES
            (
                pending_changes(r).ID,
                pending_changes(r).JURISDICTION_ID,
                pending_changes(r).JURISDICTION_NKID,
                pending_changes(r).TAX_DESCRIPTION_ID,
                pending_changes(r).REFERENCE_CODE,
                pending_changes(r).revenue_purpose_id,
                pending_changes(r).START_DATE,
                pending_changes(r).END_DATE,
                pending_changes(r).DESCRIPTION,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).entered_by
            );
END IF;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END AFTER STATEMENT;
END UPD_JURIS_TAX_IMPOSITIONS;
/