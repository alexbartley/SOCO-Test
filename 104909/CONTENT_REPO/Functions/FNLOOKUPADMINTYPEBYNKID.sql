CREATE OR REPLACE FUNCTION content_repo.fnlookupadmintypebynkid (pNKID in number) return varchar2
/*
|| Lookup administrator type based on NKID
|| Return last revision of the administrator only
*/
is
  rtnName varchar2(250) :=null;
begin
  if pNKID is not null then
     select vad.administrator_type into rtnName from vadministrators vad
     where nkid = pNKID
       and next_rid is null;
  end if;
  return rtnName;
end fnLookupAdminTypeByNKID;
/