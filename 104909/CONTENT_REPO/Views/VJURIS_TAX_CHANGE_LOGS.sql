CREATE OR REPLACE FORCE VIEW content_repo.vjuris_tax_change_logs ("ID",nkid,rid,primary_key,status,status_modified_date,entered_date,entered_by,entered_by_id,table_name,change_reason,change_reason_id,assignment_type,assignment_type_id,juris_tax,change_summary,document_count) AS
SELECT jtcl.id,
            jtr.nkid,
            jtr.id,
            jtcl.primary_key,
            jtr.status,
            jtcl.status_modified_date,
            jtcl.entered_date,
            u.username,
            jtcl.entered_by,
            --jtcl.table_name,
            etm.ui_alias||': '||q.qr table_name,
            cr.reason,
            jtcl.reason_id,
            LISTAGG (at.name, ', ' || '')
               WITHIN GROUP (ORDER BY at.NAME)
               OVER (PARTITION BY jtcl.id),
            jtcv.assignment_type_id,
            jti.reference_code,
            jtcl.summary,
            COUNT (DISTINCT ci.attachment_id)
       FROM juris_tax_chg_logs jtcl
            join tax_qr q on (q.table_name = jtcl.table_name and q.ref_id = jtcl.primary_key)
            JOIN entity_table_map etm
               ON (etm.table_name = jtcl.table_name)
            JOIN jurisdiction_tax_revisions jtr
               ON (jtr.id = jtcl.rid)
            JOIN juris_tax_impositions jti
               ON (jti.id = jtcl.entity_id)
            LEFT OUTER JOIN juris_tax_chg_cits jtcc
               ON (jtcc.juris_tax_chg_log_id = jtcl.id)
            LEFT OUTER JOIN citations ci
               ON (jtcc.citation_id = ci.id)
            LEFT OUTER JOIN change_reasons cr
               ON (cr.id = jtcl.reason_id)
            LEFT OUTER JOIN juris_tax_chg_vlds jtcv
               ON (jtcv.juris_tax_chg_log_id = jtcl.id)
            LEFT OUTER JOIN assignment_types at
               ON (at.id = jtcv.assignment_type_id)
            JOIN users u
               ON (u.id = jtcl.entered_by)
      WHERE logical_entity = 'Tax'
   GROUP BY jtcl.id,
            jtr.nkid,
            jtr.id,
            jtcl.primary_key,
            jtr.status,
            jtcl.status_modified_date,
            jtcl.entered_date,
            etm.ui_alias||': '||q.qr,
            u.username,
            jtcl.entered_by,
            cr.reason,
            jtcl.reason_id,
            at.name,
            jtcv.assignment_type_id,
            jti.reference_code,
            jtcl.summary
 
 ;