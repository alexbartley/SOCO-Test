CREATE OR REPLACE FUNCTION content_repo."GETCHANGELOGTABLES" (iEntityType IN number) RETURN VARCHAR2
    IS

    /* Lookup list for change log tables
       -- should have been in Oracle lookup table
       -- 1/7/2015: todo: name of the function itself
       -- based on a copy from package change_mgmt
    */
      qstr varchar2(256);
      TYPE sectionRecord IS RECORD
      (vld_table varchar2(32),
       log_table varchar2(32),
       ixcolumn varchar2(32));
      TYPE sectionTable IS TABLE OF sectionRecord; -- INDEX BY BINARY_INTEGER;
      sections sectionTable;
    BEGIN
      sections := sectionTable();
      sections.extend();
      sections(1).vld_table :='admin_chg_vlds';
      sections(1).log_table :='admin_chg_logs';
      sections(1).ixcolumn  :='admin_chg_log_id';
      sections.extend();
      sections(2).vld_table :='juris_chg_vlds';
      sections(2).log_table :='juris_chg_logs';
      sections(2).ixcolumn  :='juris_chg_log_id';
      sections.extend();
      sections(3).vld_table :='juris_tax_chg_vlds';
      sections(3).log_table :='juris_tax_chg_logs';
      sections(3).ixcolumn  :='juris_tax_chg_log_id';
      sections.extend();
      sections(4).vld_table :='juris_tax_app_chg_vlds';
      sections(4).log_table :='juris_tax_app_chg_logs';
      sections(4).ixcolumn  :='juris_tax_app_chg_log_id';
      sections.extend();
      sections(5).vld_table :='comm_chg_vlds';
      sections(5).log_table :='comm_chg_logs';
      sections(5).ixcolumn  :='comm_chg_log_id';
      sections.extend();
      sections(6).vld_table :='comm_grp_chg_vlds';
      sections(6).log_table :='comm_grp_chg_logs';
      sections(6).ixcolumn  :='comm_grp_chg_log_id';

      sections.extend();
      sections(7).vld_table :='comm_grp_chg_vlds';
      sections(7).log_table :='comm_grp_chg_logs';
      sections(7).ixcolumn  :='comm_grp_chg_log_id';
      sections.extend();
      sections(8).vld_table :='comm_grp_chg_vlds';
      sections(8).log_table :='comm_grp_chg_logs';
      sections(8).ixcolumn  :='comm_grp_chg_log_id';

      sections.extend();
      sections(9).vld_table :='ref_grp_chg_vlds';
      sections(9).log_table :='ref_grp_chg_logs';
      sections(9).ixcolumn  :='ref_grp_chg_log_id';

      sections.extend();
      sections(10).vld_table :='geo_poly_ref_chg_vlds';
      sections(10).log_table :='geo_poly_ref_chg_logs';
      sections(10).ixcolumn  :='geo_poly_ref_chg_log_id';

      /*qstr:='SELECT vl.id FROM '||sections(iEntityType).vld_table||' vl
        JOIN '||sections(iEntityType).log_table||' lg
          ON (lg.id = '||sections(iEntityType).ixcolumn||')
       WHERE lg.rid = :iRid AND lg.status<>2';*/
      qstr:=sections(iEntityType).log_table;
      RETURN qstr;

    END getChangeLogTables;
 
 
/