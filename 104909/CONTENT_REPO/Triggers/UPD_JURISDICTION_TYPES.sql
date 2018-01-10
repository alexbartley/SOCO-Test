CREATE OR REPLACE TRIGGER content_repo.upd_jurisdiction_types
 FOR
  UPDATE
 ON content_repo.jurisdiction_types
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF jurisdiction_types%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new jurisdiction_types%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        
        IF updating('NAME') AND :NEW.NAME != :OLD.NAME THEN
            l_new.NAME := :NEW.NAME;
            l_changed := TRUE;
        ELSE
            l_new.NAME := :OLD.NAME;
        END IF;
       
        IF updating('DESCRIPTION') AND NVL(:new.description,'~~~') !=  NVL(:old.description,'~~~') THEN
            l_new.DESCRIPTION := :NEW.DESCRIPTION;
            l_changed := TRUE;
        ELSE
            l_new.DESCRIPTION := :OLD.DESCRIPTION;
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
            l_new.rid := jurisdiction_type.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update (reset :NEW values) but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_jurisdictions.nextval;
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.NAME := :OLD.NAME;
                :NEW.DESCRIPTION := :OLD.DESCRIPTION;
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
                UPDATE juris_type_chg_logs
                SET entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'JURISDICTION_TYPES'
                AND primary_key = :old.id;
                UPDATE juris_type_QR
                SET qr = :new.name, entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'JURISDICTION_TYPES'
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
            INSERT INTO jurisdiction_types (
                ID,
                name,
                DESCRIPTION,
                rid,
                nkid,
                entered_by
                )
            VALUES (
                pending_changes(r).ID,
                pending_changes(r).NAME,
                pending_changes(r).DESCRIPTION,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).entered_by
                );
            END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END upd_jurisdiction_types;
/