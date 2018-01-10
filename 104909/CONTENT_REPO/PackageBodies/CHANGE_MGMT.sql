CREATE OR REPLACE PACKAGE BODY content_repo.change_mgmt
IS
/*
 CRAPP-3007/1775
 Variables for copy taxability action log message
 lcopy_err_message, lcopy_link

 Exceptions: rv_exception and time out
 report_and_stop
*/
    lcopy_err_message clob;
    lcopy_link varchar2(200);

    -- Build a list of log and vld tables
    -- Based on Entity used with change log id
    -- (See overloaded function)
    -- (Type could have been global)
    FUNCTION getLogTables_Chg(iEntityType IN number) RETURN VARCHAR2
    IS
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

      sections.extend();
      sections(11).vld_table :='juris_type_chg_vlds';
      sections(11).log_table :='juris_type_chg_logs';
      sections(11).ixcolumn  :='juris_type_chg_log_id';

      qstr:='SELECT vl.id FROM '||sections(iEntityType).vld_table||' vl
        JOIN '||sections(iEntityType).log_table||' lg
          ON (lg.id = '||sections(iEntityType).ixcolumn||')
       WHERE lg.id = :iChgLogId AND lg.status<>2';
      RETURN qstr;

    END getLogTables_Chg;

    -- Build a list of log and vld tables
    -- Based on Entity and User List used with change log id
    FUNCTION getLogTables_Chg(iEntityType IN number, userList in varchar2) RETURN VARCHAR2
    IS
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

      sections.extend();
      sections(11).vld_table :='juris_type_chg_vlds';
      sections(11).log_table :='juris_type_chg_logs';
      sections(11).ixcolumn  :='juris_type_chg_log_id';

      qstr:='SELECT vld.id FROM '||sections(iEntityType).vld_table||' vld
        JOIN '||sections(iEntityType).log_table||' lg
          ON (lg.id = '||sections(iEntityType).ixcolumn||')
       WHERE lg.id = :iChgLogId AND lg.status<>2 and vld.assigned_by IN( '||userlist||')';
      RETURN qstr;

    END getLogTables_Chg;

    -- Build a list of log and vld tables to used specifying RID
    --
    FUNCTION getLogTables(iEntityType IN number) RETURN VARCHAR2
    IS
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

      sections.extend();
      sections(11).vld_table :='juris_type_chg_vlds';
      sections(11).log_table :='juris_type_chg_logs';
      sections(11).ixcolumn  :='juris_type_chg_log_id';

      qstr:='SELECT vl.id FROM '||sections(iEntityType).vld_table||' vl
        JOIN '||sections(iEntityType).log_table||' lg
          ON (lg.id = '||sections(iEntityType).ixcolumn||')
       WHERE lg.rid = :iRid AND lg.status<>2';
      RETURN qstr;

    END getLogTables;

    -- Log tables based on entity and user list used with RID
    FUNCTION getLogTables(iEntityType IN number, userList in varchar2) RETURN VARCHAR2
    IS
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

      sections.extend();
      sections(11).vld_table :='juris_type_chg_vlds';
      sections(11).log_table :='juris_type_chg_logs';
      sections(11).ixcolumn  :='juris_type_chg_log_id';

      qstr:='SELECT vld.id FROM '||sections(iEntityType).vld_table||' vld
        JOIN '||sections(iEntityType).log_table||' lg
          ON (lg.id = '||sections(iEntityType).ixcolumn||')
       WHERE lg.rid = :iRid AND lg.status<>2 and vld.assigned_by IN( '||userlist||')';
      RETURN qstr;

    END getLogTables;

    -- Build validation query based on entity (used with RID)
    FUNCTION getVldItems(iEntityType IN number) RETURN VARCHAR2
    IS
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
      -- 7 and 8 are not used yet
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

      sections.extend();
      sections(11).vld_table :='juris_type_chg_vlds';
      sections(11).log_table :='juris_type_chg_logs';
      sections(11).ixcolumn  :='juris_type_chg_log_id';

      qstr:='SELECT vl.id FROM '||sections(iEntityType).vld_table||' vl
        JOIN '||sections(iEntityType).log_table||' lg
          ON (lg.id = vl.'||sections(iEntityType).ixcolumn||')
       WHERE lg.rid = :iRid AND lg.status=0';
      RETURN qstr;
    END getVldItems;


    PROCEDURE dev_vld_remove(ientity_type IN NUMBER, iRid IN NUMBER, unlock_success OUT NUMBER)
    IS
      l_del_vlds chglogids := chglogids();  -- list of id
      l_entity NUMBER := ientity_type;      -- 1..6
      l_rid NUMBER    := iRid;              -- current rid to reset
      l_upd_success NUMBER := 0;
      -- Tables
      QryVld CLOB;
    BEGIN
      --
      IF l_entity IS NOT NULL THEN
         QryVld := getVldItems(l_entity);
         EXECUTE IMMEDIATE QryVld
         BULK COLLECT INTO l_del_vlds using l_rid;
      IF (l_entity = '1') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_admin_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '2') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_juris_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '3') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_tax_chg_logs(l_del_vlds);
         END LOOP;
       ELSIF (l_entity = '4') THEN
          FOR i IN 1..l_del_vlds.COUNT LOOP
              CHANGE_MGMT.unsign_tax_app_chg_logs(l_del_vlds);
          END LOOP;
      ELSIF (l_entity = '5') THEN
          -- Commodities
          FOR i IN 1..l_del_vlds.COUNT LOOP
              CHANGE_MGMT.unsign_comm_chg_logs(l_del_vlds);
          END LOOP;

      ELSIF (l_entity = '9') THEN
          -- Reference Groups
          FOR i IN 1..l_del_vlds.COUNT LOOP
              CHANGE_MGMT.unsign_ref_grp_chg_logs(l_del_vlds);
          END LOOP;
      ELSIF (l_entity = '11') THEN
          -- Jurisdiction Types
          FOR i IN 1..l_del_vlds.COUNT LOOP
              CHANGE_MGMT.unsign_juris_type_chg_logs(l_del_vlds);
          END LOOP;
      END IF;
     l_upd_success := 1;
      unlock_success := l_upd_success;
      ELSE
        l_upd_success := 0;
        unlock_success := l_upd_success;
      END IF;
    END dev_vld_remove;


    -- Bulk Add verification
    procedure Bulk_Verification(pEntity_Type in number
                              , change_id_list in clob
                              , verif_type in number
                              , entered_by in number
                              , success_o out number)
    is
      change_list numTableType; -- table of numbers
      change_tt chglogids := chglogids();
    begin
      change_list:=str2tbl( change_id_list );
      SELECT DISTINCT COLUMN_VALUE BULK COLLECT INTO change_tt FROM TABLE(change_list);

      IF (pEntity_Type = 1) THEN
                CHANGE_MGMT.sign_admin_chg_logs(change_tt, entered_by, verif_type);
      ELSIF (pEntity_Type = 2) THEN
                CHANGE_MGMT.sign_juris_chg_logs(change_tt, entered_by, verif_type);
      ELSIF (pEntity_Type = 3) THEN
                CHANGE_MGMT.sign_tax_chg_logs(change_tt, entered_by, verif_type);
      ELSIF (pEntity_Type = 4) THEN
                CHANGE_MGMT.sign_tax_app_chg_logs(change_tt, entered_by, verif_type);
      ELSIF (pEntity_Type = 5) THEN
                CHANGE_MGMT.sign_comm_chg_logs(change_tt, entered_by, verif_type);
      ELSIF (pEntity_Type = 9) THEN
                CHANGE_MGMT.sign_ref_grp_chg_logs(change_tt, entered_by, verif_type);
      ELSIF (pEntity_Type = 11) THEN
                CHANGE_MGMT.sign_juris_type_chg_logs(change_tt, entered_by, verif_type);
      END IF;
      success_o := 1;
    end;

    -- Dev: 3/31/2014 Remove verification
    -- Entity, list of rids, return success flag, return log id
    procedure Bulk_Remove_Verification(pEntity_Type in number
                                     , rid_list in clob
                                     , deleted_by_i in number
                                     , success_o out number
                                     , logId_o out number)
    is
      change_tt numTableType;     -- table of numbers
      pr number := 0;             -- process status for delete verification
      nLog_id number := null;
      l_logged number := 0;
      l_remove_ver_n number := 0; -- remove verification status

      --timer
      sx number;
      sy number;

    begin
      success_o := 1;
      change_tt:=str2tbl( rid_list );
      -- Log Id
      nLog_id := Log_Remove_Revision_Seq.NEXTVAL();

      --timer
      sx:=DBMS_UTILITY.get_time;

      FOR i IN 1 .. change_tt.count LOOP
        --> Remove:
        unlock_revision(pEntity_Type, change_tt(i), l_remove_ver_n);

        -- Log failure
        if l_remove_ver_n = 0 then
           log_remove(nLog_id, change_tt(i), pEntity_Type);
        end if;


      end loop;

      --timer
      sy:=DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('T:'||to_char(sy-sx));

      -- Quick check for logged records
      Select COUNT(*) into l_logged
        from change_log_remove_rev
       where logId = nLog_id;
      if (l_logged>0) then
        success_o := 0;
        logId_o := nLog_id;
      else
        success_o := 1;
        logId_o := null;
      end if;

      EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
          success_o := 0;
          raise;
    end;


    --OVERLOADED
    -- 6/26/14
    procedure Bulk_Remove_Verification(pEntity_Type in number
                                     , rid_list in clob
                                     , deleted_by_r in varchar2
                                     , success_o out number
                                     , logId_o out number)
    is
      change_tt numTableType;     -- table of numbers
      pr number := 0;             -- process status for delete verification
      nLog_id number := null;
      l_logged number := 0;
      l_remove_ver_n number := 0; -- remove verification status
    begin
      success_o := 1;
      change_tt:=str2tbl( rid_list );

      -- Log Id
      nLog_id := Log_Remove_Revision_Seq.NEXTVAL();

      FOR i IN 1 .. change_tt.count LOOP
        --> Remove:
        unlock_revision(ientity_type=>pEntity_Type, iRid=>change_tt(i), unlock_success=>l_remove_ver_n, userList=>deleted_by_r);
        -- Log failure
        if l_remove_ver_n = 0 then
           log_remove(nLog_id, change_tt(i), pEntity_Type);
        end if;

      end loop;

    -- Quick check for logged records
      Select COUNT(*) into l_logged
        from change_log_remove_rev
       where logId = nLog_id;
      if (l_logged>0) then
        success_o := 0;
        logId_o := nLog_id;
      else
        success_o := 1;
        logId_o := null;
      end if;

      EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
          success_o := 0;
          raise;
    end;

    -- Bulk remove verifications based on change log id
    procedure Bulk_Remove_Verif_Chg (pEntity_Type in number
                                     , changelog_list in clob
                                     , deleted_by_i in number
                                     , success_o out number
                                     , logId_o out number
                                     , myVerification in number)
    is
      change_tt numTableType;     -- table of numbers
      pr number := 0;             -- process status for delete verification
      nLog_id number := null;
      l_logged number := 0;
      l_remove_ver_n number := 0; -- remove verification status
    begin
      success_o := 1;
      change_tt:=str2tbl( changelog_list );

      -- Log Id uses the same sequence as remove bulk revisions
      -- it's just a sequence # to send back to the MidTier
      nLog_id := Log_Remove_Revision_Seq.NEXTVAL();

      FOR i IN 1 .. change_tt.count LOOP
        if myVerification=1 then
          unlock_change_log(pEntity_Type, change_tt(i), l_remove_ver_n, to_char(deleted_by_i));
        else
          unlock_change_log(pEntity_Type, change_tt(i), l_remove_ver_n);
        end if;

        -- Log failure
        if l_remove_ver_n = 0 then
           log_remove(nLog_id, change_tt(i), pEntity_Type);
        end if;

      end loop;

    -- Quick check for logged records
      Select COUNT(*) into l_logged
        from change_log_remove_rev
       where logId = nLog_id;
      if (l_logged>0) then
        success_o := 0;
        logId_o := nLog_id;
      else
        success_o := 1;
        logId_o := null;
      end if;

      EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
          success_o := 0;
          raise;
    End Bulk_Remove_Verif_Chg;


    -- Bulk remove verifications based on change log id
    procedure Bulk_Remove_Verif_Chg (pEntity_Type in number
                                     , changelog_list in clob
                                     , deleted_by_r in varchar2
                                     , success_o out number
                                     , logId_o out number
                                     , myVerification in number)
    is
      change_tt numTableType;     -- table of numbers
      pr number := 0;             -- process status for delete verification
      nLog_id number := null;
      l_logged number := 0;
      l_remove_ver_n number := 0; -- remove verification status
    begin
      success_o := 1;
      change_tt:=str2tbl( changelog_list );

      -- Log Id uses the same sequence as remove bulk revisions
      -- it's just a sequence # to send back to the MidTier
      nLog_id := Log_Remove_Revision_Seq.NEXTVAL();

      FOR i IN 1 .. change_tt.count LOOP
        if myVerification=1 then
          unlock_change_log(pEntity_Type, change_tt(i), l_remove_ver_n, deleted_by_r);
        else
          unlock_change_log(pEntity_Type, change_tt(i), l_remove_ver_n);
        end if;

        -- Log failure
        if l_remove_ver_n = 0 then
           log_remove(nLog_id, change_tt(i), pEntity_Type);
        end if;
      end loop;

    -- Quick check for logged records
      Select COUNT(*) into l_logged
        from change_log_remove_rev
       where logId = nLog_id;
      if (l_logged>0) then
        success_o := 0;
        logId_o := nLog_id;
      else
        success_o := 1;
        logId_o := null;
      end if;

      EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
          success_o := 0;
          raise;
    End Bulk_Remove_Verif_Chg;


    PROCEDURE XMLProcess_Form_RvwChgLog(
        sx IN CLOB,
        update_success OUT NUMBER
        )
    IS
    --l_ids IS TABLE OF INTEGER;
    l_reviewed_by NUMBER;
    l_review_type_id NUMBER;
    l_entity VARCHAR2(50);
    l_chg_logs chglogids;
    l_del_vlds chglogids := chglogids();
    l_rvw_types chglogids  := chglogids();
    --CLBTemp    CLOB := TO_CHAR(sx);
    l_upd_success NUMBER := 0;
    l_deleted NUMBER;

    rv_exception EXCEPTION;                       -- review exception
    PRAGMA EXCEPTION_INIT (rv_exception, -21100); -- assigned error code to exception
    BEGIN
    -- nnt_xml_p(puiusr=> 304, ppart=> 2, inxml=> sx);
    --Get Entity Type and Entered By
        SELECT
            extractvalue(column_value, '/change_log/entity') entity,
            extractvalue(column_value, '/change_log/entered_by') reviewed_by
        INTO
            l_entity,
            l_reviewed_by
        FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/change_log'))) t;
    --Get Reviewed_By and Review_Type_Id and deleted flag
    FOR  v IN (
        SELECT
            extractvalue(column_value, '/verifications/id') id,
            extractvalue(column_value, '/verifications/verification_level') review_type_id,
            extractvalue(column_value, '/verifications/deleted') deleted
        FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/change_log/verifications')) )
        ) LOOP
            IF (v.id IS NULL) THEN
                --we are adding review rows because it does not exist yet
                l_rvw_types.extend;
                l_rvw_types(l_rvw_types.last) := v.review_type_id;
            ELSIF NVL(v.deleted,0) = 1 THEN
                --the review already exists and needs to be deleted
                l_del_vlds.extend;
                l_del_vlds(l_del_vlds.last) := v.id;
            END IF;
        END LOOP;
    --Get Change_Log_Ids to apply the above to
        SELECT
            extractvalue(column_value, '/id')
        BULK COLLECT INTO
            l_chg_logs
        FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/change_log/changes/id'))) t;

        IF (l_entity = '1') THEN
            FOR i IN 1..l_rvw_types.COUNT LOOP
                CHANGE_MGMT.sign_admin_chg_logs(l_chg_logs, l_reviewed_by, l_rvw_types(i));
            END LOOP;
            FOR i IN 1..l_del_vlds.COUNT LOOP
                CHANGE_MGMT.unsign_admin_chg_logs(l_del_vlds);
            END LOOP;
        ELSIF (l_entity = '2') THEN
            FOR i IN 1..l_rvw_types.COUNT LOOP
                CHANGE_MGMT.sign_juris_chg_logs(l_chg_logs, l_reviewed_by, l_rvw_types(i));
            END LOOP;
            FOR i IN 1..l_del_vlds.COUNT LOOP
                CHANGE_MGMT.unsign_juris_chg_logs(l_del_vlds);
            END LOOP;
        ELSIF (l_entity = '3') THEN
            FOR i IN 1..l_rvw_types.COUNT LOOP
                CHANGE_MGMT.sign_tax_chg_logs(l_chg_logs, l_reviewed_by, l_rvw_types(i));
            END LOOP;
            FOR i IN 1..l_del_vlds.COUNT LOOP
                CHANGE_MGMT.unsign_tax_chg_logs(l_del_vlds);
            END LOOP;
        ELSIF (l_entity = '4') THEN
            FOR i IN 1..l_rvw_types.COUNT LOOP
                CHANGE_MGMT.sign_tax_app_chg_logs(l_chg_logs, l_reviewed_by, l_rvw_types(i));
            END LOOP;
            FOR i IN 1..l_del_vlds.COUNT LOOP
                CHANGE_MGMT.unsign_tax_app_chg_logs(l_del_vlds);
            END LOOP;
        ELSIF (l_entity = '5') THEN
            -- Commodities
            FOR i IN 1..l_rvw_types.COUNT LOOP
                CHANGE_MGMT.sign_comm_chg_logs(l_chg_logs, l_reviewed_by, l_rvw_types(i));
            END LOOP;
            FOR i IN 1..l_del_vlds.COUNT LOOP
                CHANGE_MGMT.unsign_comm_chg_logs(l_del_vlds);
            END LOOP;
        ELSIF (l_entity = '9') THEN
            -- Reference Groups
            FOR i IN 1..l_rvw_types.COUNT LOOP
                CHANGE_MGMT.sign_ref_grp_chg_logs(l_chg_logs, l_reviewed_by, l_rvw_types(i));
            END LOOP;
            FOR i IN 1..l_del_vlds.COUNT LOOP
                CHANGE_MGMT.unsign_ref_grp_chg_logs(l_del_vlds);
            END LOOP;
        ELSIF (l_entity = '11') then
            FOR i IN 1..l_rvw_types.COUNT LOOP
                CHANGE_MGMT.sign_juris_type_chg_logs(l_chg_logs, l_reviewed_by, l_rvw_types(i));
            END LOOP;
            FOR i IN 1..l_del_vlds.COUNT LOOP
                CHANGE_MGMT.unsign_juris_type_chg_logs(l_del_vlds);
            END LOOP;
        ELSIF (l_entity = '12') then
            null;
        END IF;
    l_upd_success := 1;
    update_success := l_upd_success;

    Exception
    When rv_exception then
      update_success := 0;
    When others then
      update_success := 0;

    END;

    PROCEDURE XMLProcess_Form_UpdChgLog(sx IN CLOB, update_success OUT NUMBER) IS
      l_citations XMLForm_Cita_TT := XMLForm_Cita_TT();
      l_external  XMLForm_External_Ref_TT := XMLForm_External_Ref_TT();
      l_entity VARCHAR2(50);
      l_overwrite NUMBER;
      l_change_reason_id NUMBER;
      l_summary VARCHAR2(1000);
      l_entered_by NUMBER;
      l_chg_logs chglogids;
      --CLBTemp    CLOB := TO_CHAR(sx);
      l_upd_success NUMBER := 0;
      TYPE docids IS TABLE OF INTEGER;
      l_docs docids := docids();

    -- External references
    CURSOR crs (sx IN clob) IS
    SELECT
    id,
    ref_system,
    ref_id ,
    ext_link,
    deleted,
    modified
    FROM xmltable('change_log/external_ref'
    passing XMLType(sx)
    COLUMNS
        id NUMBER path 'id',
        ref_system NUMBER path 'system',
        ref_id varchar2(2048) path 'reference_id',
        ext_link varchar2(2048) path 'link',
        deleted NUMBER path 'deleted',
        modified NUMBER path 'modified') x;
    TYPE ext_TR IS TABLE OF crs%ROWTYPE INDEX BY PLS_INTEGER;
    rec_ext ext_TR;    -- record external reference
    lmt NUMBER := 100; -- bulk record count

    BEGIN

    --Get Overwrite flag, Change_Reason_Id, Summary, Entered_By
        SELECT
            extractvalue(column_value, '/change_log/entity') entity,
            extractvalue(column_value, '/change_log/overwrite') overwrite,
            extractvalue(column_value, '/change_log/change_reason_id') change_reason_id,
            extractvalue(column_value, '/change_log/summary') summary,
            extractvalue(column_value, '/change_log/entered_by') entered_by
        INTO
            l_entity,
            l_overwrite,
            l_change_reason_id,
            l_summary,
            l_entered_by
        FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/change_log'))) t;

    --Get Change_Log_Ids to apply the above to
        SELECT
            extractvalue(column_value, '/id')
        BULK COLLECT INTO
            l_chg_logs
        FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/change_log/changes/id'))) t;
    --Get Documents to apply the above to
        SELECT
            extractvalue(column_value, '/document/id') id
        BULK COLLECT INTO
            l_docs
        FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/change_log/document'))) t;

       --Get the Citations to apply to the Change_Log_Ids

        FOR d IN 1..l_docs.COUNT LOOP
        --Get the Citations to apply to the Change_Log_Ids
            FOR citation IN (
                SELECT
                    extractvalue(column_value, '/citation/id') id,
                    extractvalue(column_value, '/citation/text') text,
                    extractvalue(column_value, '/citation/deleted') del,
                    l_docs(d) attachment_id
                FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/change_log/document['||d||']/citation'))) t
            ) LOOP

                --dbms_output.put_line(d||':'||citation.id||':'||citation.text||':'||citation.attachment_id||':'||citation.del);
                l_citations.EXTEND;
                l_citations(l_citations.last) :=
                XMLForm_Citation(
                    citation.id,
                    citation.text,
                    citation.attachment_id,
                    citation.del
                    );
            END LOOP;
        END LOOP;

        --
        -- External References
        --
        -- kept this to be able to add columns to XMLForm_External_Ref if needed
        OPEN crs(sx);
        LOOP
        FETCH crs BULK COLLECT INTO rec_ext;
        FOR indx IN 1 .. rec_ext.COUNT
        LOOP
         l_external.extend;
         l_external(l_external.last) := XMLForm_External_Ref
         (rec_ext(indx).id,
          rec_ext(indx).ref_system,
          rec_ext(indx).ref_id,
          rec_ext(indx).ext_link,
          rec_ext(indx).deleted,
          rec_ext(indx).modified);
        END LOOP;
        EXIT WHEN rec_ext.COUNT < lmt;
        END LOOP;
        CLOSE crs;

    --Update change_logs with citations and summary/reason
    CHANGE_MGMT.upd_change_logs(l_entity,
                                l_chg_logs,
                                l_citations,
                                l_external,
                                l_change_reason_id,
                                l_summary,
                                l_overwrite,
                                l_entered_by);
    l_upd_success := 1;

    update_success := l_upd_success;
    EXCEPTION
            WHEN others THEN
              ROLLBACK;
              errlogger.report_and_stop(SQLCODE,'Update change log error: by '||l_entered_by);
    END XMLProcess_Form_UpdChgLog;


    PROCEDURE upd_change_logs(entity_i IN VARCHAR2, change_logs_i IN chglogids,
                              citations_i IN XMLForm_Cita_TT,
                              external_links_i IN XMLForm_External_Ref_TT,
                              change_reason_id_i IN NUMBER,
                              summary_i IN VARCHAR2,
                              overwrite_i IN NUMBER, entered_by_i IN NUMBER)
    IS
     type citids is table of NUMBER;
     l_remove_citations citids := citids();
     l_citation_id NUMBER;
     l_citations citids := citids();

     l_extlink_id NUMBER;
     l_ext_id NUMBER;

    BEGIN
    -- citations
      FOR cita IN 1..citations_i.COUNT LOOP <<citations>>
        l_citation_id := citations_i(cita).id;
        IF (l_citation_id IS NULL) THEN
            INSERT INTO citations(text,attachment_id, entered_by)
            VALUES (citations_i(cita).text, citations_i(cita).attachment_id,entered_by_i)
            RETURNING id INTO l_citation_id;
        END IF;
        IF (citations_i(cita).deleted = 1) THEN
            l_remove_citations.extend;
            l_remove_citations(l_remove_citations.last) := l_citation_id;
        ELSE
            l_citations.extend;
            l_citations(l_citations.last) := l_citation_id;
        END IF;
      END LOOP citations;

      -- external links
      FOR clog IN 1..change_logs_i.COUNT LOOP <<changelogid>>
        FOR extlink IN 1..external_links_i.COUNT LOOP <<extlinks>>
          l_extlink_id := external_links_i(extlink).id;
          IF (l_extlink_id IS NULL) THEN
            INSERT INTO external_references(chng_id, entity_type, ref_system, ref_id, ext_link, entered_by)
            VALUES (change_logs_i(clog),
                    entity_i,
                    external_links_i(extlink).ref_system,
                    external_links_i(extlink).ref_id,
                    external_links_i(extlink).ext_link,
                    entered_by_i)
            RETURNING id INTO l_ext_id;
          ELSIF (l_extlink_id IS NOT NULL AND nvl(external_links_i(extlink).modified,0)=1) THEN
            UPDATE external_references
               SET ref_system = external_links_i(extlink).ref_system,
                   ref_id = external_links_i(extlink).ref_id,
                   ext_link = external_links_i(extlink).ext_link,
                   entity_type = entity_i
            WHERE id = l_extlink_id
              AND chng_id = change_logs_i(clog);
          END IF;
          IF (external_links_i(extlink).deleted = 1) THEN
            DELETE FROM external_references
            WHERE id = l_extlink_id;
          END IF;
        END LOOP extlinks;
      END LOOP changelogid;

      IF (entity_i = '1') THEN
        FOR clog IN 1..change_logs_i.COUNT LOOP
            change_mgmt.add_admin_chg_rsn(
                change_logs_i(clog),
                change_reason_id_i,
                summary_i,
                overwrite_i,
                entered_by_i);
            FOR c1 IN 1..l_citations.COUNT LOOP <<citations>>
                CHANGE_MGMT.add_admin_chg_cit(
                    change_logs_i(clog),
                    l_citations(c1),
                    entered_by_i);
            END LOOP citations;
            FOR c2 IN 1..l_remove_citations.COUNT LOOP <<remove_citations>>

                DELETE FROM admin_chg_cits
                WHERE admin_chg_log_id = change_logs_i(clog)
                AND citation_id = l_remove_citations(c2);
            END LOOP remove_citations;
        END LOOP;
      ELSIF (entity_i = '2') THEN

        FOR clog IN 1..change_logs_i.COUNT LOOP
            change_mgmt.add_juris_chg_rsn(
                change_logs_i(clog),
                change_reason_id_i,
                summary_i,
                overwrite_i,
                entered_by_i);

            FOR c1 IN 1..l_citations.COUNT LOOP <<citations>>
                CHANGE_MGMT.add_juris_chg_cit(
                    change_logs_i(clog),
                    l_citations(c1),
                    entered_by_i);
            END LOOP citations;
            FOR c2 IN 1..l_remove_citations.COUNT LOOP <<remove_citations>>
                DELETE FROM juris_chg_cits
                WHERE juris_chg_log_id = change_logs_i(clog)
                AND citation_id = l_remove_citations(c2);
            END LOOP remove_citations;
        END LOOP;
      ELSIF (entity_i = '3') THEN
        FOR clog IN 1..change_logs_i.COUNT LOOP
            change_mgmt.add_tax_chg_rsn(
                change_logs_i(clog),
                change_reason_id_i,
                summary_i,
                overwrite_i,
                entered_by_i);
            FOR c1 IN 1..l_citations.COUNT LOOP <<citations>>
                CHANGE_MGMT.add_tax_chg_cit(
                    change_logs_i(clog),
                    l_citations(c1),
                    entered_by_i);
            END LOOP citations;
            FOR c2 IN 1..l_remove_citations.COUNT LOOP <<remove_citations>>
                DELETE FROM juris_tax_chg_cits
                WHERE juris_tax_chg_log_id = change_logs_i(clog)
                AND citation_id = l_remove_citations(c2);
            END LOOP remove_citations;
        END LOOP;
      ELSIF (entity_i = '4') THEN
        FOR clog IN 1..change_logs_i.COUNT LOOP
            change_mgmt.add_tax_app_chg_rsn(
                change_logs_i(clog),
                change_reason_id_i,
                summary_i,
                overwrite_i,
                entered_by_i);
            FOR c1 IN 1..l_citations.COUNT LOOP <<citations>>
                CHANGE_MGMT.add_tax_app_chg_cit(
                    change_logs_i(clog),
                    l_citations(c1),
                    entered_by_i);
            END LOOP citations;
            FOR c2 IN 1..l_remove_citations.COUNT LOOP <<remove_citations>>
                DELETE FROM juris_tax_app_chg_cits
                WHERE juris_tax_app_chg_log_id = change_logs_i(clog)
                AND citation_id = l_remove_citations(c2);
            END LOOP remove_citations;
        END LOOP;
      ELSIF (entity_i = '5') THEN
      -- Commodities
        FOR clog IN 1..change_logs_i.COUNT LOOP
            change_mgmt.add_comm_chg_rsn(
                change_logs_i(clog),
                change_reason_id_i,
                summary_i,
                overwrite_i,
                entered_by_i);

            FOR c1 IN 1..l_citations.COUNT LOOP <<citations>>
                CHANGE_MGMT.add_comm_chg_cit(
                    change_logs_i(clog),
                    l_citations(c1),
                    entered_by_i);
            END LOOP citations;
            FOR c2 IN 1..l_remove_citations.COUNT LOOP <<remove_citations>>
                DELETE FROM comm_chg_cits
                WHERE comm_chg_log_id = change_logs_i(clog)
                AND citation_id = l_remove_citations(c2);
            END LOOP remove_citations;
        END LOOP;
      ELSIF (entity_i = '9') THEN
      -- Reference Groups
        FOR clog IN 1..change_logs_i.COUNT LOOP
            change_mgmt.add_ref_grp_chg_rsn(
                change_logs_i(clog),
                change_reason_id_i,
                summary_i,
                overwrite_i,
                entered_by_i);

            FOR c1 IN 1..l_citations.COUNT LOOP <<citations>>
                CHANGE_MGMT.add_ref_grp_chg_cit(
                    change_logs_i(clog),
                    l_citations(c1),
                    entered_by_i);
            END LOOP citations;
            FOR c2 IN 1..l_remove_citations.COUNT LOOP <<remove_citations>>
                DELETE FROM ref_grp_chg_cits
                WHERE ref_grp_chg_log_id = change_logs_i(clog)
                AND citation_id = l_remove_citations(c2);
            END LOOP remove_citations;
        END LOOP;
      ELSIF (entity_i = '11') THEN
      -- Jurisdiction Type
        FOR clog IN 1..change_logs_i.COUNT LOOP
            change_mgmt.add_juris_type_chg_rsn(
                change_logs_i(clog),
                change_reason_id_i,
                summary_i,
                overwrite_i,
                entered_by_i);

            FOR c1 IN 1..l_citations.COUNT LOOP <<citations>>
                CHANGE_MGMT.add_juris_type_chg_cit(
                    change_logs_i(clog),
                    l_citations(c1),
                    entered_by_i);
            END LOOP citations;
            FOR c2 IN 1..l_remove_citations.COUNT LOOP <<remove_citations>>
                DELETE FROM juris_type_chg_cits
                WHERE juris_type_chg_log_id = change_logs_i(clog)
                AND citation_id = l_remove_citations(c2);
            END LOOP remove_citations;
        END LOOP;

      END IF;
      EXCEPTION
           WHEN others THEN
                ROLLBACK;
                errlogger.report_and_stop(SQLCODE,'Delete change log error: ');
    END upd_change_logs;


    PROCEDURE add_admin_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        )
    IS
        l_reason_id NUMBER;
        l_summary VARCHAR2(4000);
        l_excl NUMBER := 0;
    BEGIN
        /*IF (overwrite_i = 0) THEN
            --check and get the one that already exists
            SELECT COUNT(*)
            INTO l_excl
            FROM admin_chg_logs
            WHERE id = change_log_id_i
            AND (reason_id IS NULL
            OR summary IS NULL);
        END IF;*/

        --IF (l_excl = 0) THEN
            --update the reason if it has already been set
            UPDATE admin_chg_logs clr
            SET reason_id = reason_id_i,
                summary = summary_i
            WHERE id = change_log_id_i;
        --END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i does not exist: '||change_log_id_i);
    END add_admin_chg_rsn;

    -- Jurisdiction
    PROCEDURE add_juris_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER;
        l_reason_id NUMBER;
        l_summary VARCHAR2(4000);
        l_excl NUMBER := 0;
    BEGIN
        /*IF (overwrite_i = 0) THEN
            --check and get the one that already exists
            SELECT COUNT(*)
            INTO l_excl
            FROM juris_chg_logs
            WHERE id = change_log_id_i
            AND (reason_id IS NULL
            OR summary IS NULL);
        END IF;
        */

        --IF (l_excl = 0) THEN
            --update the reason if it has already been set
            UPDATE juris_chg_logs clr
            SET reason_id = reason_id_i,
                summary = summary_i
            WHERE id = change_log_id_i;
        --END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i does not exist: '||change_log_id_i);
    END add_juris_chg_rsn;

    -- Jurisdiction Type
    PROCEDURE add_juris_type_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER;
        l_reason_id NUMBER;
        l_summary VARCHAR2(4000);
        l_excl NUMBER := 0;
    BEGIN
        --IF (l_excl = 0) THEN
            --update the reason if it has already been set
            UPDATE juris_type_chg_logs clr
            SET reason_id = reason_id_i,
                summary = summary_i
                --entered_by = entered_by_i
            WHERE id = change_log_id_i;
        --END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i does not exist: '||change_log_id_i);
    END add_juris_type_chg_rsn;


    PROCEDURE add_tax_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER;
        l_reason_id NUMBER;
        l_summary VARCHAR2(4000);
        l_excl NUMBER := 0;
    BEGIN
        /*
        IF (overwrite_i = 0) THEN
            --check and get the one that already exists
            SELECT COUNT(*)
            INTO l_excl
            FROM juris_tax_chg_logs
            WHERE id = change_log_id_i
            AND (reason_id IS NULL
            OR summary IS NULL);
        END IF;
        */

        --IF (l_excl = 0) THEN
        --update the reason if it has already been set
          UPDATE juris_tax_chg_logs clr
          SET reason_id = reason_id_i,
              summary = summary_i
          WHERE id = change_log_id_i AND status<>2;
        --END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i does not exist: '||change_log_id_i);
    END add_tax_chg_rsn;

    PROCEDURE add_tax_app_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER;
        l_reason_id NUMBER;
        l_summary VARCHAR2(4000);
        l_excl NUMBER := 0;
    BEGIN
       /* IF (overwrite_i = 0) THEN
            --check and get the one that already exists
            SELECT COUNT(*)
            INTO l_excl
            FROM juris_tax_app_chg_logs
            WHERE id = change_log_id_i
            AND (reason_id IS NULL
            OR summary IS NULL);
        END IF;*/

--        IF (l_excl = 0) THEN
            --update the reason if it has already been set
            UPDATE juris_tax_app_chg_logs clr
            SET reason_id = reason_id_i,
                summary = summary_i
                --entered_by = entered_by_i
            WHERE id = change_log_id_i;
       -- END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i does not exist: '||change_log_id_i);
    END add_tax_app_chg_rsn;

    -- Commodities
    PROCEDURE add_comm_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER;
        l_reason_id NUMBER;
        l_summary VARCHAR2(4000);
        l_excl NUMBER := 0;
    BEGIN
       /* IF (overwrite_i = 0) THEN
            --check and get the one that already exists
            SELECT COUNT(*)
            INTO l_excl
            FROM comm_chg_logs
            WHERE id = change_log_id_i
            AND (reason_id IS NULL
            OR summary IS NULL);
        END IF;*/

        --IF (l_excl = 0) THEN
            --update the reason if it has already been set
            UPDATE comm_chg_logs clr
            SET reason_id = reason_id_i,
                summary = summary_i
                --entered_by = entered_by_i
            WHERE id = change_log_id_i;
        --END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i does not exist: '||change_log_id_i);
    END add_comm_chg_rsn;

    -- Reference Groups
    PROCEDURE add_ref_grp_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER;
        l_reason_id NUMBER;
        l_summary VARCHAR2(4000);
        l_excl NUMBER := 0;
    BEGIN
        /*IF (overwrite_i = 0) THEN
            --check and get the one that already exists
            SELECT COUNT(*)
            INTO l_excl
            FROM ref_grp_chg_logs
            WHERE id = change_log_id_i
            AND (reason_id IS NULL
            OR summary IS NULL);
        END IF;*/

        --IF (l_excl = 0) THEN
            --update the reason if it has already been set
            UPDATE ref_grp_chg_logs clr
            SET reason_id = reason_id_i,
                summary = summary_i
                --entered_by = entered_by_i
            WHERE id = change_log_id_i;
        --END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i does not exist: '||change_log_id_i);
    END add_ref_grp_chg_rsn;

    --
    PROCEDURE add_admin_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER := change_log_id_i;
        l_Citation_id NUMBER := citation_id_i;
        l_entered_by NUMBER := entered_by_i;
        l_excit NUMBER;
        l_orig_creator number;
    BEGIN
        SELECT COUNT(*)
          INTO l_excit
          FROM admin_chg_cits
         WHERE admin_chg_log_id = l_change_log_id
           and citation_id = l_citation_id;
        IF (l_excit = 0) THEN

            Select entered_by
            INTO l_orig_creator
            From admin_chg_logs
            WHERE id = l_change_log_id;

          INSERT INTO admin_chg_cits (admin_chg_log_id, citation_id, entered_by)
          VALUES (l_change_log_id, l_citation_id, l_orig_creator);
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i is invalid or uneditable: '||change_log_id_i);
    END add_admin_chg_cit;


    PROCEDURE add_juris_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER := change_log_id_i;
        l_Citation_id NUMBER := citation_id_i;
        l_entered_by NUMBER := entered_by_i;
        l_excit NUMBER;
        l_orig_creator number;
    BEGIN
        SELECT COUNT(*)
        INTO l_excit
        FROM juris_chg_cits
        WHERE juris_chg_log_id = l_change_log_id
        and citation_id = l_citation_id;
        IF (l_excit = 0) THEN

            Select entered_by
            INTO l_orig_creator
            From juris_chg_logs
            WHERE id = l_change_log_id;

        INSERT INTO juris_chg_cits (juris_chg_log_id, citation_id, entered_by)
        VALUES (l_change_log_id, l_citation_id, l_orig_creator);
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i is invalid or uneditable: '||change_log_id_i);
    END add_juris_chg_cit;

    PROCEDURE add_juris_type_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER := change_log_id_i;
        l_Citation_id NUMBER := citation_id_i;
        l_entered_by NUMBER := entered_by_i;
        l_excit NUMBER;
        l_orig_creator number;
    BEGIN
        SELECT COUNT(*)
          INTO l_excit
          FROM juris_type_chg_cits
         WHERE juris_type_chg_log_id = l_change_log_id
           and citation_id = l_citation_id;
        IF (l_excit = 0) THEN

            Select entered_by
            INTO l_orig_creator
            From juris_type_chg_logs
            WHERE id = l_change_log_id;

          INSERT INTO juris_type_chg_cits (juris_type_chg_log_id, citation_id, entered_by)
          VALUES (l_change_log_id, l_citation_id, l_orig_creator);
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i is invalid or uneditable: '||change_log_id_i);
    END add_juris_type_chg_cit;


    PROCEDURE add_tax_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER := change_log_id_i;
        l_Citation_id NUMBER := citation_id_i;
        l_entered_by NUMBER := entered_by_i;
        l_excit NUMBER;
        l_orig_creator number;
    BEGIN
        SELECT COUNT(*)
        INTO l_excit
        FROM juris_tax_chg_cits
        WHERE juris_tax_chg_log_id = l_change_log_id
        and citation_id = l_citation_id;
        IF (l_excit = 0) THEN

            -- 7/2/2014 : pick up orig entered by for the change log record
            -- entered_by SHOULD be populated (no test here yet for it)
            Select entered_by
            INTO l_orig_creator
            From juris_tax_chg_logs
            WHERE id = l_change_log_id;

        --INSERT INTO juris_tax_chg_cits (juris_tax_chg_log_id, citation_id, entered_by)
        --VALUES (l_change_log_id, l_citation_id, l_entered_by);
        INSERT INTO juris_tax_chg_cits (juris_tax_chg_log_id, citation_id, entered_by)
        VALUES (l_change_log_id, l_citation_id, l_orig_creator);

        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i is invalid or uneditable: '||change_log_id_i);
    END add_tax_chg_cit;

    PROCEDURE add_tax_app_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER := change_log_id_i;
        l_Citation_id NUMBER := citation_id_i;
        l_entered_by NUMBER := entered_by_i;
        l_excit NUMBER;
        l_orig_creator number;
    BEGIN
        SELECT COUNT(*)
        INTO l_excit
        FROM juris_tax_app_chg_cits
        WHERE juris_tax_app_chg_log_id = l_change_log_id
        and citation_id = l_citation_id;
        IF (l_excit = 0) THEN

            Select entered_by
            INTO l_orig_creator
            From juris_tax_app_chg_logs
            WHERE id = l_change_log_id;

        INSERT INTO juris_tax_app_chg_cits (juris_tax_app_chg_log_id, citation_id, entered_by)
        VALUES (l_change_log_id, l_citation_id, l_orig_creator);
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i is invalid or uneditable: '||change_log_id_i);
    END add_tax_app_chg_cit;

    --Commodities
    PROCEDURE add_comm_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER := change_log_id_i;
        l_Citation_id NUMBER := citation_id_i;
        l_entered_by NUMBER := entered_by_i;
        l_excit NUMBER;
        l_orig_creator number;
    BEGIN
        SELECT COUNT(*)
        INTO l_excit
        FROM comm_chg_cits
        WHERE comm_chg_log_id = l_change_log_id
        and citation_id = l_citation_id;
        IF (l_excit = 0) THEN

            Select entered_by
            INTO l_orig_creator
            From comm_chg_logs
            WHERE id = l_change_log_id;

        INSERT INTO comm_chg_cits (comm_chg_log_id, citation_id, entered_by)
        VALUES (l_change_log_id, l_citation_id, l_orig_creator);
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i is invalid or uneditable: '||change_log_id_i);
    END add_comm_chg_cit;

    -- Reference Groups
    PROCEDURE add_ref_grp_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        )
    IS
        l_change_log_id NUMBER := change_log_id_i;
        l_Citation_id NUMBER := citation_id_i;
        l_entered_by NUMBER := entered_by_i;
        l_excit NUMBER;
        l_orig_creator number;
    BEGIN
        SELECT COUNT(*)
        INTO l_excit
        FROM ref_grp_chg_cits
        WHERE ref_grp_chg_log_id = l_change_log_id
        and citation_id = l_citation_id;
        IF (l_excit = 0) THEN

            Select entered_by
            INTO l_orig_creator
            From ref_grp_chg_logs
            WHERE id = l_change_log_id;

        INSERT INTO ref_grp_chg_cits (ref_grp_chg_log_id, citation_id, entered_by)
        VALUES (l_change_log_id, l_citation_id, l_orig_creator);
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            errlogger.report_and_stop(SQLCODE,'change_log_id_i is invalid or uneditable: '||change_log_id_i);
    END add_ref_grp_chg_cit;


    -- Administrator
    PROCEDURE sign_admin_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        )
    IS
        l_chg_tbl NUMBER;
        l_pk NUMBER;
        l_rid NUMBER;
        l_Review_type varchar2(50);
        l_count_chg_logs NUMBER;
        l_count_fr NUMBER;
        TYPE rids IS TABLE OF INTEGER;
        l_rids rids := rids();
        l_rid_counter NUMBER := 1;
        verif_exists number:=0; -- Other thoughts; REF to object that can store what records contain the verification
        letl_chg_cnt number := 0;
        letl_vld_stg_cnt number := 1;
    BEGIN

        FOR i IN 1..chg_logs_i.COUNT LOOP
          UPDATE admin_chg_logs lg
          SET status = 1
          WHERE id = chg_logs_i(i)
          /*and not exists(select 1
                           from admin_chg_vlds vld
                           where vld.admin_chg_log_id = lg.id
                           and vld.assignment_type_id=review_type_id_i
                           and vld.assigned_by = reviewed_by_i)*/
          RETURNING rid into l_rid;
          /*if sql%rowcount = 0 then
              dbms_output.put_line('Noticed that we are not returning anything from this one');
              verif_exists:=1;
          else*/
            IF (NVL(l_rids.PRIOR(l_rid_counter),-1) != l_rid) THEN
                l_rids.extend;
                l_rids(l_rid_counter) := l_rid;
                l_rid_counter := l_rid_counter+1;
            END IF;

            INSERT INTO admin_chg_vlds(assigned_user_id, signoff_date, admin_chg_log_id, assignment_type_id, assigned_by, rid)
            VALUES (reviewed_by_i, SYSTIMESTAMP, chg_logs_i(i), review_type_id_i, reviewed_by_i, l_rid);
          --end if;
        END LOOP;

      --if (verif_exists<>0) then
        --If this is a Final Review, check to see if all Changes have final review, if so, update the Revision Summary Status
        SELECT name
        INTO l_review_type
        FROM assignment_types
        WHERE id = review_type_id_i;
        IF (l_review_type = 'Final Review') THEN
            FOR r IN 1..l_rids.COUNT LOOP
                /*
                SELECT COUNT(DISTINCT admin_chg_log_id), NVL(SUM(CASE WHEN assignment_type_id = review_type_id_i THEN 1 ELSE 0 END),0)
                INTO l_count_chg_logs, l_count_fr
                FROM admin_chg_vlds
                WHERE rid = l_rids(r);
                */
                -- CRAPP-3149
                SELECT COUNT (DISTINCT admin_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = review_type_id_i THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT admin_chg_log_id, assignment_type_id
                        FROM admin_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 and l_count_chg_logs = l_count_fr) THEN
                    update administrator_revisions
                    set summ_Ass_status = 5
                    where id = l_rids(r);
                END IF;
            END LOOP;
        -- Changes for "Test in Staging", If all changes have "Test in Staging", set summ_ass_status = 2, that way these records will get pulled into ETL.
        ELSIF (l_review_type = 'Test in Staging') THEN
            FOR r IN 1..l_rids.COUNT LOOP

                SELECT COUNT (DISTINCT admin_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 7 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT admin_chg_log_id, assignment_type_id
                        FROM admin_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 and l_count_chg_logs = l_count_fr) THEN
                    update administrator_revisions
                    set summ_Ass_status = 2
                    where id = l_rids(r);
                END IF;
            END LOOP;
        END IF;

        -- Set the staging flag if all change records are either final reviewed or test in staging added.
            FOR r IN 1..l_rids.COUNT
            LOOP
                select count(1) into letl_chg_cnt from admin_chg_logs where rid = l_rids(r);
                select count(distinct admin_chg_log_id) into letl_vld_stg_cnt from admin_chg_vlds where rid = l_rids(r) and assignment_type_id in (2,7);

                if  letl_chg_cnt = letl_vld_stg_cnt
                then
                    update administrator_revisions set ready_for_staging = 1 where id = l_rids(r);
                end if;
            end loop;
       --end if;

    END sign_admin_chg_logs;

    -- Jurisdiction
    PROCEDURE sign_juris_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        )
    IS
        l_chg_tbl NUMBER;
        l_pk NUMBER;
        l_rid NUMBER;
        l_Review_type varchar2(50);
        l_count_chg_logs NUMBER;
        l_count_fr NUMBER;
        TYPE rids IS TABLE OF INTEGER;
        l_rids rids := rids();
        l_rid_counter NUMBER := 1;
        verif_exists number:=0;
        letl_chg_cnt number := 0;
        letl_vld_stg_cnt number := 1;
    BEGIN
        FOR i IN 1..chg_logs_i.COUNT LOOP
            UPDATE juris_chg_logs lg
            SET status = 1
            WHERE id = chg_logs_i(i)
            /*          and not exists(select 1
                           from juris_chg_vlds vld
                           where vld.juris_chg_log_id = lg.id
                           and vld.assignment_type_id=review_type_id_i
                           and vld.assigned_by = reviewed_by_i)*/
            RETURNING rid into l_rid;

-- 20161027: In 2013 we had 1 of each review type allowed for a record. That changed to allow multiple.
--           Than it changed back to only allowing 1 when change log search was changed at one point
--           Than it changed to allowing multiple again (even final reviews)
          /*
          if sql%rowcount = 0 then
              dbms_output.put_line('Noticed that we are not returning anything from this one');
              verif_exists:=1;
          else
          */

            IF (NVL(l_rids.PRIOR(l_rid_counter),-1) != l_rid) THEN
                l_rids.extend;
                l_rids(l_rid_counter) := l_rid;
                l_rid_counter := l_rid_counter+1;
            END IF;
            INSERT INTO juris_chg_vlds(assigned_user_id, signoff_date, juris_chg_log_id, assignment_type_id, assigned_by, rid)
            VALUES (reviewed_by_i, SYSTIMESTAMP, chg_logs_i(i), review_type_id_i, reviewed_by_i, l_rid);
          --end if;
        END LOOP;

        --if (verif_exists<>0) then
        --If this is a Final Review, check to see if all Changes have final review, if so, update the Revision Summary Status
        SELECT name
        INTO l_review_type
        FROM assignment_types
        WHERE id = review_type_id_i;
        IF (l_review_type = 'Final Review') THEN
            FOR r IN 1..l_rids.COUNT LOOP
                -- CRAPP-3149
                SELECT COUNT (DISTINCT juris_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT juris_chg_log_id, assignment_type_id
                        FROM juris_chg_vlds
                        WHERE rid = l_rids(r)
                );

                IF (l_count_chg_logs > 0 and l_count_chg_logs = l_count_fr) THEN
                    update jurisdiction_revisions
                    set summ_Ass_status = 5
                    where id = l_rids(r);
                END IF;
            END LOOP;
        -- Changes for "Test in Staging", If all changes have "Test in Staging", set summ_ass_status = 2, that way these records will get pulled into ETL.
        ELSIF (l_review_type = 'Test in Staging') THEN
            FOR r IN 1..l_rids.COUNT LOOP

                SELECT COUNT (DISTINCT juris_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 7 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT juris_chg_log_id, assignment_type_id
                        FROM juris_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 and l_count_chg_logs = l_count_fr) THEN
                    update jurisdiction_revisions
                    set summ_Ass_status = 2
                    where id = l_rids(r);
                END IF;
            END LOOP;
        END IF;

        -- Set the staging flag if all change records are either final reviewed or test in staging added.
            FOR r IN 1..l_rids.COUNT
            LOOP
                select count(1) into letl_chg_cnt from juris_chg_logs where rid = l_rids(r);
                select count(distinct juris_chg_log_id) into letl_vld_stg_cnt from juris_chg_vlds where rid = l_rids(r) and assignment_type_id in (2,7);

                if  letl_chg_cnt = letl_vld_stg_cnt
                then
                    update jurisdiction_revisions set ready_for_staging = 1 where id = l_rids(r);
                end if;
            end loop;
     -- end if;
    END sign_juris_chg_logs;

    -- Jurisdiction Type
    PROCEDURE sign_juris_type_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        )
    IS
        l_chg_tbl NUMBER;
        l_pk NUMBER;
        l_rid NUMBER;
        l_Review_type varchar2(50);
        l_count_chg_logs NUMBER;
        l_count_fr NUMBER;
        TYPE rids IS TABLE OF INTEGER;
        l_rids rids := rids();
        l_rid_counter NUMBER := 1;
        verif_exists number:=0;
        letl_chg_cnt number := 0;
        letl_vld_stg_cnt number := 1;
    BEGIN
        FOR i IN 1..chg_logs_i.COUNT LOOP
            UPDATE juris_type_chg_logs lg
            SET status = 1
            WHERE id = chg_logs_i(i)
            RETURNING rid into l_rid;

            IF (NVL(l_rids.PRIOR(l_rid_counter),-1) != l_rid) THEN
                l_rids.extend;
                l_rids(l_rid_counter) := l_rid;
                l_rid_counter := l_rid_counter+1;
            END IF;
            INSERT INTO juris_type_chg_vlds(assigned_user_id, signoff_date, juris_type_chg_log_id, assignment_type_id, assigned_by, rid)
            VALUES (reviewed_by_i, SYSTIMESTAMP, chg_logs_i(i), review_type_id_i, reviewed_by_i, l_rid);
          --end if;
        END LOOP;

        --if (verif_exists<>0) then
        --If this is a Final Review, check to see if all Changes have final review, if so, update the Revision Summary Status
        SELECT name
        INTO l_review_type
        FROM assignment_types
        WHERE id = review_type_id_i;
        IF (l_review_type = 'Final Review') THEN
            FOR r IN 1..l_rids.COUNT LOOP
                -- CRAPP-3149
                SELECT COUNT (DISTINCT juris_type_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT juris_type_chg_log_id, assignment_type_id
                        FROM juris_type_chg_vlds
                        WHERE rid = l_rids(r)
                );

                IF (l_count_chg_logs > 0 and l_count_chg_logs = l_count_fr) THEN
                    update jurisdiction_type_revisions
                    set summ_Ass_status = 5
                    where id = l_rids(r);
                END IF;
            END LOOP;
        -- Changes for "Test in Staging", If all changes have "Test in Staging", set summ_ass_status = 2, that way these records will get pulled into ETL.
        ELSIF (l_review_type = 'Test in Staging') THEN
            FOR r IN 1..l_rids.COUNT LOOP

                SELECT COUNT (DISTINCT juris_type_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 7 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT juris_type_chg_log_id, assignment_type_id
                        FROM juris_type_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 and l_count_chg_logs = l_count_fr) THEN
                    update jurisdiction_type_revisions
                    set summ_Ass_status = 2
                    where id = l_rids(r);
                END IF;
            END LOOP;
        END IF;

        -- Set the staging flag if all change records are either final reviewed or test in staging added.
            FOR r IN 1..l_rids.COUNT
            LOOP
                select count(1) into letl_chg_cnt from juris_type_chg_logs where rid = l_rids(r);
                select count(distinct juris_type_chg_log_id) into letl_vld_stg_cnt from juris_type_chg_vlds where rid = l_rids(r) and assignment_type_id in (2,7);

                if  letl_chg_cnt = letl_vld_stg_cnt
                then
                    update jurisdiction_type_revisions set ready_for_staging = 1 where id = l_rids(r);
                end if;
            end loop;

     -- end if;
    END sign_juris_type_chg_logs;

    PROCEDURE unsign_juris_chg_logs(
        chg_log_rvws_i IN chglogids
        )
    IS
       l_chg_log_id NUMBER;
       l_Rid NUMBER;
       l_unlocked_chg_log NUMBER;
       E_Selection_Error exception;

        -- start new
        TYPE t_id_tab IS TABLE OF juris_chg_vlds.juris_chg_log_id%TYPE;
        TYPE t_rid_tab IS TABLE OF juris_chg_vlds.rid%TYPE;
        l_id_tab    t_id_tab   := t_id_tab();
        l_rid_tab   t_rid_tab  := t_rid_tab();
        letl_chg_cnt number := 0;
        letl_vld_stg_cnt number := 0;

    BEGIN
DBMS_OUTPUT.Put_Line( 'Loop chg id' );
DBMS_OUTPUT.Put_Line( chg_log_rvws_i.COUNT );

        FOR i IN 1..chg_log_rvws_i.count LOOP
          DELETE from juris_chg_vlds v
          WHERE id = chg_log_rvws_i(i)
          AND
          exists
          (Select 1 from juris_chg_logs jl
           where jl.id = v.juris_chg_log_id and jl.status<>2)
          RETURNING juris_chg_log_id INTO l_chg_log_id;

DBMS_OUTPUT.Put_Line( chg_log_rvws_i(i) );

           IF (SQL%ROWCOUNT != 0) THEN
              l_id_tab.extend;
              l_id_tab(l_id_tab.last) := l_chg_log_id;
            ELSE
             RAISE E_Selection_Error;
            END IF;

        END LOOP;
DBMS_OUTPUT.Put_Line( 'R 1');

-- start alternate
-- bulk collect the ids
-- update juris_chg_logs bulk using list
-- bulk collect the rids
-- update jurisdiction_revisions bulk using rid list

           FORALL ii IN l_id_tab.first .. l_id_tab.last
           UPDATE juris_chg_logs l
           SET status = 0
           WHERE id = l_id_tab(ii)
           AND NOT EXISTS (
               SELECT 1
               from juris_chg_vlds v
               WHERE v.juris_chg_log_id = l.id
               )
           RETURNING RID BULK COLLECT INTO l_rid_tab;
DBMS_OUTPUT.Put_Line( 'R 2');


           FORALL jj IN l_rid_tab.first .. l_rid_tab.last
                UPDATE jurisdiction_revisions r
                   SET summ_ass_status = 0
                 WHERE id = l_rid_tab(jj);

DBMS_OUTPUT.Put_Line( 'R 3');

    -- Mark this item is not ready for etl is any of the review has been deleted and doesn't have all change logs reviews on them.
        FOR jj IN l_rid_tab.first .. l_rid_tab.last
        LOOP
            select count(1) into letl_chg_cnt from juris_chg_logs where rid = l_rid_tab(jj);
            select count(distinct juris_chg_log_id) into letl_vld_stg_cnt from juris_chg_vlds where rid = l_rid_tab(jj) and assignment_type_id in (2,7);

            if  letl_chg_cnt != letl_vld_stg_cnt
            then
                update jurisdiction_revisions set ready_for_staging = 0 where id = l_rid_tab(jj);
            end if;
        END LOOP;

-- end alternate

/*
            --unlock change if all the reviews have been removed
            IF (SQL%ROWCOUNT != 0) THEN

            UPDATE juris_chg_logs l
            SET status = 0
            WHERE id = l_chg_log_id
            AND NOT EXISTS (
                SELECT 1
                from juris_chg_vlds v
                WHERE v.juris_chg_log_id = l.id
                )
            RETURNING RID into l_rid;
            ELSE
             RAISE E_Selection_Error;
            END IF;

            IF (SQL%ROWCOUNT != 0) THEN
            --mark revision as unreviewed if all reviews have been removed
                UPDATE jurisdiction_revisions r
                   SET summ_ass_status = 0
                 WHERE id = l_Rid;
            END IF;

        END LOOP;
*/

      EXCEPTION
      WHEN E_Selection_Error THEN
        ERRLOGGER.REPORT_AND_GO(SQLCODE, 'Removing review not possible. Published record was selected.');
      WHEN OTHERS THEN
        ERRLOGGER.REPORT_AND_STOP(SQLCODE, 'Removing selected reviews not possible.');

    END unsign_juris_chg_logs;

    PROCEDURE unsign_juris_type_chg_logs(
        chg_log_rvws_i IN chglogids
        )
    IS
       l_chg_log_id NUMBER;
       l_Rid NUMBER;
       l_unlocked_chg_log NUMBER;
       E_Selection_Error exception;

        -- start new
        TYPE t_id_tab IS TABLE OF juris_type_chg_vlds.juris_type_chg_log_id%TYPE;
        TYPE t_rid_tab IS TABLE OF juris_type_chg_vlds.rid%TYPE;
        l_id_tab    t_id_tab   := t_id_tab();
        l_rid_tab   t_rid_tab  := t_rid_tab();
        letl_chg_cnt number := 0;
        letl_vld_stg_cnt number := 0;
        -- end new

    BEGIN

        FOR i IN 1..chg_log_rvws_i.count LOOP
          DELETE from juris_type_chg_vlds v
          WHERE id = chg_log_rvws_i(i)
          AND
          exists
          (Select 1 from juris_type_chg_logs jl
           where jl.id = v.juris_type_chg_log_id and jl.status<>2)
          RETURNING juris_type_chg_log_id INTO l_chg_log_id;

           IF (SQL%ROWCOUNT != 0) THEN
              l_id_tab.extend;
              l_id_tab(l_id_tab.last) := l_chg_log_id;
            ELSE
             RAISE E_Selection_Error;
            END IF;

        END LOOP;

           FORALL ii IN l_id_tab.first .. l_id_tab.last
           UPDATE juris_type_chg_logs l
           SET status = 0
           WHERE id = l_id_tab(ii)
           AND NOT EXISTS (
               SELECT 1
               from juris_type_chg_vlds v
               WHERE v.juris_type_chg_log_id = l.id
               )
           RETURNING RID BULK COLLECT INTO l_rid_tab;

           FORALL jj IN l_rid_tab.first .. l_rid_tab.last
                UPDATE jurisdiction_type_revisions r
                   SET summ_ass_status = 0
                 WHERE id = l_rid_tab(jj);

           -- Mark this item is not ready for etl is any of the review has been deleted and doesn't have all change logs reviews on them.
        FOR jj IN l_rid_tab.first .. l_rid_tab.last
        LOOP
            select count(1) into letl_chg_cnt from juris_type_chg_logs where rid = l_rid_tab(jj);
            select count(distinct juris_type_chg_log_id) into letl_vld_stg_cnt from juris_type_chg_vlds where rid = l_rid_tab(jj) and assignment_type_id in (2,7);

            if  letl_chg_cnt != letl_vld_stg_cnt
            then
                update jurisdiction_type_revisions set ready_for_staging = 0 where id = l_rid_tab(jj);
            end if;
        END LOOP;


      EXCEPTION
      WHEN E_Selection_Error THEN
        ERRLOGGER.REPORT_AND_GO(SQLCODE, 'Removing review not possible. Published record was selected.');
      WHEN OTHERS THEN
        ERRLOGGER.REPORT_AND_STOP(SQLCODE, 'Removing selected reviews not possible.');

    END unsign_juris_type_chg_logs;

    PROCEDURE unsign_tax_chg_logs(
        chg_log_rvws_i IN chglogids
        )
    IS
       l_chg_log_id NUMBER;
       l_Rid NUMBER;
       l_unlocked_chg_log NUMBER;
       E_Selection_Error exception;

       TYPE t_id_tab IS TABLE OF juris_chg_vlds.juris_chg_log_id%TYPE;
       TYPE t_rid_tab IS TABLE OF juris_chg_vlds.rid%TYPE;
       l_id_tab    t_id_tab   := t_id_tab();
       l_rid_tab   t_rid_tab  := t_rid_tab();
       letl_chg_cnt number := 0;
       letl_vld_stg_cnt number := 0;

    BEGIN
        FOR i IN 1..chg_log_rvws_i.COUNT LOOP
            DELETE from juris_tax_chg_vlds v
            WHERE id = chg_log_rvws_i(i)
            AND
            exists
            (Select 1 from juris_tax_chg_logs jl
             where jl.id = v.juris_tax_chg_log_id and jl.status<>2)
            RETURNING juris_tax_chg_log_id INTO l_chg_log_id;

           IF (SQL%ROWCOUNT != 0) THEN
              l_id_tab.extend;
              l_id_tab(l_id_tab.last) := l_chg_log_id;
            ELSE
             RAISE E_Selection_Error;
            END IF;

        END LOOP;

           FORALL ii IN l_id_tab.first .. l_id_tab.last
            UPDATE juris_tax_chg_logs l
            SET status = 0
            WHERE id = l_id_tab(ii)
            AND NOT EXISTS (
                SELECT 1
                from juris_tax_chg_vlds v
                WHERE v.juris_tax_chg_log_id = l.id
                )
            RETURNING RID BULK COLLECT INTO l_rid_tab;

           FORALL jj IN l_rid_tab.first .. l_rid_tab.last
                UPDATE jurisdiction_tax_revisions r
                   SET summ_ass_status = 0
                 WHERE id = l_rid_tab(jj);

        /* Set whether the revisions has been ready for staging or not. */
        FOR jj IN l_rid_tab.first .. l_rid_tab.last
        LOOP
            select count(1) into letl_chg_cnt from juris_tax_chg_logs where rid = l_rid_tab(jj);
            select count(distinct juris_tax_chg_log_id) into letl_vld_stg_cnt from juris_tax_chg_vlds where rid = l_rid_tab(jj) and assignment_type_id in (2,7);

            if  letl_chg_cnt != letl_vld_stg_cnt
            then
                update jurisdiction_tax_revisions set ready_for_staging = 0 where id = l_rid_tab(jj);
            end if;
        END LOOP;

 /*           IF (SQL%ROWCOUNT != 0) THEN
            --unlock change if all the reviews have been removed
            UPDATE juris_tax_chg_logs l
            SET status = 0
            WHERE id = l_chg_log_id
            AND NOT EXISTS (
                SELECT 1
                from juris_tax_chg_vlds v
                WHERE v.juris_tax_chg_log_id = l.id
                )
            RETURNING RID into l_rid;
            ELSE
             RAISE E_Selection_Error;
            END IF;


            IF (SQL%ROWCOUNT != 0) THEN
            --mark revision as unreviewed if all reviews have been removed
                UPDATE jurisdiction_tax_revisions r
                SET summ_ass_status = 0
                WHERE id = l_Rid;
            END IF;
        END LOOP;*/

      EXCEPTION
      WHEN E_Selection_Error THEN
        ERRLOGGER.REPORT_AND_GO(SQLCODE, 'Removing review not possible. Published record was selected.');
      WHEN OTHERS THEN
        ERRLOGGER.REPORT_AND_STOP(SQLCODE, 'Removing selected reviews not possible.');

    END unsign_tax_chg_logs;

    PROCEDURE unsign_tax_app_chg_logs(
        chg_log_rvws_i IN chglogids
        )
    IS
       l_chg_log_id NUMBER;
       l_Rid NUMBER;
       l_unlocked_chg_log NUMBER;
       E_Selection_Error exception;

       TYPE t_id_tab IS TABLE OF juris_tax_app_chg_vlds.juris_tax_app_chg_log_id%TYPE;
       TYPE t_rid_tab IS TABLE OF juris_tax_app_chg_vlds.rid%TYPE;
       l_id_tab    t_id_tab   := t_id_tab();
       l_rid_tab   t_rid_tab  := t_rid_tab();
       letl_chg_cnt number := 0;
       letl_vld_stg_cnt number := 0;

    BEGIN
        FOR i IN 1..chg_log_rvws_i.COUNT LOOP
            DELETE from juris_tax_app_chg_vlds v
            WHERE id = chg_log_rvws_i(i)
           AND
            exists
            (Select 1 from juris_tax_app_chg_logs jl
             where jl.id = v.juris_tax_app_chg_log_id and jl.status<>2)
            RETURNING juris_tax_app_chg_log_id INTO l_chg_log_id;

           IF (SQL%ROWCOUNT != 0) THEN
              l_id_tab.extend;
              l_id_tab(l_id_tab.last) := l_chg_log_id;
            ELSE
             RAISE E_Selection_Error;
            END IF;

        END LOOP;

           FORALL ii IN l_id_tab.first .. l_id_tab.last
            -- CRAPP-3020 Reset summ_ass_status
            Update juris_tax_app_revisions set summ_ass_status = 4
            where id =
            (Select distinct rv.id
             from juris_tax_app_chg_logs lg
             join juris_tax_app_revisions rv on (rv.id = lg.rid)
             where lg.status = 1
             and rv.summ_ass_status = 5
             and lg.id = l_id_tab(ii)
             AND NOT EXISTS (
                SELECT 1
                from juris_tax_app_chg_vlds vld
                WHERE vld.juris_tax_app_chg_log_id = lg.id
                  and vld.assignment_type_id = 2
                )
             );

            --unlock change if all the reviews have been removed
           FORALL ii IN l_id_tab.first .. l_id_tab.last
            UPDATE juris_tax_app_chg_logs l
            SET status = 0
            WHERE id = l_id_tab(ii)
            AND NOT EXISTS (
                SELECT 1
                from juris_tax_app_chg_vlds v
                WHERE v.juris_tax_app_chg_log_id = l.id
                )
            RETURNING RID BULK COLLECT INTO l_rid_tab;

           --mark revision as unreviewed if all reviews have been removed
           FORALL jj IN l_rid_tab.first .. l_rid_tab.last
                UPDATE juris_tax_app_revisions r
                SET summ_ass_status = 0
                WHERE id = l_rid_tab(jj);

            /* Set whether the revisions has been ready for staging or not. */
            FOR jj IN l_rid_tab.first .. l_rid_tab.last
            LOOP
                select count(1) into letl_chg_cnt from juris_tax_app_chg_logs where rid = l_rid_tab(jj);
                select count(distinct juris_tax_app_chg_log_id) into letl_vld_stg_cnt from juris_tax_app_chg_vlds where rid = l_rid_tab(jj) and assignment_type_id in (2,7);

                if  letl_chg_cnt != letl_vld_stg_cnt
                then
                    update juris_tax_app_revisions set ready_for_staging = 0 where id = l_rid_tab(jj);
                end if;
            END LOOP;


      EXCEPTION
      WHEN E_Selection_Error THEN
        ERRLOGGER.REPORT_AND_GO(SQLCODE, 'Removing review not possible. Published record was selected.');
      WHEN OTHERS THEN
        ERRLOGGER.REPORT_AND_STOP(SQLCODE, 'Removing selected reviews not possible.');

    END unsign_tax_app_chg_logs;


    PROCEDURE unsign_admin_chg_logs(
        chg_log_rvws_i IN chglogids
        )
    IS
       l_chg_log_id NUMBER;
       l_Rid NUMBER;
       l_unlocked_chg_log NUMBER;
       E_Selection_Error exception;

       TYPE t_id_tab IS TABLE OF admin_chg_vlds.admin_chg_log_id%TYPE;
       TYPE t_rid_tab IS TABLE OF admin_chg_vlds.rid%TYPE;
       l_id_tab    t_id_tab   := t_id_tab();
       l_rid_tab   t_rid_tab  := t_rid_tab();
       letl_chg_cnt number := 0;
       letl_vld_stg_cnt number := 0;

    BEGIN
        FOR i IN 1..chg_log_rvws_i.COUNT LOOP
            DELETE from admin_chg_vlds v
            WHERE id = chg_log_rvws_i(i)
            AND
            exists
            (Select 1 from admin_chg_logs jl
             where jl.id = v.admin_chg_log_id and jl.status<>2)
            RETURNING admin_chg_log_id INTO l_chg_log_id;

           IF (SQL%ROWCOUNT != 0) THEN
              l_id_tab.extend;
              l_id_tab(l_id_tab.last) := l_chg_log_id;
            ELSE
             RAISE E_Selection_Error;
            END IF;

        END LOOP;

           FORALL ii IN l_id_tab.first .. l_id_tab.last
              UPDATE admin_chg_logs l
              SET status = 0
              WHERE id = l_chg_log_id
              AND NOT EXISTS (
                SELECT 1
                from admin_chg_vlds v
                WHERE v.admin_chg_log_id = l_id_tab(ii)
                )
            RETURNING RID BULK COLLECT INTO l_rid_tab;

           FORALL jj IN l_rid_tab.first .. l_rid_tab.last
                UPDATE administrator_Revisions r
                SET summ_ass_status = 0
                WHERE id = l_rid_tab(jj);

           /* Set whether the revisions has been ready for staging or not. */
        FOR jj IN l_rid_tab.first .. l_rid_tab.last
        LOOP
            select count(1) into letl_chg_cnt from admin_chg_logs where rid = l_rid_tab(jj);
            select count(distinct admin_chg_log_id) into letl_vld_stg_cnt from admin_chg_vlds where rid = l_rid_tab(jj) and assignment_type_id in (2,7);

            if  letl_chg_cnt != letl_vld_stg_cnt
            then
                update administrator_revisions set ready_for_staging = 0 where id = l_rid_tab(jj);
            end if;
        END LOOP;


/*            IF (SQL%ROWCOUNT != 0) THEN
              --unlock change if all the reviews have been removed
              UPDATE admin_chg_logs l
              SET status = 0
              WHERE id = l_chg_log_id
              AND NOT EXISTS (
                SELECT 1
                from admin_chg_vlds v
                WHERE v.admin_chg_log_id = l.id
                )
              RETURNING RID into l_rid;
            ELSE
             RAISE E_Selection_Error;
            END IF;


            IF (SQL%ROWCOUNT != 0) THEN
            --mark revision as unreviewed if all reviews have been removed
                UPDATE administrator_Revisions r
                SET summ_ass_status = 0
                WHERE id = l_Rid;
            END IF;
        END LOOP;
*/

      EXCEPTION
      WHEN E_Selection_Error THEN
        ERRLOGGER.REPORT_AND_GO(SQLCODE, 'Removing review not possible. Published record was selected.');
      WHEN OTHERS THEN
        ERRLOGGER.REPORT_AND_STOP(SQLCODE, 'Removing selected reviews not possible.');

    END unsign_admin_chg_logs;

    -- Commodities
    PROCEDURE unsign_comm_chg_logs(
        chg_log_rvws_i IN chglogids
        )
    IS
       l_chg_log_id NUMBER;
       l_Rid NUMBER;
       l_unlocked_chg_log NUMBER;
       E_Selection_Error exception;

       TYPE t_id_tab IS TABLE OF comm_chg_vlds.comm_chg_log_id%TYPE;
       TYPE t_rid_tab IS TABLE OF comm_chg_vlds.rid%TYPE;
       l_id_tab    t_id_tab   := t_id_tab();
       l_rid_tab   t_rid_tab  := t_rid_tab();
       letl_chg_cnt number := 0;
       letl_vld_stg_cnt number := 0;

    BEGIN
        FOR i IN 1..chg_log_rvws_i.COUNT LOOP
            DELETE from comm_chg_vlds v
            WHERE id = chg_log_rvws_i(i)
            AND
            exists
            (Select 1 from comm_chg_logs jl
             where jl.id = v.comm_chg_log_id and jl.status<>2)
            RETURNING comm_chg_log_id INTO l_chg_log_id;

           IF (SQL%ROWCOUNT != 0) THEN
              l_id_tab.extend;
              l_id_tab(l_id_tab.last) := l_chg_log_id;
            ELSE
             RAISE E_Selection_Error;
            END IF;

        END LOOP;

           FORALL ii IN l_id_tab.first .. l_id_tab.last
            UPDATE comm_chg_logs l
            SET status = 0
            WHERE id = l_chg_log_id
            AND NOT EXISTS (
                SELECT 1
                from comm_chg_vlds v
                WHERE v.comm_chg_log_id = l_id_tab(ii)
                )
            RETURNING RID BULK COLLECT INTO l_rid_tab;

            --mark revision as unreviewed if all reviews have been removed
           FORALL jj IN l_rid_tab.first .. l_rid_tab.last
                UPDATE commodity_revisions r
                SET summ_ass_status = 0
                WHERE id = l_rid_tab(jj);

        /* Set whether the revisions has been ready for staging or not. */
        FOR jj IN l_rid_tab.first .. l_rid_tab.last
        LOOP
            select count(1) into letl_chg_cnt from comm_chg_logs where rid = l_rid_tab(jj);
            select count(distinct comm_chg_log_id) into letl_vld_stg_cnt from comm_chg_vlds where rid = l_rid_tab(jj) and assignment_type_id in (2,7);

            if  letl_chg_cnt != letl_vld_stg_cnt
            then
                update commodity_revisions set ready_for_staging = 0 where id = l_rid_tab(jj);
            end if;
        END LOOP;

      EXCEPTION
      WHEN E_Selection_Error THEN
        ERRLOGGER.REPORT_AND_GO(SQLCODE, 'Removing review not possible. Published record was selected.');
      WHEN OTHERS THEN
        ERRLOGGER.REPORT_AND_STOP(SQLCODE, 'Removing selected reviews not possible.');

    END unsign_comm_chg_logs;

    -- Reference Groups
    PROCEDURE unsign_ref_grp_chg_logs(
        chg_log_rvws_i IN chglogids
        )
    IS
       l_chg_log_id NUMBER;
       l_Rid NUMBER;
       l_unlocked_chg_log NUMBER;
       E_Selection_Error exception;

       TYPE t_id_tab IS TABLE OF comm_chg_vlds.comm_chg_log_id%TYPE;
       TYPE t_rid_tab IS TABLE OF comm_chg_vlds.rid%TYPE;
       l_id_tab    t_id_tab   := t_id_tab();
       l_rid_tab   t_rid_tab  := t_rid_tab();
       letl_chg_cnt number := 0;
       letl_vld_stg_cnt number := 0;

    BEGIN
        FOR i IN 1..chg_log_rvws_i.COUNT LOOP
            DELETE from ref_grp_chg_vlds v
            WHERE id = chg_log_rvws_i(i)
            AND
            exists
            (Select 1 from ref_grp_chg_logs jl
             where jl.id = v.ref_grp_chg_log_id and jl.status<>2)
            RETURNING ref_grp_chg_log_id INTO l_chg_log_id;

           IF (SQL%ROWCOUNT != 0) THEN
              l_id_tab.extend;
              l_id_tab(l_id_tab.last) := l_chg_log_id;
            ELSE
             RAISE E_Selection_Error;
            END IF;
        END LOOP;

           FORALL ii IN l_id_tab.first .. l_id_tab.last
            UPDATE ref_grp_chg_logs l
            SET status = 0
            WHERE id = l_chg_log_id
            AND NOT EXISTS (
                SELECT 1
                from ref_grp_chg_vlds v
                WHERE v.ref_grp_chg_log_id = l_id_tab(ii)
                )
            RETURNING RID BULK COLLECT INTO l_rid_tab;

           FORALL jj IN l_rid_tab.first .. l_rid_tab.last
                UPDATE ref_group_revisions r
                SET summ_ass_status = 0
                WHERE id = l_rid_tab(jj);

           /* Set whether the revisions has been ready for staging or not. */
        FOR jj IN l_rid_tab.first .. l_rid_tab.last
        LOOP
            select count(1) into letl_chg_cnt from ref_grp_chg_logs where rid = l_rid_tab(jj);
            select count(distinct ref_grp_chg_log_id) into letl_vld_stg_cnt from ref_grp_chg_vlds where rid = l_rid_tab(jj) and assignment_type_id in (2,7);

            if  letl_chg_cnt != letl_vld_stg_cnt
            then
                update ref_group_revisions set ready_for_staging = 0 where id = l_rid_tab(jj);
            end if;
        END LOOP;

      EXCEPTION
      WHEN E_Selection_Error THEN
        ERRLOGGER.REPORT_AND_GO(SQLCODE, 'Removing review not possible. Published record was selected.');
      WHEN OTHERS THEN
        ERRLOGGER.REPORT_AND_STOP(SQLCODE, 'Removing selected reviews not possible.');

    END unsign_ref_grp_chg_logs;


    PROCEDURE sign_tax_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        )
    IS
        l_chg_tbl NUMBER;
        l_pk NUMBER;
        l_rid NUMBER;
        l_Review_type varchar2(50);
        l_count_chg_logs NUMBER;
        l_count_fr NUMBER;
        TYPE rids IS TABLE OF INTEGER;
        l_rids rids := rids();
        l_rid_counter NUMBER := 1;
        verif_exists number:=0;
        letl_chg_cnt number := 0;
        letl_vld_stg_cnt number := 1;
    BEGIN
        FOR i IN 1..chg_logs_i.COUNT LOOP
            UPDATE juris_tax_chg_logs lg
            SET status = 1
            WHERE id = chg_logs_i(i)
              /*and not exists(select 1
                           from juris_tax_chg_vlds vld
                           where vld.juris_tax_chg_log_id = lg.id
                           and vld.assignment_type_id=review_type_id_i
                           and vld.assigned_by = reviewed_by_i)*/
            RETURNING rid into l_rid;

          /*if sql%rowcount = 0 then
              dbms_output.put_line('Noticed that we are not returning anything from this one');
              verif_exists:=1;
          else*/
            IF (NVL(l_rids.PRIOR(l_rid_counter),-1) != l_rid) THEN
                l_rids.extend;
                l_rids(l_rid_counter) := l_rid;
                l_rid_counter := l_rid_counter+1;
            END IF;
            INSERT INTO juris_tax_chg_vlds(assigned_user_id, signoff_date, juris_tax_chg_log_id, assignment_type_id, assigned_by, rid)
            VALUES (reviewed_by_i, SYSTIMESTAMP, chg_logs_i(i), review_type_id_i, reviewed_by_i, l_rid);
          --end if;
        END LOOP;

      --if (verif_exists<>0) then
        --If this is a Final Review, check to see if all Changes have final review, if so, update the Revision Summary Status
        SELECT name
        INTO l_review_type
        FROM assignment_types
        WHERE id = review_type_id_i;
        IF (l_review_type = 'Final Review') THEN
            FOR r IN 1..l_rids.COUNT LOOP
                /*
                SELECT COUNT(DISTINCT juris_tax_chg_log_id), NVL(SUM(CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END),0)
                INTO l_count_chg_logs, l_count_fr
                FROM juris_tax_chg_vlds
                WHERE rid = l_rids(r);
                */
                -- CRAPP-3149
                SELECT COUNT (DISTINCT juris_tax_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT juris_tax_chg_log_id, assignment_type_id
                        FROM juris_tax_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 AND l_count_chg_logs = l_count_fr) THEN
                    UPDATE jurisdiction_tax_revisions
                    SET summ_ass_status = 5
                    WHERE id = l_rids(r);
                END IF;
            END LOOP;
        -- Changes for "Test in Staging", If all changes have "Test in Staging", set summ_ass_status = 2, that way these records will get pulled into ETL.
        ELSIF (l_review_type = 'Test in Staging') THEN
            FOR r IN 1..l_rids.COUNT LOOP

                SELECT COUNT (DISTINCT juris_tax_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 7 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT juris_tax_chg_log_id, assignment_type_id
                        FROM juris_tax_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 AND l_count_chg_logs = l_count_fr) THEN
                    UPDATE jurisdiction_tax_revisions
                    SET summ_ass_status = 2
                    WHERE id = l_rids(r);
                END IF;
            END LOOP;
        END IF;

        /* Set whether the revisions has been ready for staging or not. */
        FOR r IN 1..l_rids.COUNT
        LOOP
            select count(1) into letl_chg_cnt from juris_tax_chg_logs where rid = l_rids(r);
            select count(distinct juris_tax_chg_log_id) into letl_vld_stg_cnt from juris_tax_chg_vlds where rid = l_rids(r) and assignment_type_id in (2,7);

            if  letl_chg_cnt = letl_vld_stg_cnt
            then
                update jurisdiction_tax_revisions set ready_for_staging = 1 where id = l_rids(r);
            end if;
        END LOOP;
      --end if;

    END sign_tax_chg_logs;

    PROCEDURE sign_tax_app_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        )
    IS
        l_chg_tbl NUMBER;
        l_pk NUMBER;
        l_rid NUMBER;
        l_Review_type varchar2(50);
        l_count_chg_logs NUMBER;
        l_count_fr NUMBER;
        TYPE rids IS TABLE OF INTEGER;
        l_rids rids := rids();
        l_rid_counter NUMBER := 1;
        verif_exists number:=0;
        letl_chg_cnt number := 0;
        letl_vld_stg_cnt number := 1;

    BEGIN
        FOR i IN 1..chg_logs_i.COUNT LOOP
            UPDATE juris_tax_app_chg_logs lg
            SET status = 1
            WHERE id = chg_logs_i(i)
            /*               and not exists(select 1
                           from juris_tax_app_chg_vlds vld
                           where vld.juris_tax_app_chg_log_id = lg.id
                           and vld.assignment_type_id=review_type_id_i
                           and vld.assigned_by = reviewed_by_i)*/
            RETURNING rid into l_rid;
          /*if sql%rowcount = 0 then
              dbms_output.put_line('Noticed that we are not returning anything from this one');
              verif_exists:=1;
          else*/
            IF (NVL(l_rids.PRIOR(l_rid_counter),-1) != l_rid) THEN
                l_rids.extend;
                l_rids(l_rid_counter) := l_rid;
                l_rid_counter := l_rid_counter+1;
            END IF;
            INSERT INTO juris_tax_app_chg_vlds(assigned_user_id, signoff_date, juris_tax_app_chg_log_id, assignment_type_id, assigned_by, rid)
            VALUES (reviewed_by_i, SYSTIMESTAMP, chg_logs_i(i), review_type_id_i, reviewed_by_i, l_rid);
          --end if;
        END LOOP;

      --if (verif_exists<>0) then
        --If this is a Final Review, check to see if all Changes have final review, if so, update the Revision Summary Status
        SELECT name
        INTO l_review_type
        FROM assignment_types
        WHERE id = review_type_id_i;
        IF (l_review_type = 'Final Review') THEN
            FOR r IN 1..l_rids.COUNT LOOP
                /*
                SELECT COUNT(DISTINCT juris_tax_app_chg_log_id), NVL(SUM(CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END),0)
                INTO l_count_chg_logs, l_count_fr
                FROM juris_tax_app_chg_vlds
                WHERE rid = l_rids(r);
                */
                -- CRAPP-3149
                SELECT COUNT (DISTINCT juris_tax_app_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT juris_tax_app_chg_log_id, assignment_type_id
                        FROM juris_tax_app_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 AND l_count_chg_logs = l_count_fr) THEN
                    UPDATE juris_tax_app_revisions
                    SET summ_ass_status = 5
                    WHERE id = l_rids(r);
                END IF;
            END LOOP;
        -- Changes for "Test in Staging", If all changes have "Test in Staging", set summ_ass_status = 2, that way these records will get pulled into ETL.
        ELSIF (l_review_type = 'Test in Staging') THEN
            FOR r IN 1..l_rids.COUNT LOOP

                SELECT COUNT (DISTINCT juris_tax_app_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 7 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT juris_tax_app_chg_log_id, assignment_type_id
                        FROM juris_tax_app_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 AND l_count_chg_logs = l_count_fr) THEN
                    UPDATE juris_tax_app_revisions
                    SET summ_ass_status = 2
                    WHERE id = l_rids(r);
                END IF;
            END LOOP;
        END IF;

            /* Set whether the revisions has been ready for staging or not. */
            FOR r IN 1..l_rids.COUNT
            LOOP

                select count(1) into letl_chg_cnt from juris_tax_app_chg_logs where rid = l_rids(r);
                select count(distinct juris_tax_app_chg_log_id) into letl_vld_stg_cnt from juris_tax_app_chg_vlds where rid = l_rids(r) and assignment_type_id in (2,7);

                if  letl_chg_cnt = letl_vld_stg_cnt
                then
                    update juris_tax_app_revisions set ready_for_staging = 1 where id = l_rids(r);
                end if;
            end loop;
      --end if;
    END sign_tax_app_chg_logs;

    -- Commodities
    PROCEDURE sign_comm_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        )
    IS
        l_chg_tbl NUMBER;
        l_pk NUMBER;
        l_rid NUMBER;
        l_Review_type varchar2(50);
        l_count_chg_logs NUMBER;
        l_count_fr NUMBER;
        TYPE rids IS TABLE OF INTEGER;
        l_rids rids := rids();
        l_rid_counter NUMBER := 1;
        verif_exists number:=0;
        letl_chg_cnt number := 0;
        letl_vld_stg_cnt number := 1;

    BEGIN
        FOR i IN 1..chg_logs_i.COUNT LOOP
            UPDATE comm_chg_logs lg
            SET status = 1
            WHERE id = chg_logs_i(i)
             /*         and not exists(select 1
                           from comm_chg_vlds vld
                           where vld.comm_chg_log_id = lg.id
                           and vld.assignment_type_id=review_type_id_i
                           and vld.assigned_by = reviewed_by_i)*/
            RETURNING rid into l_rid;
          /*if sql%rowcount = 0 then
              dbms_output.put_line('Noticed that we are not returning anything from this one');
              verif_exists:=1;
          else*/
            IF (NVL(l_rids.PRIOR(l_rid_counter),-1) != l_rid) THEN
                l_rids.extend;
                l_rids(l_rid_counter) := l_rid;
                l_rid_counter := l_rid_counter+1;
            END IF;
            INSERT INTO comm_chg_vlds(assigned_user_id, signoff_date, comm_chg_log_id, assignment_type_id, assigned_by, rid)
            VALUES (reviewed_by_i, SYSTIMESTAMP, chg_logs_i(i), review_type_id_i, reviewed_by_i, l_rid);
          --end if;
        END LOOP;

      --if (verif_exists<>0) then
        --If this is a Final Review, check to see if all Changes have final review, if so, update the Revision Summary Status
        SELECT name
        INTO l_review_type
        FROM assignment_types
        WHERE id = review_type_id_i;
        IF (l_review_type = 'Final Review') THEN
            FOR r IN 1..l_rids.COUNT LOOP
                /*
                SELECT COUNT(DISTINCT comm_chg_log_id), NVL(SUM(CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END),0)
                INTO l_count_chg_logs, l_count_fr
                FROM comm_chg_vlds
                WHERE rid = l_rids(r);
                */
                -- CRAPP-3149
                SELECT COUNT (DISTINCT comm_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT comm_chg_log_id, assignment_type_id
                        FROM comm_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 AND l_count_chg_logs = l_count_fr) THEN
                    UPDATE commodity_revisions
                    SET summ_ass_status = 5
                    WHERE id = l_rids(r);
                END IF;
            END LOOP;
        -- Changes for "Test in Staging", If all changes have "Test in Staging", set summ_ass_status = 2, that way these records will get pulled into ETL.
        ELSIF (l_review_type = 'Test in Staging') THEN
            FOR r IN 1..l_rids.COUNT LOOP

                SELECT COUNT (DISTINCT comm_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 7 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT comm_chg_log_id, assignment_type_id
                        FROM comm_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 AND l_count_chg_logs = l_count_fr) THEN
                    UPDATE commodity_revisions
                    SET summ_ass_status = 2
                    WHERE id = l_rids(r);
                END IF;
            END LOOP;
        END IF;

        -- Set the staging flag if all change records are either final reviewed or test in staging added.
            FOR r IN 1..l_rids.COUNT
            LOOP
                select count(1) into letl_chg_cnt from comm_chg_logs where rid = l_rids(r);
                select count(distinct comm_chg_log_id) into letl_vld_stg_cnt from comm_chg_vlds where rid = l_rids(r) and assignment_type_id in (2,7);

                if  letl_chg_cnt = letl_vld_stg_cnt
                then
                    update commodity_revisions set ready_for_staging = 1 where id = l_rids(r);
                end if;
            end loop;
      --end if;
    END sign_comm_chg_logs;

    -- Reference groups
    PROCEDURE sign_ref_grp_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        )
    IS
        l_chg_tbl NUMBER;
        l_pk NUMBER;
        l_rid NUMBER;
        l_Review_type varchar2(50);
        l_count_chg_logs NUMBER;
        l_count_fr NUMBER;
        TYPE rids IS TABLE OF INTEGER;
        l_rids rids := rids();
        l_rid_counter NUMBER := 1;
        verif_exists number:=0;
        lactlog_processid number := crapp_admin.pk_action_log_process_id.nextval;
        letl_chg_cnt number := 0;
        letl_vld_stg_cnt number := 1;

       E_Selection_Error exception;
    BEGIN
        FOR i IN 1..chg_logs_i.COUNT LOOP
            UPDATE ref_grp_chg_logs lg
            SET status = 1
            WHERE id = chg_logs_i(i)

            -- Orig from unsign: CRAPP-3007 prep for fix to not allow adding review to published record
            AND lg.status<>2

            /*  and not exists(select 1
                           from ref_grp_chg_vlds vld
                           where vld.ref_grp_chg_log_id= lg.id
                           and vld.assignment_type_id=review_type_id_i
                           and vld.assigned_by = reviewed_by_i)*/
            RETURNING rid into l_rid;

          IF (SQL%ROWCOUNT != 0) THEN
            /*if sql%rowcount = 0 then
                dbms_output.put_line('Noticed that we are not returning anything from this one');
                verif_exists:=1;
            else*/
            IF (NVL(l_rids.PRIOR(l_rid_counter),-1) != l_rid) THEN
                l_rids.extend;
                l_rids(l_rid_counter) := l_rid;
                l_rid_counter := l_rid_counter+1;
            END IF;
            INSERT INTO ref_grp_chg_vlds(assigned_user_id, signoff_date, ref_grp_chg_log_id, assignment_type_id, assigned_by, rid)
            VALUES (reviewed_by_i, SYSTIMESTAMP, chg_logs_i(i), review_type_id_i, reviewed_by_i, l_rid);
            --end if;
          ELSE
           RAISE E_Selection_Error;
          END IF;

        END LOOP;

      --if (verif_exists<>0) then
        --If this is a Final Review, check to see if all Changes have final review, if so, update the Revision Summary Status
        SELECT name
        INTO l_review_type
        FROM assignment_types
        WHERE id = review_type_id_i;
          IF (l_review_type = 'Final Review') THEN
            FOR r IN 1..l_rids.COUNT LOOP
                /*
                SELECT COUNT(DISTINCT ref_grp_chg_log_id), NVL(SUM(CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END),0)
                INTO l_count_chg_logs, l_count_fr
                FROM ref_grp_chg_vlds
                WHERE rid = l_rids(r);
                */
                -- CRAPP-3149
                SELECT COUNT (DISTINCT ref_grp_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT ref_grp_chg_log_id, assignment_type_id
                        FROM ref_grp_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 AND l_count_chg_logs = l_count_fr) THEN
                    UPDATE ref_group_revisions
                    SET summ_ass_status = 5
                    WHERE id = l_rids(r);
                END IF;
            END LOOP;
          -- Changes for "Test in Staging", If all changes have "Test in Staging", set summ_ass_status = 2, that way these records will get pulled into ETL.
          ELSIF (l_review_type = 'Test in Staging') THEN
            FOR r IN 1..l_rids.COUNT LOOP

                SELECT COUNT (DISTINCT ref_grp_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 7 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT ref_grp_chg_log_id, assignment_type_id
                        FROM ref_grp_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 AND l_count_chg_logs = l_count_fr) THEN
                    UPDATE ref_group_revisions
                    SET summ_ass_status = 2
                    WHERE id = l_rids(r);
                END IF;
            END LOOP;
          END IF;

            -- Set the staging flag if all change records are either final reviewed or test in staging added.
            FOR r IN 1..l_rids.COUNT
            LOOP
                select count(1) into letl_chg_cnt from ref_grp_chg_logs where rid = l_rids(r);
                select count(distinct ref_grp_chg_log_id) into letl_vld_stg_cnt from ref_grp_chg_vlds where rid = l_rids(r) and assignment_type_id in (2,7);

                if  letl_chg_cnt = letl_vld_stg_cnt
                then
                    update ref_group_revisions set ready_for_staging = 1 where id = l_rids(r);
                end if;
            end loop;
      --end if;

      EXCEPTION
      WHEN E_Selection_Error THEN
-- TODO
-- 201610
-- Some sort of message to UI or just log?
           lcopy_err_message := nvl(lcopy_err_message, '{')||',"Error Message":"Already published record selected"}';
           insert into crapp_admin.action_log ( status, referrer, entered_by, parameters, process_id )
           values (  -1, ' '||'/documentation/change-log/', reviewed_by_i, lcopy_err_message, lactlog_processid );
           commit;
           ERRLOGGER.REPORT_AND_GO(-21100, 'Adding review not possible. Published record was selected.');
      WHEN OTHERS THEN
        ERRLOGGER.REPORT_AND_STOP(SQLCODE, 'Adding selected reviews not possible.');

    END sign_ref_grp_chg_logs;


    PROCEDURE sign_gis_unique_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        )
    IS
        l_chg_tbl NUMBER;
        l_pk NUMBER;
        l_rid NUMBER;
        l_Review_type varchar2(50);
        l_count_chg_logs NUMBER;
        l_count_fr NUMBER;
        TYPE rids IS TABLE OF INTEGER;
        l_rids rids := rids();
        l_rid_counter NUMBER := 1;
        verif_exists number:=0;
    BEGIN
        FOR i IN 1..chg_logs_i.COUNT LOOP
            UPDATE geo_unique_area_chg_logs lg
            SET status = 1
            WHERE id = chg_logs_i(i)
            RETURNING rid into l_rid;
          /*if sql%rowcount = 0 then
              dbms_output.put_line('Noticed that we are not returning anything from this one');
              verif_exists:=1;
          else*/
            IF (NVL(l_rids.PRIOR(l_rid_counter),-1) != l_rid) THEN
                l_rids.extend;
                l_rids(l_rid_counter) := l_rid;
                l_rid_counter := l_rid_counter+1;
            END IF;
            INSERT INTO geo_unique_area_chg_vlds(assigned_user_id, signoff_date, geo_unique_area_chg_log_id, assignment_type_id, assigned_by, rid)
            VALUES (reviewed_by_i, SYSTIMESTAMP, chg_logs_i(i), review_type_id_i, reviewed_by_i, l_rid);
          --end if;
        END LOOP;

        --If this is a Final Review, check to see if all Changes have final review, if so, update the Revision Summary Status
        SELECT name
        INTO l_review_type
        FROM assignment_types
        WHERE id = review_type_id_i;
        IF (l_review_type = 'Final Review') THEN
            FOR r IN 1..l_rids.COUNT LOOP
                /*
                SELECT COUNT(DISTINCT geo_unique_area_chg_log_id), NVL(SUM(CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END),0)
                INTO l_count_chg_logs, l_count_fr
                FROM geo_unique_area_chg_vlds
                WHERE rid = l_rids(r);
                */
                -- CRAPP-3149
                SELECT COUNT (DISTINCT geo_unique_area_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT geo_unique_area_chg_log_id, assignment_type_id
                        FROM geo_unique_area_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 AND l_count_chg_logs = l_count_fr) THEN
                    UPDATE geo_unique_area_revisions
                    SET summ_ass_status = 5
                    WHERE id = l_rids(r);
                END IF;
            END LOOP;
        END IF;
    END sign_gis_unique_chg_logs;

    -- Unlock status for revision
    -- Note: this one is Overloaded -->
    PROCEDURE unlock_revision(ientity_type IN NUMBER, iRid IN NUMBER, unlock_success OUT NUMBER)
    IS
      l_del_vlds chglogids := chglogids();  -- list of id
      l_entity NUMBER := ientity_type;      -- 1..6
      l_rid NUMBER    := iRid;              -- current rid to reset
      l_upd_success NUMBER := 0;
      -- Tables
      QryVld CLOB;
    BEGIN
      --
      IF l_entity IS NOT NULL THEN
         QryVld := getLogTables(l_entity);
--DBMS_OUTPUT.Put_Line( QryVld );
         EXECUTE IMMEDIATE QryVld
         BULK COLLECT INTO l_del_vlds using l_rid;
      IF (l_entity = '1') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_admin_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '2') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_juris_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '3') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_tax_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '4') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_tax_app_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '5') THEN
         -- Commodities
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_comm_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '11') THEN
         -- Jurisdiction Type
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_juris_type_chg_logs(l_del_vlds);
         END LOOP;
      /*
      ELSIF (l_entity = '6') THEN
         -- Commodity Groups
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_comm_grp_chg_logs(l_del_vlds);
         END LOOP;
      */
      END IF;

      l_upd_success := 1;
      unlock_success := l_upd_success;
      ELSE
        l_upd_success := 0;
        unlock_success := l_upd_success;
      END IF;
    END unlock_revision;


    PROCEDURE unlock_revision(ientity_type IN NUMBER, iRid IN NUMBER, unlock_success OUT NUMBER, userList in varchar2)
    IS
      l_del_vlds chglogids := chglogids();  -- list of id
      l_entity NUMBER := ientity_type;      -- 1..6
      l_rid NUMBER    := iRid;              -- current rid to reset
      l_upd_success NUMBER := 0;
      -- Tables
      QryVld CLOB;
    BEGIN
      --
      IF l_entity IS NOT NULL THEN
         QryVld := getLogTables(iEntityType=>l_entity, userList=>userlist);
-- DBMS_OUTPUT.Put_Line( QryVld );
         EXECUTE IMMEDIATE QryVld
         BULK COLLECT INTO l_del_vlds using l_rid;
      IF (l_entity = '1') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_admin_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '2') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_juris_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '3') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_tax_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '4') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_tax_app_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '5') THEN
         -- Commodities
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_comm_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '11') THEN
         -- Jurisdiction Type
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_juris_type_chg_logs(l_del_vlds);
         END LOOP;
      /*
      ELSIF (l_entity = '6') THEN
         -- Commodity Groups
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_comm_grp_chg_logs(l_del_vlds);
         END LOOP;
      */
      END IF;

      l_upd_success := 1;
      unlock_success := l_upd_success;
      ELSE
        l_upd_success := 0;
        unlock_success := l_upd_success;
      END IF;
    END unlock_revision;


    PROCEDURE unlock_change_log(ientity_type IN NUMBER, iChgLog IN NUMBER, unlock_success OUT NUMBER)
    IS
      l_del_vlds chglogids := chglogids();  -- list of id
      l_entity NUMBER := ientity_type;      -- 1..6
      l_change_log NUMBER    := iChgLog;    -- current change log id to reset
      l_upd_success NUMBER := 0;
      QryVld CLOB;
    BEGIN
      --
      IF l_entity IS NOT NULL THEN
         QryVld := getLogTables_Chg(l_entity);
         DBMS_OUTPUT.Put_Line( QryVld );
         EXECUTE IMMEDIATE QryVld
         BULK COLLECT INTO l_del_vlds using iChgLog;
      IF (l_entity = '1') THEN
         --FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_admin_chg_logs(l_del_vlds);
         --END LOOP;
      ELSIF (l_entity = '2') THEN
DBMS_OUTPUT.Put_Line( 'Ent 2' );

         --FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_juris_chg_logs(l_del_vlds);
         --END LOOP;
      ELSIF (l_entity = '3') THEN
         --FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_tax_chg_logs(l_del_vlds);
         --END LOOP;
      ELSIF (l_entity = '4') THEN
         --FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_tax_app_chg_logs(l_del_vlds);
         --END LOOP;
      ELSIF (l_entity = '5') THEN
         -- Commodities
         --FOR i IN 1..l_del_vlds.COUNT LOOP
            CHANGE_MGMT.unsign_comm_chg_logs(l_del_vlds);
         --END LOOP;
      ELSIF (l_entity = '11') THEN
         -- Jurisdictuion Type
         --FOR i IN 1..l_del_vlds.COUNT LOOP
            CHANGE_MGMT.unsign_juris_type_chg_logs(l_del_vlds);
         --END LOOP;
      /*
      ELSIF (l_entity = '6') THEN
         -- Commodity Groups
         FOR i IN 1..l_del_vlds.COUNT LOOP
            CHANGE_MGMT.unsign_comm_grp_chg_logs(l_del_vlds);
         END LOOP;
      */
      END IF;

      l_upd_success := 1;
      unlock_success := l_upd_success;
      ELSE
        l_upd_success := 0;
        unlock_success := l_upd_success;
      END IF;
    END unlock_change_log;

    PROCEDURE unlock_change_log(ientity_type IN NUMBER, iChgLog IN NUMBER, unlock_success OUT NUMBER, userList in varchar2)
    IS
      l_del_vlds chglogids := chglogids();  -- list of id
      l_entity NUMBER := ientity_type;      -- 1..6
      l_change_log NUMBER    := iChgLog;    -- current change log id to reset
      l_upd_success NUMBER := 0;
      QryVld CLOB;
    BEGIN
      IF l_entity IS NOT NULL THEN
         QryVld := getLogTables_Chg(iEntityType=>l_entity, userList=>userlist);
--DBMS_OUTPUT.Put_Line( QryVld );
         EXECUTE IMMEDIATE QryVld
         BULK COLLECT INTO l_del_vlds using iChgLog;
      IF (l_entity = '1') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_admin_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '2') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_juris_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '3') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_tax_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '4') THEN
         FOR i IN 1..l_del_vlds.COUNT LOOP
             CHANGE_MGMT.unsign_tax_app_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '5') THEN
         -- Commodities
         FOR i IN 1..l_del_vlds.COUNT LOOP
            CHANGE_MGMT.unsign_comm_chg_logs(l_del_vlds);
         END LOOP;
      ELSIF (l_entity = '11') THEN
         -- Jurisdiction Type
         FOR i IN 1..l_del_vlds.COUNT LOOP
            CHANGE_MGMT.unsign_juris_type_chg_logs(l_del_vlds);
         END LOOP;
      /*
      ELSIF (l_entity = '6') THEN
         -- Commodity Groups
         FOR i IN 1..l_del_vlds.COUNT LOOP
            CHANGE_MGMT.unsign_comm_grp_chg_logs(l_del_vlds);
         END LOOP;
      */
      END IF;

      l_upd_success := 1;
      unlock_success := l_upd_success;
      ELSE
        l_upd_success := 0;
        unlock_success := l_upd_success;
      END IF;
    END unlock_change_log;

    -- Remove Pending Revisions
    -- -- CRAPP-1481: unlock/remove revision/remove attachments
    Procedure remove_pending(pEntity_type in number, rid_list in clob, deleted_by_i in number,
                             success_o out number, logId_o out number)
    is
      change_tt numTableType;     -- table of numbers
      pr number := 0;             -- process status for delete revision
      nLog_id number := null;
      l_logged number := 0;
      l_remove_vld_n number := 0; -- remove validation records status
      comms_clob clob:=EMPTY_CLOB();
    BEGIN
       change_tt:=str2tbl( rid_list );
       -- ToDo: we're not taking care of status in the loop here
       -- Fail will return 0

       -- Log Id
       nLog_id := Log_Remove_Revision_Seq.NEXTVAL();

       FOR i IN 1 .. change_tt.count LOOP
          success_o := 0;
          dev_vld_remove(pEntity_type, change_tt(i), l_remove_vld_n);
          if l_remove_vld_n =1 then
              IF (pEntity_type = 1) THEN
                --administrator.delete_revision(change_tt(i), deleted_by_i, pr);
                administrator.delete_revision(resetall=>1, revision_id_i=>change_tt(i), deleted_by_i=>deleted_by_i, success_o=> pr);
              ELSIF (pEntity_type = 2) THEN
                --jurisdiction.delete_revision(change_tt(i), deleted_by_i, pr);
                jurisdiction.delete_revision(resetall=>1, revision_id_i=>change_tt(i), deleted_by_i=>deleted_by_i, success_o=> pr);
              ELSIF (pEntity_type = 3) THEN
                --taxlaw_taxes.delete_revision(change_tt(i), deleted_by_i, pr);
                taxlaw_taxes.delete_revision(resetall=>1, revision_id_i=>change_tt(i), deleted_by_i=>deleted_by_i, success_o=> pr);
              ELSIF (pEntity_type = 4) THEN
                taxability.delete_revision(resetall=>1, revision_id_i=>change_tt(i), deleted_by_i=>deleted_by_i, success_o=> pr);
                --taxability.delete_revision(revision_id_i=> change_tt(i), deleted_by_i=>deleted_by_i, success_o=> pr);
              ELSIF (pEntity_type = 5) THEN
                --commodity.delete_revision(revision_id_i=> change_tt(i), deleted_by_i=>deleted_by_i, success_o=>pr, existsingroups=> comms_clob);
                commodity.delete_revision(resetall=>1, revision_id_i=> change_tt(i), deleted_by_i=>deleted_by_i, success_o=>pr, existsingroups=> comms_clob);
              /*
              ELSIF (pEntity_type = 6) THEN
                --commodity_group.delete_revision(change_tt(i), deleted_by_i, pr);
                commodity_group.delete_revision(resetall=>1, revision_id_i=>change_tt(i), deleted_by_i=>deleted_by_i, success_o=> pr);
              */
              ELSIF (pEntity_type = 9) THEN
                --reference_group.delete_revision(revision_id_i=>change_tt(i), deleted_by_i=>deleted_by_i, success_o=>pr);
                reference_group.delete_revision(resetall=>1, revision_id_i=>change_tt(i), deleted_by_i=>deleted_by_i, success_o=> pr);
              ELSIF (pEntity_type = 11) THEN
                jurisdiction_type.delete_revision(resetall=>1, revision_id_i=>change_tt(i), deleted_by_i=>deleted_by_i, success_o=> pr);
            END IF;
          END IF;

          -- Log failure
          -- (ToDo: Might want to log successful ones too)
          if pr = 0 then
             success_o:=0;
             log_remove(nLog_id, change_tt(i), pEntity_type);
          end if;
          --DBMS_OUTPUT.put_line(i || ' : ' ||  change_tt(i));
       END LOOP;

       /* Dev: Simple check for now : might want to keep count/what in the future */
       Select count(*) into l_logged
         from change_log_remove_rev
        where logId = nLog_id;
       if (l_logged>0) then
         success_o := 0;
         logId_o := nLog_id;
       else
         success_o := 1;
         logId_o := null;
       end if;

      EXCEPTION
       WHEN TIMEOUT_ON_RESOURCE THEN
          success_o := 0;
          raise;
    End;


    -- Log removed id
    PROCEDURE log_remove(pId in number, pRid in number, pEntity in number) is
    PRAGMA autonomous_transaction;
    BEGIN
      -- simple insert for now
      EXECUTE IMMEDIATE 'INSERT INTO change_log_remove_rev
                         values(:Id, :Rid, :Entity, sysdate)'
      USING pId, pRid, pEntity;
      Commit;
    end;


  /* Unlink documentation
  #
  # XML
  <change_log>
    <entity>2</entity>
    <document>
        <id>84</id>
        <deleted>0</deleted>
        <document_name>Test document 2</document_name>
        <citation>
            <id>100</id>
            <deleted>0</deleted>
            <document_id/>
            <text/>
        </citation>
    </document>
    <entered_by>304</entered_by>
    <overwrite>1</overwrite>
    <cancel_button/>
    <addDocumentation/>
    <changes>
        <id>1017707</id>
    </changes>
    <changes>
        <id>1017681</id>
    </changes>
    <changes>
        <id>1017655</id>
    </changes>
    <modified>1</modified>
   </change_log>
  #
  #
  */
  Procedure Bulk_Unlink_Doc(sx IN CLOB, success OUT NUMBER) is
    l_chg_logs chglogids;
    l_upd_success NUMBER := 0;
    TYPE docids IS TABLE OF INTEGER;
    l_docs docids := docids();
    l_entity number;
    l_entered_by number;
  Begin
        SELECT
            extractvalue(column_value, '/change_log/entity') entity,
            extractvalue(column_value, '/change_log/entered_by') entered_by
        INTO
            l_entity,
            l_entered_by
        FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/change_log'))) t;
    -- Get Change_Log_Ids
        SELECT
            extractvalue(column_value, '/id')
        BULK COLLECT INTO
            l_chg_logs
        FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/change_log/changes/id'))) t;
    -- Get Documents
        SELECT
            extractvalue(column_value, '/document/id') id
        BULK COLLECT INTO
            l_docs
        FROM TABLE(XMLSequence(XMLTYPE(sx).extract('/change_log/document'))) t;

    -- Entity
    -- NOTE: I decided to keep these individually even if I do have a function
    --       in this package 'getLogTables' that can pick out the tables needed
    IF (l_entity = 1) THEN
      FOR v in 1..l_chg_logs.count LOOP
      FORALL i IN 1..l_docs.COUNT
       DELETE FROM admin_chg_cits ctd
       WHERE EXISTS
       (SELECT a.id
        FROM admin_chg_cits a
        JOIN citations c on (c.id=a.citation_id)
        JOIN attachments att on (att.id = c.attachment_id )
        WHERE att.id=l_docs(i)
        AND ctd.id=a.id)
       AND ctd.admin_chg_log_id=l_chg_logs(v);
      End loop;
    End if;

    IF (l_entity = 2) THEN
      FOR v in 1..l_chg_logs.count LOOP
      FORALL i IN 1..l_docs.COUNT
       DELETE FROM juris_chg_cits ctd
       WHERE EXISTS
       (SELECT a.id
        FROM juris_chg_cits a
        JOIN citations c on (c.id=a.citation_id)
        JOIN attachments att on (att.id = c.attachment_id )
        WHERE att.id=l_docs(i)
        AND ctd.id=a.id)
       AND ctd.juris_chg_log_id=l_chg_logs(v);
      end loop;
    End if;

    IF (l_entity = 3) THEN
      FOR v in 1..l_chg_logs.count LOOP
      FORALL i IN 1..l_docs.COUNT
       DELETE FROM juris_tax_chg_cits ctd
       WHERE EXISTS
       (SELECT a.id
        FROM juris_tax_chg_cits a
        JOIN citations c on (c.id=a.citation_id)
        JOIN attachments att on (att.id = c.attachment_id )
        WHERE att.id=l_docs(i)
        AND ctd.id=a.id)
       AND ctd.juris_tax_chg_log_id=l_chg_logs(v);
      End loop;
    End if;

    IF (l_entity = 4) THEN
      FOR v in 1..l_chg_logs.count LOOP
      FORALL i IN 1..l_docs.COUNT
       DELETE FROM juris_tax_app_chg_cits ctd
       WHERE EXISTS
       (SELECT a.id
        FROM juris_tax_app_chg_cits a
        JOIN citations c on (c.id=a.citation_id)
        JOIN attachments att on (att.id = c.attachment_id )
        WHERE att.id=l_docs(i)
        AND ctd.id=a.id)
       AND ctd.juris_tax_app_chg_log_id=l_chg_logs(v);
      End loop;
    End if;

    IF (l_entity = 5) THEN
      FOR v in 1..l_chg_logs.count LOOP
      FORALL i IN 1..l_docs.COUNT
       DELETE FROM comm_chg_cits ctd
       WHERE EXISTS
       (SELECT a.id
        FROM comm_chg_cits a
        JOIN citations c on (c.id=a.citation_id)
        JOIN attachments att on (att.id = c.attachment_id )
        WHERE att.id=l_docs(i)
        AND ctd.id=a.id)
       AND ctd.comm_chg_log_id=l_chg_logs(v);
      End loop;
    End if;

    /*
    IF (l_entity = 6) THEN
      FOR v in 1..l_chg_logs.count LOOP
      FORALL i IN 1..l_docs.COUNT
       DELETE FROM comm_grp_chg_cits ctd
       WHERE EXISTS
       (SELECT a.id
        FROM comm_grp_chg_cits a
        JOIN citations c on (c.id=a.citation_id)
        JOIN attachments att on (att.id = c.attachment_id )
        WHERE att.id=l_docs(i)
        AND ctd.id=a.id)
       AND ctd.comm_grp_chg_log_id=l_chg_logs(v);
      END LOOP;
    END IF;
    */

    IF (l_entity = 9) THEN
      FOR v in 1..l_chg_logs.count LOOP
      FORALL i IN 1..l_docs.COUNT
       DELETE FROM ref_grp_chg_cits ctd
       WHERE EXISTS
       (SELECT a.id
        FROM ref_grp_chg_cits a
        JOIN citations c on (c.id=a.citation_id)
        JOIN attachments att on (att.id = c.attachment_id )
        WHERE att.id=l_docs(i)
        AND ctd.id=a.id)
       AND ctd.ref_grp_chg_log_id=l_chg_logs(v);
      End loop;
    End if;

    IF (l_entity = 10) THEN
      FOR v in 1..l_chg_logs.count LOOP
      FORALL i IN 1..l_docs.COUNT
       DELETE FROM geo_poly_ref_chg_cits ctd
       WHERE EXISTS
       (SELECT a.id
        FROM geo_poly_ref_chg_cits a
        JOIN citations c on (c.id=a.citation_id)
        JOIN attachments att on (att.id = c.attachment_id )
        WHERE att.id=l_docs(i)
        AND ctd.id=a.id)
       AND ctd.geo_poly_ref_chg_log_id=l_chg_logs(v);
      End loop;
    End if;

    IF (l_entity = 11) THEN
      FOR v in 1..l_chg_logs.count LOOP
      FORALL i IN 1..l_docs.COUNT
       DELETE FROM juris_type_chg_cits ctd
       WHERE EXISTS
       (SELECT a.id
        FROM juris_type_chg_cits a
        JOIN citations c on (c.id=a.citation_id)
        JOIN attachments att on (att.id = c.attachment_id )
        WHERE att.id=l_docs(i)
        AND ctd.id=a.id)
       AND ctd.juris_type_chg_log_id=l_chg_logs(v);
      End loop;
    End if;

    -- for now there is no other check than raw exceptions
    success := 1;

    EXCEPTION
    WHEN TIMEOUT_ON_RESOURCE THEN
         success := 0;
         raise;
    WHEN NO_DATA_FOUND THEN
         success := 0;
    WHEN OTHERS THEN
         success := 0;

  END Bulk_Unlink_Doc;

-- TODO
   procedure Bulk_Remove_Revision(pEntity_Type in number
                                    , rid_list in clob
                                    , deleted_by_i in number
                                    , success_o out number
                                    , logId_o out number)
    is
      change_tt numTableType;     -- table of numbers
      pr number := 0;             -- process status for delete verification
      nLog_id number := null;
      l_logged number := 0;
      l_remove_ver_n number := 0; -- remove verification status
    begin
      success_o := 1;
      change_tt:=str2tbl( rid_list );
      -- Log Id
      nLog_id := Log_Remove_Revision_Seq.NEXTVAL();

--DBMS_OUTPUT.Put_Line( 'NLogID:'||nLog_id);

      FOR i IN 1 .. change_tt.count LOOP
        --> Remove:
        unlock_revision(pEntity_Type, change_tt(i), l_remove_ver_n);
        -- Log failure
        if l_remove_ver_n = 0 then
           log_remove(nLog_id, change_tt(i), pEntity_Type);
        end if;
--DBMS_OUTPUT.put_line(i || ' : ' ||  change_tt(i));
      end loop;

    -- Quick check for logged records
      Select COUNT(*) into l_logged
        from change_log_remove_rev
       where logId = nLog_id;
      if (l_logged>0) then
        success_o := 0;
        logId_o := nLog_id;
      else
        success_o := 1;
        logId_o := null;
      end if;

      EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
          success_o := 0;
          raise;
    end Bulk_Remove_Revision;


/*
|| Bulk add tags
|| CRAPP-2929
|| change_id_list - each individual change log record (rid will give multiple)
||
*/
procedure Bulk_Add_Tags(pEntity_Type in number
         ,change_id_list in clob
         ,tagId_list in varchar2
         ,nRemove in number default 0
         ,editedBy in number
         ,success_o out number
         ,logId_o out number)
is
  change_list numTableType; -- table of numbers
  change_tt chglogids := chglogids();

  entered_by number := editedBy; -- should have been renamed
  nAddOrRemove number := nRemove;
  -- All available tags
  Cursor cTags is
    Select * from Tags;
    recs tTags;

begin
 open cTags;
 fetch cTags bulk collect into recs;
 close cTags;
 change_list:=str2tbl(change_id_list);
 SELECT DISTINCT COLUMN_VALUE BULK COLLECT INTO change_tt FROM TABLE(change_list);

 IF (pEntity_Type = 1) THEN
   CHANGE_MGMT.add_tags_admin(change_tt, entered_by, tagId_list, nAddOrRemove);  -- Administrator
 ELSIF (pEntity_Type = 2) THEN
   CHANGE_MGMT.add_tags_juris(change_tt, entered_by, tagId_list, nAddOrRemove);  -- Jurisdiction
 ELSIF (pEntity_Type = 3) THEN
   CHANGE_MGMT.add_tags_tax(change_tt, entered_by, tagId_list, nAddOrRemove);  -- Taxes
 ELSIF (pEntity_Type = 4) THEN
   CHANGE_MGMT.add_tags_taxability(change_tt, entered_by, tagId_list, nAddOrRemove);  -- Taxability
 ELSIF (pEntity_Type = 5) THEN
   CHANGE_MGMT.add_tags_comm(change_tt, entered_by, tagId_list, nAddOrRemove); -- Commodities
 ELSIF (pEntity_Type = 9) THEN
   CHANGE_MGMT.add_tags_ref(change_tt, entered_by, tagId_list, nAddOrRemove);  -- Reference groups
 ELSIF (pEntity_Type = 11) THEN
   CHANGE_MGMT.add_tags_juris_type(change_tt, entered_by, tagId_list, nAddOrRemove);  -- Jurisdiction Type
 END IF;

 --> Steps
 -- Start log
 -- Entity (all need merge for each entity and its tag tables)
    -- a/ Rid list to process
    -- Admins
    -- Jurisdiction
    -- Taxes
    -- Taxability
    -- Commodities
    -- Reference Groups

    -- Send success flag
 -- End log (log id, time, what)
      success_o := 1;

End;

    -- Administrator
   PROCEDURE add_tags_admin(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        )
    IS
      -- memory allocation 'local' for each procedure instead of global
      tag_list xmlform_tags_tt := xmlform_tags_tt();
      type rzx is table of varchar2(32);
      rz rzx:=rzx();

      t_nkid administrators.nkid%type;
      status_o number;
    BEGIN
      with cmList as (select ''''||replace(tagid_list,',',''''||','||' ''')||'''' colx from dual)
      select xt.column_value.getClobVal()
      bulk collect into rz
      from xmltable((select colx from cmList)) xt;

      FOR i IN 1..chg_logs_i.COUNT LOOP
        -- Build tag collection by NKID
        Select nkid into t_nkid
          from administrators where id=
         (select distinct primary_key from admin_chg_logs where id =  chg_logs_i(i));
        -- functionality is calling for being able to add for both published/unpublished so no rid nor status used.

        -- Tags
        FOR itags IN rz.first..rz.last LOOP
          tag_list.extend;
          tag_list( tag_list.last ):=xmlform_tags(
          1,
          t_nkid,
          enteredBy,
          rz(itags),
                    nAddOrRemove,
          0);
        END LOOP;
        tags_registry.tags_entry(tag_list=> tag_list, ref_nkid=> t_nkid);
      END LOOP;

      -- EXCEPTION in tags_registry, status should probably be passed back here

    END add_tags_admin;


    -- Jurisdictions
   PROCEDURE add_tags_juris(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        )
    IS
      -- memory allocation 'local' for each procedure instead of global
      tag_list xmlform_tags_tt := xmlform_tags_tt();
      type rzx is table of varchar2(32);
      rz rzx:=rzx();

      t_nkid administrators.nkid%type;
      status_o number;
    BEGIN
      with cmList as (select ''''||replace(tagid_list,',',''''||','||' ''')||'''' colx from dual)
      select xt.column_value.getClobVal()
      bulk collect into rz
      from xmltable((select colx from cmList)) xt;

      FOR i IN 1..chg_logs_i.COUNT LOOP
        -- Build tag collection by NKID
        Select nkid into t_nkid
          from jurisdictions where id=
         (select distinct primary_key from juris_chg_logs where id =  chg_logs_i(i));
        -- functionality is calling for being able to add for both published/unpublished so no rid nor status used.

        -- Tags
        FOR itags IN rz.first..rz.last LOOP
          tag_list.extend;
          tag_list( tag_list.last ):=xmlform_tags(
          2,
          t_nkid,
          enteredBy,
          rz(itags),
                    nAddOrRemove,
          0);
        END LOOP;
        tags_registry.tags_entry(tag_list=> tag_list, ref_nkid=> t_nkid);
      END LOOP;

      -- EXCEPTION in tags_registry, status should probably be passed back here

    END add_tags_juris;

    -- Jurisdiction Types
   PROCEDURE add_tags_juris_type(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        )
    IS
      -- memory allocation 'local' for each procedure instead of global
      tag_list xmlform_tags_tt := xmlform_tags_tt();
      type rzx is table of varchar2(32);
      rz rzx:=rzx();

      t_nkid jurisdiction_types.nkid%type;
      status_o number;
    BEGIN
      with cmList as (select ''''||replace(tagid_list,',',''''||','||' ''')||'''' colx from dual)
      select xt.column_value.getClobVal()
      bulk collect into rz
      from xmltable((select colx from cmList)) xt;

      FOR i IN 1..chg_logs_i.COUNT LOOP
        -- Build tag collection by NKID
        Select nkid into t_nkid
          from jurisdiction_types where id=
         (select distinct primary_key from juris_type_chg_logs where id =  chg_logs_i(i));
        -- functionality is calling for being able to add for both published/unpublished so no rid nor status used.

        -- Tags
        FOR itags IN rz.first..rz.last LOOP
          tag_list.extend;
          tag_list( tag_list.last ):=xmlform_tags(
          11,
          t_nkid,
          enteredBy,
          rz(itags),
          nAddOrRemove,
          0);
        END LOOP;
        tags_registry.tags_entry(tag_list=> tag_list, ref_nkid=> t_nkid);
      END LOOP;

    END add_tags_juris_type;
    -- Tax
   PROCEDURE add_tags_tax(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        )
    IS
      -- memory allocation 'local' for each procedure instead of global
      tag_list xmlform_tags_tt := xmlform_tags_tt();
      type rzx is table of varchar2(32);
      rz rzx:=rzx();

      t_nkid juris_tax_impositions.nkid%type;
      status_o number;
    BEGIN
      with cmList as (select ''''||replace(tagid_list,',',''''||','||' ''')||'''' colx from dual)
      select xt.column_value.getClobVal()
      bulk collect into rz
      from xmltable((select colx from cmList)) xt;

      FOR i IN 1..chg_logs_i.COUNT LOOP
        -- Build tag collection by NKID
        Select nkid into t_nkid
          from juris_tax_impositions where id=
         (select distinct primary_key from juris_tax_chg_logs where id =  chg_logs_i(i));
        -- functionality is calling for being able to add for both published/unpublished so no rid nor status used.

        -- Tags
        FOR itags IN rz.first..rz.last LOOP
          tag_list.extend;
          tag_list( tag_list.last ):=xmlform_tags(
          3,
          t_nkid,
          enteredBy,
          rz(itags),
             nAddOrRemove,
          0);
        END LOOP;
        tags_registry.tags_entry(tag_list=> tag_list, ref_nkid=> t_nkid);
      END LOOP;

      -- EXCEPTION in tags_registry, status should probably be passed back here

    END add_tags_tax;


    -- Taxability
   PROCEDURE add_tags_taxability(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        )
    IS
      -- memory allocation 'local' for each procedure instead of global
      tag_list xmlform_tags_tt := xmlform_tags_tt();
      type rzx is table of varchar2(32);
      rz rzx:=rzx();

      t_nkid juris_tax_applicabilities.nkid%type;
      status_o number;
    BEGIN
      with cmList as (select ''''||replace(tagid_list,',',''''||','||' ''')||'''' colx from dual)
      select xt.column_value.getClobVal()
      bulk collect into rz
      from xmltable((select colx from cmList)) xt;

      FOR i IN 1..chg_logs_i.COUNT LOOP
        -- Build tag collection by NKID
        Select nkid into t_nkid
          from juris_tax_applicabilities where id=
         (select distinct primary_key from juris_tax_app_chg_logs where id =  chg_logs_i(i));
        -- functionality is calling for being able to add for both published/unpublished so no rid nor status used.

        -- Tags
        FOR itags IN rz.first..rz.last LOOP
          tag_list.extend;
          tag_list( tag_list.last ):=xmlform_tags(
          4,
          t_nkid,
          enteredBy,
          rz(itags),
                              nAddOrRemove,
          0);
        END LOOP;
        tags_registry.tags_entry(tag_list=> tag_list, ref_nkid=> t_nkid);
      END LOOP;

      -- EXCEPTION in tags_registry, status should probably be passed back here

    END add_tags_taxability;


    -- Commodities
   PROCEDURE add_tags_comm(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        )
    IS
      -- memory allocation 'local' for each procedure instead of global
      tag_list xmlform_tags_tt := xmlform_tags_tt();
      type rzx is table of varchar2(32);
      rz rzx:=rzx();

      t_nkid commodities.nkid%type;
      status_o number;
    BEGIN
      with cmList as (select ''''||replace(tagid_list,',',''''||','||' ''')||'''' colx from dual)
      select xt.column_value.getClobVal()
      bulk collect into rz
      from xmltable((select colx from cmList)) xt;

      FOR i IN 1..chg_logs_i.COUNT LOOP
        -- Build tag collection by NKID
        Select nkid into t_nkid
          from commodities where id=
         (select distinct primary_key from comm_chg_logs where id =  chg_logs_i(i));
        -- functionality is calling for being able to add for both published/unpublished so no rid nor status used.

        -- Tags
        FOR itags IN rz.first..rz.last LOOP
          tag_list.extend;
          tag_list( tag_list.last ):=xmlform_tags(
          5,
          t_nkid,
          enteredBy,
          rz(itags),
                              nAddOrRemove,
          0);
        END LOOP;
        tags_registry.tags_entry(tag_list=> tag_list, ref_nkid=> t_nkid);
      END LOOP;

      -- EXCEPTION in tags_registry, status should probably be passed back here

    END add_tags_comm;


    -- Ref groups
   PROCEDURE add_tags_ref(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        )
    IS
      -- memory allocation 'local' for each procedure instead of global
      tag_list xmlform_tags_tt := xmlform_tags_tt();
      type rzx is table of varchar2(32);
      rz rzx:=rzx();

      t_nkid reference_groups.nkid%type;
      status_o number;
    BEGIN
      with cmList as (select ''''||replace(tagid_list,',',''''||','||' ''')||'''' colx from dual)
      select xt.column_value.getClobVal()
      bulk collect into rz
      from xmltable((select colx from cmList)) xt;

      FOR i IN 1..chg_logs_i.COUNT LOOP
        -- Build tag collection by NKID
        Select nkid into t_nkid
          from reference_groups where id=
         (select distinct primary_key from ref_grp_chg_logs where id =  chg_logs_i(i));
        -- functionality is calling for being able to add for both published/unpublished so no rid nor status used.

        -- Tags
        FOR itags IN rz.first..rz.last LOOP
          tag_list.extend;
          tag_list( tag_list.last ):=xmlform_tags(
          9,
          t_nkid,
          enteredBy,
          rz(itags),
                              nAddOrRemove,
          0);
        END LOOP;
        tags_registry.tags_entry(tag_list=> tag_list, ref_nkid=> t_nkid);
      END LOOP;

      -- EXCEPTION in tags_registry, status should probably be passed back here

    END add_tags_ref;

END change_mgmt;
/