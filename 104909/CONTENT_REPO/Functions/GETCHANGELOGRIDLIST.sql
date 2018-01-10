CREATE OR REPLACE FUNCTION content_repo."GETCHANGELOGRIDLIST" (pProcessId in number) return varchar2
is
-- Get a list of RID's from update multiple process
  rec_arr  dbms_utility.lname_array;
  rec_size BINARY_INTEGER;
  rec_out  VARCHAR2(4000);
  -- example out
  rec_ex_arr  dbms_utility.lname_array;
  rec_ex_size BINARY_INTEGER;
  rec_ex_out  VARCHAR2(4000);

  type recSet is record
  (entity number,
   status number,
   primary_key number);
  type log_data is table of recSet;
  log_cc log_data;
  rid_list numtabletype;
  chglogtable all_tables.table_name%type;
begin
  Select entity, decode(status,2,1,0), primary_key
  bulk collect into log_cc
  from update_multiple_log
  where process_id=pProcessId
    and status=2;
  -- Add here: Data found check -> Move on
  -- Build list or query directly
  -- List
  for i in log_cc.first..log_cc.last
  loop
    rec_arr(i):=log_cc(i).primary_key;
    DBMS_OUTPUT.Put_Line( log_cc(i).primary_key);
  end loop;
  dbms_utility.table_to_comma(rec_arr, rec_size, rec_out);
  DBMS_OUTPUT.Put_Line('Change Log List:'||rec_out);

  chglogtable:=getchangelogtables(ientitytype=> log_cc(1).entity);
  -- Quick Query
  -- or you can use a nested table.
  -- this is just one way...
  -- from my_table where id in (select * from table(v_num_array));
  execute immediate
  'Select lg.rid from '||chglogtable||' lg
   join update_multiple_log um on (um.primary_key = lg.primary_key)
   where um.status=2 and lg.primary_key in('||rec_out||')'
  bulk collect into rid_list;

  for i in rid_list.first..rid_list.last
  loop
    rec_ex_arr(i):=rid_list(i);
  end loop;
  dbms_utility.table_to_comma(rec_ex_arr, rec_ex_size, rec_ex_out);
  --DBMS_OUTPUT.Put_Line('Rid List Out:'||rec_ex_out);
  Return rec_ex_out;
  -- no checks

  -- CRAPP-1775
  -- Non-specified error. It is either success or fail.
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    errlogger.report_and_stop (SQLCODE,'No RID list returned');
  WHEN OTHERS THEN
    errlogger.report_and_stop (SQLCODE,'Change log rid list function failed');


end getChangeLogRidList;
/