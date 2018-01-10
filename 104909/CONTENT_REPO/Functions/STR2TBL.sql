CREATE OR REPLACE FUNCTION content_repo."STR2TBL" ( p_str in CLOB ) return numTableType
as
/*
|| xx/xx/2014 tnn
|| 08/27/2016 tnn Code cleanup - no rename, function being used in multiple areas
|| 09/01/2016 tnn "double paste"
||
*/
  l_data    numTableType := numTableType();  -- Global
  c                   CLOB;
  l_offset            POSITIVE := 1;
  l_part    long;
  l_counter           NATURAL := 0;
  xo numtabletype;
begin
 c:=p_str||',';
 WHILE (DBMS_LOB.INSTR(c,',',l_offset) > 0)
    LOOP
        l_part :=
                DBMS_LOB.SUBSTR(c
                ,               DBMS_LOB.INSTR(c
                                , ','
                                , l_offset) - l_offset
                ,               l_offset);
    l_offset := DBMS_LOB.INSTR(c,',',l_offset) + 1;
    l_data.extend;
    l_data( l_data.count ) :=  TO_NUMBER(l_part);
    END LOOP;

    return l_data;
end;
/