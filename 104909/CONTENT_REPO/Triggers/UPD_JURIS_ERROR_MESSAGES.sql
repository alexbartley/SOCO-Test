CREATE OR REPLACE TRIGGER content_repo.UPD_JURIS_ERROR_MESSAGES

FOR UPDATE
 ON content_repo.JURIS_ERROR_MESSAGES
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF JURIS_ERROR_MESSAGES%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new JURIS_ERROR_MESSAGES%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.

        IF updating('SEVERITY') AND :new.severity_id != :old.severity_id THEN
            l_new.severity_id := :NEW.severity_id;
            l_changed := TRUE;
        ELSE
            l_new.severity_id := :OLD.severity_id;
        END IF;


        l_new.description := :old.description;
	l_new.error_msg := :old.error_msg;

        IF updating('START_DATE') AND NVL(:new.start_date,'31-Dec-9999') != NVL(:old.start_date,'31-Dec-9999') THEN
            l_new.start_date := :NEW.start_date;
            l_changed := TRUE;
        ELSE
            l_new.start_date := :OLD.start_date;
        END IF;
        IF updating('END_DATE') AND NVL(:new.end_date,'31-Dec-9999') != NVL(:old.end_date,'31-Dec-9999') THEN
            l_new.end_date := :NEW.end_date;
            l_changed := TRUE;
        ELSE
            l_new.end_date := :OLD.end_date;
        END IF;



        l_new.nkid := :OLD.nkid;
        l_new.jurisdiction_id := :OLD.jurisdiction_id;
        l_new.jurisdiction_nkid := :OLD.jurisdiction_nkid;
        l_new.entered_by := :NEW.entered_by;
        IF NOT l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSIF l_changed THEN
            IF (:new.jurisdiction_id != :old.jurisdiction_id OR :new.severity_id != :old.severity_id) THEN
                RAISE errnums.cannot_update_record;
            END IF;
            --l_pci := pending_changes.COUNT+1;
            --get current pending revision
            l_new.rid := jurisdiction.get_revision(rid_i => :old.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := PK_JURIS_ERROR_MESSAGES.nextval; --new ID
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.jurisdiction_id := :OLD.jurisdiction_id;
                :NEW.jurisdiction_nkid := :OLD.jurisdiction_nkid;
                :NEW.severity_id := :OLD.severity_id;
                :NEW.error_msg := :OLD.error_msg;
		:NEW.description := :OLD.description;
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
                UPDATE juris_chg_logs
                SET entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'JURIS_ERROR_MESSAGES'
                AND primary_key = :old.id;
                UPDATE juris_QR
                SET qr = to_char(:new.start_date,'MM/DD/YYYY')||'-'||to_char(:new.end_date,'MM/DD/YYYY')||' '||(select severity_description from JURIS_MSG_SEVERITY_LOOKUPS where severity_id = :new.severity_id), entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'JURIS_ERROR_MESSAGES'
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
            INSERT INTO juris_error_messages (
                id,
                jurisdiction_id,
                jurisdiction_nkid,
                severity_id,
                error_msg,

                description,
		start_date,
                end_date,

                rid,
                nkid,
                entered_by
                )
            VALUES (
                pending_changes(r).id,
                pending_changes(r).jurisdiction_id,
                pending_changes(r).jurisdiction_nkid,
                pending_changes(r).severity_id,
                pending_changes(r).error_msg,

                pending_changes(r).description,
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

END UPD_JURIS_ERROR_MESSAGES;
/