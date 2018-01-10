CREATE OR REPLACE TYPE content_repo."XMLFORM_TAXESTHRESHOLD"                                          AS OBJECT
  ( id NUMBER -- tax_definitions.id
  , rid NUMBER -- tax_definitions.rid
  , nkid NUMBER -- tax_definitions.nkid
  , defntype NUMBER -- tax_outlines.calculation_structure_id
  , amounttype NUMBER -- tax_calculation_structures.amount_type_id needed?
  , startdate DATE -- tax_outlines.start_date
  , enddate DATE -- tax_outlines.end_date
  , taxoutlineid NUMBER -- tax_outlines.id
  , minthreshold NUMBER -- tax_definitions.min_threshold
  , maxlimit NUMBER -- tax_definitions.max_limit
  , thrvaluetype varchar2(15) -- tax_definitions.value_type
  , thrvalue NUMBER -- tax_definitions.value
  , defertojuristaxid NUMBER -- tax_definitions.defer_to_juris_tax_id
  , currencyid NUMBER -- tax_definitions.currency_id
  , modified NUMBER -- APPflag
  , deleted NUMBER -- APPflag
  , throutlinerec NUMBER -- PLRecord
  , thModified number -- threshold modified
  , thDeleted number -- threshold delete
  );
/