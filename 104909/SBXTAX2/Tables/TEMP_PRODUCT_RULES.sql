CREATE GLOBAL TEMPORARY TABLE sbxtax2.temp_product_rules (
  product_rule_id NUMBER NOT NULL,
  rule_id NUMBER,
  product_category_id NUMBER,
  commodity_code VARCHAR2(100 BYTE)
)
ON COMMIT PRESERVE ROWS;