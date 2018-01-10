CREATE OR REPLACE TRIGGER content_repo."UNIQUE_CHECK_COMM" 
 FOR 
 INSERT OR UPDATE
 ON content_repo.COMMODITIES
 REFERENCING OLD AS OLD NEW AS NEW
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF commodities%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    AFTER EACH ROW IS
        l_new commodities%ROWTYPE;
    BEGIN
        l_new.name := nvl(:NEW.name,:old.name);
        l_new.product_tree_id := nvl(:NEW.product_tree_id,:old.product_tree_id);
        l_new.h_code := nvl(:NEW.h_code,:old.h_code);
        l_new.nkid := nvl(:NEW.nkid,:old.nkid);
        pending_changes.extend;
        pending_changes(pending_changes.last) := l_new;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        l_pcc NUMBER := pending_changes.COUNT;
    BEGIN
        IF l_pcc > 0 THEN
            FOR r in 1 .. l_pcc LOOP
            commodity.unique_check(pending_changes(r).name,pending_changes(r).product_tree_id,pending_changes(r).h_code,pending_changes(r).nkid);
            END LOOP;

          -- Rebuild commodity tree using scheduler
          -- Commecnting this for CRAPP-2816
          -- COMMODITY_TREE_EXEC;

		END IF;
	EXCEPTION
        WHEN others THEN
            RAISE;
    END AFTER STATEMENT;

END unique_check_comm;
/