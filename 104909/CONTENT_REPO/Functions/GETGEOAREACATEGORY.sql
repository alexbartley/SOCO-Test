CREATE OR REPLACE FUNCTION content_repo."GETGEOAREACATEGORY" ( categoryname varchar2)
return number
is
v_category_code number;
begin
select id into v_category_code
from geo_area_categories
where name = categoryname;
return v_category_code;
exception
when others
then return 0;
end;

 
/