CREATE OR REPLACE FUNCTION content_repo."FNJURISATTRIBADMIN" (pN in number) return number
is
/*
|| Note: Fixed text for attributes. Problem here is that the names are
|| used to determine sections in the ETL. 'Reporting Code' etc.
|| (Yes, ETL is using fixed names)
||
|| NOTE: Reporting Code in Content_Repo is hard coded to an ID of 8.
||
|| ID can be different if sequence is not the same across the databases
|| 1 = ADMIN
|| 2 = REPORTING CODE
*/
  r_attribute_id number:=-1;
begin
  if pN = 1 then
    select id
    into r_attribute_id
    from
    additional_attributes
    where attribute_category_id = 1
    and name = 'Default Administrator'
    and id != 8;
    return r_attribute_id;
  end if; -- build additional lookup here

  if pN = 2 then
    select id
    into r_attribute_id
    from
    additional_attributes
    where attribute_category_id = 1
    and name = 'Default Reporting Code'
    and id != 8;
    return r_attribute_id;
  end if;
end fnJurisAttribAdmin;
 
/