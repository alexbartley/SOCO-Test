CREATE OR REPLACE TYPE content_repo."GEN_APPLCOND"                                          as object
(
ac_ID                              NUMBER,
ac_JURIS_TAX_APPLI_ID        NUMBER,
ac_JURISDICTION_ID                   NUMBER,
ac_REFERENCE_GROUP_ID                NUMBER,
ac_TAXABILITY_ELEMENT_ID           NUMBER,
ac_LOGICAL_QUALIFIER               VARCHAR2(100),
ac_VALUE                           VARCHAR2(100),
ac_ELEMENT_QUAL_GROUP              VARCHAR2(100),
ac_START_DATE                      DATE,
ac_END_DATE                        DATE,
ac_ENTERED_BY                      NUMBER,
ac_QUALIFIER_TYPE                  VARCHAR2(16),
ac_deleted                         VARCHAR2(1 CHAR)

);
/