CREATE OR REPLACE FORCE VIEW content_repo.vgeo_area_change_logs ("ID",nkid,rid,primary_key,is_published,status,status_modified_date,entered_date,entered_by,table_name,change_reason,change_reason_id,change_summary,document_count) AS
(SELECT clo.id,
            ar.nkid,
            ar.id,
            clo.primary_key,
            CASE WHEN ar.status = 1 THEN 1 ELSE 0 END is_published,
            clo.status,
            clo.status_modified_date,
            clo.entered_date,
            clo.entered_by,
            etm.ui_alias AS table_name,
            cr.reason,
            cr.id,
            clo.summary,
            COUNT (DISTINCT ci.attachment_id)
       FROM geo_unique_area_chg_logs clo
            JOIN entity_table_map etm
               ON (etm.table_name = clo.table_name)
            JOIN geo_unique_area_revisions ar
               ON (ar.id = clo.rid)
            LEFT OUTER JOIN geo_unique_area_chg_cits cc
               ON (cc.geo_unique_area_chg_log_id = clo.id)
            LEFT OUTER JOIN citations ci
               ON (cc.citation_id = ci.id)
            LEFT OUTER JOIN change_reasons cr
               ON (cr.id = clo.reason_id)
      WHERE logical_entity = 'Unique Areas'
   GROUP BY clo.id,
            ar.nkid,
            ar.id,
            clo.primary_key,
            CASE WHEN ar.status = 1 THEN 1 ELSE 0 END,
            clo.status,
            clo.status_modified_date,
            clo.entered_date,
            etm.ui_alias,
            clo.entered_by,
            cr.reason,
            cr.id,
            clo.summary
 )
 
 ;