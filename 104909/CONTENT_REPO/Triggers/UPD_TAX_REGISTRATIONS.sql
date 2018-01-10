CREATE OR REPLACE TRIGGER content_repo.upd_tax_registrations
 FOR
  UPDATE
 ON content_repo.tax_registrations
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF TAX_REGISTRATIONS%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new TAX_REGISTRATIONS%ROWTYPE;
        --l_pci NUMBER;
        l_changed BOOLEAN := FALSE; -- Changes for CRAPP-3538
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.

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
        IF updating('REGISTRATION_MASK') AND :new.REGISTRATION_MASK != :old.REGISTRATION_MASK THEN
            l_new.REGISTRATION_MASK := :NEW.REGISTRATION_MASK;
            l_changed := TRUE;
        ELSE
            l_new.REGISTRATION_MASK := :OLD.REGISTRATION_MASK;
        END IF;
        l_new.nkid := :OLD.nkid;
        l_new.administrator_id := :OLD.administrator_id;
        l_new.administrator_nkid := :OLD.administrator_nkid;
        l_new.entered_by := :NEW.entered_by;
        IF NOT l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSIF l_changed THEN
            --l_pci := pending_changes.COUNT+1;
            --get current pending revision
            l_new.rid := ADMINISTRATOR.get_revision(rid_i => :old.rid,entered_by_i =>  l_new.entered_by); --assign to new or current revision id
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_TAX_REGISTRATIONS.nextval; --new ID
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.ADMINISTRATOR_ID := :OLD.ADMINISTRATOR_ID;
                :NEW.ADMINISTRATOR_NKID := :OLD.ADMINISTRATOR_NKID;
                :NEW.START_DATE := :OLD.START_DATE;
                :NEW.END_DATE := :OLD.END_DATE;
                :NEW.REGISTRATION_MASK := :OLD.REGISTRATION_MASK;
                :NEW.rid := :OLD.rid;
                :NEW.nkid := :OLD.nkid;
                :NEW.next_rid := l_new.rid; --point the next_rid to the new revision
                :NEW.status := :OLD.status;
                :NEW.entered_by := :OLD.entered_by;
                :NEW.entered_date := :OLD.entered_date;
                :NEW.status_modified_date := :OLD.status_modified_date;
            ELSE
                update admin_chg_logs
                SET entered_by = :new.entered_By, entered_date = :new.entered_Date
                WHERE table_name = 'TAX_REGISTRATIONS'
                AND primary_key = :old.id;
                UPDATE admin_qr
                SET qr = :NEW.REGISTRATION_MASK, entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'TAX_REGISTRATIONS'
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
            INSERT INTO TAX_REGISTRATIONS (
                ADMINISTRATOR_ID,
                ADMINISTRATOR_NKID,
                START_DATE,
                END_DATE,
                REGISTRATION_MASK,
                id,
                rid,
                nkid,
                entered_by
                )
            VALUES (
                pending_changes(r).ADMINISTRATOR_ID,
                pending_changes(r).ADMINISTRATOR_NKID,
                pending_changes(r).START_DATE,
                pending_changes(r).END_DATE,
                pending_changes(r).REGISTRATION_MASK,
                pending_changes(r).id,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).entered_by
                );
            END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END upd_TAX_REGISTRATIONS;
/