CREATE OR REPLACE TYPE content_repo."CR2XMLFORM_CONTRIB"                                          AS OBJECT
( id number
, related_juris_id number
, related_juris_nkid number
, start_date  date
, end_date date
, modified number
, deleted NUMBER
);
/