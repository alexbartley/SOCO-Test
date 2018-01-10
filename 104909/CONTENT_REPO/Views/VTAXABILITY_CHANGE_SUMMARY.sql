CREATE OR REPLACE FORCE VIEW content_repo.vtaxability_change_summary ("ID",rid,nkid,jurisdiction_nkid,jurisdiction_rid,status,published,modified,entered_by,table_name,reason,"SUMMARY",documents,veriftype) AS
SELECT JTCL.ID
           , JTR.ID
           , JTR.NKID
           , J.NKID JURISDICTION_NKID
           , J.RID  JURISDICTION_RID
           , JTCL.STATUS
           , (CASE WHEN JTCL.STATUS = '2' THEN TO_CHAR (JTR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                   ELSE RS.NAME
              END) PUBLISHED
           , TO_CHAR(jtcl.entered_date, 'mm/dd/yyyy hh:mi:ss') MODIFIED
           , u.firstname || ' ' || u.lastname ENTERED_BY

           --, etm.ui_alias||': '||q.qr TABLE_NAME
           , CASE WHEN etm.ui_alias = 'Taxability Details' THEN -- crapp-2617
                       CASE WHEN com.name IS NOT NULL THEN etm.ui_alias||': '||com.name
                            ELSE etm.ui_alias||': All Commodities Apply'
                       END
                 ELSE etm.ui_alias||': '||q.qr
             END TABLE_NAME

           , CR.REASON
           , JTCL.SUMMARY
           , LISTAGG (A.ID, ',') WITHIN GROUP (ORDER BY A.ID) DOCUMENTS
           , LISTAGG (fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id), ',') WITHIN GROUP (ORDER BY A.ID) VerifType

    FROM juris_tax_app_revisions JTR
         JOIN juris_tax_app_chg_logs JTCL
              ON jtr.id = jtcl.rid
         JOIN juris_tax_app_qr q 
              ON (q.table_name = jtcl.table_name AND q.ref_id = jtcl.primary_key)
         LEFT JOIN juris_tax_app_chg_vlds vld 
              ON (vld.juris_tax_app_chg_log_id = jtcl.id)
         LEFT JOIN juris_tax_applicabilities jti
              ON jti.id = jtcl.entity_id
         LEFT JOIN jurisdictions J
              ON j.id = jti.jurisdiction_id
         JOIN entity_table_map ETM
              ON jtcl.table_name = etm.table_name
         LEFT OUTER JOIN change_reasons CR
              ON jtcl.reason_id = cr.id
         LEFT OUTER JOIN juris_tax_app_chg_cits JTCC
              ON jtcl.id = jtcc.juris_tax_app_chg_log_id
         LEFT OUTER JOIN citations C
              ON jtcc.citation_id = c.id
         LEFT OUTER JOIN attachments A
              ON c.attachment_id = a.id
         JOIN record_statuses RS
              ON jtcl.status = rs.id
         JOIN users U 
              ON jtcl.entered_by = u.id
         -- crapp-2617
         LEFT JOIN commodities com 
              ON (com.id = jti.commodity_id)
    GROUP BY 
        JTCL.ID
        ,JTR.ID
        ,JTR.NKID
        ,J.NKID
        ,J.RID
        ,JTCL.STATUS
        ,(CASE WHEN JTCL.STATUS = '2' THEN TO_CHAR (JTR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
               ELSE RS.NAME
          END)
        ,TO_CHAR(jtcl.entered_date, 'mm/dd/yyyy hh:mi:ss')
        ,u.firstname || ' ' || u.lastname
        ,etm.ui_alias||': '||q.qr
        ,CR.REASON
        ,JTCL.SUMMARY
        ,etm.ui_alias   -- crapp-2617
        ,com.NAME;