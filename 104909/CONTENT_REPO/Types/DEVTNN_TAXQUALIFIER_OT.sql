CREATE OR REPLACE TYPE content_repo."DEVTNN_TAXQUALIFIER_OT"                                          AS OBJECT
( id number
, transaction_tx_id number
, element_id NUMBER
, logicalq varchar2(32)
, logvalue varchar2(64)
, qstart date
, qend date
, entered_by number
, entered_date date
, status number
, modifDate date
, rid number
, nkid number
, juris_id number
, refgroupid number
, qualifType varchar2(16)
);
/