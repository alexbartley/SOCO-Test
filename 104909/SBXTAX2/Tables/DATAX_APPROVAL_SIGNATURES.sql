CREATE TABLE sbxtax2.datax_approval_signatures (
  signature VARCHAR2(100 BYTE) NOT NULL,
  approval_signature_id NUMBER NOT NULL,
  thomson_reuters_uid VARCHAR2(20 BYTE) NOT NULL,
  authorize_type VARCHAR2(50 BYTE) NOT NULL
) 
TABLESPACE ositax;