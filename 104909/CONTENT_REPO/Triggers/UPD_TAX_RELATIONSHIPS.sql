CREATE OR REPLACE TRIGGER content_repo."UPD_TAX_RELATIONSHIPS" 
 FOR
  UPDATE
 ON content_repo.tax_relationships
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF TAX_RELATIONSHIPS%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new TAX_RELATIONSHIPS%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.

        IF updating('RELATED_JURISDICTION_ID') AND :new.RELATED_JURISDICTION_ID != :old.RELATED_JURISDICTION_ID THEN
            l_new.RELATED_JURISDICTION_ID := :NEW.RELATED_JURISDICTION_ID;
            l_changed := TRUE;

            SELECT nkid
            INTO  l_new.RELATED_JURISDICTION_NKID
            FROM  jurisdictions
            WHERE id = :NEW.RELATED_JURISDICTION_ID ;
        ELSE
            l_new.RELATED_JURISDICTION_ID := :OLD.RELATED_JURISDICTION_ID;
            l_new.RELATED_JURISDICTION_NKID := :OLD.RELATED_JURISDICTION_NKID;
        END IF;

        IF updating('RELATIONSHIP_TYPE') AND :new.RELATIONSHIP_TYPE != :old.RELATIONSHIP_TYPE THEN
            l_new.RELATIONSHIP_TYPE := :NEW.RELATIONSHIP_TYPE;
            l_changed := TRUE;
        ELSE
            l_new.RELATIONSHIP_TYPE := :OLD.RELATIONSHIP_TYPE;
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

        IF updating('BASIS_PERCENT') AND :new.BASIS_PERCENT != :old.BASIS_PERCENT THEN
            l_new.BASIS_PERCENT := :NEW.BASIS_PERCENT;
            l_changed := TRUE;
        ELSE
            l_new.BASIS_PERCENT := :OLD.BASIS_PERCENT;
        END IF;

        l_new.jurisdiction_id   := :old.jurisdiction_id;
        l_new.jurisdiction_nkid := :old.jurisdiction_nkid;
        l_new.entered_by := :NEW.entered_by;

        IF NOT l_changed AND UPDATING('STATUS') THEN      -- (UPDATING('STATUS') OR UPDATING('NEXT_RID'))
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF l_changed AND UPDATING('STATUS') THEN      -- (UPDATING('STATUS') OR UPDATING('NEXT_RID'))
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSIF l_changed THEN
            --get current pending revision
         --   l_new.jurisdiction_rid := jurisdiction.get_revision(entity_id_io => :new.JURISDICTION_ID, entity_nkid_i => :new.jurisdiction_nkid, entered_by_i => l_new.entered_by);

            -- Commented above call and add the below call to get the RID
                l_new.jurisdiction_rid := jurisdiction.get_revision(rid_i => :OLD.jurisdiction_rid, entered_by_i => l_new.entered_by);
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;

            --If a new revision id was created,
            --abort the update (reset :NEW values) but preserve the new values to be inserted as a new record
            IF (l_new.jurisdiction_rid != :old.jurisdiction_rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_tax_relationships.nextval;
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;

                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.JURISDICTION_ID := :OLD.JURISDICTION_ID;
                :NEW.JURISDICTION_NKID := :OLD.JURISDICTION_NKID;
                :NEW.JURISDICTION_RID := :OLD.JURISDICTION_RID;
                :NEW.RELATED_JURISDICTION_ID := :OLD.RELATED_JURISDICTION_ID;
                :NEW.RELATED_JURISDICTION_NKID := :OLD.RELATED_JURISDICTION_NKID;
                :NEW.RELATIONSHIP_TYPE := :OLD.RELATIONSHIP_TYPE;
                :NEW.START_DATE := :OLD.START_DATE;
                :NEW.END_DATE := :OLD.END_DATE;
                :NEW.BASIS_PERCENT := :OLD.BASIS_PERCENT;
                :NEW.status := :OLD.status;
                :NEW.entered_by := :OLD.entered_by;
                :NEW.entered_date := :OLD.entered_date;
                :NEW.status_modified_date := :OLD.status_modified_date;
            ELSE
                UPDATE juris_chg_logs
                SET entered_by = :new.entered_by, entered_date = :new.entered_date
                WHERE table_name = 'TAX_RELATIONSHIPS'
                AND primary_key = :old.id;

                UPDATE juris_qr
                SET qr = :NEW.RELATIONSHIP_TYPE, entered_by = :new.entered_by, entered_date = :new.entered_date
                WHERE table_name = 'TAX_RELATIONSHIPS'
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
        
            INSERT INTO TAX_RELATIONSHIPS (
                ID,
                JURISDICTION_ID,
                JURISDICTION_NKID,
                JURISDICTION_RID,
                RELATED_JURISDICTION_ID,
                RELATED_JURISDICTION_NKID,
                RELATIONSHIP_TYPE,
                START_DATE,
                END_DATE,
                BASIS_PERCENT,
                entered_by
                )
            VALUES (
                pending_changes(r).ID,
                pending_changes(r).JURISDICTION_ID,
                pending_changes(r).JURISDICTION_NKID,
                pending_changes(r).JURISDICTION_RID,
                pending_changes(r).RELATED_JURISDICTION_ID,
                pending_changes(r).RELATED_JURISDICTION_NKID,
                pending_changes(r).RELATIONSHIP_TYPE,
                pending_changes(r).START_DATE,
                pending_changes(r).END_DATE,
                pending_changes(r).BASIS_PERCENT,
                pending_changes(r).entered_by
                );
            END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END UPD_TAX_RELATIONSHIPS;
/