CREATE OR REPLACE TYPE content_repo."CR2XMLFORMTAXABILITY_HEADER"                                          
as object (
id NUMBER,
nkid NUMBER,
rid NUMBER,
next_rid NUMBER,
applicability_type_id NUMBER,   -- New
calculation_method NUMBER,
input_recoverability NUMBER,
basis_percent NUMBER,
charge_type_id NUMBER,         -- New
Unit_of_Measure  NUMBER,             --NEW
ref_Rule_Order   NUMBER,         -- New
transaction_type varchar2(200),
taxation_type varchar2(200),
specific_applicability_type varchar2(200),
Tax_Type    varchar2(5),            -- New
start_date DATE,
end_date DATE,
Status NUmber,                    -- NEW
status_Modified_Date  date,     -- New
all_taxes_apply number,
commodity_Nkid  NUMBER,     -- New
commodity_Tree_Id  NUMBER,   -- New
jurisdiction_id number,
jurisdiction_Nkid NUMBER,  -- New
commodity_Name  varchar2(500), -- New
commodity_Code  varchar2(100), -- New
commodity_Rid   NUMBER,        -- New
entered_by number,
default_Taxability   VARCHAR2(1),   -- NEW
product_Tree_Id     NUMBER,
entered_Date        Date  -- New
);
/