CREATE OR REPLACE function content_repo.check_kpmg_atleast_3_bounds(unique_area_i varchar2)
return number
is
    vreturn number;
begin

return regexp_count( replace(unique_area_i, chr(124), '@'), '@') ;
end;
/