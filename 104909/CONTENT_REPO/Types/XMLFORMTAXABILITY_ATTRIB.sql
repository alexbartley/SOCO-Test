CREATE OR REPLACE TYPE content_repo."XMLFORMTAXABILITY_ATTRIB"                                          AS OBJECT
(
attr_Id NUMBER,
attr_Rid NUMBER,
attr_Nkid NUMBER,
attr_next_rid NUMBER,
attr_Status NUMBER,
juris_id NUMBER,
juris_rid NUMBER,
juris_nkid NUMBER,
juris_next_rid NUMBER,
attr_Value varchar2(64),
attrAttributeId NUMBER,
attrCatId NUMBER,
attrStart_date DATE,
attrEnd_date DATE,
attrModified NUMBER,
attrStatus NUMBER,
attrDeleted NUMBER
);
/