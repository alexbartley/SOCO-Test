CREATE OR REPLACE TRIGGER content_repo."UPD_JURIS_TAX_APPLICABILITIES"
 FOR
 UPDATE
 ON content_repo.JURIS_TAX_APPLICABILITIES
 REFERENCING OLD AS OLD NEW AS NEW
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF JURIS_TAX_APPLICABILITIES%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new JURIS_TAX_APPLICABILITIES%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.

        -- REF_RULE_ORDER is currently a read only field and being updated once ETL is completed on a taxability.
        -- Hence this should not be recorded as a change when we update the ref_rule_order.

        IF updating('REF_RULE_ORDER') AND NVL(:new.REF_RULE_ORDER,-999) != NVL(:old.REF_RULE_ORDER, -999) THEN
            l_new.REF_RULE_ORDER := :NEW.REF_RULE_ORDER;
            l_changed := TRUE;
        ELSE
            l_new.REF_RULE_ORDER := :OLD.REF_RULE_ORDER;
        END IF;

        IF updating('REFERENCE_CODE') AND :new.REFERENCE_CODE != :old.REFERENCE_CODE THEN
            l_new.REFERENCE_CODE := :NEW.REFERENCE_CODE;
            l_changed := TRUE;
        ELSE
            l_new.REFERENCE_CODE := :OLD.REFERENCE_CODE;
        END IF;

        IF updating('CALCULATION_METHOD_ID') AND :new.CALCULATION_METHOD_ID != :old.CALCULATION_METHOD_ID THEN
            l_new.CALCULATION_METHOD_ID := :NEW.CALCULATION_METHOD_ID;
            l_changed := TRUE;
        ELSE
            l_new.CALCULATION_METHOD_ID := :OLD.CALCULATION_METHOD_ID;
        END IF;

        IF updating('BASIS_PERCENT') AND :new.BASIS_PERCENT != :old.BASIS_PERCENT THEN
            l_new.BASIS_PERCENT := :NEW.BASIS_PERCENT;
            l_changed := TRUE;
        ELSE
            l_new.BASIS_PERCENT := :OLD.BASIS_PERCENT;
        END IF;

        IF updating('RECOVERABLE_PERCENT') AND NVL(:new.RECOVERABLE_PERCENT, -999) != NVL(:old.RECOVERABLE_PERCENT, -999) THEN
            l_new.RECOVERABLE_PERCENT := :NEW.RECOVERABLE_PERCENT;
            l_changed := TRUE;
        ELSE
            l_new.RECOVERABLE_PERCENT := :OLD.RECOVERABLE_PERCENT;
        END IF;

        IF updating('START_DATE') AND NVL(:new.start_date,'31-Dec-9999') != NVL(:old.start_date,'31-Dec-9999') THEN
            l_new.START_DATE := :NEW.START_DATE;
            l_changed := TRUE;
        ELSE
            l_new.START_DATE := :OLD.START_DATE;
        END IF;

        IF updating('END_DATE') AND NVL(:new.END_DATE,'31-Dec-9999') != NVL(:old.END_DATE,'31-Dec-9999') THEN
            l_new.END_DATE := :NEW.END_DATE;
            l_changed := TRUE;
        ELSE
            l_new.END_DATE := :OLD.END_DATE;
        END IF;

        IF updating('RECOVERABLE_AMOUNT') AND NVL(:new.RECOVERABLE_AMOUNT, -999) != NVL(:old.RECOVERABLE_AMOUNT, -999) THEN
            l_new.RECOVERABLE_AMOUNT := :NEW.RECOVERABLE_AMOUNT;
            l_changed := TRUE;
        ELSE
            l_new.RECOVERABLE_AMOUNT := :OLD.RECOVERABLE_AMOUNT;
        END IF;

        IF updating('ALL_TAXES_APPLY') AND :new.ALL_TAXES_APPLY != :old.ALL_TAXES_APPLY THEN
            l_new.ALL_TAXES_APPLY := :NEW.ALL_TAXES_APPLY;
            l_changed := TRUE;
        ELSE
            l_new.ALL_TAXES_APPLY := :OLD.ALL_TAXES_APPLY;
        END IF;

        IF updating('APPLICABILITY_TYPE_ID') AND :new.APPLICABILITY_TYPE_ID != :old.APPLICABILITY_TYPE_ID THEN
            l_new.APPLICABILITY_TYPE_ID := :NEW.APPLICABILITY_TYPE_ID;
            l_changed := TRUE;
        ELSE
            l_new.APPLICABILITY_TYPE_ID := :OLD.APPLICABILITY_TYPE_ID;
        END IF;

        IF updating('CHARGE_TYPE_ID') AND nvl(:new.CHARGE_TYPE_ID, -999) != nvl(:old.CHARGE_TYPE_ID, -999) THEN
            l_new.CHARGE_TYPE_ID := :NEW.CHARGE_TYPE_ID;
            l_changed := TRUE;
        ELSE
            l_new.CHARGE_TYPE_ID := :OLD.CHARGE_TYPE_ID;
        END IF;

        IF updating('UNIT_OF_MEASURE') AND NVL(:new.UNIT_OF_MEASURE,'xx') !=  NVL(:old.UNIT_OF_MEASURE, 'xx') THEN
            l_new.UNIT_OF_MEASURE := :NEW.UNIT_OF_MEASURE;
            l_changed := TRUE;
        ELSE
            l_new.UNIT_OF_MEASURE := :OLD.UNIT_OF_MEASURE;
        END IF;

        IF updating('DEFAULT_TAXABILITY') AND NVL(:new.DEFAULT_TAXABILITY,'xx') != NVL(:old.DEFAULT_TAXABILITY, 'xx') THEN
            l_new.DEFAULT_TAXABILITY := :NEW.DEFAULT_TAXABILITY;
            l_changed := TRUE;
        ELSE
            l_new.DEFAULT_TAXABILITY := :OLD.DEFAULT_TAXABILITY;
        END IF;

        IF updating('PRODUCT_TREE_ID') AND NVL(:new.PRODUCT_TREE_ID,-999) != NVL(:old.PRODUCT_TREE_ID, -999) THEN
            l_new.PRODUCT_TREE_ID := :NEW.PRODUCT_TREE_ID;
            l_changed := TRUE;
        ELSE
            l_new.PRODUCT_TREE_ID := :OLD.PRODUCT_TREE_ID;
        END IF;

        IF updating('COMMODITY_ID') AND NVL(:new.COMMODITY_ID,-999) != NVL(:old.COMMODITY_ID, -999) THEN
            l_new.COMMODITY_ID := :NEW.COMMODITY_ID;
            l_changed := TRUE;
        ELSE
            l_new.COMMODITY_ID := :OLD.COMMODITY_ID;
        END IF;

        IF updating('TAX_TYPE') AND NVL(:new.TAX_TYPE,'xx') != NVL(:old.TAX_TYPE, 'xx') THEN
            l_new.TAX_TYPE := :NEW.TAX_TYPE;
            l_changed := TRUE;
        ELSE
            l_new.TAX_TYPE := :OLD.TAX_TYPE;
        END IF;

        /*
        IF updating('RELATED_CHARGE') AND NVL(:new.RELATED_CHARGE,'xx') != NVL(:old.RELATED_CHARGE, 'xx') THEN
            l_new.RELATED_CHARGE := :NEW.RELATED_CHARGE;
            l_changed := TRUE;
        ELSE
            l_new.RELATED_CHARGE := :OLD.RELATED_CHARGE;
        END IF;
        */

        IF updating('IS_LOCAL') AND NVL(:new.IS_LOCAL,'xx') != NVL(:old.IS_LOCAL, 'xx') THEN
            l_new.IS_LOCAL := :NEW.IS_LOCAL;
            l_changed := TRUE;
        ELSE
            l_new.IS_LOCAL := :OLD.IS_LOCAL;
        END IF;

        IF updating('EXEMPT') AND NVL(:new.EXEMPT,'xx') != NVL(:old.EXEMPT, 'xx') THEN
            l_new.EXEMPT := :NEW.EXEMPT;
            l_changed := TRUE;
        ELSE
            l_new.EXEMPT := :OLD.EXEMPT;
        END IF;

        IF updating('NO_TAX') AND NVL(:new.NO_TAX,'xx') != NVL(:old.NO_TAX, 'xx') THEN
            l_new.NO_TAX := :NEW.NO_TAX;
            l_changed := TRUE;
        ELSE
            l_new.NO_TAX := :OLD.NO_TAX;
        END IF;

        l_new.nkid := :OLD.nkid;
        l_new.entered_by := :NEW.entered_by;
        l_new.jurisdiction_id := :OLD.jurisdiction_id;
        l_new.jurisdiction_nkid := :OLD.jurisdiction_nkid;

        IF NOT l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSIF l_changed THEN
            --get current pending revision

            dbms_output.put_line('old rid value is '||:old.rid);

            dbms_output.put_line('old rid value is '||l_new.rid);

            l_new.rid := tax_applicability.get_revision(rid_i => :OLD.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id

            dbms_output.put_line('old rid value is '||l_new.rid);
            --regardless of updating or inserting, record gets a new timestamp
            :NEW.entered_date := SYSTIMESTAMP;
            --If a new revision id was created,
            --abort the update (reset :NEW values) but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_juris_tax_applicabilities.nextval;
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;
                --reset the values, except next_rid
                :NEW.id := :OLD.id;
                :NEW.JURISDICTION_ID := :OLD.JURISDICTION_ID;
                :NEW.JURISDICTION_NKID := :OLD.JURISDICTION_NKID;
                :NEW.REFERENCE_CODE := :OLD.REFERENCE_CODE;
                :NEW.CALCULATION_METHOD_ID := :OLD.CALCULATION_METHOD_ID;
                :NEW.BASIS_PERCENT := :OLD.BASIS_PERCENT;
                :NEW.RECOVERABLE_PERCENT := :OLD.RECOVERABLE_PERCENT;
                :NEW.START_DATE := :OLD.START_DATE;
                :NEW.END_DATE := :OLD.END_DATE;

                -- Newly added fields.
                :NEW.RECOVERABLE_AMOUNT := :OLD.RECOVERABLE_AMOUNT;
                :NEW.ALL_TAXES_APPLY := :OLD.ALL_TAXES_APPLY;
                :NEW.APPLICABILITY_TYPE_ID := :OLD.APPLICABILITY_TYPE_ID;
                :NEW.CHARGE_TYPE_ID := :OLD.CHARGE_TYPE_ID;
                :NEW.UNIT_OF_MEASURE := :OLD.UNIT_OF_MEASURE;
                :NEW.REF_RULE_ORDER := :OLD.REF_RULE_ORDER;
                :NEW.DEFAULT_TAXABILITY := :OLD.DEFAULT_TAXABILITY;
                :NEW.PRODUCT_TREE_ID := :OLD.PRODUCT_TREE_ID;
                :NEW.COMMODITY_ID := :OLD.COMMODITY_ID;
                :NEW.TAX_TYPE := :OLD.TAX_TYPE;   -- okay to leave commented, not used
               -- :NEW.RELATED_CHARGE := :OLD.RELATED_CHARGE;
                :NEW.IS_LOCAL := :OLD.IS_LOCAL;
                :NEW.EXEMPT := :OLD.EXEMPT;
                :NEW.NO_TAX := :OLD.NO_TAX;
                -- End of new fields.

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
                WHERE table_name = 'JURIS_TAX_APPLICABILITIES'
                AND primary_key = :old.id;

                UPDATE juris_tax_app_QR
                SET qr = :new.reference_code, entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'JURIS_TAX_APPLICABILITIES'
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

        dbms_output.put_line('About to insert new revision');


        FORALL r in 1 .. l_pcc
            INSERT INTO JURIS_TAX_APPLICABILITIES (
                ID,
                JURISDICTION_ID,
                JURISDICTION_NKID,
                REFERENCE_CODE,
                CALCULATION_METHOD_ID,
                BASIS_PERCENT,
                RECOVERABLE_PERCENT,
                -- Newly introduced fields
                RECOVERABLE_AMOUNT,
                ALL_TAXES_APPLY,
                APPLICABILITY_TYPE_ID,
                CHARGE_TYPE_ID,
                UNIT_OF_MEASURE,
                REF_RULE_ORDER,
                DEFAULT_TAXABILITY,
                PRODUCT_TREE_ID,
                COMMODITY_ID,
                TAX_TYPE,
               -- RELATED_CHARGE,
                IS_LOCAL,
                EXEMPT,
                NO_TAX,
                -- End newly introduced fields
                START_DATE,
                END_DATE,
                rid,
                nkid,
                entered_by
                )
            VALUES (
                pending_changes(r).ID,
                pending_changes(r).JURISDICTION_ID,
                pending_changes(r).JURISDICTION_NKID,
                pending_changes(r).REFERENCE_CODE,
                pending_changes(r).CALCULATION_METHOD_ID,
                pending_changes(r).BASIS_PERCENT,
                pending_changes(r).RECOVERABLE_PERCENT,
                -- Newly introduced fields
                pending_changes(r).RECOVERABLE_AMOUNT,
                pending_changes(r).ALL_TAXES_APPLY,
                pending_changes(r).APPLICABILITY_TYPE_ID,
                pending_changes(r).CHARGE_TYPE_ID,
                pending_changes(r).UNIT_OF_MEASURE,
                pending_changes(r).REF_RULE_ORDER,
                pending_changes(r).DEFAULT_TAXABILITY,
                pending_changes(r).PRODUCT_TREE_ID,
                pending_changes(r).COMMODITY_ID,
                pending_changes(r).TAX_TYPE,
               -- pending_changes(r).RELATED_CHARGE,
                pending_changes(r).IS_LOCAL,
                pending_changes(r).EXEMPT,
                pending_changes(r).NO_TAX,
                -- End newly introduced fields
                pending_changes(r).START_DATE,
                pending_changes(r).END_DATE,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).entered_by
                );
            END IF;
    EXCEPTION
        WHEN others THEN
            dbms_output.put_line('failed');
        RAISE;
    END AFTER STATEMENT;

END upd_juris_tax_applicabilities;
/