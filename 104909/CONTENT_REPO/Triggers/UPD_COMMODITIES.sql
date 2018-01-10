CREATE OR REPLACE TRIGGER content_repo.UPD_COMMODITIES
 FOR 
 UPDATE
 ON content_repo.COMMODITIES
 REFERENCING OLD AS OLD NEW AS NEW
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF commodities%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new commodities%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.
        IF updating('NAME') AND :new.name != :old.name THEN
            l_new.name := :new.name;
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
        IF updating('COMMODITY_CODE') AND nvl(:new.commodity_code,'~~~') != nvl(:old.commodity_code,'~~~') THEN
            l_new.commodity_code := :NEW.commodity_code;
            l_changed := TRUE;
        ELSE
            l_new.COMMODITY_CODE := :OLD.COMMODITY_CODE;
        END IF;
        IF updating('DESCRIPTION') AND nvl(:new.description,'~~~') != nvl(:old.description,'~~~') THEN
            l_new.description := :NEW.description;
            l_changed := TRUE;
        ELSE
            l_new.description := :OLD.description;
        END IF;
        IF updating('PRODUCT_TREE_ID') AND :new.PRODUCT_TREE_ID != :old.PRODUCT_TREE_ID THEN
            l_new.PRODUCT_TREE_ID := :NEW.PRODUCT_TREE_ID;
            l_changed := TRUE;
        ELSE
            l_new.PRODUCT_TREE_ID := :OLD.PRODUCT_TREE_ID;
        END IF;
        l_new.nkid := :OLD.nkid;
        l_new.entered_by := :NEW.entered_by;
        --q
        l_new.h_code := :OLD.h_code;

        IF NOT l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSIF l_changed THEN
            --get current pending revision

            l_new.rid := commodity.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id

            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_commodities.nextval; --new ID
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.name := :OLD.name;
                :NEW.product_tree_id := :OLD.product_tree_id;
                :NEW.commodity_code := :OLD.commodity_code;
                -- q
                :NEW.h_code :=l_new.h_code;
                :NEW.description := :OLD.description;
                :NEW.rid := :OLD.rid;
                :NEW.nkid := :OLD.nkid;
                :NEW.next_rid := l_new.rid; --point the next_rid to the new revision
                :NEW.status := :OLD.status;
                :NEW.entered_by := :OLD.entered_by;
                :NEW.entered_date := :OLD.entered_date;
                :NEW.status_modified_date := :OLD.status_modified_date;
            ELSE
              :NEW.name:=fnnlsconvert(pfield=>:NEW.name);
              :NEW.description:=fnnlsconvert(pfield=>:NEW.description);
              
                UPDATE comm_chg_logs
                SET entered_by = :new.entered_By, entered_date = :new.entered_Date
                WHERE table_name = 'COMMODITIES'
                AND primary_key = :old.id;
                UPDATE comm_QR
                SET qr = :new.name||' '||:new.commodity_code, entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'COMMODITIES'
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
            INSERT INTO commodities (
                name,
                description,
                start_date,
                end_date,
                product_tree_id,
                commodity_code,
                h_code,
                rid,
                nkid,
                id,
                entered_by
                )
            VALUES (
                pending_changes(r).name,
                pending_changes(r).description,
                pending_changes(r).start_date,
                pending_changes(r).end_date,
                pending_changes(r).product_tree_id,
                pending_changes(r).commodity_code,
                pending_changes(r).h_code,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).id,
                pending_changes(r).entered_by
                );

          -- Rebuild commodity tree using scheduler
          COMMODITY_TREE_EXEC;

        END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END upd_commodities;
/