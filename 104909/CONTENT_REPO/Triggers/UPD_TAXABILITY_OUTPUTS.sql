CREATE OR REPLACE TRIGGER content_repo.UPD_TAXABILITY_OUTPUTS
 FOR 
 UPDATE
 ON content_repo.TAXABILITY_OUTPUTS
 REFERENCING OLD AS OLD NEW AS NEW
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF taxability_outputs%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new taxability_outputs%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.
        IF updating('SHORT_TEXT') AND :new.SHORT_TEXT != :old.SHORT_TEXT THEN
            l_new.SHORT_TEXT := :NEW.SHORT_TEXT;
            l_changed := TRUE;
        ELSE
            l_new.SHORT_TEXT := :OLD.SHORT_TEXT;
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

        l_new.nkid := :OLD.nkid;
        l_new.JURIS_TAX_APPLICABILITY_ID := :OLD.JURIS_TAX_APPLICABILITY_ID;
        l_new.JURIS_TAX_APPLICABILITY_NKID := :OLD.JURIS_TAX_APPLICABILITY_NKID;
        l_new.TAX_APPLICABILITY_TAX_ID := :OLD.TAX_APPLICABILITY_TAX_ID;
        l_new.TAX_APPLICABILITY_TAX_NKID := :OLD.TAX_APPLICABILITY_TAX_NKID;

       -- Changes for CRAPP-2682. This should be changed for future jira CRAPP-2688
      if :OLD.TAX_APPLICABILITY_TAX_NKID is not null
      then
        SELECT id
          INTO l_new.tax_applicability_tax_id
          FROM tax_applicability_taxes
         WHERE nkid = :old.tax_applicability_tax_nkid AND next_rid IS NULL;
      end if;

        l_new.entered_by := :NEW.entered_by;
        IF NOT l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSIF l_changed THEN
            IF (:new.JURIS_TAX_APPLICABILITY_NKID != :old.JURIS_TAX_APPLICABILITY_NKID) THEN
                RAISE errnums.cannot_update_record;
            END IF;
            --get current pending revision
            l_new.rid := tax_applicability.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update (reset :NEW values) but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_TAXABILITY_OUTPUTS.nextval;
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.JURIS_TAX_APPLICABILITY_ID := :OLD.JURIS_TAX_APPLICABILITY_ID;
                :NEW.JURIS_TAX_APPLICABILITY_NKID := :OLD.JURIS_TAX_APPLICABILITY_NKID;
                :NEW.TAX_APPLICABILITY_TAX_ID := :OLD.TAX_APPLICABILITY_TAX_ID;
                :NEW.TAX_APPLICABILITY_TAX_NKID := :OLD.TAX_APPLICABILITY_TAX_NKID;
                :NEW.START_DATE := :OLD.START_DATE;
                :NEW.END_DATE := :OLD.END_DATE;

                :NEW.short_text := :OLD.short_text;
                :NEW.rid := :OLD.rid;
                :NEW.nkid := :OLD.nkid;
                :NEW.next_rid := l_new.rid; --point the next_rid to the new revision
                :NEW.status := :OLD.status;
                :NEW.entered_by := :OLD.entered_by;
                :NEW.entered_date := :OLD.entered_date;
                :NEW.status_modified_date := :OLD.status_modified_date;
            ELSE
                :new.short_text := fnnlsconvert(pfield=>:new.short_text);
                :new.full_text := fnnlsconvert(pfield=>:new.full_text);

                UPDATE juris_tax_app_chg_logs
                SET entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'TAXABILITY_OUTPUTS'
                AND primary_key = :old.id;

                UPDATE admin_qr
                SET qr = :NEW.short_text, entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'TAXABILITY_OUTPUTS'
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
            INSERT INTO taxability_outputs (
                ID,
                juris_tax_applicability_id,
                juris_tax_applicability_nkid,
                short_text,
                rid,
                nkid,
                entered_by,
                tax_applicability_tax_id,
                tax_applicability_tax_nkid,
                start_date,
                end_date
                )
            VALUES (
                pending_changes(r).ID,
                pending_changes(r).juris_tax_applicability_id,
                pending_changes(r).juris_tax_applicability_nkid,
                pending_changes(r).short_text,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).entered_by,
                pending_changes(r).tax_applicability_tax_id,
                pending_changes(r).tax_applicability_tax_nkid,
                pending_changes(r).start_date,
                pending_changes(r).end_date
               );
            END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END upd_taxability_outputs;
/