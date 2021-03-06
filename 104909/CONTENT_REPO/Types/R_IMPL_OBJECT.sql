CREATE OR REPLACE TYPE content_repo."R_IMPL_OBJECT"                                          IS OBJECT (
IMPL number,
C_ID number,
ccc_level number,
h_code_level number,
commtree varchar2(500),
ppc varchar2(128),
parent_h_code varchar2(128),
child_h_code varchar2(128),
parent_id number,
cc_commodity_id number,
cc_nkid number,
cc_code varchar2(128),
cc_name varchar2(500),
cc_product_tree_id number,
ID                             NUMBER                ,
REFERENCE_CODE                 VARCHAR2(100 CHAR)    ,
CALCULATION_METHOD_ID          NUMBER                ,
BASIS_PERCENT                  NUMBER,
RECOVERABLE_PERCENT            NUMBER,
START_DATE                     DATE,
END_DATE                       DATE,
ENTERED_BY                     NUMBER                ,
ENTERED_DATE                   DATE,
STATUS                         NUMBER                ,
STATUS_MODIFIED_DATE           DATE,
RID                            NUMBER                ,
NKID                           NUMBER                ,
NEXT_RID                       NUMBER,
JURISDICTION_ID                NUMBER ,               
JURISDICTION_NKID              NUMBER  ,              
ALL_TAXES_APPLY                NUMBER(1,0)           ,
RECOVERABLE_AMOUNT             NUMBER,
APPLICABILITY_TYPE_ID          NUMBER                ,
UNIT_OF_MEASURE                VARCHAR2(16 CHAR),
REF_RULE_ORDER                 NUMBER,
DEFAULT_TAXABILITY             VARCHAR2(1 CHAR),
PRODUCT_TREE_ID                NUMBER,
COMMODITY_ID                   NUMBER,
TAX_TYPE                       VARCHAR2(4 CHAR),
IS_LOCAL                       VARCHAR2(1 CHAR),
EXEMPT                         VARCHAR2(1 CHAR),
NO_TAX                         VARCHAR2(1 CHAR),
COMMODITY_NKID                 NUMBER,
CHARGE_TYPE_ID                 NUMBER
 );
/