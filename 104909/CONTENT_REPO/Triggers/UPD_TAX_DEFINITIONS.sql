CREATE OR REPLACE TRIGGER content_repo.upd_tax_definitions
 FOR
  UPDATE
 ON content_repo.tax_definitions
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF TAX_DEFINITIONS%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new TAX_DEFINITIONS%ROWTYPE;
        --l_pci NUMBER;
        l_changed BOOLEAN := FALSE; -- Changes for CRAPP-3538
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.
        IF updating('MIN_THRESHOLD') AND :new.MIN_THRESHOLD != :old.MIN_THRESHOLD  THEN
            l_new.MIN_THRESHOLD := :NEW.MIN_THRESHOLD;
            l_changed := TRUE;
        ELSE
            l_new.MIN_THRESHOLD := :OLD.MIN_THRESHOLD;
        END IF;
        IF updating('MAX_LIMIT') AND :new.MAX_LIMIT != :old.MAX_LIMIT THEN
            l_new.MAX_LIMIT := :NEW.MAX_LIMIT;
            l_changed := TRUE;
        ELSE
            l_new.MAX_LIMIT := :OLD.MAX_LIMIT;
        END IF;
        IF updating('VALUE_TYPE') AND :new.VALUE_TYPE != :old.VALUE_TYPE THEN
            l_new.VALUE_TYPE := :NEW.VALUE_TYPE;
            l_changed := TRUE;
        ELSE
            l_new.VALUE_TYPE := :OLD.VALUE_TYPE;
        END IF;
        IF updating('VALUE') AND :new.VALUE != :old.VALUE THEN
            l_new.VALUE := :NEW.VALUE;
            l_changed := TRUE;
        ELSE
            l_new.VALUE := :OLD.VALUE;
        END IF;
        IF updating('DEFER_TO_JURIS_TAX_ID') AND :new.DEFER_TO_JURIS_TAX_ID != :old.DEFER_TO_JURIS_TAX_ID THEN
            l_new.DEFER_TO_JURIS_TAX_ID := :NEW.DEFER_TO_JURIS_TAX_ID;
            l_changed := TRUE;
            IF (:new.defer_to_juris_tax_id IS NOT NULL) THEN
                SELECT NKID
                into l_new.defer_to_juris_Tax_nkid
                from juris_Tax_impositions
                WHERE id = :new.DEFER_TO_JURIS_TAX_ID;
            END IF;
        ELSE
            l_new.DEFER_TO_JURIS_TAX_ID := :OLD.DEFER_TO_JURIS_TAX_ID;
            l_new.DEFER_TO_JURIS_TAX_NKID := :OLD.DEFER_TO_JURIS_TAX_NKID;
        END IF;
        
        -- If block added to fix CRAPP-3790
        if upper(:new.VALUE_TYPE) != 'REFERENCED'
        then
            l_new.DEFER_TO_JURIS_TAX_ID := null;
            l_new.DEFER_TO_JURIS_TAX_NKID := null;
            :new.DEFER_TO_JURIS_TAX_ID := null;
            :new.DEFER_TO_JURIS_TAX_NKID := null;
        end if;
        
        IF updating('CURRENCY_ID') AND nvl(:new.CURRENCY_ID,-1) != nvl(:old.CURRENCY_ID,-1) THEN
            l_new.CURRENCY_ID := :NEW.CURRENCY_ID;
            l_changed := TRUE;
        ELSE
            l_new.CURRENCY_ID := :OLD.CURRENCY_ID;
        END IF;
        l_new.nkid := :OLD.nkid;
        l_new.tax_outline_id := :OLD.tax_outline_id;
        l_new.tax_outline_nkid := :OLD.tax_outline_nkid;
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
            l_new.rid := tax.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_TAX_DEFINITIONS.nextval; --new ID
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.tax_outline_id := :OLD.tax_outline_id;
                :NEW.tax_outline_nkid := :OLD.tax_outline_nkid;
                :NEW.MIN_THRESHOLD := :OLD.MIN_THRESHOLD;
                :NEW.MAX_LIMIT := :OLD.MAX_LIMIT;
                :NEW.VALUE_TYPE := :OLD.VALUE_TYPE;
                :NEW.VALUE := :OLD.VALUE;
                :NEW.DEFER_TO_JURIS_TAX_ID := :OLD.DEFER_TO_JURIS_TAX_ID;
                :NEW.DEFER_TO_JURIS_TAX_NKID := :OLD.DEFER_TO_JURIS_TAX_NKID;
                :NEW.CURRENCY_ID := :OLD.CURRENCY_ID;
                :NEW.rid := :OLD.rid;
                :NEW.nkid := :OLD.nkid;
                :NEW.next_rid := l_new.rid; --point the next_rid to the new revision
                :NEW.status := :OLD.status;
                :NEW.entered_by := :OLD.entered_by;
                :NEW.entered_date := :OLD.entered_date;
                :NEW.status_modified_date := :OLD.status_modified_date;
            ELSE
                UPDATE juris_tax_chg_logs
                SET entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'TAX_DEFINITIONS'
                AND primary_key = :old.id;
                UPDATE tax_qr
                SET qr = nvl(to_char(:new.value),'...')||' '||:NEW.value_type, entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'TAX_DEFINITIONS'
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
            INSERT INTO TAX_DEFINITIONS (
                id,
                tax_outline_id,
                tax_outline_nkid,
                MIN_THRESHOLD,
                MAX_LIMIT,
                VALUE_TYPE,
                VALUE,
                DEFER_TO_JURIS_TAX_ID,
                DEFER_TO_JURIS_TAX_NKID,
                CURRENCY_ID,
                rid,
                nkid,
                entered_by
                )
            VALUES (
                 pending_changes(r).id,
                pending_changes(r).tax_outline_id,
                pending_changes(r).tax_outline_nkid,
                pending_changes(r).MIN_THRESHOLD,
                pending_changes(r).MAX_LIMIT,
                pending_changes(r).VALUE_TYPE,
                pending_changes(r).VALUE,
                pending_changes(r).DEFER_TO_JURIS_TAX_ID,
                pending_changes(r).DEFER_TO_JURIS_TAX_NKID,
                pending_changes(r).CURRENCY_ID,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).entered_by
                );
            END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END upd_tax_definitions;
/