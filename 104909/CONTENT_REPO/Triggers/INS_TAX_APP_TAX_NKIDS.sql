CREATE OR REPLACE TRIGGER content_repo."INS_TAX_APP_TAX_NKIDS" 
 BEFORE
  INSERT
 ON content_repo.tax_applicability_taxes
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN

  SELECT nkid
  INTO :new.JURIS_TAX_APPLICABILITY_NKID
  FROM  juris_tax_applicabilities
  WHERE id = :new.JURIS_TAX_APPLICABILITY_ID;

  SELECT nkid
  INTO :new.JURIS_TAX_IMPOSITION_NKID
  FROM  juris_tax_impositions
  WHERE id = :new.JURIS_TAX_IMPOSITION_ID;

END;
/