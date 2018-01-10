CREATE OR REPLACE TRIGGER content_repo.UPD_ADMINISTRATORS
 FOR 
 UPDATE
 ON content_repo.ADMINISTRATORS
 REFERENCING OLD AS OLD NEW AS NEW
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF administrators%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new administrators%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.
        IF updating('NAME') AND :new.name != :old.name THEN
            l_new.name := :NEW.name;
            l_changed := TRUE;
        ELSE
            l_new.name := :OLD.name;
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
        IF updating('COLLECTS_TAX') AND :new.collects_tax != :old.collects_tax  THEN
            l_new.collects_tax := :NEW.collects_tax;
            l_changed := TRUE;
        ELSE
            l_new.collects_tax := :OLD.collects_tax;
        END IF;
        IF updating('REQUIRES_REGISTRATION') AND :new.requires_registration != :old.requires_registration THEN
            l_new.requires_registration := :NEW.requires_registration;
            l_changed := TRUE;
        ELSE
            l_new.requires_registration := :OLD.requires_registration;
        END IF;
        IF updating('ADMINISTRATOR_TYPE_ID') AND :new.administrator_type_id != :old.administrator_type_id THEN
            l_new.administrator_type_id := :NEW.administrator_type_id;
            l_changed := TRUE;
        ELSE
            l_new.administrator_type_id := :OLD.administrator_type_id;
        END IF;
        IF updating('DESCRIPTION') AND nvl(:new.description,'~~~') != nvl(:old.description,'~~~') THEN
            l_new.description := :NEW.description;
            l_changed := TRUE;
        ELSE
            l_new.description := :OLD.description;
        END IF;
        l_new.nkid := :OLD.nkid;
        l_new.entered_by := :NEW.entered_by;

        IF NOT l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSIF l_changed THEN
            --get current pending revision

            l_new.rid := administrator.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id

            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_Administrators.nextval; --new ID
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.name := :OLD.name;
                :NEW.collects_tax := :OLD.collects_tax;
                :NEW.requires_registration := :OLD.requires_registration;
                :NEW.administrator_type_id := :OLD.administrator_type_id;
                :NEW.description := :OLD.description;
                :NEW.start_date := :OLD.start_date;
                :NEW.end_Date := :OLD.end_Date;
                :NEW.rid := :OLD.rid;
                :NEW.nkid := :OLD.nkid;
                :NEW.next_rid := l_new.rid; --point the next_rid to the new revision
                :NEW.status := :OLD.status;
                :NEW.entered_by := :OLD.entered_by;
                :NEW.entered_date := :OLD.entered_date;
                :NEW.status_modified_date := :OLD.status_modified_date;
            ELSE
                :new.name := fnnlsconvert(pfield=>:new.name);
                :new.description := fnnlsconvert(pfield=>:new.description);
                update admin_chg_logs
                SET entered_by = :new.entered_By, entered_date = :new.entered_Date
                WHERE table_name = 'ADMINISTRATORS'
                AND primary_key = :old.id;
                UPDATE admin_QR
                SET qr = :new.name, entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'ADMINISTRATORS'
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
        FOR r in 1 .. l_pcc LOOP
            INSERT INTO administrators (
                name,
                collects_tax,
                requires_registration,
                administrator_type_id,
                start_date,
                end_date,
                description,
                rid,
                nkid,
                id,
                entered_by
                )
            VALUES (
                pending_changes(r).name,
                pending_changes(r).collects_tax,
                pending_changes(r).requires_registration,
                pending_changes(r).administrator_type_id,
                pending_changes(r).start_date,
                pending_changes(r).end_date,
                pending_changes(r).description,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).id,
                pending_changes(r).entered_by
                );
            END LOOP;
        END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END upd_administrators;
/