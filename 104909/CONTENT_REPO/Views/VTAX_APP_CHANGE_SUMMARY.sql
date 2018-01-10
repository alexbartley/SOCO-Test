CREATE OR REPLACE FORCE VIEW content_repo.vtax_app_change_summary ("ID",rid,nkid,status,published,modified,entered_by,table_name,reason,"SUMMARY",documents) AS
SELECT JTCL.ID,
            JTR.ID,
            JTR.NKID,
            JTCL.STATUS,
            (CASE
                WHEN JTCL.STATUS = '2'
                THEN
                   TO_CHAR (JTR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                ELSE
                   RS.NAME
             END),
            TO_CHAR (JTCL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss'),
            U.FIRSTNAME || ' ' || U.LASTNAME,
            ETM.UI_ALIAS TABLE_NAME,
            CR.REASON,
            JTCL.SUMMARY,
            LISTAGG (A.ID, ',') WITHIN GROUP (ORDER BY A.ID)
       FROM JURIS_tax_app_REVISIONS JTR
            JOIN JURIS_TAX_app_CHG_LOGS JTCL
               ON JTR.ID = JTCL.RID
            JOIN ENTITY_TABLE_MAP ETM
               ON JTCL.TABLE_NAME = ETM.TABLE_NAME
            LEFT OUTER JOIN CHANGE_REASONS CR
               ON JTCL.REASON_ID = CR.ID
            LEFT OUTER JOIN JURIS_TAX_app_CHG_CITS JTCC
               ON JTCL.ID = JTCC.JURIS_TAX_app_CHG_LOG_ID
            LEFT OUTER JOIN CITATIONS C
               ON JTCC.CITATION_ID = C.ID
            LEFT OUTER JOIN ATTACHMENTS A
               ON C.ATTACHMENT_ID = A.ID
            JOIN RECORD_STATUSES RS
               ON JTCL.STATUS = RS.ID
            JOIN USERS U
               ON JTCL.ENTERED_BY = U.ID
   GROUP BY JTCL.ID,
            JTR.ID,
            JTR.NKID,
            JTCL.STATUS,
            (CASE
                WHEN JTCL.STATUS = '2'
                THEN
                   TO_CHAR (JTR.STATUS_MODIFIED_DATE, 'mm/dd/yyyy')
                ELSE
                   RS.NAME
             END),
            TO_CHAR (JTCL.ENTERED_DATE, 'mm/dd/yyyy hh24:mi:ss'),
            U.FIRSTNAME || ' ' || U.LASTNAME,
            ETM.UI_ALIAS,
            CR.REASON,
            JTCL.SUMMARY
 
 
 ;