CREATE OR REPLACE PACKAGE BODY content_repo.publish
IS
--
-- To modify this template, edit file PKGBODY.TXT in TEMPLATE
-- directory of SQL Navigator
--
-- Purpose: Briefly explain the functionality of the package body
--
-- MODIFICATION HISTORY
-- Person      Date    Comments
-- ---------   ------  ------------------------------------------
-- Enter procedure, function bodies as shown below
-- 12/18/13 tnn 'removed' update jurisdiction_administrators
-- 8/27/14  tnn Applicability fix
-- 10/18,10/20 added test of status count for entities (quick fix - non index)
-- Added publish for tax_descr/attributes
-- 11/30/2016 removed commodity_group_tags ref
-- 06/04/2017 commodity tree check
-- CRAPP-1845 Generate link to published entities after publication occurs
-- CRAPP-3678 Action Log publish id needed
-- CRAPP-4020 Added process_id for action_log
-- CRAPP-4141 Changes to handle exceptions during publication process of any entity.

Procedure logPublishItem(entityId in number, revision in number, nkid_i in number, publishedBy in number,
publishId in number)
is
PRAGMA AUTONOMOUS_TRANSACTION;
  TYPE entityRec IS RECORD
      (ui_link varchar2(32),
       entity varchar2(32),
       chglog varchar2(30),
       ui_entitylink varchar2(100));
  TYPE entTable IS TABLE OF entityRec; -- INDEX BY BINARY_INTEGER;
  l_ent entTable;
  l_ui_comm_link varchar2(1000);
  l_env varchar2(1000);
begin
  -- TN: TODO This could be moved to header and be populated once from a table.
  l_ent := entTable();
  l_ent.extend();
  l_ent(1).ui_link :='/admin/publication';
  l_ent(1).entity :='administrator';
  l_ent(1).chglog :='admin_chg_logs';
  l_ent(1).ui_entitylink:='/taxadmin/rid/upd';

  l_ent.extend();
  l_ent(2).ui_link :='/juris/publication';
  l_ent(2).entity :='jurisdiction';
  l_ent(2).chglog :='juris_chg_logs';
  l_ent(2).ui_entitylink:='/taxadmin/rid/nkid/upd';

  l_ent.extend();
  l_ent(3).ui_link :='/taxes/publication';
  l_ent(3).entity :='taxes';
  l_ent(3).chglog :='juris_tax_chg_logs';
  l_ent(3).ui_entitylink:='/taxlaw/rid/upd';

  l_ent.extend();
  l_ent(4).ui_link :='/taxability/publication';
  l_ent(4).entity :='taxability';
  l_ent(4).chglog :='juris_tax_app_chg_logs';
  l_ent(4).ui_entitylink:='/taxability/rid/upd';

  l_ent.extend();
  l_ent(5).ui_link :='/commodity/publication';
  l_ent(5).entity :='commodities';
  l_ent(5).chglog :='comm_chg_logs';
  l_ent(5).ui_entitylink:='commodities/rid/upd';

  /* N/A */
  l_ent.extend(); --6
  l_ent.extend(); --7
  l_ent.extend(); --8
  l_ent.extend(); --9
  l_ent(9).ui_link :='/reference/publication';
  l_ent(9).entity :='reference_groups';
  l_ent(9).chglog :='ref_grp_chg_logs';
  l_ent(9).ui_entitylink:='reference-groups/rid/upd';

  l_ent.extend();
  l_ent(10).ui_link :='/boundaries/publication';
  l_ent(10).entity :='boundaries';
  l_ent(10).chglog :='geo_poly_ref_chg_logs';
  l_ent(10).ui_entitylink:='geography/boundaries/rid/upd';

  l_ent.extend();
  l_ent(11).ui_link :='/unique_areas/publication';
  l_ent(11).entity :='unique_areas';
  l_ent(11).chglog :='geo_unique_area_chg_logs';
  l_ent(11).ui_entitylink:='geography/unique-areas/rid/upd';

  -- Changes for CRAPP-2871
  l_ent.extend();
  l_ent(12).ui_link :='/jurisdiction_types/publication';
  l_ent(12).entity :='jurisdiction_types';
  l_ent(12).chglog :='juris_type_chg_logs';
  l_ent(12).ui_entitylink:='jurisdiction_types/rid/upd';

  /* UI Log */
  Select
    replace(replace(replace('/documentation/change-log/0/nkid/rid/1/upd?link=true', 'nkid', nkid_i), 'rid', revision),'/1/','/'||entityId||'/')
  , replace(replace(l_ent(entityId).ui_entitylink, 'rid', revision),'nkid', nkid_i)
  Into l_ui_comm_link, l_env
  From dual;

  Insert Into crapp_admin.action_log ( action_start, action_end, status, referrer, entered_by, parameters, process_id)
  Values (sysdate, sysdate, -1, l_ent(entityId).ui_link, publishedBy,
  '{"Process":"Publication", "Entity":"'||l_ent(entityId).entity||'","Change Log":"'||l_ui_comm_link||'"}', publishId);

  Insert Into tdr_publish_log (entity_id, entered_by, publish_date, rid, nkid)
  Values (entityId, publishedBy, sysdate, revision, nkid_i);

  Commit;
End logPublishItem;


PROCEDURE unpublished_entity_tags
IS
BEGIN
    UPDATE administrator_tags t
    SET status = 2
    WHERE exists (
        select 1
        from administrator_revisions r
        where r.nkid = t.ref_nkid
        and r.status = 2
        )
    AND status != 2;
    --COMMIT;
    UPDATE juris_tax_imposition_tags t
    SET status = 2
    WHERE exists (
        select 1
        from jurisdiction_tax_revisions r
        where r.nkid = t.ref_nkid
        and r.status = 2
        )
    AND status != 2;
    --COMMIT;
    UPDATE juris_tax_app_tags t
    SET status = 2
    WHERE exists (
        select 1
        from juris_tax_app_revisions r
        where r.nkid = t.ref_nkid
        and r.status = 2
        )
    AND status != 2;
    --COMMIT;
    UPDATE jurisdiction_tags t
    SET status = 2
    WHERE exists (
        select 1
        from jurisdiction_revisions r
        where r.nkid = t.ref_nkid
        and r.status = 2
        )
    AND status != 2;
    --COMMIT;
    UPDATE commodity_tags t
    SET status = 2
    WHERE exists (
        select 1
        from commodity_revisions r
        where r.nkid = t.ref_nkid
        and r.status = 2
        )
    AND status != 2;
    --COMMIT;
    /*UPDATE commodity_group_tags t
    SET status = 2
    WHERE exists (
        select 1
        from commodity_group_revisions r
        where r.nkid = t.ref_nkid
        and r.status = 2
        )
    AND status != 2;
    COMMIT;*/
    UPDATE ref_group_tags t
    SET status = 2
    WHERE exists (
        select 1
        from ref_group_revisions r
        where r.nkid = t.ref_nkid
        and r.status = 2
        )
    AND status != 2;

     -- Changes for CRAPP-2871
    UPDATE juris_type_tags t
    SET status = 2
    WHERE exists (
        select 1
        from jurisdiction_type_revisions r
        where r.nkid = t.ref_nkid
        and r.status = 2
        )
    AND status != 2;

    COMMIT;
EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
END unpublished_entity_tags;


FUNCTION ADMINISTRATORS (
    published_by_i IN NUMBER,
    publishId in number default crapp_admin.pk_action_log_process_id.nextval
    ) RETURN NUMBER
   IS
   l_retval NUMBER :=0;
   ln_status NUMBER := 0;
   CURSOR rids IS
       SELECT r.id, r.nkid
       FROM administrator_revisions r
       WHERE r.status = 1
       and r.summ_ass_status = 5
        and 0 = (select count(*) from
                admin_chg_logs jr where jr.status=0 and jr.rid = r.id);
    l_rid number;
    l_nkid number;
BEGIN
 OPEN rids;
  LOOP
    FETCH rids INTO l_rid, l_nkid;
    EXIT WHEN rids%NOTFOUND;
    l_retval := l_retval+administrator_revision(l_rid, l_nkid, published_by_i, publishId);
  END LOOP;
  CLOSE rids;
  ln_status := 1;
  COMMIT;
  RETURN ln_status;
EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
			RETURN ln_status;
END administrators;


FUNCTION administrator_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER,
publishId in number) RETURN NUMBER
IS
BEGIN
    UPDATE administrator_revisions r
    SET status = 2
    WHERE status = 1
    and id = rid_i
    and r.summ_ass_status = 5;

    IF (SQL%ROWCOUNT = 0) THEN
        logPublishItem(entityId=>1, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);
        --ROLLBACK;
        RETURN 0;
    ELSE
        UPDATE admin_chg_logs
        SET status = 2
        WHERE status = 1
        AND rid = rid_i;

        UPDATE administrator_tags
        SET status = 2
        WHERE ref_nkid = (
            select distinct nkid
            from administrator_revisions
            where id = rid_i
            );

        --logPublishItem(entityId=>1, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);

        --COMMIT;
        RETURN 1;
    END IF;
END administrator_revision;


FUNCTION commodities (
    published_by_i IN NUMBER,
    publishId in number default crapp_admin.pk_action_log_process_id.nextval
    ) RETURN NUMBER
   IS
   l_retval NUMBER :=0;
   ln_status NUMBER := 0;
   CURSOR rids IS
       SELECT r.id, r.nkid
       FROM commodity_revisions r
       WHERE r.status = 1
       and r.summ_ass_status = 5
        and 0 = (select count(*) from
                comm_chg_logs jr where jr.status=0 and jr.rid = r.id);
    l_rid number;
    l_nkid number;
BEGIN
 OPEN rids;
  LOOP
    FETCH rids INTO l_rid, l_nkid;
    EXIT WHEN rids%NOTFOUND;

    l_retval := l_retval+commodity_revision(l_rid, l_nkid, published_by_i, publishId);
  END LOOP;
  CLOSE rids;
  ln_status := 1;
  COMMIT;
  RETURN ln_status;
EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
			RETURN ln_status;
END commodities;

FUNCTION commodity_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number) RETURN NUMBER
IS
  c_id  number;
  c_rid number;
  c_err number:=0;
BEGIN

   /** C Publish Tree check **/
   Select id into c_id from commodities
   Where rid = rid_i;
   content_repo.getcommoditypubcheck(pcommodityid=> c_id, oerr=> c_err, publishId=>publishId);

   IF c_err=0 Then
    UPDATE commodity_revisions r
     SET status = 2
     WHERE status = 1
     and id = rid_i
     and r.summ_ass_status = 5;
     IF (SQL%ROWCOUNT = 0) THEN
         logPublishItem(entityId=>5, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);
         --ROLLBACK;
         RETURN 0;
     ELSE
        UPDATE comm_chg_logs
        SET status = 2
        where status = 1
        and rid = rid_i;
        UPDATE commodity_tags
        SET status = 2
        WHERE ref_nkid = (
            select distinct nkid
            from commodity_revisions
            where id = rid_i
            );

        --logPublishItem(entityId=>5, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);

        --COMMIT;
        RETURN 1;
     END IF;

   ELSE
        RETURN 0;
   END IF;

END commodity_revision;

FUNCTION reference_groups (
    published_by_i IN NUMBER,
    publishId in number default crapp_admin.pk_action_log_process_id.nextval
    ) RETURN NUMBER
   IS
   l_retval NUMBER :=0;
   ln_status NUMBER := 0;
   CURSOR rids IS
       SELECT r.id, r.nkid
       FROM ref_group_revisions r
       WHERE r.status = 1
       and r.summ_ass_status = 5
-- lookup test
       and 0 = (select count(*) from
                ref_grp_chg_logs rf where rf.status=0 and rf.rid = r.id);
    l_rid number;
    l_nkid number;
BEGIN
 OPEN rids;
  LOOP
    FETCH rids INTO l_rid, l_nkid;
    EXIT WHEN rids%NOTFOUND;

    l_retval := l_retval+reference_group_revision(l_rid, l_nkid, published_by_i, publishId);
  END LOOP;
  CLOSE rids;
  ln_status := 1;
  COMMIT;
  RETURN ln_status;
EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
			RETURN ln_status;
END reference_groups;


FUNCTION reference_group_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER,
publishId in number) RETURN NUMBER
IS
BEGIN
    UPDATE ref_group_revisions r
    SET status = 2
    WHERE status = 1
    and id = rid_i
    and r.summ_ass_status = 5;
    IF (SQL%ROWCOUNT = 0) THEN
        logPublishItem(entityId=>9, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);
        --ROLLBACK;
        RETURN 0;
    ELSE
        UPDATE ref_grp_chg_logs
        SET status = 2
        where status = 1
        and rid = rid_i;
        UPDATE ref_group_tags
        SET status = 2
        WHERE ref_nkid = (
            select distinct nkid
            from ref_group_revisions
            where id = rid_i
            );

        --logPublishItem(entityId=>9, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);

        --COMMIT;
        RETURN 1;
    END IF;
END reference_group_revision;

/*
FUNCTION commodity_groups (
    published_by_i IN NUMBER
    ) RETURN NUMBER
   IS
   l_retval NUMBER :=0;
   CURSOR rids IS
       SELECT r.id
       FROM commodity_group_revisions r
       WHERE r.status = 1
       and r.summ_ass_status = 5
-- lookup test
       and 0 = (select count(*) from
                comm_grp_chg_logs cr where cr.status=0 and cr.rid = r.id);
    l_rid number;
BEGIN
 OPEN rids;
  LOOP
    FETCH rids INTO l_rid;
    EXIT WHEN rids%NOTFOUND;

    l_retval := l_retval+commodity_group_revision(l_rid,published_by_i);
  END LOOP;
  CLOSE rids;
  COMMIT;
  RETURN l_retval;
END commodity_groups;
*/

/*
FUNCTION commodity_group_revision(rid_i NUMBER, published_by_i IN NUMBER) RETURN NUMBER
IS
BEGIN
    UPDATE commodity_group_revisions r
    SET status = 2
    WHERE status = 1
    and id = rid_i
    and r.summ_ass_status = 5;
    IF (SQL%ROWCOUNT = 0) THEN
        ROLLBACK;
        RETURN 0;
    ELSE

        UPDATE comm_grp_chg_logs
        SET status = 2
        where status = 1
        and rid = rid_i;
        UPDATE commodity_group_tags
        SET status = 2
        WHERE ref_nkid = (
            select distinct nkid
            from commodity_group_revisions
            where id = rid_i
            );
        COMMIT;
        RETURN 1;
    END IF;
END commodity_group_revision;
*/


FUNCTION jurisdictions (
    published_by_i IN NUMBER,
    publishId in number default crapp_admin.pk_action_log_process_id.nextval
    ) RETURN NUMBER
   IS
   l_retval NUMBER :=0;
   ln_status NUMBER := 0;
   CURSOR rids IS
       SELECT r.id, r.nkid
       FROM jurisdiction_revisions r
       WHERE r.status = 1
       and r.summ_ass_status = 5
-- lookup test
       and 0 = (select count(*) from
                juris_chg_logs jr where jr.status=0 and jr.rid = r.id);
    l_rid number;
    l_nkid number;
BEGIN
 OPEN rids;
  LOOP
    FETCH rids INTO l_rid, l_nkid;
    EXIT WHEN rids%NOTFOUND;

    l_retval := l_retval+jurisdiction_revision(l_rid, l_nkid, published_by_i, publishId);
  END LOOP;
  CLOSE rids;
  ln_status := 1;
  COMMIT;
  RETURN ln_status;
EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
			RETURN ln_status;
END jurisdictions;

FUNCTION jurisdiction_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number) RETURN NUMBER
IS
BEGIN
    UPDATE jurisdiction_revisions r
    SET status = 2
    WHERE status = 1
    and id = rid_i
    and r.summ_ass_status = 5;

    IF (SQL%ROWCOUNT = 0) THEN
        logPublishItem(entityId=>2, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);
        --ROLLBACK;
        RETURN 0;
    ELSE
        UPDATE juris_chg_logs
        SET status = 2
        WHERE status = 1
        and rid = rid_i;
        UPDATE jurisdiction_tags
        SET status = 2
        WHERE ref_nkid = (
            select distinct nkid
            from jurisdiction_revisions
            where id = rid_i
            );

        --logPublishItem(entityId=>2, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);

        --COMMIT;
        RETURN 1;
    END IF;
END jurisdiction_revision;

FUNCTION check_taxes_dependency(tax_rid_i number, publishId in number)
-- Changes for CRAPP-2871
FUNCTION jurisdiction_types
   ( published_by_i IN NUMBER, publishId in number default 0) RETURN NUMBER
   IS
   l_retval NUMBER :=0;
   CURSOR rids IS
       SELECT r.id, r.nkid
       FROM jurisdiction_type_revisions r
       WHERE r.status = 1
       and r.summ_ass_status = 5
       and 0 = (select count(*) from
                juris_type_chg_logs tr where tr.status=0 and tr.rid = r.id);

    l_rid number;
    l_nkid number;
BEGIN
 OPEN rids;
  LOOP
    FETCH rids INTO l_rid, l_nkid;
    EXIT WHEN rids%NOTFOUND;
        l_retval := l_retval+jurisdiction_type_revision(l_rid, l_nkid, published_by_i, publishId );
  END LOOP;
  CLOSE rids;
  COMMIT;
  RETURN l_retval;
END jurisdiction_types;

-- Changes for CRAPP-2871
FUNCTION jurisdiction_type_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number default 0) RETURN NUMBER
IS
BEGIN

    UPDATE jurisdiction_type_revisions r
    SET status = 2
    WHERE status = 1
    and id = rid_i
    and r.summ_ass_status = 5;
    IF (SQL%ROWCOUNT = 0) THEN
        logPublishItem(entityId=>3, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);
        ROLLBACK;
        RETURN 0;
    ELSE
        UPDATE juris_type_chg_logs
        SET status = 2
        where status = 1
        and rid = rid_i;
    END IF;
    UPDATE juris_type_tags
    SET status = 2
    WHERE ref_nkid = (
        select distinct nkid
        from jurisdiction_type_revisions
        where id = rid_i
        )
    and status != 2; --9/26 comment: when was this added?

    COMMIT;
    RETURN 1;

END jurisdiction_type_revision;


FUNCTION check_taxes_dependency(tax_rid_i number, publishId in number)
return number
is
    l_tax_nkid number;
    l_juris_check number;
    l_min_juris_rid number;
    l_juris_nkid number;
    l_juris_rid number;
    l_juris_tax_nkid number;
    l_ui_juris_link varchar2(2000);
    l_ui_taxes_link varchar2(2000);
    l_entity varchar2(100);
begin

    select nkid into l_juris_tax_nkid from jurisdiction_tax_revisions where id = tax_rid_i;

    select distinct jurisdiction_nkid into l_juris_nkid from juris_tax_impositions where nkid = l_juris_tax_nkid;

    select j.official_name||' : '||jti.reference_code into l_entity from jurisdictions j join juris_tax_impositions jti on j.nkid = jti.jurisdiction_nkid
      where jti.nkid = l_juris_tax_nkid
        and j.nkid = l_juris_nkid
        and j.next_rid is null
        and jti.next_rid is null;

    begin
        select id, nkid into l_juris_nkid, l_juris_rid from jurisdiction_revisions where nkid = l_juris_nkid and status = 2 and rownum <=1;
        return 1;
    exception
    when no_data_found
    then
        select id, nkid into l_juris_rid, l_juris_nkid from jurisdiction_revisions where nkid = l_juris_nkid;

        select replace(replace(url, 'nkid', l_juris_nkid), 'rid',l_juris_rid)  into l_ui_juris_link from action_log_url where entity = 'TAXES_DEP' and action = 'JURISDICTION_URL';
        select replace(replace(url, 'nkid', l_juris_tax_nkid), 'rid',tax_rid_i)  into l_ui_taxes_link from action_log_url where entity = 'TAXES_DEP' and action = 'TAXES_URL';

        insert into crapp_admin.action_log ( action_start, action_end, status, referrer, entered_by, parameters)
        values (sysdate, sysdate, -1, '/admin/publication', -1703,
            '{"process":"publication","id":"'||publishId||'","entity":"'||l_entity||'","entity_change_log":"'||l_ui_taxes_link||'","blocked_entity":"jurisdiction", "blocked_change_log":"'||l_ui_juris_link||'"}');

        dbms_output.put_line('returning 0 for taxes dependency check');
        return 0;
    end;
end check_taxes_dependency;


FUNCTION TAXES
   ( published_by_i IN NUMBER, publishId in number default crapp_admin.pk_action_log_process_id.nextval) RETURN NUMBER
   IS
   l_retval NUMBER :=0;
   ln_status NUMBER := 0;
   CURSOR rids IS
       SELECT r.id, r.nkid
       FROM jurisdiction_tax_revisions r
       WHERE r.status = 1
       and r.summ_ass_status = 5
       and 0 = (select count(*) from
                juris_tax_chg_logs tr where tr.status=0 and tr.rid = r.id);

    l_rid number;
    l_nkid number;
BEGIN
 OPEN rids;
  LOOP
    FETCH rids INTO l_rid, l_nkid;
    EXIT WHEN rids%NOTFOUND;

    if 1 = check_taxes_dependency(l_rid, publishId)
    THEN
        l_retval := l_retval+tax_revision(l_rid, l_nkid, published_by_i, publishId );
    end if;

  END LOOP;
  CLOSE rids;
  ln_status := 1;
  COMMIT;
  RETURN ln_status;
EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
			RETURN ln_status;
END taxes; -- Procedure

FUNCTION tax_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number) RETURN NUMBER
IS
BEGIN
    dbms_output.put_line('Getting tax revisions');
    UPDATE jurisdiction_tax_revisions r
    SET status = 2
    WHERE status = 1
    and id = rid_i
    and r.summ_ass_status = 5;
    IF (SQL%ROWCOUNT = 0) THEN
        logPublishItem(entityId=>3, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);
        --ROLLBACK;
        RETURN 0;
    ELSE
        UPDATE juris_tax_chg_logs
        SET status = 2
        where status = 1
        and rid = rid_i;
    END IF;
    UPDATE juris_tax_imposition_tags
    SET status = 2
    WHERE ref_nkid = (
        select distinct nkid
        from jurisdiction_tax_revisions
        where id = rid_i
        )
    and status != 2; --9/26 comment: when was this added?

    --logPublishItem(entityId=>3, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);

    --COMMIT;
    RETURN 1;

/*    UPDATE jurisdiction_tax_revisions r
    SET status = 2
    WHERE status != 2
    and id = rid_i
    and r.summ_ass_status = 5;
    IF (SQL%ROWCOUNT = 0) THEN
        ROLLBACK;
        RETURN 0;
    ELSE
        UPDATE juris_tax_chg_logs
        SET status = 2
        where status != 2
        and rid = rid_i;
    END IF;
    UPDATE juris_tax_imposition_tags
    SET status = 2
    WHERE ref_nkid = (
        select distinct nkid
        from jurisdiction_tax_revisions
        where id = rid_i
        )
    and status != 2;
    COMMIT;
    RETURN 1;
*/
END tax_revision;


FUNCTION check_taxability_dependency ( jta_rid_i number, publishId in number, published_by_i number default -1703)
return number
is
    l_juris_check number := 1;
    l_jta_nkid number := 1;
    l_juris_taxes_check number := 1;
    l_appl_type_check varchar2(30);
    l_return number := 1;
    l_reference_check number;
    l_ref_auth_check number;
    l_juris_nkid number;
    l_juris_rid number;
    l_taxes_nkid number;
    l_taxes_rid number;
    l_refgrp_nkid number;
    l_refgrp_rid number;
    l_blocked_by varchar2(2000);
    l_ui_taxability_url varchar2(2000);
    l_ui_juris_url varchar2(2000);
    l_ui_taxes_url varchar2(2000);
    l_ui_refgrp_url varchar2(2000);
    l_status number;
    l_exit number := 1;
    l_ui_link  clob;
    l_taxability_details varchar2(1000);
    l_rule_order_check number;
    l_ui_comm_url varchar2(2000);

    /* Commoditites: publish information in commodity tree */
    c_id number;
    c_err number;
begin

    Select nkid Into l_jta_nkid From juris_tax_app_revisions where id = jta_rid_i;

    Select replace(replace(url, 'nkid', l_jta_nkid), 'rid',jta_rid_i) Into l_ui_taxability_url
    From action_log_url where entity = 'TAXABILITY_DEP' and action = 'TAXABILITY_URL';

    select nkid, id, status into l_juris_nkid, l_juris_rid, l_status from jurisdiction_revisions where (nkid, id) in (
    select nkid, min(id) rid from jurisdiction_revisions
     where nkid in ( select distinct jurisdiction_nkid from juris_tax_applicabilities where nkid = l_jta_nkid)
       group by nkid
     );

     select j.official_name||', '||aty.name||', '||jta.start_date||', '||jta.is_local||', '||c.name into l_taxability_details
     from jurisdictions j join juris_tax_applicabilities jta on j.nkid = jta.jurisdiction_nkid
      left join commodities c on c.nkid = jta.commodity_nkid
      join applicability_types aty on aty.id = jta.applicability_type_id
       where j.next_rid is null
         and jta.next_rid is null
         and c.next_rid is null
         and jta.nkid = l_jta_nkid;

    select count(1) into l_rule_order_check from juris_tax_app_revisions jtr join juris_tax_applicabilities jta on jta.nkid = jtr.nkid
      left join tax_applicability_taxes tat on tat.juris_tax_applicability_nkid = jta.nkid
      where jtr.id =  jta_rid_i
        and nvl(tat.ref_rule_order, jta.ref_rule_order) is null;

    l_ui_link := '{"process":"publication","entity":"taxability","details":"'||l_taxability_details||'","rule order check":';

    if l_rule_order_check >= 1
    then
        l_ui_link := l_ui_link||'"missing rule order"';
        l_exit := 0;
    else
        l_ui_link := l_ui_link||'"Success"';
    end if;

    l_ui_link := l_ui_link||',"blocked entity change log":""';

    if l_status != 2
    then
        select replace(replace(url, 'nkid', l_juris_nkid), 'rid',l_juris_rid)  into l_ui_juris_url from action_log_url where entity = 'TAXABILITY_DEP' and action = 'JURISDICTION_URL';

        l_ui_link := l_ui_link||',"Jurisdiction":"'||l_ui_juris_url||'"';
        l_exit := 0;
    end if;

    for i in ( select nkid, id rid, status from ref_group_revisions where (nkid, id) in (
                select rgr.nkid, min(rgr.id) rid from juris_tax_app_revisions jtr join tran_tax_qualifiers ttq on jtr.nkid = ttq.juris_tax_applicability_nkid
                join ref_group_revisions rgr on rgr.nkid = ttq.reference_group_nkid
                where jtr.id = jta_rid_i
                group by rgr.nkid
                )
    )
    loop
        if i.status != 2
        then
            select replace(replace(url, 'nkid', i.nkid), 'rid',i.rid)  into l_ui_refgrp_url from action_log_url where entity = 'TAXABILITY_DEP' and action = 'REFERENCE_GROUP_URL';

            l_ui_link := l_ui_link||',"reference groups":"'||l_ui_refgrp_url||'"';
            l_exit := 0;
        end if;
    end loop;

    for i in ( select nkid, id rid, status from jurisdiction_revisions where (nkid, id) in (
                select jr.nkid, min(jr.id) rid from juris_tax_app_revisions jtr join tran_tax_qualifiers ttq on jtr.nkid = ttq.juris_tax_applicability_nkid
                join jurisdiction_revisions jr on jr.nkid = ttq.jurisdiction_nkid
                where jtr.id = jta_rid_i
                group by jr.nkid
                )
    )
    loop
        if i.status != 2
        then
            select replace(replace(url, 'nkid', i.nkid), 'rid',i.rid)  into l_ui_juris_url from action_log_url where entity = 'TAXABILITY_DEP' and action = 'JURISDICTION_URL';
            l_ui_link := l_ui_link||',"jurisdiction":"'||l_ui_juris_url||'"';
            l_exit := 0;
        end if;
    end loop;

    for i in ( select nkid, id rid, status from jurisdiction_tax_revisions where (nkid, id) in (
                    select tr.nkid, min(tr.id) rid from juris_tax_app_revisions jtr join tax_applicability_taxes tat on jtr.nkid = tat.juris_tax_applicability_nkid
                    join jurisdiction_tax_revisions tr on tr.nkid = tat.juris_tax_imposition_nkid
                    where jtr.id = jta_rid_i
                    group by tr.nkid
                    )
    )
    loop
        if i.status != 2
        then
            select replace(replace(url, 'nkid', i.nkid), 'rid',i.rid)  into l_ui_taxes_url from action_log_url where entity = 'TAXABILITY_DEP' and action = 'TAXES_URL';
            l_ui_link := l_ui_link||',"taxes":"'||l_ui_taxes_url||'"';
            l_exit := 0;
        end if;
    end loop;
    dbms_output.put_line('l_exit value is level 1 '||l_exit);
    /* Commodities */
    -- at the top of this one there is already a select of nkid from juris_tax_applicabilities

    declare
        c_id number := 0;
        vcnt number := 0;
        l_comm_nkid number;
        l_comm_rid number;
        l_comm_status number;
    begin

        select distinct commodity_id into c_id from juris_tax_applicabilities where nkid = l_jta_nkid;

        if c_id is not null
        then
            select nkid, rid, status into l_comm_nkid, l_comm_rid, l_comm_status from commodities where id = c_id;
                if l_comm_status != 2
                then
                    select replace(replace(url, 'nkid', l_comm_nkid), 'rid',l_comm_rid)  into l_ui_comm_url from action_log_url where entity = 'TAXABILITY_DEP' and action = 'COMMODITY_URL';
                    l_ui_link := l_ui_link||',"commodity":"'||l_ui_comm_url||'"';
                    l_exit := 0;
                end if;

        end if;
    end;
    dbms_output.put_line('l_exit value is level 2 '||l_exit);
    l_ui_link := l_ui_link||'}';

    dbms_output.put_line('l_ui_link value is '||l_ui_link);

    /*-- Default Commoditites - no action.
    if c_id is not null
    then
        content_repo.getcommoditypubcheck(pcommodityid=> c_id, oerr=> c_err);
        if c_err = 1 then
          l_exit := 0;
        end if;
    end if;
    */

    dbms_output.put_line('l_exit value is level 3 '||l_exit);
     if l_exit = 0
    then
        dbms_output.put_line('returning 0 for taxability dependency check');

        insert into crapp_admin.action_log ( action_start, action_end, status, referrer, entered_by, parameters, process_id)
                values (sysdate, sysdate, -1, '/admin/publication', published_by_i, l_ui_link, publishId);
        --commit;
    end if;

    dbms_output.put_line('l_exit value is level 4 '||l_exit);

    return l_exit;
EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
			RETURN l_exit;
end check_taxability_dependency;


FUNCTION taxabilities
   ( published_by_i IN NUMBER, publishId in number default crapp_admin.pk_action_log_process_id.nextval) RETURN NUMBER
   IS
   l_retval NUMBER :=0;
   ln_status NUMBER := 0;
   CURSOR rids IS
       SELECT r.id, r.nkid
       FROM juris_tax_app_revisions r
       WHERE r.status = 1
       and r.summ_ass_status = 5
       and 0 = (select count(*) from
                juris_tax_app_chg_logs jr where jr.status=0 and jr.rid = r.id);
    l_rid number;
    l_nkid number;
BEGIN
 OPEN rids;
  LOOP
    FETCH rids INTO l_rid, l_nkid;
    EXIT WHEN rids%NOTFOUND;

    if 1 = check_taxability_dependency(l_rid, publishId, published_by_i)
    then
        l_retval := l_retval+taxability_revision(l_rid, l_nkid, published_by_i, publishId );
    end if;

  END LOOP;
  CLOSE rids;
	ln_status := 1;
	COMMIT;
  RETURN ln_status;
EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
			RETURN ln_status;
END taxabilities; -- Procedure

FUNCTION taxability_revision(rid_i in NUMBER, nkid_i in number, published_by_i IN NUMBER, publishId in number) RETURN NUMBER
IS
BEGIN
DBMS_OUTPUT.Put_Line( 'RID:'||rid_i);

    UPDATE juris_tax_app_revisions r
    SET status = 2
    WHERE status = 1
    and summ_ass_status = 5
    and id = rid_i;
    IF (SQL%ROWCOUNT = 0) THEN
        logPublishItem(entityId=>4, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);
        --ROLLBACK;
        RETURN 0;
    ELSE
        UPDATE juris_tax_app_chg_logs r
        SET status = 2
        WHERE status = 1
        and rid = rid_i;
        UPDATE juris_tax_app_tags
        SET status = 2
        WHERE ref_nkid = (
            select distinct nkid
            from juris_tax_app_revisions
            where id = rid_i
            );

        --logPublishItem(entityId=>4, revision=>rid_i, nkid_i=>nkid_i, publishedBy=>published_by_i, publishId=>publishId);

        --COMMIT;
        RETURN 1;
    END IF;

END taxability_revision;


PROCEDURE publish_lookups
IS
BEGIN
    --publish Additional_Attributes
    UPDATE additional_attributes aa
    SET status = 2
    WHERE status != 2
    and attribute_category_id in (
        select id
        from attribute_categories ac
        where ac.name = 'Tax Administration'
        )
    and exists (
        select 1
        from administrator_Attributes ada
        where attribute_id = aa.id
        and ada.status = 2
        );

    UPDATE additional_attributes aa
    SET status = 2
    WHERE status != 2
    and attribute_category_id in (
        select id
        from attribute_categories ac
        where ac.name= 'Tax Jurisdiction'
        )
    and exists (
        select 1
        from jurisdiction_Attributes ada
        where attribute_id = aa.id
        and ada.status = 2
        );

    UPDATE additional_attributes aa
    SET status = 2
    WHERE status != 2
    and attribute_category_id in (
        select id
        from attribute_categories ac
        where ac.name= 'Tax Definition'
        )
    and exists (
        select 1
        from tax_Attributes ta
        where attribute_id = aa.id
        and ta.status = 2
        );

    UPDATE additional_attributes aa
    SET status = 2
    WHERE status != 2
    and attribute_category_id in (
        select id
        from attribute_categories ac
        where ac.name= 'Tax Applicability'
        )
    and exists (
        select 1
        from juris_tax_app_Attributes ta
        where attribute_id = aa.id
        and ta.status = 2
        );

    --update administrator_types
    update administrator_types aty
    set status = 2
    where status != 2
    and exists (
        select 1
        from administrators a
        where a.administrator_type_id = aty.id
        and a.status = 2
        );

    -- Currencies
    update currencies c
    set status = 2
    where status != 2
    and exists (
        select 1
        from jurisdictions j
        where j.currency_id = c.id
        and j.status = 2
        );

    update currencies c
    set status = 2
    where status != 2
    and exists (
        select 1
        from tax_definitions j
        where j.currency_id = c.id
        and j.status = 2
        );

    -- geo_area_categories
    update geo_area_categories c
    set c.status = 2
    where c.status != 2
    and exists (
        select 1
        from jurisdictions j
        where j.geo_area_category_id = c.id
        and j.status = 2
        );

    -- tax_descriptions
    update tax_descriptions td
    set status = 2
    where status != 2
    and exists (
        select 1
        from juris_tax_impositions jti
        where jti.tax_description_id = td.id
        and jti.status = 2
        );

    -- specific_applicability_types
    update specific_applicability_types sat
    set status = 2
    where status != 2
    and exists (
        select 1
        from tax_descriptions td
        where td.spec_applicability_type_id = sat.id
        and td.status = 2
        );

    -- transaction_types
    update transaction_types sat
    set status = 2
    where status != 2
    and exists (
        select 1
        from tax_descriptions td
        where td.transaction_type_id = sat.id
        and td.status = 2
        );

    -- taxation_types
    update taxation_types sat
    set status = 2
    where status != 2
    and exists (
        select 1
        from tax_descriptions td
        where td.taxation_type_id = sat.id
        and td.status = 2
        );

    -- revenue_purposes
    update revenue_purposes rp
    set status = 2
    where status != 2
    and exists (
        select 1
        from juris_tax_impositions jti
        where rp.id = jti.revenue_purpose_id
        and jti.status = 2
        );

    -- tax_calculation_structures
    update tax_calculation_structures tcs
    set status = 2
    where status != 2
    and exists (
        select 1
        from tax_outlines td
        where tcs.id = td.calculation_structure_id
        and td.status = 2
        );

    -- applicability_types
    update applicability_types aty
    set status = 2
    where status != 2
    and exists (
        select 1
        from juris_tax_applicabilities jta
        where aty.id = jta.applicability_type_id
        and jta.status = 2
        );

    -- calculation_methods
    update calculation_methods cm
    set status = 2
    where status != 2
    and exists (
        select 1
        from juris_tax_applicabilities td
        where cm.id = td.calculation_method_id
        and td.status = 2
        );

    -- product_trees
    update product_trees pt
    set status = 2
    where status != 2
    and exists (
        select 1
        from commodities c
        where pt.id = c.product_tree_id
        and c.status = 2
        );
	COMMIT;
EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
    end publish_lookups;
END publish;
/