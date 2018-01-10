CREATE OR REPLACE FORCE VIEW content_repo.ref_grp_change_summary_v ("ID",rid,nkid,status,published,modified,entered_by,table_name,reason,"SUMMARY",documents,veriftype) AS
SELECT CGCL.ID,
            CGR.ID,
            CGR.NKID,
            CGCL.STATUS,
            (CASE WHEN CGCL.STATUS = '2' THEN TO_CHAR (CGR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                  ELSE RS.NAME
             END) published,
            TO_CHAR (CGCL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss') modified,
            U.FIRSTNAME || ' ' || U.LASTNAME entered_by,
            ETM.UI_ALIAS||': '||q.qr TABLE_NAME,
            CR.REASON,
            CGCL.SUMMARY
            --, wm_concat(distinct A.ID) documents
            --, wm_concat(distinct fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id)) VerifType
            , LISTAGG (A.ID, ',') WITHIN GROUP (ORDER BY A.ID) documents
            , LISTAGG (fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id),',') WITHIN GROUP (ORDER BY a.id) VerifType
       FROM ref_group_REVISIONS CGR
            JOIN ref_grp_CHG_LOGS CGCL
               ON CGR.ID = CGCL.RID
            JOIN ref_grp_qr q on (q.table_name = cgcl.table_name and q.ref_id = cgcl.primary_key)
            LEFT JOIN ref_grp_chg_vlds vld on (vld.ref_grp_chg_log_id = cgcl.id)
            JOIN ENTITY_TABLE_MAP ETM
               ON CGCL.TABLE_NAME = ETM.TABLE_NAME
            LEFT OUTER JOIN CHANGE_REASONS CR
               ON CGCL.REASON_ID = CR.ID
            LEFT OUTER JOIN ref_grp_CHG_CITS ACC
               ON CGCL.ID = ACC.ref_grp_CHG_LOG_ID
            LEFT OUTER JOIN CITATIONS C
               ON ACC.CITATION_ID = C.ID
            LEFT OUTER JOIN ATTACHMENTS A
               ON C.ATTACHMENT_ID = A.ID
            JOIN RECORD_STATUSES RS
               ON CGCL.STATUS = RS.ID
            JOIN USERS U
               ON CGCL.ENTERED_BY = U.ID
   GROUP BY CGCL.ID,
            CGR.ID,
            CGR.NKID,
            CGCL.STATUS,
            (CASE WHEN CGCL.STATUS = '2' THEN TO_CHAR (CGR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                  ELSE RS.NAME
             END),
            TO_CHAR (CGCL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss'),
            U.FIRSTNAME || ' ' || U.LASTNAME,
            ETM.UI_ALIAS||': '||q.qr,
            CR.REASON,
            CGCL.SUMMARY;