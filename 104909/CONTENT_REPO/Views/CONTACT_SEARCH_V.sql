CREATE OR REPLACE FORCE VIEW content_repo.contact_search_v ("ID","NAME",frequency,next_contact_date,method_id,contact_method_id,contact_method,contact_details,contact_notes,contact_reason,contact_reason_id,usage_order,"OWNER",owner_id,tag_id,last_contact_date) AS
SELECT rs.ID,
       rs.DESCRIPTION AS NAME,
       rs.FREQUENCY,
       rs.NEXT_CONTACT_DATE,
       cd.ID AS METHOD_ID,
       cd.CONTACT_METHOD_ID,
       cd.CONTACT_METHOD,
       cd.CONTACT_DETAILS,
       cd.CONTACT_NOTES,
       cd.CONTACT_REASON,
       cd.CONTACT_REASON_ID,
       cd.USAGE_ORDER,
       u.FIRSTNAME || ' ' || u.LASTNAME AS OWNER,
       u.ID AS OWNER_ID,
       rst.TAG_ID,
       LAST_CONTACT_DATE
  FROM vcontact_details cd
       LEFT JOIN (SELECT rs.DESCRIPTION,
                         rs.ID,
                         rs.FREQUENCY,
                         rs.NEXT_CONTACT_DATE,
                         rs.OWNER
                    FROM VRESEARCH_SOURCES rs) rs
          ON rs.ID = cd.RESEARCH_SOURCE_ID
       LEFT JOIN (SELECT u.ID, u.FIRSTNAME, u.LASTNAME
                    FROM USERS u) u
          ON u.ID = rs.OWNER
       LEFT JOIN
       (  SELECT ch.RESEARCH_SOURCE_ID,
                 TO_CHAR (
                    MAX (TO_DATE (ch.ENTERED_DATE, 'MM/DD/YYYY HH24:MI:SS')),
                    'MM/DD/YYYY HH24:MI:SS')
                    AS LAST_CONTACT_DATE
            FROM VCONTACT_HISTORY ch
        GROUP BY RESEARCH_SOURCE_ID) ch
          ON ch.RESEARCH_SOURCE_ID = cd.RESEARCH_SOURCE_ID
       LEFT JOIN VRESEARCH_SOURCE_TAGS rst ON rst.RESEARCH_SOURCE_ID = rs.id;