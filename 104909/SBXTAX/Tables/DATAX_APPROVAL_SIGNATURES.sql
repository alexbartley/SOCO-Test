CREATE TABLE sbxtax.datax_approval_signatures (
  signature VARCHAR2(100 BYTE) NOT NULL,
  approval_signature_id NUMBER NOT NULL,
  authorize_type VARCHAR2(50 BYTE),
  thomson_reuters_uid VARCHAR2(50 BYTE)
) 
TABLESPACE ositax;