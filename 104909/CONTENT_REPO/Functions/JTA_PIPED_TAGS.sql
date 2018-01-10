CREATE OR REPLACE FUNCTION content_repo."JTA_PIPED_TAGS" (jtaNkid in number) return varchar2
is
  l_data   varchar2(4000);
begin

select listagg (tgs.name, chr(13)) within group (order by 1)
    into l_data
 from juris_tax_app_tags jta
 join tags tgs on (tgs.id = jta.tag_id)
where jta.ref_nkid = jtaNkid;
/*
with jta_tags as
( select
       TagName 
  from juris_tax_app_tags jta
  join tags tgs on (tgs.id = jta.tag_id)
  where jta.ref_nkid = jtaNkid
)
select ''
       ||( select listagg( json, ',')
                  within group (order by 1)
           from   jtaQ1
          )
       ||''
into l_data
from   dual;
*/

return l_data;

end jta_piped_tags;
/