CREATE OR REPLACE TRIGGER content_repo."UPD_TRANSACTION_TAXABILITIES" 
FOR update on content_repo.transaction_taxabilities
REFERENCING new as new old as old
COMPOUND trigger
TYPE mod_records IS TABLE OF transaction_taxabilities%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE each row is
l_new TRANSACTION_TAXABILITIES%ROWTYPE;
l_changed BOOLEAN := FALSE;

BEGIN
    --check the entity fields for modification:
    --if a field was not modified, preserve the original value in the new record
    --Also, use flag to indicate whether or not this entity is being modified.

    IF UPDATING ('APPLICABILITY_TYPE_ID')
       AND :new.applicability_type_id != :old.applicability_type_id
    THEN
        l_new.applicability_type_id := :new.applicability_type_id;

        l_changed := TRUE;
    ELSE
        l_new.applicability_type_id := :old.applicability_type_id;
    END IF;

    /*
    IF UPDATING ('QUALIFICATION_METHOD_ID')
       AND :new.qualification_method_id != :old.qualification_method_id
    THEN
        l_new.qualification_method_id := :new.qualification_method_id;

        l_changed := TRUE;
    ELSE
        l_new.qualification_method_id := :old.qualification_method_id;
    END IF;
    */

    /*
    IF UPDATING ('TRANSACTION_TYPE_ID')
       AND :new.transaction_type_id != :old.transaction_type_id
    THEN
        l_new.transaction_type_id := :new.transaction_type_id;

        l_changed := TRUE;
    ELSE
        l_new.transaction_type_id := :old.transaction_type_id;
    END IF;
    */

    IF UPDATING ('REFERENCE_CODE')
       AND :new.reference_code != :old.reference_code
    THEN
        l_new.reference_code := :new.reference_code;

        l_changed := TRUE;
    ELSE
        l_new.reference_code := :old.reference_code;
    END IF;

    IF UPDATING ('START_DATE')
       AND NVL (:new.start_date, '31-Dec-9999') !=
               NVL (:old.start_date, '31-Dec-9999')
    THEN
        l_new.start_date := :new.start_date;

        l_changed := TRUE;
    ELSE
        l_new.start_date := :old.start_date;
    END IF;

    IF UPDATING ('END_DATE')
       AND NVL (:new.end_date, '31-Dec-9999') !=
               NVL (:old.end_date, '31-Dec-9999')
    THEN
        l_new.end_date := :new.end_date;

        l_changed := TRUE;
    ELSE
        l_new.end_date := :old.end_date;
    END IF;



    l_new.nkid := :old.nkid;

    l_new.entered_by := :new.entered_by;

    IF NOT l_changed AND (UPDATING ('STATUS') OR UPDATING ('NEXT_RID'))
    THEN
        --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)

        :new.status_modified_date := SYSTIMESTAMP;
    ELSIF l_changed AND (UPDATING ('STATUS') OR UPDATING ('NEXT_RID'))
    THEN
        --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time

        RAISE errnums.cannot_update_record;
    ELSIF l_changed
    THEN
        --get current pending revision

        l_new.rid :=
            tax_applicability.
             get_revision (rid_i => :old.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id

        --regardless of updating or inserting, record gets a new timestamp

        :new.entered_date := SYSTIMESTAMP;

        --If a new revision id was created,

        --abort the update (reset :NEW values) but preserve the new values to be inserted as a new record

        IF (l_new.rid != :old.rid)
        THEN
            --add the new values to pending_changes

            l_new.id := pk_transaction_taxabilities.NEXTVAL;
            l_new.next_rid := NULL;             --not assigned for new records
            l_new.status := NULL; --let insert trigger or default handle status
            pending_changes.EXTEND;
            pending_changes (pending_changes.LAST) := l_new;

            --reset the values, except next_rid

            :new.id := :old.id;
            :new.juris_tax_applicability_id := :old.juris_tax_applicability_id;
            :new.applicability_type_id := :old.applicability_type_id;

            --:new.qualification_method_id := :old.qualification_method_id;
            --:new.transaction_type_id := :old.transaction_type_id;

            :new.reference_code := :old.reference_code;
            :new.start_date := :old.start_date;
            :new.end_date := :old.end_date;
            :new.rid := :old.rid;
            :new.nkid := :old.nkid;
            :new.next_rid := l_new.rid; --point the next_rid to the new revision
            :new.status := :old.status;
            :new.entered_by := :old.entered_by;
            :new.entered_date := :old.entered_date;
            :new.status_modified_date := :old.status_modified_date;
        ELSE
            UPDATE juris_tax_app_chg_logs
            SET entered_by = :new.entered_by, entered_date = :new.entered_Date
            WHERE table_name = 'TRANSACTION_TAXABILITIES'
            AND primary_key = :old.id;
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        RAISE;
END BEFORE EACH row;

AFTER STATEMENT IS
l_pcc NUMBER := pending_changes.COUNT;

BEGIN
    IF l_pcc > 0
    THEN
        FORALL r IN 1 .. l_pcc
            INSERT INTO transaction_taxabilities (id,
                                                  juris_tax_applicability_id,
                                                  applicability_type_id,
                                                  --qualification_method_id,
                                                  --transaction_type_id,
                                                  reference_code,
                                                  start_date,
                                                  end_date,
                                                  rid,
                                                  nkid,
                                                  entered_by)
            VALUES (pending_changes (r).id,
                    pending_changes (r).juris_tax_applicability_id,
                    pending_changes (r).applicability_type_id,
                    --pending_changes (r).qualification_method_id,
                    --pending_changes (r).transaction_type_id,
                    pending_changes (r).reference_code,
                    pending_changes (r).start_date,
                    pending_changes (r).end_date,
                    pending_changes (r).rid,
                    pending_changes (r).nkid,
                    pending_changes (r).entered_by);
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        RAISE;
END AFTER STATEMENT;
END upd_transaction_taxabilities;
/