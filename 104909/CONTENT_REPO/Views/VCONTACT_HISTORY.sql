CREATE OR REPLACE FORCE VIEW content_repo.vcontact_history ("ID",entered_date,note,contact_reason_id,contact_reason,contact_method_id,contact_method,method_id,contact_details,research_source_id,description,frequency,entered_by,entered_by_id,document_id) AS
SELECT DISTINCT
            VRL.ID ID,
            VRL.ENTERED_DATE ENTERED_DATE,
            VRL.NOTE NOTE,
            VCD.CONTACT_REASON_ID CONTACT_REASON_ID,
            VCD.CONTACT_REASON CONTACT_REASON,
            VCD.CONTACT_METHOD_ID CONTACT_METHOD_ID,
            VCD.CONTACT_METHOD CONTACT_METHOD,
            VCD.ID METHOD_ID,
            VCD.CONTACT_DETAILS CONTACT_DETAILS,
            VRS.ID RESEARCH_SOURCE_ID,
            VRS.DESCRIPTION DESCRIPTION,
            VRS.FREQUENCY,
            U.FIRSTNAME || ' ' || U.LASTNAME ENTERED_BY,
            VRL.ENTERED_BY ENTERED_BY_ID,
            LISTAGG (VRL.DOCUMENT_ID, ',')
               WITHIN GROUP (ORDER BY VRL.DOCUMENT_ID)
       FROM VRESEARCH_LOGS VRL
            LEFT OUTER JOIN VCONTACT_DETAILS VCD
               ON VRL.SOURCE_CONTACT_ID = VCD.ID
            LEFT OUTER JOIN VRESEARCH_SOURCES VRS
               ON VRL.RESEARCH_SOURCE_ID = VRS.ID
            LEFT OUTER JOIN USERS U
               ON U.ID = VRL.ENTERED_BY
   GROUP BY VRL.ID,
            VRL.ENTERED_DATE,
            VRL.NOTE,
            VCD.CONTACT_REASON_ID,
            VCD.CONTACT_REASON,
            VCD.CONTACT_METHOD_ID,
            VCD.CONTACT_METHOD,
            VCD.ID,
            VCD.CONTACT_DETAILS,
            VRS.ID,
            VRS.DESCRIPTION,
            VRS.FREQUENCY,
            U.FIRSTNAME || ' ' || U.LASTNAME,
            VRL.ENTERED_BY
   ORDER BY VRS.DESCRIPTION DESC
 
 
 ;