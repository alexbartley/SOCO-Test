CREATE OR REPLACE TRIGGER content_repo."TRAN_TAX_QUALIFIER_NKIDS" 
 BEFORE
  INSERT OR UPDATE
 ON content_repo.tran_tax_qualifiers
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN

  SELECT nkid
  INTO :new.JURIS_TAX_APPLICABILITY_NKID
  FROM juris_tax_applicabilities
  WHERE id = :new.JURIS_TAX_APPLICABILITY_ID;

  IF (:new.reference_group_id IS NOT NULL) THEN
    SELECT nkid
    INTO :new.REFERENCE_GROUP_NKID
    FROM reference_groups
    WHERE id = :new.REFERENCE_GROUP_ID;
  ELSE
    :new.reference_group_nkid := NULL;
  END IF;

  IF (:new.jurisdiction_id IS NOT NULL) THEN
    SELECT nkid
    INTO :new.JURISDICTION_NKID
    FROM jurisdictions
    WHERE id = :new.JURISDICTION_ID;
  ELSE
    :new.JURISDICTION_NKID := NULL;
  END IF;

END;
/