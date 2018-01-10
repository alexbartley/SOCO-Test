CREATE OR REPLACE TRIGGER content_repo."UPD_TAX_OUTLINES"

FOR UPDATE
 ON content_repo.tax_outlines
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF TAX_OUTLINES%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new TAX_OUTLINES%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.
        IF updating('CALCULATION_STRUCTURE_ID') AND :new.CALCULATION_STRUCTURE_ID !=  :old.CALCULATION_STRUCTURE_ID THEN
            l_new.CALCULATION_STRUCTURE_ID := :NEW.CALCULATION_STRUCTURE_ID;
            l_changed := TRUE;
        ELSE
            l_new.CALCULATION_STRUCTURE_ID := :OLD.CALCULATION_STRUCTURE_ID;
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
        l_new.JURIS_TAX_IMPOSITION_ID := :OLD.JURIS_TAX_IMPOSITION_ID;
        l_new.JURIS_TAX_IMPOSITION_NKID := :OLD.JURIS_TAX_IMPOSITION_NKID;
        l_new.entered_by := :NEW.entered_by;
        IF NOT l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSIF l_changed THEN
            IF (:new.juris_tax_imposition_id != :old.juris_tax_imposition_id
                ) THEN
                RAISE errnums.cannot_update_record;
            END IF;
            --get current pending revision
            l_new.rid := tax.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update (reset :NEW values) but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_TAX_OUTLINES.nextval;
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.calculation_structure_id := :OLD.calculation_structure_id;
                :NEW.juris_Tax_imposition_id := :OLD.juris_Tax_imposition_id;
                :NEW.juris_Tax_imposition_nkid := :OLD.juris_Tax_imposition_nkid;
                :NEW.START_DATE := :OLD.START_DATE;
                :NEW.END_DATE := :OLD.END_DATE;
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
                WHERE table_name = 'TAX_OUTLINES'
                AND primary_key = :old.id;

                UPDATE tax_qr
                SET qr = to_char(:new.start_date,'MM/DD/YYYY')||'-'||to_char(:new.end_date,'MM/DD/YYYY')||' '||
                    (select tax_structure||' '||amount_type from vtax_calc_structures where id = :new.calculation_structure_id),
                    entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'TAX_OUTLINES'
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
            INSERT INTO TAX_OUTLINES (
                ID,
                JURIS_TAX_IMPOSITION_ID,
                JURIS_TAX_IMPOSITION_NKID,
                START_DATE,
                END_DATE,
                calculation_structure_id,
                rid,
                nkid,
                entered_by
                )
            VALUES (
                pending_changes(r).ID,
                pending_changes(r).JURIS_TAX_IMPOSITION_ID,
                pending_changes(r).JURIS_TAX_IMPOSITION_NKID,
                pending_changes(r).START_DATE,
                pending_changes(r).END_DATE,
                pending_changes(r).calculation_structure_id,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).entered_by
                );
            END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END UPD_TAX_OUTLINES;
/