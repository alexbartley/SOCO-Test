CREATE OR REPLACE TRIGGER content_repo."INS_TAX_RELATIONSHIPS" 
 BEFORE
  INSERT
 ON content_repo.tax_relationships
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.id IS NULL) THEN
        :new.id :=   pk_TAX_RELATIONSHIPS.nextval;
        --:new.nkid := nkid_TAX_RELATIONSHIPS.nextval;
        :new.jurisdiction_rid := jurisdiction.get_revision(entity_id_io => :new.JURISDICTION_ID, entity_nkid_i => NULL, entered_by_i => :new.entered_by);
    END IF;
    
    :new.entered_date := SYSTIMESTAMP;
    :new.status_modified_date := SYSTIMESTAMP;

    INSERT INTO juris_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
    VALUES ('TAX_RELATIONSHIPS',:new.id,:new.entered_by,:new.jurisdiction_rid, :new.jurisdiction_id);

    INSERT INTO juris_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
    VALUES ('TAX_RELATIONSHIPS', :new.related_jurisdiction_nkid, :new.id,:new.entered_by,:new.jurisdiction_rid,:NEW.RELATIONSHIP_TYPE); -- crapp-2516

END;
/