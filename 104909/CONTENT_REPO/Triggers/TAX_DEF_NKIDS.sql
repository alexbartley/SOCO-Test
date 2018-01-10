CREATE OR REPLACE TRIGGER content_repo.tax_def_nkids
 BEFORE
  INSERT OR UPDATE
 ON content_repo.tax_definitions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN
IF (:new.DEFER_TO_JURIS_TAX_ID IS NOT NULL) THEN 
    select nkid
    into :new.DEFER_TO_JURIS_TAX_NKID
    from juris_tax_impositions
    where id = :new.DEFER_TO_JURIS_TAX_ID;
    ELSE
    :new.DEFER_TO_JURIS_TAX_NKID := null;
END IF;
select nkid
into :new.TAX_OUTLINE_NKID
from tax_outlines
where id = :new.TAX_OUTLINE_ID;
END;
/