CREATE OR REPLACE FUNCTION content_repo."FNATTACHMENTSEXIST" (pEntity in number, pRid number) return number
is
  nAttch number:=0;
  TYPE sectionRecord IS RECORD
      (vld_table varchar2(32),
       log_table varchar2(32),
       ixcolumn varchar2(32));
  TYPE sectionTable IS TABLE OF sectionRecord;
  sections sectionTable;
begin
  sections := sectionTable();
  sections.extend();
  sections(1).vld_table :='admin_chg_cits';
  sections(1).log_table :='admin_chg_logs';
  sections(1).ixcolumn  :='admin_chg_log_id';
  sections.extend();
  sections(2).vld_table :='juris_chg_cits';
  sections(2).log_table :='juris_chg_logs';
  sections(2).ixcolumn  :='juris_chg_log_id';
  sections.extend();
  sections(3).vld_table :='juris_tax_chg_cits';
  sections(3).log_table :='juris_tax_chg_logs';
  sections(3).ixcolumn  :='juris_tax_chg_log_id';
  sections.extend();
  sections(4).vld_table :='juris_tax_app_chg_cits';
  sections(4).log_table :='juris_tax_app_chg_logs';
  sections(4).ixcolumn  :='juris_tax_app_chg_log_id';
  sections.extend();
  sections(5).vld_table :='comm_chg_cits';
  sections(5).log_table :='comm_chg_logs';
  sections(5).ixcolumn  :='comm_chg_log_id';
  sections.extend();
  sections(6).vld_table :='comm_grp_chg_cits';
  sections(6).log_table :='comm_grp_chg_logs';
  sections(6).ixcolumn  :='comm_grp_chg_log_id';
  sections.extend();
  sections(7).vld_table :='comm_grp_chg_cits';
  sections(7).log_table :='comm_grp_chg_logs';
  sections(7).ixcolumn  :='comm_grp_chg_log_id';
  sections.extend();
  sections(8).vld_table :='comm_grp_chg_cits';
  sections(8).log_table :='comm_grp_chg_logs';
  sections(8).ixcolumn  :='comm_grp_chg_log_id';
  sections.extend();
  sections(9).vld_table :='ref_grp_chg_cits';
  sections(9).log_table :='ref_grp_chg_logs';
  sections(9).ixcolumn  :='ref_grp_chg_log_id';
  sections.extend();
  sections(10).vld_table :='geo_poly_ref_chg_cits';
  sections(10).log_table :='geo_poly_ref_chg_logs';
  sections(10).ixcolumn  :='geo_poly_ref_chg_log_id';
  sections.extend();
  sections(11).vld_table :='geo_poly_ref_chg_cits';
  sections(11).log_table :='geo_unique_area_chg_logs';
  sections(11).ixcolumn  :='geo_unique_area_chg_log_id';

  EXECUTE IMMEDIATE 'Select count(*) from '||sections(pEntity).vld_table||
  ' where '||sections(pEntity).ixcolumn||
  ' in (select id from '||sections(pEntity).log_table||
  ' jc where jc.rid = :l_rid)'
  INTO nAttch USING pRid;
  return nAttch;
end fnAttachmentsExist;
 
/