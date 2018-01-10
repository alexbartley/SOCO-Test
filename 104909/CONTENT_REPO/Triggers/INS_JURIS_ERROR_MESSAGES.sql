CREATE OR REPLACE TRIGGER content_repo.INS_JURIS_ERROR_MESSAGES
 BEFORE
 INSERT
 ON content_repo.JURIS_ERROR_MESSAGES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := NKID_JURIS_ERROR_MESSAGES.nextval;
    -- Comment out for data load DEV TEST of default administrator and reporting code
    -- not to create a new revision if already exists and is published    
    if (:new.rid is null) then
    :new.rid := jurisdiction.get_revision(entity_id_io => :new.jurisdiction_id,
                                          entity_nkid_i => NULL,
                                          entered_by_i => :new.entered_by);
    end if;
END IF;

IF (:new.id IS NULL) THEN
:new.id := PK_JURIS_ERROR_MESSAGES.nextval;
END IF;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
INSERT INTO juris_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('JURIS_ERROR_MESSAGES',:new.id,:new.entered_by,:new.rid, :new.jurisdiction_id);
INSERT INTO juris_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('JURIS_ERROR_MESSAGES', :new.nkid, :new.id,:new.entered_by,:new.rid,to_char(:new.start_date,'MM/DD/YYYY')||'-'||to_char(:new.end_date,'MM/DD/YYYY')||' '||(select severity_description from JURIS_MSG_SEVERITY_LOOKUPS where severity_id = :new.severity_id));

END INS_JURIS_ERROR_MESSAGES;
/