CREATE OR REPLACE FUNCTION content_repo.fnNLSConvert(pField in varchar2) return varchar2
is
 l_str varchar2(2000);
 l_chrfrom varchar2(128);
 l_chrto varchar2(128);
 begin
  if (LENGTH(pField)>0) then
    select
    listagg(incharacter) within group (order by id) chrFrom,
    listagg(convertto) within group (order by id) chrTo
    into l_chrfrom, l_chrto
    from TDR_NLS_CONVERT;

    Select Translate(pField, l_chrfrom, l_chrto) into l_str from dual;
    l_str := trim(regexp_replace(l_str, '\s+',' '));
  end if;

  return l_str;  -- leave as is if there are no changes to prevent null text
end fnNLSConvert;
/