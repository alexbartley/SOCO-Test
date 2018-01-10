CREATE OR REPLACE TRIGGER content_repo.INS_JURIS_TAX_APP_NKIDS
 BEFORE 
 INSERT
 ON content_repo.JURIS_TAX_APPLICABILITIES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
DECLARE
    l_nkid number;
BEGIN
    dbms_output.put_line('the jurisdiction value is '||:new.JURISDICTION_ID ); 
  SELECT nkid
  INTO :new.JURISDICTION_NKID
  FROM jurisdictions
  WHERE id = :new.JURISDICTION_ID; -- AND NEXT_RID IS NULL; Changes for CRAPP-3510
  
  if :new.commodity_id is not null and :new.commodity_nkid is null 
  then

      select nkid 
      into :new.commodity_nkid
      from commodities
      where id = :new.commodity_id;
  
  end if;
  
END;
/