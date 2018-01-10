CREATE OR REPLACE TRIGGER content_repo.INS_ADMINISTRATORS
 BEFORE 
 INSERT
 ON content_repo.ADMINISTRATORS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN
/*
--Two types of inserts can occur:
--a) as a new revision to an existing nkid-
    will have ID, NKID, RID,
    because the upd_jurisdictions trigger sets RID and ID
--b) as a brand new nkid- needs ID, RID, NKID
*/
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_ADMINISTRATORS.nextval;
    :new.id := pk_ADMINISTRATORS.nextval;
    :new.rid := administrator.get_revision(entity_id_io => :new.id, entity_nkid_i => :new.nkid, entered_by_i => :new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
:new.name := fnnlsconvert(pfield=>:new.name);
:new.description := fnnlsconvert(pfield=>:new.description);

INSERT INTO admin_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('ADMINISTRATORS',:new.id,:new.entered_by,:new.rid, :new.id);
INSERT INTO admin_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('ADMINISTRATORS', :new.nkid, :new.id,:new.entered_by,:new.rid,:new.name);
END;
/