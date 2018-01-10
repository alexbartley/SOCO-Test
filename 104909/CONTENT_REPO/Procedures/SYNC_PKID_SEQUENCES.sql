CREATE OR REPLACE PROCEDURE content_repo."SYNC_PKID_SEQUENCES" is
tableName VARCHAR2(30);
newVal NUMBER;
maxVal NUMBER;
cursor seqs is
select distinct sequence_name, last_number, table_name
from user_source uso
join user_triggers ut on (ut.trigger_name = uso.name)
join user_sequences us on(instr(upper(uso.text),us.sequence_name) > 1)
and us.sequence_name like 'PK%'
and exists (
    select 1
    from user_tab_columns utc
    where utc.table_name = ut.table_name
    and utc.column_name = 'ID'
    );

begin

for s in seqs loop

execute immediate 'select max(id) from '||s.table_name INTO maxVal;

IF maxVal >= s.last_number THEN
    dbms_output.put_line(s.table_name||':'||s.sequence_name||':'||maxVal||':'||s.last_number);
    execute immediate 'alter sequence ' || s.sequence_name || ' increment by ' || to_char((maxVal-s.last_number)+1);

    execute immediate 'select ' || s.sequence_name || '.nextval from dual' INTO newVal;

    execute immediate 'alter sequence ' || s.sequence_name|| ' increment by 1';

END IF;

END LOOP;

END;
 
/