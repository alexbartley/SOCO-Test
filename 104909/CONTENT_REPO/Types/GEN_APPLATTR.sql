CREATE OR REPLACE TYPE content_repo."GEN_APPLATTR"                                          is object
(
at_id                              NUMBER,
at_applicabilityId     NUMBER,
at_attribute_id                   NUMBER,
at_start_date                     DATE,
at_end_date                       DATE,
at_entered_by                     NUMBER,
at_value                          CLOB,
at_deleted                         VARCHAR2(1)
);
/