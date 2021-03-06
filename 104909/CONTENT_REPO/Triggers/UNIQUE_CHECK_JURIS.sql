CREATE OR REPLACE TRIGGER content_repo."UNIQUE_CHECK_JURIS"

FOR  INSERT OR UPDATE
 ON content_repo.jurisdictions
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF jurisdictions%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    AFTER EACH ROW IS
        l_new jurisdictions%ROWTYPE;
    BEGIN
        l_new.official_name := nvl(:NEW.official_name,:old.official_name);
        l_new.nkid := nvl(:NEW.nkid,:old.nkid);
        pending_changes.extend;
        pending_changes(pending_changes.last) := l_new;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        l_pcc NUMBER := pending_changes.COUNT;
    BEGIN
        IF l_pcc > 0 THEN
            FOR r in 1 .. l_pcc LOOP
            jurisdiction.unique_check(pending_changes(r).official_name,pending_changes(r).nkid);
            END LOOP;
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE;
    END AFTER STATEMENT;

END unique_check_juris;
/