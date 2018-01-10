CREATE OR REPLACE TRIGGER content_repo.tax_admin_nkids
 BEFORE
  INSERT OR UPDATE
 ON content_repo.tax_administrators
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN
select nkid
into :new.ADMINISTRATOR_NKID
from administrators
where id = :new.ADMINISTRATOR_ID;

select nkid
into :new.JURIS_TAX_IMPOSITION_NKID
from juris_tax_impositions
where id = :new.JURIS_TAX_IMPOSITION_ID;
IF (:new.collector_id IS NOT NULL) THEN
    select nkid
    into :new.COLLECTOR_NKID
    from administrators
    where id = :new.COLLECTOR_ID;
else
    :new.collector_nkid := null;
END IF;
END;
/