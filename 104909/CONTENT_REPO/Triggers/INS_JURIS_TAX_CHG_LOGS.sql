CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_TAX_CHG_LOGS" 
 BEFORE 
 INSERT
 ON content_repo.JURIS_TAX_CHG_LOGS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN
:new.id := pk_CHANGE_LOGS.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
IF(:new.table_name = 'TAX_DEFINITIONS') THEN
    SELECT juris_tax_imposition_id
    INTO :new.entity_id
    FROM tax_outlines
    WHERE id = :new.entity_id;
END IF;
END;
/