CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_TAX_APP_ATT_NKIDS" 
 BEFORE
  INSERT
 ON content_repo.JURIS_TAX_APP_ATTRIBUTES
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN
select nkid
into :new.JURIS_TAX_APPLICABILITY_NKID
from juris_tax_applicabilities
where id = :new.JURIS_TAX_APPLICABILITY_ID;

END;
/