CREATE OR REPLACE TRIGGER content_repo."INS_TAX_OUTLINES"
 BEFORE
  INSERT
 ON content_repo.tax_outlines
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_tax_outlines.nextval;
    :new.id := pk_tax_outlines.nextval;
    :new.rid := tax.get_revision(entity_id_io => :new.juris_tax_imposition_id, entity_nkid_i => null, entered_by_i => :new.entered_by);
END IF;


:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
INSERT INTO juris_tax_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('TAX_OUTLINES',:new.id,:new.entered_by,:new.rid, :new.juris_tax_imposition_id);

INSERT INTO tax_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('TAX_OUTLINES', :new.nkid, :new.id,:new.entered_by,:new.rid,to_char(:new.start_date,'MM/DD/YYYY')||'-'||to_char(:new.end_date,'MM/DD/YYYY')||' '||
                    (select tax_structure||' '||amount_type from vtax_calc_structures where id = :new.calculation_structure_id));
END;
/