CREATE OR REPLACE TRIGGER content_repo.INS_ADMIN_ATTRIBUTES
 BEFORE 
 INSERT
 ON content_repo.ADMINISTRATOR_ATTRIBUTES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_ADMINISTRATOR_ATTRIBUTES.nextval;
    :new.id := pk_ADMINISTRATOR_ATTRIBUTES.nextval;
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
IF (:new.rid IS NULL) THEN
    :new.rid := administrator.get_revision(entity_id_io => :new.administrator_id, entity_nkid_i => NULL, entered_by_i => :new.entered_by);
END IF;

:new.value := fnnlsconvert(pfield=>:new.value);

INSERT INTO admin_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('ADMINISTRATOR_ATTRIBUTES',:new.id,:new.entered_by,:new.rid, :new.administrator_id);
INSERT INTO admin_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('ADMINISTRATOR_ATTRIBUTES',:new.nkid, :new.id,:new.entered_by,:new.rid,to_char(:new.start_date,'MM/DD/YYYY')||'-'||to_char(:new.end_date,'MM/DD/YYYY')||' '||(select name from additional_attributes where id = :new.attribute_id));
END;
/