CREATE OR REPLACE FORCE VIEW content_repo.vtax_reference_codes (jurisdiction_id,jurisdiction_nkid,jurisdiction_rid,jurisdiction_taxation_nkid,tax_description_id,jurisdiction_taxation_id,reference_code,start_date,end_date) AS
SELECT ji.id jurisdiction_id,
            ji.nkid jurisdiction_nkid,
            ji.rid jurisdiction_rid,
            jts.nkid jurisdiction_Taxation_nkid,
            jts.tax_description_id,
            jts.id,
            reference_code,
            MIN (jts.start_date) start_date,
            MAX (NVL (jts.end_Date, '31-Dec-9999')) end_date
       FROM    juris_tax_impositions jts
            JOIN
               jurisdictions ji
            ON (ji.id = jts.jurisdiction_id)
      WHERE jts.next_rid IS NULL
   GROUP BY ji.id,
            ji.nkid,
            ji.rid,
            jts.nkid,
            jts.tax_description_id,
            jts.id,
            reference_code
 
 
 ;