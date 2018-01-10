CREATE OR REPLACE procedure content_repo.statuschange_ref_constraints ( table_name_i varchar2, status_i varchar2, owner_i varchar2 default 'CONTENT_REPO'  )
is
vsql varchar2(200);
begin
for i in ( select constraint_name from all_constraints where table_name = upper(table_name_i) and constraint_type = 'R' and owner = upper(owner_i) )
loop
    vsql:= 'alter table '||owner_i||'.'||table_name_i||' '||status_i||' constraint '||i.constraint_name||'';
    dbms_output.put_line('vsql value is '||vsql);
    execute immediate vsql;
end loop;
end;
/