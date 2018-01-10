CREATE OR REPLACE FUNCTION content_repo."GET_CHRTAB" (pAggList in varchar2) return CollTab 
is
  r_T CollTab;
begin
  Execute immediate 'Select CollObj(regexp_substr( :pAggList, ''[^,]+'', 1, level))
                    From dual Connect By regexp_substr( :pAggList, ''[^,]+'', 1, level) is not null'
  Bulk Collect Into r_T using pAggList, pAggList;
  return r_T;
end;
/