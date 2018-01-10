CREATE OR REPLACE TRIGGER content_repo."UNIQUE_CHECK_TAX"

FOR  INSERT OR UPDATE
 ON content_repo.juris_tax_impositions
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF juris_tax_impositions%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    AFTER EACH ROW IS
        l_new juris_tax_impositions%ROWTYPE;
    BEGIN
        l_new.reference_code := nvl(:NEW.reference_code,:old.reference_code);
        l_new.jurisdiction_nkid := nvl(:NEW.jurisdiction_nkid,:old.jurisdiction_nkid);
        l_new.nkid := nvl(:NEW.nkid,:old.nkid);
        pending_changes.extend;
        pending_changes(pending_changes.last) := l_new;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        l_pcc NUMBER := pending_changes.COUNT;
    BEGIN
        IF l_pcc > 0 THEN
            FOR r in 1 .. l_pcc LOOP
            tax.unique_check(pending_changes(r).jurisdiction_nkid,pending_changes(r).reference_code,pending_changes(r).nkid);
            END LOOP;
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE;
    END AFTER STATEMENT;

END unique_check_tax;
/