CREATE TABLE ab_94676.pro_mod_oei_qd_op (
  modele VARCHAR2(5 BYTE) NOT NULL,
  oei NUMBER(8) NOT NULL,
  fonction_op ab_94676.fnqdouverturepartielle,
  CONSTRAINT pro_m_o_q_op_pk PRIMARY KEY (modele,oei),
  CONSTRAINT pro_m_o_q_op_ouvevaind_fk FOREIGN KEY (modele,oei) REFERENCES ab_94676.pro_mod_ouvevacindividuels (modele,oei)
)
NESTED TABLE "FONCTION_OP"."COEFFICIENTDEBITZ1"."SEGMENTS" STORE AS pro_mod_oei_qd_op_cdz1
NESTED TABLE "FONCTION_OP"."COEFFICIENTDEBITZ2"."SEGMENTS" STORE AS pro_mod_oei_qd_op_cdz2;
COMMENT ON COLUMN ab_94676.pro_mod_oei_qd_op.oei IS 'Identifiant de l''OEI';
COMMENT ON COLUMN ab_94676.pro_mod_oei_qd_op.fonction_op IS 'Fonction univariable par morceaux qui représente le débit déversé en mode ouverture partielle';