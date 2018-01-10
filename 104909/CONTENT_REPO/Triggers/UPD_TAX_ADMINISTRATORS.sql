CREATE OR REPLACE TRIGGER content_repo."UPD_TAX_ADMINISTRATORS"
FOR UPDATE
 ON content_repo.tax_administrators
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF tax_administrators%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new tax_administrators%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.
        IF updating('COLLECTOR_ID') AND NVL(:new.COLLECTOR_ID,-100) != NVL(:old.COLLECTOR_ID,-100) THEN
            l_new.COLLECTOR_ID := :NEW.COLLECTOR_ID;
            l_changed := TRUE;
			IF (:NEW.collector_id IS NOT NULL) THEN
				SELECT nkid
				into l_new.collector_nkid
				from administrators
				where id = :new.collector_id;
			END IF;
        ELSE
            l_new.COLLECTOR_ID := :OLD.COLLECTOR_ID;
            l_new.COLLECTOR_NKID := :OLD.COLLECTOR_NKID;
        END IF;
        IF updating('ADMINISTRATOR_ID') AND NVL(:new.ADMINISTRATOR_ID,-100) != :old.ADMINISTRATOR_ID  THEN
            l_new.ADMINISTRATOR_ID := :NEW.ADMINISTRATOR_ID;
            l_changed := TRUE;
            SELECT nkid
            into l_new.administrator_nkid
            from administrators
            where id = :new.ADMINISTRATOR_ID;
        ELSE
            l_new.ADMINISTRATOR_ID := :OLD.ADMINISTRATOR_ID;
            l_new.ADMINISTRATOR_NKID := :OLD.ADMINISTRATOR_NKID;
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
        ELSIF l_changed THEN --this fixed it 09/12/2013 12:00PM
            --l_pci := pending_changes.COUNT+1;
            --get current pending revision
            l_new.rid := tax.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_tax_Administrators.nextval; --new ID
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.start_date := :OLD.start_date;
                :NEW.end_date := :OLD.end_date;
                :NEW.administrator_id := :OLD.administrator_id;
                :NEW.collector_id := :OLD.collector_id;
                 :NEW.juris_tax_imposition_id := :OLD.juris_tax_imposition_id;
                :NEW.administrator_nkid := :OLD.administrator_nkid;
                :NEW.collector_nkid := :OLD.collector_nkid;
                :NEW.juris_tax_imposition_nkid := :OLD.juris_tax_imposition_nkid;
                --:NEW.collects_tax := :OLD.collects_tax;
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
                WHERE table_name = 'TAX_ADMINISTRATORS'
                AND primary_key = :old.id;
                UPDATE tax_qr
                SET qr = (select name from administrators where nkid = :new.administrator_nkid and next_rid is null), entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'TAX_ADMINISTRATORS'
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
            INSERT INTO tax_administrators (
                id,
                juris_tax_imposition_id,
                administrator_id,
                collector_id,
                juris_tax_imposition_nkid,
                administrator_nkid,
                collector_nkid,
                --collects_tax,
                start_date,
                end_date,
                rid,
                nkid,
                entered_by
                )
            VALUES (
                pending_changes(r).id,
                pending_changes(r).juris_tax_imposition_id,
                pending_changes(r).administrator_id,
                pending_changes(r).collector_id,
                pending_changes(r).juris_tax_imposition_nkid,
                pending_changes(r).administrator_nkid,
                pending_changes(r).collector_nkid,
                --pending_changes(r).collects_tax,
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

END upd_tax_administrators;
/