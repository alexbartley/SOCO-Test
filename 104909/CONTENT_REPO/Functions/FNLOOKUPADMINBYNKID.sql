CREATE OR REPLACE FUNCTION content_repo."FNLOOKUPADMINBYNKID" (pNKID in number) return varchar2
/*
|| Lookup administrator based on NKID
|| Returns only the last revision of the administrator name
|| SCHEMA: CRAPP_EXTRACT
*/
is
  rtnName varchar2(250) :=null;
begin
  if pNKID is not null then
     select name into rtnName from administrators
     where nkid = pNKID
       and next_rid is null;
  end if;
  return rtnName;
end fnLookupAdminByNKID;
 
/