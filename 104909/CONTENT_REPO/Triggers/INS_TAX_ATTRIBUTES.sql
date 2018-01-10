CREATE OR REPLACE TRIGGER content_repo."INS_TAX_ATTRIBUTES"
 BEFORE
  INSERT
 ON content_repo.tax_attributes
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
/* OLD
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_TAX_ATTRIBUTES.nextval;
END IF;
:new.id := pk_TAX_ATTRIBUTES.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
*/
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_TAX_ATTRIBUTES.nextval;

    :new.rid := tax.get_revision(entity_id_io => :new.JURIS_TAX_IMPOSITION_id, entity_nkid_i => NULL, entered_by_i => :new.entered_by);
END IF;

IF (:new.id IS NULL) THEN
:new.id := pk_TAX_ATTRIBUTES.nextval;
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

--will need to update to use specific entity change log
INSERT INTO juris_tax_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('TAX_ATTRIBUTES',:new.id,:new.entered_by,:new.rid, :new.juris_tax_imposition_id);
INSERT INTO tax_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('TAX_ATTRIBUTES', :new.nkid, :new.id,:new.entered_by,:new.rid,to_char(:new.start_date,'MM/DD/YYYY')||'-'||to_char(:new.end_date,'MM/DD/YYYY')||' '||(select name from additional_attributes where id = :new.attribute_id));
END;
/