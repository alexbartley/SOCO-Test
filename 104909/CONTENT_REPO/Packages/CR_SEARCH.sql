CREATE OR REPLACE PACKAGE content_repo."CR_SEARCH"
IS
-- DEVELOPMENT PACKAGE
-- Purpose: CR Main Search
--
-- MODIFICATION HISTORY
-- Person      Date    Comments
-- ---------   ------  ------------------------------------------
   ix_count     NUMBER := 0;             -- # of hits
   ix_dsMax     NUMBER := 0;             -- record count
   is_text      BOOLEAN;                 -- text search
   is_searchcol BOOLEAN;                 -- searching column

   sConcatCol   VARCHAR2(512);           -- column names
   tc_st        NUMBER;                  -- start time
   tc_et        NUMBER;                  -- end time

   --JSON
   g_json_null_object            constant varchar2(20) := '{ }';

   Function get_xml_to_json_stylesheet return varchar2;

   PROCEDURE sync_citations_ix;
   PROCEDURE sync_juris_imp_ix;
   -- procedure juris_app_ix;
   -- procedure juris_ix;
   -- procedure comm_ix;
   -- procedure comm_grp_ix;

   -- procedure rc_ds_citations();
   -- procedure rc_ds_juris_imp();
   -- procedure rc_ds_juris_app();
   PROCEDURE attach_concat_columns(i_rowid IN ROWID, io_text IN OUT NOCOPY VARCHAR2);

END cr_search;
 
 
/