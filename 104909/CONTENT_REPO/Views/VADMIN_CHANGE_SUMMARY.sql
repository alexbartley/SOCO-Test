CREATE OR REPLACE FORCE VIEW content_repo.vadmin_change_summary ("ID",rid,nkid,status,published,modified,entered_by,table_name,reason,"SUMMARY",documents,veriftype) AS
SELECT ACL.ID,
            AR.ID,
            AR.NKID,
            ACL.STATUS,
            (CASE
                WHEN ACL.STATUS = '2'
                THEN
                   TO_CHAR (AR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                ELSE
                   RS.NAME
             END) published,
            TO_CHAR (ACL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss') modified,
            U.FIRSTNAME || ' ' || U.LASTNAME entered_by,
            ETM.UI_ALIAS||': '||q.qr TABLE_NAME,
            CR.REASON,
            ACL.SUMMARY
            --, wm_concat(distinct A.ID) documents
            , LISTAGG (A.ID, ',') WITHIN GROUP (ORDER BY A.ID) documents
            -- either this or join to the assignment_type table
            --, listagg (getAssignmentTypeStr(vld.assignment_type_id),',') within group (order by a.id) VerifType
            -- regular concat using wm_concat(distinct getAssignmentTypeStr(vld.assignment_type_id)) VerifType
            --, wm_concat(distinct fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id)) VerifType
            , LISTAGG (fnAssignmentAbbr(vld.assignment_type_id)||' '|| get_username(vld.assigned_user_id),',') WITHIN GROUP (ORDER BY a.id) VerifType
       FROM ADMINISTRATOR_REVISIONS AR
            JOIN ADMIN_CHG_LOGS ACL
               ON AR.ID = ACL.RID
            left join admin_chg_vlds vld on (vld.admin_chg_log_id = acl.id)
            join admin_qr q on (q.table_name = acl.table_name and q.ref_id = acl.primary_key)
            JOIN ENTITY_TABLE_MAP ETM
               ON ACL.TABLE_NAME = ETM.TABLE_NAME
            LEFT OUTER JOIN CHANGE_REASONS CR
               ON ACL.REASON_ID = CR.ID
            LEFT OUTER JOIN ADMIN_CHG_CITS ACC
               ON ACL.ID = ACC.ADMIN_CHG_LOG_ID
            LEFT OUTER JOIN CITATIONS C
               ON ACC.CITATION_ID = C.ID
            LEFT OUTER JOIN ATTACHMENTS A
               ON C.ATTACHMENT_ID = A.ID
            JOIN RECORD_STATUSES RS
               ON ACL.STATUS = RS.ID
            JOIN USERS U
               ON ACL.ENTERED_BY = U.ID
   GROUP BY ACL.ID,
            AR.ID,
            AR.NKID,
            ACL.STATUS,
            (CASE WHEN ACL.STATUS = '2' THEN TO_CHAR (AR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                  ELSE RS.NAME
             END),
            TO_CHAR (ACL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss'),
            U.FIRSTNAME || ' ' || U.LASTNAME,
            ETM.UI_ALIAS||': '||q.qr,
            CR.REASON,
            ACL.SUMMARY;