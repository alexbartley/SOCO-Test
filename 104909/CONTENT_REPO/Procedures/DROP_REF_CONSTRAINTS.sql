CREATE OR REPLACE procedure content_repo.drop_ref_constraints ( table_name_i varchar2, owner_i varchar2 DEFAULT 'CONTENT_REPO')
is
begin

for i in ( select constraint_name from all_constraints where table_name = upper(table_name_i) and owner = upper( owner_i )
            and constraint_type = 'R')
loop

    execute immediate 'alter table '||table_name_i||' drop constraint '||i.constraint_name||' ';
    
end loop;

end;
/