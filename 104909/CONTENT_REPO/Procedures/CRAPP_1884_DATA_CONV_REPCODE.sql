CREATE OR REPLACE Procedure content_repo.CRAPP_1884_DATA_CONV_REPCODE is
  sx number;
  sy number;
   cursor cAttrNew is
   select j.id, j.nkid, j.default_admin_id, j.start_date, j.end_date, j.entered_by  
   from jurisdictions j  
   where 
   j.default_admin_id is not null 
   and j.next_rid is null;
   -- used for test: 
   --and id=38076;
   admin_attribute number;
   xRid number;
   newRepCode varchar2(500);
   newRepCodeCount number;

   cmp number:=0; -- simple commit point counter 
   cmpnow number:=100; -- simple commit point level
   stophere number;      
            
begin
  -- Get ID for Reporting Code in current environment
  admin_attribute:=fnjurisattribadmin(pn=> 2);
  DBMS_OUTPUT.Put_Line( admin_attribute );  

  sx:=dbms_utility.get_time;

  -- Get attributes to update 
  for ins in cAttrNew loop
  
  -- if status = 2 there's already a RID for the attributes
  -- (if generating a new one there will be a new revision of the Jurisdiction)
  select max(rid) into xRid
    from jurisdiction_attributes 
   where jurisdiction_nkid=ins.nkid and next_rid is null;

  -- Count first - exit if nothing to run
  Select Count(distinct txa.value)
    into newRepCodeCount 
    from tax_attributes txa
    join juris_tax_impositions jti on (jti.nkid = txa.juris_tax_imposition_nkid)
    where jti.jurisdiction_nkid = ins.nkid 
    and txa.next_rid is null
    and txa.end_date is null and txa.attribute_id=8;    

    IF newRepCodeCount>0 then
    -- -- -- 
    -- Get Taxes and reporting code
    --
    Select max(txa.value)
    into newRepCode 
    from tax_attributes txa
    join juris_tax_impositions jti on (jti.nkid = txa.juris_tax_imposition_nkid)
    where jti.jurisdiction_nkid =ins.nkid 
    and txa.next_rid is null
    and txa.end_date is null and txa.attribute_id=8;    
    -- -- --
    Insert Into jurisdiction_attributes(jurisdiction_id,
      attribute_id,
      value,
      start_date,
      end_date,
      entered_by,
      jurisdiction_nkid,
      rid)
      values(
        ins.id,
        admin_attribute,
        newRepCode,
        ins.start_date,
        ins.end_date,
        ins.entered_by,
        ins.nkid,
        xRid);

        Insert into CRAPP_1884_DATA_CONV values(SYSTIMESTAMP, ins.nkid,'R');
        cmp:=cmp+1; 
        if cmp>cmpnow then
          commit;
          cmp:=0;
        end if;

    else
      DBMS_OUTPUT.Put_Line( 'Nothing for:'||ins.nkid);  
    end if;        

        Select stopped into stophere from CRAPP_1884_MAIN where proc_step=1;
        if stophere <> 0 then
         exit;
        end if; 
       
  end loop;

  sy:=dbms_utility.get_time;
  DBMS_OUTPUT.Put_Line( to_char((sy-sx)/100) );

  -- Commit point if nothing was stopped 
  Select stopped into stophere from CRAPP_1884_MAIN where proc_step=1;
  if stophere = 0 then
     commit;
  end if; 

  /* 
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
       DBMS_OUTPUT.Put_Line( 'Next' );
  */         
end CRAPP_1884_DATA_CONV_REPCODE;
 
/