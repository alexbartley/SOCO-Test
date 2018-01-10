CREATE OR REPLACE procedure content_repo.truncate_drop_table ( table_name_i varchar2, status_i varchar2, owner_i varchar2 default 'CONTENT_REPO' )
is
vcnt number;
begin
select count(1) into vcnt from all_tables where table_name = upper(table_name_i) and owner = owner_i;
if vcnt >= 1 then
	if upper(status_i) = 'DROP'
	then
		execute immediate 'drop table '||owner_i||'.'||table_name_i||'';
	else
		execute immediate 'truncate table '||owner_i||'.'||table_name_i||' drop storage';
    end if;

end if;
end;
/