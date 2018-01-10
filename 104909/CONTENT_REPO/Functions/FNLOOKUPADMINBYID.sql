CREATE OR REPLACE FUNCTION content_repo."FNLOOKUPADMINBYID" (pID in number) return varchar2
/*
|| Lookup administrator based on ID
|| Returns only the last revision of the administrator name
|| SCHEMA: CRAPP_EXTRACT
*/
is
  rtnName varchar2(250) :=null;
begin
  if pID is not null then
     select name into rtnName from administrators
     where id = pID;
  end if;
  return rtnName;
end fnLookupAdminByID;
 
/