CREATE OR REPLACE procedure content_repo.drop_taxability_triggers ( table_name_i varchar2, owner_i varchar2 default 'CONTENT_REPO' )
is
vcnt number;
begin
select count(1) into vcnt from all_tables where table_name = upper(table_name_i) and owner = upper(owner_i);
if vcnt >= 1 then
	for i in ( select trigger_name from all_triggers where table_name = upper(table_name_i) and owner = upper(owner_i) )
	loop
		execute immediate 'drop trigger '||i.trigger_name||'';
	end loop;
end if;
end;
/