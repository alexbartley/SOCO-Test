CREATE OR REPLACE TRIGGER
content_repo.ins_upd_jurisdiction_nkid
 BEFORE
  INSERT or update
 ON content_repo.jurisdictions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN
if :new.jurisdiction_type_id is not null
then 
    select nkid
    into :new.jurisdiction_type_nkid
    from jurisdiction_types
    where id = :new.jurisdiction_type_id;
end if;
END;
/