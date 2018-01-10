CREATE OR REPLACE FORCE VIEW sbxtax.datax_who_approved (data_check_name,data_check_id,primary_key,thomson_reuters_uid) AS
SELECT dc.name, dc.data_check_id, o.primary_key, a.thomson_reuters_uid
FROM datax_checks dc
JOIN datax_check_output o ON (o.data_check_id = dc.data_Check_id)
JOIN datax_approval_Signatures a ON (a.approval_signature_id = o.reviewed_approved)
 
 
 ;