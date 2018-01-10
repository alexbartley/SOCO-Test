CREATE OR REPLACE TRIGGER content_repo."UPD_COMMODITY_ATTRIBUTES"

FOR UPDATE
 ON content_repo.commodity_attributes
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF commodity_attributes%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new commodity_attributes%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record.
        --Also, use flag to indicate whether or not this entity is being modified,
        --we do not want to insert a new record if nothing has changed.
        IF updating('VALUE') AND :new.value != :old.value THEN
            l_new.value := :NEW.value;
            l_changed := TRUE;
        ELSE
            l_new.value := :OLD.value;
        END IF;
        IF updating('START_DATE') AND NVL(:new.start_date,'31-Dec-9999') != NVL(:old.start_date,'31-Dec-9999') THEN
            l_new.start_date := :NEW.start_date;
            l_changed := TRUE;
        ELSE
            l_new.start_date := :OLD.start_date;
        END IF;
        IF updating('END_DATE') AND NVL(:new.end_date,'31-Dec-9999') != NVL(:old.end_date,'31-Dec-9999') THEN
            l_new.end_date := :NEW.end_date;
            l_changed := TRUE;
        ELSE
            l_new.end_date := :OLD.end_date;
        END IF;
        l_new.nkid := :OLD.nkid;
        l_new.commodity_id := :OLD.commodity_id;
        l_new.commodity_nkid := :OLD.commodity_nkid;
        l_new.attribute_id := :OLD.attribute_id;
        l_new.entered_by := :NEW.entered_by;
        IF NOT l_changed AND NVL(:new.status,:old.status) != :old.status THEN
            IF (:new.commodity_id != :old.commodity_id OR :new.attribute_id != :old.attribute_id) THEN
                RAISE errnums.cannot_update_record;
            END IF;
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF NVL(:new.status,:old.status) != :old.status THEN
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSE
            --l_pci := pending_changes.COUNT+1;
            --get current pending revision
            l_new.rid := commodity.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_commodity_attributes.nextval; --new ID
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.commodity_id := :OLD.commodity_id;
                :NEW.commodity_nkid := :OLD.commodity_nkid;
                :NEW.attribute_id := :OLD.attribute_id;
                :NEW.value := :OLD.value;
                :NEW.start_date := :OLD.start_date;
                :NEW.end_date := :OLD.end_date;
                :NEW.rid := :OLD.rid;
                :NEW.nkid := :OLD.nkid;
                :NEW.next_rid := l_new.rid; --point the next_rid to the new revision
                :NEW.status := :OLD.status;
                :NEW.entered_by := :OLD.entered_by;
                :NEW.entered_date := :OLD.entered_date;
                :NEW.status_modified_date := :OLD.status_modified_date;
            ELSE
                UPDATE comm_chg_logs
                SET entered_by = :new.entered_By, entered_date = :new.entered_Date
                WHERE table_name = 'COMMODITY_ATTRIBUTES'
                AND primary_key = :old.id;
                UPDATE comm_QR
                SET qr = to_char(:new.start_date,'MM/DD/YYYY')||'-'||to_char(:new.end_date,'MM/DD/YYYY')||' '||(select name from additional_attributes where id = :new.attribute_id), entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'COMMODITY_ATTRIBUTES'
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
            INSERT INTO commodity_attributes (
                commodity_id,
                commodity_nkid,
                attribute_id,
                value,
                start_date,
                end_date,
                rid,
                nkid,
                entered_by
                )
            VALUES (
                pending_changes(r).commodity_id,
                pending_changes(r).commodity_nkid,
                pending_changes(r).attribute_id,
                pending_changes(r).value,
                pending_changes(r).start_date,
                pending_changes(r).end_date,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).entered_by
                );
            END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END upd_commodity_attributes;
/