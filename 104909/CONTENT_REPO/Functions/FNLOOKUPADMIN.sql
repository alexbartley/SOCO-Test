CREATE OR REPLACE FUNCTION content_repo."FNLOOKUPADMIN" (pName in varchar2) return number
/*
|| Lookup administrator ID just based on Name
|| Return last revision of the administrator only
*/
is
  rtnid number :=0;
begin
  if pName is not null then
     select id into rtnid from administrators
     where lower(name) = lower(pName)
       and next_rid is null;
  end if;
  return rtnid;
end;
 
/