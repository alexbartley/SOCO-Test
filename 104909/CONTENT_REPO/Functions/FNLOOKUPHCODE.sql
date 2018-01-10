CREATE OR REPLACE FUNCTION content_repo."FNLOOKUPHCODE" (pCommodity in number) return varchar2
/*
|| 20160808: change to use the commodity tree since all the commodity data is based on the tree and
|| not what is in the commodity table.
|| Caused issue with newly updated commodity information since the tree build is not enabled in DEV.
||
*/
is
  -- l_h_code commodities.h_code%type;
  l_h_code commodities_pctree_build.child_h_code%type;
begin
  if pCommodity is not null then
/*   Select h_code into l_h_code
     from commodities where id=pCommodity;*/
   Select child_h_code into l_h_code
     from commodities_pctree_build where commodity_id=pCommodity;
  end if;
  return l_h_code;
end;
/