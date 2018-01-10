CREATE OR REPLACE TRIGGER content_repo."INS_TAX_OUTL_NKIDS" 
 BEFORE
  INSERT
 ON content_repo.TAX_OUTLINES
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN
select nkid
into :new.JURIS_TAX_IMPOSITION_NKID
from juris_tax_impositions
where id = :new.JURIS_TAX_IMPOSITION_ID;

END;
/