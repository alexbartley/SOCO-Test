CREATE OR REPLACE TRIGGER content_repo.upd_tran_tax_qualifiers
 FOR
  UPDATE
 ON content_repo.tran_tax_qualifiers
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER
    TYPE mod_records IS TABLE OF TRAN_TAX_QUALIFIERS%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new TRAN_TAX_QUALIFIERS%ROWTYPE;
        --l_pci NUMBER;
        l_changed BOOLEAN := FALSE; -- Changes for CRAPP-3538
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.
        IF updating('LOGICAL_QUALIFIER') AND :new.LOGICAL_QUALIFIER != :old.LOGICAL_QUALIFIER THEN
            l_new.LOGICAL_QUALIFIER := :NEW.LOGICAL_QUALIFIER;
            l_changed := TRUE;
        ELSE
            l_new.LOGICAL_QUALIFIER := :OLD.LOGICAL_QUALIFIER;
        END IF;

        IF updating('VALUE') AND :new.VALUE != :old.VALUE THEN
            l_new.VALUE := :NEW.VALUE;
            l_changed := TRUE;
        ELSE
            l_new.VALUE := :OLD.VALUE;
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

        IF updating('REFERENCE_GROUP_ID') AND nvl(:new.reference_group_id,-1) != nvl(:old.reference_group_id,-1) THEN
            l_new.reference_group_id := :NEW.reference_group_id;
            l_new.reference_group_nkid := :NEW.reference_group_nkid;
            l_changed := TRUE;
        ELSE
            l_new.reference_group_nkid := :OLD.reference_group_nkid;
            l_new.reference_group_id := :OLD.reference_group_id;
        END IF;

        IF updating('JURISDICTION_ID') AND nvl(:new.jurisdiction_id,-1) != nvl(:old.jurisdiction_id,-1) THEN
            l_new.jurisdiction_id := :NEW.jurisdiction_id;
            l_new.jurisdiction_nkid := :NEW.jurisdiction_nkid;
            l_changed := TRUE;
        ELSE
            l_new.jurisdiction_nkid := :OLD.jurisdiction_nkid;
            l_new.jurisdiction_id := :OLD.jurisdiction_id;
        END IF;

        IF updating('TAXABILITY_ELEMENT_ID') AND nvl(:new.taxability_element_id,-1) != nvl(:old.taxability_element_id,-1) THEN
            l_new.taxability_element_id := :NEW.taxability_element_id;
            l_changed := TRUE;
        ELSE
            l_new.taxability_element_id := :OLD.taxability_element_id;
        END IF;

        l_new.juris_tax_applicability_id := :OLD.juris_tax_applicability_id;
        l_new.juris_tax_applicability_nkid := :OLD.juris_tax_applicability_nkid;
        l_new.nkid := :OLD.nkid;
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
            l_new.rid := tax_applicability.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_TRAN_TAX_QUALIFIERS.nextval; --new ID
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.juris_tax_applicability_id := :old.juris_tax_applicability_id;
                :NEW.juris_tax_applicability_nkid := :old.juris_tax_applicability_nkid;
                :NEW.taxability_element_id := :old.taxability_element_id;
                :NEW.reference_group_id := :old.reference_group_id;
                :NEW.reference_group_nkid := :old.reference_group_nkid;
                :NEW.jurisdiction_id := :old.jurisdiction_id;
                :NEW.jurisdiction_nkid := :old.jurisdiction_nkid;
                :NEW.VALUE := :OLD.VALUE;
                :NEW.logical_qualifier := :OLD.logical_qualifier;
                :NEW.start_date := :OLD.start_date;
                :NEW.end_date := :OLD.end_date;
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
                WHERE table_name = 'TRAN_TAX_QUALIFIERS'
                AND primary_key = :old.id;

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
            INSERT INTO TRAN_TAX_QUALIFIERS (
                id,
                juris_tax_applicability_id,
                juris_tax_applicability_nkid,
                taxability_element_id,
                jurisdiction_id,
                jurisdiction_nkid,
                reference_group_id,
                reference_group_nkid,
                VALUE,
                logical_qualifier,
                start_date,
                end_date,
                rid,
                nkid,
                entered_by
                )
            VALUES (
                 pending_changes(r).id,
                pending_changes(r).juris_tax_applicability_id,
                pending_changes(r).juris_tax_applicability_nkid,
                pending_changes(r).taxability_element_id,
                pending_changes(r).jurisdiction_id,
                pending_changes(r).jurisdiction_nkid,
                pending_changes(r).reference_group_id,
                pending_changes(r).reference_group_nkid,
                pending_changes(r).VALUE,
                pending_changes(r).logical_qualifier,
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

END upd_TRAN_TAX_QUALIFIERS;
/