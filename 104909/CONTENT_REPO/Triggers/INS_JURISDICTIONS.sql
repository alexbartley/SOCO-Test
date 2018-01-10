CREATE OR REPLACE TRIGGER content_repo.INS_JURISDICTIONS
 BEFORE 
 INSERT
 ON content_repo.JURISDICTIONS
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
    :new.nkid := nkid_jurisdictions.nextval;
    :new.id := pk_jurisdictions.nextval;
    :new.rid := jurisdiction.get_revision(entity_id_io => :new.id, entity_nkid_i => :new.nkid, entered_by_i => :new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
:new.official_name := fnnlsconvert(pfield=>:new.official_name);
:new.description := fnnlsconvert(pfield=>:new.description);

INSERT INTO juris_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('JURISDICTIONS',:new.id,:new.entered_by,:new.rid, :new.id);
INSERT INTO juris_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('JURISDICTIONS', :new.nkid, :new.id,:new.entered_by,:new.rid,:new.official_name);
END;
/