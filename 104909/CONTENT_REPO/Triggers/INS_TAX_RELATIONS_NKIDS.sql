CREATE OR REPLACE TRIGGER content_repo."INS_TAX_RELATIONS_NKIDS" 
 BEFORE
  INSERT
 ON content_repo.tax_relationships
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN

  SELECT nkid
  INTO :new.JURISDICTION_NKID
  FROM jurisdictions
  WHERE id = :new.JURISDICTION_ID;
  
  -- Added by Madhu
  dbms_output.put_line('Getting NKID value with ID '||:new.related_jurisdiction_id);
  
  if :new.related_jurisdiction_id is not null
  then
     select distinct nkid into :new.related_jurisdiction_nkid
      from jurisdictions
     where id = :new.related_jurisdiction_id;
  end if;
  
    dbms_output.put_line('Getting NKID value with ID '||:new.related_jurisdiction_id||':'||:new.related_jurisdiction_nkid);

END;
/