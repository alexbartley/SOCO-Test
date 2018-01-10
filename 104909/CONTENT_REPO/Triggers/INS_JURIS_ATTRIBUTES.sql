CREATE OR REPLACE TRIGGER content_repo.INS_JURIS_ATTRIBUTES
 BEFORE 
 INSERT
 ON content_repo.JURISDICTION_ATTRIBUTES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_jurisdiction_attributes.nextval;
    -- Comment out for data load DEV TEST of default administrator and reporting code
    -- not to create a new revision if already exists and is published

    -- 10/27 can the RID be null from the UI?
    if (:new.rid is null) then
    :new.rid := jurisdiction.get_revision(entity_id_io => :new.jurisdiction_id,
                                          entity_nkid_i => NULL,
                                          entered_by_i => :new.entered_by);
    end if;
END IF;

IF (:new.id IS NULL) THEN
:new.id := pk_JURISDICTION_ATTRIBUTES.nextval;
END IF;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
:new.value := fnnlsconvert(pfield=>:new.value);

INSERT INTO juris_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('JURISDICTION_ATTRIBUTES',:new.id,:new.entered_by,:new.rid, :new.jurisdiction_id);
INSERT INTO juris_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('JURISDICTION_ATTRIBUTES', :new.nkid, :new.id,:new.entered_by,:new.rid,to_char(:new.start_date,'MM/DD/YYYY')||'-'||to_char(:new.end_date,'MM/DD/YYYY')||' '||(select name from additional_attributes where id = :new.attribute_id));

END ins_juris_attribute;
/