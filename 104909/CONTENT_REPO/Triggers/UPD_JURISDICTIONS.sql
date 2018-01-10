CREATE OR REPLACE TRIGGER content_repo.UPD_JURISDICTIONS
 FOR 
 UPDATE
 ON content_repo.JURISDICTIONS
 REFERENCING OLD AS OLD NEW AS NEW
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF jurisdictions%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new jurisdictions%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.
        IF updating('OFFICIAL_NAME') AND :NEW.official_name != :OLD.official_name THEN
            l_new.OFFICIAL_NAME := :NEW.OFFICIAL_NAME;
            l_changed := TRUE;
        ELSE
            l_new.OFFICIAL_NAME := :OLD.OFFICIAL_NAME;
        END IF;
        IF updating('START_DATE') AND NVL(:new.start_date,'31-Dec-9999') !=   NVL(:old.start_date,'31-Dec-9999') THEN
            l_new.START_DATE := :NEW.START_DATE;
            l_changed := TRUE;
        ELSE
            l_new.START_DATE := :OLD.START_DATE;
        END IF;
        IF updating('END_DATE') AND NVL(:new.end_date,'31-Dec-9999')  !=  NVL(:old.end_date,'31-Dec-9999')  THEN
            l_new.END_DATE := :NEW.END_DATE;
            l_changed := TRUE;
        ELSE
            l_new.END_DATE := :OLD.END_DATE;
        END IF;
        IF updating('DESCRIPTION') AND NVL(:new.description,'~~~') !=  NVL(:old.description,'~~~') THEN
            l_new.DESCRIPTION := :NEW.DESCRIPTION;
            l_changed := TRUE;
        ELSE
            l_new.DESCRIPTION := :OLD.DESCRIPTION;
        END IF;
        
        IF updating('JURISDICTION_TYPE_ID') AND NVL(:new.JURISDICTION_TYPE_ID,-999) !=  NVL(:old.JURISDICTION_TYPE_ID,-999) THEN
            l_new.JURISDICTION_TYPE_ID := :NEW.JURISDICTION_TYPE_ID;
            l_changed := TRUE;
        ELSE
            l_new.JURISDICTION_TYPE_ID := :OLD.JURISDICTION_TYPE_ID;
        END IF;
        
        IF updating('CURRENCY_ID') AND :new.currency_id != :old.currency_id THEN
            l_new.CURRENCY_ID := :NEW.CURRENCY_ID;
            l_changed := TRUE;
        ELSE
            l_new.CURRENCY_ID := :OLD.CURRENCY_ID;
        END IF;
        IF updating('GEO_AREA_CATEGORY_ID') AND :new.GEO_AREA_CATEGORY_ID != :old.GEO_AREA_CATEGORY_ID THEN
            l_new.GEO_AREA_CATEGORY_ID := :NEW.GEO_AREA_CATEGORY_ID;
            l_changed := TRUE;
        ELSE
            l_new.GEO_AREA_CATEGORY_ID := :OLD.GEO_AREA_CATEGORY_ID;
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
            l_new.rid := jurisdiction.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id
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
                :NEW.OFFICIAL_NAME := :OLD.OFFICIAL_NAME;
                :NEW.START_DATE := :OLD.START_DATE;
                :NEW.END_DATE := :OLD.END_DATE;
                :NEW.DESCRIPTION := :OLD.DESCRIPTION;
                :NEW.CURRENCY_ID := :OLD.CURRENCY_ID;
                :NEW.GEO_AREA_CATEGORY_ID := :OLD.GEO_AREA_CATEGORY_ID;
                :NEW.rid := :OLD.rid;
                :NEW.nkid := :OLD.nkid;
                :NEW.next_rid := l_new.rid; --point the next_rid to the new revision
                :NEW.status := :OLD.status;
                :NEW.entered_by := :OLD.entered_by;
                :NEW.entered_date := :OLD.entered_date;
                :NEW.status_modified_date := :OLD.status_modified_date;
                :NEW.jurisdiction_type_id := :OLD.jurisdiction_type_id;
                :NEW.jurisdiction_type_nkid := :OLD.jurisdiction_type_nkid;
            ELSE
                :new.official_name := fnnlsconvert(pfield=>:new.official_name);
                :new.description := fnnlsconvert(pfield=>:new.description);
                UPDATE juris_chg_logs
                SET entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'JURISDICTIONS'
                AND primary_key = :old.id;
                UPDATE juris_QR
                SET qr = :new.official_name, entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'JURISDICTIONS'
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
            INSERT INTO jurisdictions (
                ID,
                OFFICIAL_NAME,
                START_DATE,
                END_DATE,
                DESCRIPTION,
                CURRENCY_ID,
                GEO_AREA_CATEGORY_ID,
                rid,
                nkid,
                entered_by,
                jurisdiction_type_id
                )
            VALUES (
                pending_changes(r).ID,
                pending_changes(r).OFFICIAL_NAME,
                pending_changes(r).START_DATE,
                pending_changes(r).END_DATE,
                pending_changes(r).DESCRIPTION,
                pending_changes(r).CURRENCY_ID,
                pending_changes(r).GEO_AREA_CATEGORY_ID,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).entered_by,
                pending_changes(r).jurisdiction_type_id
                );
            END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END upd_jurisdictions;
/