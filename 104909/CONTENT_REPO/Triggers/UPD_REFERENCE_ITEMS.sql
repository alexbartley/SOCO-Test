CREATE OR REPLACE TRIGGER content_repo."UPD_REFERENCE_ITEMS"

FOR UPDATE
 ON content_repo.reference_items
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF reference_items%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new reference_items%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.
        IF updating('VALUE') AND :new.VALUE != :old.VALUE THEN
            l_new.VALUE := :NEW.VALUE;
            l_changed := TRUE;
        ELSE
            l_new.VALUE := :OLD.VALUE;
        END IF;
        IF updating('VALUE_TYPE') AND :new.VALUE_TYPE != :old.VALUE_TYPE THEN
            l_new.VALUE_TYPE := :NEW.VALUE_TYPE;
            l_changed := TRUE;
        ELSE
            l_new.VALUE_TYPE := :OLD.VALUE_TYPE;
        END IF;
        IF updating('REF_NKID') AND :new.REF_NKID != :old.REF_NKID THEN
            l_new.REF_NKID := :NEW.REF_NKID;
            l_changed := TRUE;
        ELSE
            l_new.REF_NKID := :OLD.REF_NKID;
        END IF;
        IF updating('START_DATE') AND NVL(:new.start_date,'31-Dec-9999') !=  NVL(:old.start_date,'31-Dec-9999')  THEN
            l_new.START_DATE := :NEW.START_DATE;
            l_changed := TRUE;
        ELSE
            l_new.START_DATE := :OLD.START_DATE;
        END IF;
        IF updating('END_DATE') AND NVL(:new.end_date,'31-Dec-9999') !=  NVL(:old.end_date,'31-Dec-9999') THEN
            l_new.END_DATE := :NEW.END_DATE;
            l_changed := TRUE;
        ELSE
            l_new.END_DATE := :OLD.END_DATE;
        END IF;
        l_new.nkid := :OLD.nkid;
        l_new.entered_by := :NEW.entered_by;
        l_new.reference_group_id := :OLD.reference_group_id;
        l_new.reference_group_nkid := :OLD.reference_group_nkid;
        IF NOT l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSIF l_changed THEN
            --get current pending revision

            l_new.rid := reference_group.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id

            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_reference_items.nextval; --new ID
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.reference_group_id := :OLD.reference_group_id;
                :NEW.reference_group_nkid := :OLD.reference_group_nkid;
                :NEW.start_date := :OLD.start_date;
                :NEW.end_date := :OLD.end_date;
                :NEW.value := :OLD.value;
                :NEW.value_type := :OLD.value_type;
                :NEW.ref_nkid := :OLD.ref_nkid;
                :NEW.rid := :OLD.rid;
                :NEW.nkid := :OLD.nkid;
                :NEW.next_rid := l_new.rid; --point the next_rid to the new revision
                :NEW.status := :OLD.status;
                :NEW.entered_by := :OLD.entered_by;
                :NEW.entered_date := :OLD.entered_date;
                :NEW.status_modified_date := :OLD.status_modified_date;
            ELSE
                UPDATE ref_grp_chg_logs
                SET entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'REFERENCE_ITEMS'
                AND primary_key = :old.id;
                UPDATE REF_GRP_QR
                SET qr = :new.value, entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'REFERENCE_ITEMS'
                AND ref_id = :old.id;
            END IF;
        END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        l_pcc NUMBER := pending_changes.COUNT;
    BEGIN
        IF l_pcc > 0 THEN
        FORALL r in 1 .. l_pcc
            INSERT INTO reference_items (
                reference_group_id,
                reference_group_nkid,
                value,
                value_type,
                ref_nkid,
                start_date,
                end_date,
                rid,
                nkid,
                id,
                entered_by
                )
            VALUES (
                pending_changes(r).reference_group_id,
                pending_changes(r).reference_group_nkid,
                pending_changes(r).value,
                pending_changes(r).value_type,
                pending_changes(r).ref_nkid,
                pending_changes(r).start_date,
                pending_changes(r).end_date,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).id,
                pending_changes(r).entered_by
                );
            END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END upd_reference_items;
/