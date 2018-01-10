CREATE OR REPLACE TRIGGER content_repo."INS_TAX_OUTP_NKIDS" 
 BEFORE
  INSERT
 ON content_repo.taxability_outputs
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN

    SELECT nkid
    INTO :new.JURIS_TAX_APPLICABILITY_NKID
    FROM  juris_tax_applicabilities
    WHERE id = :new.JURIS_TAX_APPLICABILITY_ID;

    IF :new.tax_applicability_tax_id IS NOT NULL THEN
        SELECT nkid
        INTO :new.tax_applicability_tax_nkid
        FROM  tax_applicability_taxes
        WHERE id = :new.tax_applicability_tax_id;
    END IF;

END;
/