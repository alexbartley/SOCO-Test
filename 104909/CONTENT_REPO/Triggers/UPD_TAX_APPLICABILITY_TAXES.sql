CREATE OR REPLACE TRIGGER content_repo."UPD_TAX_APPLICABILITY_TAXES"
 FOR
  UPDATE
 ON content_repo.tax_applicability_taxes
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER
 TYPE mod_records IS TABLE OF Tax_applicability_taxes%ROWTYPE;
 pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new Tax_applicability_taxes%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.

        /*
        IF updating('JURIS_TAX_IMPOSITION_ID') AND nvl(:new.JURIS_TAX_IMPOSITION_ID,-1) !=  nvl(:old.JURIS_TAX_IMPOSITION_ID,-1) THEN
            l_new.JURIS_TAX_IMPOSITION_ID := :NEW.JURIS_TAX_IMPOSITION_ID;
            l_changed := TRUE;
        ELSE
            l_new.JURIS_TAX_IMPOSITION_ID := :OLD.JURIS_TAX_IMPOSITION_ID;
        END IF;
        */

        IF updating('REF_RULE_ORDER') AND NVL(:new.REF_RULE_ORDER,-999) != NVL(:old.REF_RULE_ORDER, -999) THEN
            l_new.REF_RULE_ORDER := :NEW.REF_RULE_ORDER;
            l_changed := TRUE;
        ELSE
            l_new.REF_RULE_ORDER := :OLD.REF_RULE_ORDER;
        END IF;

        IF updating('START_DATE') AND NVL(:new.start_date,'31-Dec-9999') != NVL(:old.start_date,'31-Dec-9999') THEN
            l_new.START_DATE := :NEW.START_DATE;
            l_changed := TRUE;
        ELSE
            l_new.START_DATE := :OLD.START_DATE;
        END IF;

        IF updating('END_DATE') AND NVL(:new.end_date,'31-Dec-9999') != NVL(:old.end_date,'31-Dec-9999') THEN
            l_new.END_DATE := :NEW.END_DATE;
            l_changed := TRUE;
        ELSE
            l_new.END_DATE := :OLD.END_DATE;
        END IF;

		/*
        IF updating('TAX_TYPE') AND NVL(:new.TAX_TYPE,'xx') != NVL(:old.TAX_TYPE, 'xx') THEN
            l_new.TAX_TYPE := :NEW.TAX_TYPE;
            l_changed := TRUE;
        ELSE
            l_new.TAX_TYPE := :OLD.TAX_TYPE;
        END IF;
		*/

		 IF updating('TAX_TYPE_ID') AND NVL(:new.TAX_TYPE_ID,-999) != NVL(:old.TAX_TYPE_ID, -999) THEN
            l_new.TAX_TYPE_ID := :NEW.TAX_TYPE_ID;
            l_changed := TRUE;
        ELSE
            l_new.TAX_TYPE_ID := :OLD.TAX_TYPE_ID;
        END IF;

        l_new.nkid := :OLD.nkid;
        l_new.juris_tax_applicability_id := :OLD.juris_tax_applicability_id;
        l_new.juris_tax_applicability_nkid := :OLD.juris_tax_applicability_nkid;
        l_new.juris_tax_imposition_id := :OLD.juris_tax_imposition_id;
        l_new.juris_tax_imposition_nkid := :OLD.juris_tax_imposition_nkid;
        l_new.entered_by := :NEW.entered_by;

        IF NOT l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSIF l_changed THEN
            --get current pending revision
            l_new.rid := tax_applicability.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update (reset :NEW values) but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_tax_applicability_taxes.nextval;
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.JURIS_TAX_IMPOSITION_ID := :OLD.JURIS_TAX_IMPOSITION_ID;
                :NEW.JURIS_TAX_APPLICABILITY_ID := :OLD.JURIS_TAX_APPLICABILITY_ID;
                :NEW.JURIS_TAX_IMPOSITION_NKID := :OLD.JURIS_TAX_IMPOSITION_NKID;
                :NEW.JURIS_TAX_APPLICABILITY_NKID := :OLD.JURIS_TAX_APPLICABILITY_NKID;
                :NEW.REF_RULE_ORDER := :OLD.REF_RULE_ORDER;
                --:NEW.TAX_TYPE := :OLD.TAX_TYPE;
				:NEW.TAX_TYPE_ID := :OLD.TAX_TYPE_ID;
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
                UPDATE juris_tax_app_chg_logs
                SET entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'TAX_APPLICABILITY_TAXES'
                AND primary_key = :old.id;

                UPDATE juris_tax_app_qr
                SET qr = (select jti.reference_code from juris_tax_impositions jti where jti.id = :new.juris_tax_imposition_id), entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'TAX_APPLICABILITY_TAXES'
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
            INSERT INTO Tax_applicability_taxes (
                ID,
                JURIS_TAX_IMPOSITION_ID,
                JURIS_TAX_APPLICABILITY_ID,
                JURIS_TAX_IMPOSITION_NKID,
                JURIS_TAX_APPLICABILITY_NKID,
                REF_RULE_ORDER,
                --TAX_TYPE,
				TAX_TYPE_ID,
                START_DATE,
                END_DATE,
                rid,
                nkid,
                entered_by
                )
            VALUES (
                pending_changes(r).ID,
                pending_changes(r).JURIS_TAX_IMPOSITION_ID,
                pending_changes(r).JURIS_TAX_APPLICABILITY_ID,
                pending_changes(r).JURIS_TAX_IMPOSITION_NKID,
                pending_changes(r).JURIS_TAX_APPLICABILITY_NKID,
                pending_changes(r).REF_RULE_ORDER,
                --pending_changes(r).TAX_TYPE,
				pending_changes(r).TAX_TYPE_ID,
                pending_changes(r).START_DATE,
                pending_changes(r).END_DATE,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).entered_by
                );
            END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END UPD_Tax_applicability_taxes;
/