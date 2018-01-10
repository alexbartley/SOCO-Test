CREATE OR REPLACE Procedure content_repo.CRAPP_1884_DATA_CONV_ADMIN is
  sx number;
  sy number;

  cursor cAttr is
   select atr.id, j.default_admin_id 
   from jurisdiction_attributes atr
   join jurisdictions j on ( atr.jurisdiction_id = j.id) 
   where 
   j.default_admin_id is not null 
   and atr.attribute_id=fnjurisattribadmin(pn=> 1);
   
   cursor cAttrNew is
   select j.id, j.nkid, j.default_admin_id, j.start_date, j.end_date, j.entered_by  
   from jurisdictions j  
   where 
   j.default_admin_id is not null; 
  
   admin_attribute number;
   xRid number;
   cmp number:=0; -- simple commit point counter 
   cmpnow number:=100; -- simple commit point level
   stophere number;      
begin
  -- Get current Administrator attribute ID in current environment
  admin_attribute:=fnjurisattribadmin(pn=> 1);
  DBMS_OUTPUT.Put_Line( admin_attribute );  

  sx:=dbms_utility.get_time;
  /* This is for the DEV side where Jurisdictions had attributes already
     after test of override functionality in the UI.
     There MIGHT be garbage in DEV since it allows for free text to be entered in the attribute value field.
  Execute Immediate 'Alter trigger upd_juris_attributes disable';
  -- Get attributes to update 
  For z in cAttr loop
      Update jurisdiction_attributes
      Set value = z.default_admin_id
      Where id = z.id;
  End loop;
  sy:=dbms_utility.get_time;
  DBMS_OUTPUT.Put_Line( to_char((sy-sx)/100) );
  Execute immediate 'Alter trigger upd_juris_attributes enable';
  */  
  --
  sx:=dbms_utility.get_time;
  -- Get attributes to update 
  for ins in cAttrNew loop
  
  -- if status = 2 there's already a RID for the attributes
  -- (if generating a new one there will be a new revision of the Jurisdiction)
  select max(rid) into xRid
    from jurisdiction_attributes 
   where jurisdiction_nkid=ins.nkid and next_rid is null;
  
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
        ins.default_admin_id,
        ins.start_date,
        ins.end_date,
        ins.entered_by,
        ins.nkid,
        xRid);
        
        Insert into CRAPP_1884_DATA_CONV values(SYSTIMESTAMP, ins.nkid,'A');
        cmp:=cmp+1; 
        if cmp>cmpnow then
          commit;
          cmp:=0;
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
      
end CRAPP_1884_DATA_CONV_ADMIN;
 
/