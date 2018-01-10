CREATE OR REPLACE TRIGGER content_repo."INS_COMMODITY_ATTRIBUTES"
 BEFORE
  INSERT
 ON content_repo.commodity_attributes
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_Commodity_Attributes.nextval;
    :new.id := pk_Commodity_Attributes.nextval;
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
IF (:new.rid IS NULL) THEN
    :new.rid := Commodity.get_revision(entity_id_io => :new.Commodity_Id, entity_nkid_i => NULL, entered_by_i => :new.entered_by);
END IF;

INSERT INTO Comm_Chg_Logs(table_name, primary_key, entered_by, rid, entity_id)
    VALUES ('COMMODITY_ATTRIBUTES',:new.id,:new.entered_by,:new.rid, :new.Commodity_Id);
INSERT INTO comm_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('COMMODITY_ATTRIBUTES', :new.nkid, :new.id,:new.entered_by,:new.rid, to_char(:new.start_date,'MM/DD/YYYY')||'-'||to_char(:new.end_date,'MM/DD/YYYY')||' '||(select name from additional_attributes where id = :new.attribute_id));

END;
/