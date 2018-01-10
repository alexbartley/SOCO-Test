CREATE OR REPLACE FORCE VIEW content_repo.ref_grp_change_logs_v ("ID",nkid,rid,primary_key,is_published,status,status_modified_date,entered_date,entered_by,table_name,change_reason,change_reason_id,change_summary,document_count) AS
SELECT clo.id,
            ar.nkid,
            ar.id,
            clo.primary_key,
            CASE WHEN ar.status = 1 THEN 1 ELSE 0 END is_published,
            clo.status,
            clo.status_modified_date,
            clo.entered_date,
            clo.entered_by,
            ETM.UI_ALIAS||': '||q.qr TABLE_NAME,
            cr.reason,
            cr.id,
            clo.summary,
            COUNT (DISTINCT ci.attachment_id)
       FROM ref_grp_chg_logs clo
            join ref_grp_qr q on (q.table_name = clo.table_name and q.ref_id = clo.primary_key)
            JOIN entity_table_map etm
               ON (etm.table_name = clo.table_name)
            JOIN ref_group_revisions ar
               ON (ar.id = clo.rid)
            LEFT OUTER JOIN ref_grp_chg_cits cc
               ON (cc.ref_grp_chg_log_id = clo.id)
            LEFT OUTER JOIN citations ci
               ON (cc.citation_id = ci.id)
            LEFT OUTER JOIN change_reasons cr
               ON (cr.id = clo.reason_id)
      WHERE logical_entity = 'Reference Group'
   GROUP BY clo.id,
            ar.nkid,
            ar.id,
            clo.primary_key,
            CASE WHEN ar.status = 1 THEN 1 ELSE 0 END,
            clo.status,
            clo.status_modified_date,
            clo.entered_date,
            ETM.UI_ALIAS||': '||q.qr,
            clo.entered_by,
            cr.reason,
            cr.id,
            clo.summary
 
 ;