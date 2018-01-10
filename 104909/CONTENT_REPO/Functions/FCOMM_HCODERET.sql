CREATE OR REPLACE FUNCTION content_repo."FCOMM_HCODERET" (vHcode in varchar2) return varchar2
is
  ret_hcode varchar2(128);
begin
  select substr(vHcode,1,(regexp_count(vHcode,'[^.]+')-1)*4)
  into ret_hcode
  from dual;
  return ret_hcode;
end fcomm_hcodeRet;
 
/