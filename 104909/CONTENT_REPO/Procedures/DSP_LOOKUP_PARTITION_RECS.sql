CREATE OR REPLACE PROCEDURE content_repo."DSP_LOOKUP_PARTITION_RECS" (pTabName in varchar2) is
/*
|| Lookup Partitions In A Table
|| --> sql output
|| Parameters: Table name
||
|| ---
|| tnn 2015
*/
  l_cnt number;
begin
    for x in ( select partition_name from user_tab_partitions where table_name = pTabName )
    loop
      execute immediate 'select count(*) from '||pTabName||' partition('||x.partition_name||')'
              into l_cnt;
              dbms_output.put_line( x.partition_name || ' ' || l_cnt );
    end loop;

  -- No exceptions - none is 0, DB use only
end DSP_LOOKUP_PARTITION_RECS;
/