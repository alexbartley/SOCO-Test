CREATE OR REPLACE FORCE VIEW content_repo.vjuris_change_logs ("ID",nkid,rid,primary_key,is_published,status,status_modified_date,entered_date,entered_by,table_name,change_reason,change_reason_id,change_summary,document_count) AS
SELECT clo.id,
            jr.nkid,
            jr.id,
            clo.primary_key,
            CASE WHEN jr.status = 1 THEN 1 ELSE 0 END is_published,
            clo.status,
            clo.status_modified_date,
            clo.entered_date,
            clo.entered_by,
            ETM.UI_ALIAS||': '||q.qr,
            cr.reason,
            cr.id,
            clo.summary,
            COUNT (DISTINCT ci.attachment_id)
       FROM juris_chg_logs clo
            JOIN entity_table_map etm
               ON (etm.table_name = clo.table_name)
            JOIN jurisdiction_revisions jr
               ON (jr.id = clo.rid)
            JOIN juris_qr q on (q.table_name = clo.table_name and q.ref_id = clo.primary_key)
            LEFT OUTER JOIN juris_chg_cits cc
               ON (cc.juris_chg_log_id = clo.id)
            LEFT OUTER JOIN citations ci
               ON (cc.citation_id = ci.id)
            LEFT OUTER JOIN change_reasons cr
               ON (cr.id = clo.reason_id)
      --WHERE logical_entity = 'Jurisdiction'
   GROUP BY clo.id,
            jr.nkid,
            jr.id,
            clo.primary_key,
            CASE WHEN jr.status = 1 THEN 1 ELSE 0 END,
            clo.status,
            clo.status_modified_date,
            clo.entered_date,
            ETM.UI_ALIAS||': '||q.qr,
            clo.entered_by,
            cr.reason,
            cr.id,
            clo.summary
 
 ;