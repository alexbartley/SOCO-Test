CREATE OR REPLACE FUNCTION content_repo."ROUNDDATE" (pData in date) return varchar2 is
  rtn varchar2(21);
begin
  rtn := TO_CHAR(round(pData,'DD'),'MM/DD/YYYY - HH24:MI:SS');
 return rtn;
end;

 
 
/