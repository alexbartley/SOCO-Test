CREATE OR REPLACE package body sbxtax3.add_content_journal_entries
as


function asEscapedXML(string varchar2) return varchar2
is
  return_string  varchar2(400);
begin
  return_string := string;

  if(return_string like '%&%') then
    return_string := replace(return_string, '&', '&amp;');
  elsif (return_string like '%<%') then
    return_string := replace(return_string, '&', '&lt;');
  elsif (return_string like '%>%') then
    return_string := replace(return_string, '&', '&gt;');
  end if;

  return return_string;

end asEscapedXML;

/*
$Header:add_content_journal_entries.pk.cr.sql, 20, 5/3/2004 11:30:06 AM, Jim Barta$
*/
procedure make_content_journal_entry (p_table varchar2
                                     ,p_primary_key number
                                     ,p_operation varchar2
                                     ,p_unique_id varchar2
                                     ,p_merchant_id number default null
                                     )
as
  gs_procName varchar2(100) := 'add_content_journal_entries.make_content_journal_entry';
  gs_loc      varchar2(100) := '100';
--  v_merchant_id number := nvl(p_merchant_id, util.g_merchant_id);  -- 4.0.x  
  v_merchant_id number := p_merchant_id;  -- 4.1.x 
  v_date        date := sysdate;
begin

  begin
    insert into tb_content_journal (
      TABLE_NAME,
      MERCHANT_ID,
      PRIMARY_KEY,
      UNIQUE_ID_XML,
      OPERATION,
      OPERATION_DATE,
      content_journal_id)
    values (
      p_table,
      v_merchant_id,
      p_primary_key,
      p_unique_id,
      p_operation,
      v_date,
      content_journal_id_seq.nextval);
  exception
    when dup_val_on_index then
      update tb_content_journal
        set unique_id_xml = p_unique_id
        where table_name = p_table
          and merchant_id = v_merchant_id
          and operation = p_operation
          and operation_date = v_date
          and primary_key = p_primary_key;
  end;

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': table='||p_table||
                            ';key='||p_primary_key||';op='||p_operation||CHR(10)||SQLERRM);
end make_content_journal_entry;


procedure p_MERCHANTS (p_operation varchar2
                      ,p_key number
                      ,p_merchant_id number
                      ,p_old TB_MERCHANTS%rowtype)
is
 gs_procName varchar2(100) := 'add_content_journal_entries.p_MERCHANTS';
 gs_loc      varchar2(100) := '100';
 v_uid       varchar2(4000);
begin
 gs_loc := '200';


 /* build unique_ID XML */
 if p_operation != 'I' then
   v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
            ' NAME="' || asEscapedXML(p_old.Name)||'"'||
            '/></unique_ids>';
 end if;

 /* add journal entry */
 gs_loc := '400';
 make_content_journal_entry ('TB_MERCHANTS', p_key, p_operation, v_uid, p_merchant_id);

exception
 when others then
   raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_MERCHANTS;


procedure p_AUTHORITY_TYPES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_AUTHORITY_TYPES%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_AUTHORITY_TYPES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' MERCHANT_ID="' || p_old.MERCHANT_ID ||'"'||
             ' NAME="' || asEscapedXML(p_old.NAME) ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_AUTHORITY_TYPES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_AUTHORITY_TYPES;


procedure p_AUTHORITIES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_AUTHORITIES%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_AUTHORITIES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';


  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' NAME="' || asEscapedXML(p_old.NAME) ||'"'||
             ' MERCHANT_ID="' || p_old.MERCHANT_ID ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_AUTHORITIES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_AUTHORITIES;

procedure p_RATES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_RATES%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_RATES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' RATE_CODE="' || asEscapedXML(p_old.RATE_CODE) ||'"'||
             ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
             ' MERCHANT_ID="' || p_old.MERCHANT_ID ||'"'||
             ' IS_LOCAL="' || p_old.IS_LOCAL ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_RATES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_RATES;


procedure p_RATE_TIERS (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_RATE_TIERS%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_RATE_TIERS';
  gs_loc      varchar2(100) := '100';
  v_uid       varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' RATE_ID="' || p_old.RATE_ID ||'"'||
             ' AMOUNT_LOW="' || p_old.AMOUNT_LOW ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_RATE_TIERS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_RATE_TIERS;


procedure p_RULES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_RULES%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_RULES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' MERCHANT_ID="' || p_old.MERCHANT_ID ||'"'||
             ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
             ' RULE_ORDER="' || p_old.RULE_ORDER ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
             ' IS_LOCAL="' || p_old.IS_LOCAL ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_RULES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_RULES;


procedure p_ZONES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_ZONES%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_ZONES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' NAME="' || asEscapedXML(p_old.NAME) ||'"'||
             ' PARENT_ZONE_ID="' || p_old.PARENT_ZONE_ID ||'"'||
             ' MERCHANT_ID="' || p_old.MERCHANT_ID ||'"'||
             ' ZONE_LEVEL_ID="' || p_old.ZONE_LEVEL_ID ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_ZONES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_ZONES;


procedure p_ZONE_AUTHORITIES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_ZONE_AUTHORITIES%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_ZONE_AUTHORITIES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' ZONE_ID="' || p_old.ZONE_ID ||'"'||
             ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_ZONE_AUTHORITIES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_ZONE_AUTHORITIES;


procedure p_PRODUCT_CATEGORIES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_PRODUCT_CATEGORIES%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_PRODUCT_CATEGORIES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' PRODUCT_GROUP_ID="' || p_old.PRODUCT_GROUP_ID ||'"'||
             ' NAME="' || asEscapedXML(p_old.NAME) ||'"'||
             ' PARENT_PRODUCT_CATEGORY_ID="' || p_old.PARENT_PRODUCT_CATEGORY_ID ||'"'||
             ' MERCHANT_ID="' || p_old.MERCHANT_ID ||'"'||
             ' PRODCODE="' || asEscapedXML(p_old.PRODCODE) ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_PRODUCT_CATEGORIES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_PRODUCT_CATEGORIES;

procedure p_PRODUCT_ZONES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_PRODUCT_ZONES%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_PRODUCT_ZONES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' PRODUCT_CATEGORY_ID="' || p_old.PRODUCT_CATEGORY_ID ||'"'||
             ' ZONE_ID="' || p_old.ZONE_ID ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_PRODUCT_ZONES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_PRODUCT_ZONES;


procedure p_PRODUCT_AUTHORITY_TYPES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_PRODUCT_AUTHORITY_TYPES%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_PRODUCT_AUTHORITY_TYPES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' PRODUCT_CATEGORY_ID="' || p_old.PRODUCT_CATEGORY_ID ||'"'||
             ' ZONE_ID="' || p_old.ZONE_ID ||'"'||
             ' AUTHORITY_TYPE_ID="' || p_old.AUTHORITY_TYPE_ID ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_PRODUCT_AUTHORITY_TYPES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_PRODUCT_AUTHORITY_TYPES;


procedure p_PRODUCT_AUTHORITIES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_PRODUCT_AUTHORITIES%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_PRODUCT_AUTHORITIES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' PRODUCT_CATEGORY_ID="' || p_old.PRODUCT_CATEGORY_ID ||'"'||
             ' AUTHORITY_TYPE_ID="' || p_old.AUTHORITY_TYPE_ID ||'"'||
             ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
             ' ZONE_ID="' || p_old.ZONE_ID ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_PRODUCT_AUTHORITIES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_PRODUCT_AUTHORITIES;


procedure p_AUTHORITY_REQUIREMENTS (p_operation varchar2
                             ,p_key number
                             ,p_merchant_id number
                             ,p_old TB_AUTHORITY_REQUIREMENTS%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_AUTHORITY_REQUIREMENTS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' MERCHANT_ID="' || p_old.MERCHANT_ID ||'"'||
             ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
             ' NAME="' || p_old.NAME || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_AUTHORITY_REQUIREMENTS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_AUTHORITY_REQUIREMENTS;


procedure p_AUTHORITY_LOGIC_ELEMENTS (p_operation varchar2
                                   ,p_key number
                                   ,p_merchant_id number
                                   ,p_old TB_AUTHORITY_LOGIC_ELEMENTS%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_AUTHORITY_LOGIC_ELEMENTS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' AUTHORITY_LOGIC_GROUP_ID="' || p_old.AUTHORITY_LOGIC_GROUP_ID ||'"'||
             ' CONDITION="' || p_old.CONDITION || '"'||
             ' SELECTOR="' || p_old.SELECTOR || '"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
             ' VALUE="' || p_old.VALUE || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_AUTHORITY_LOGIC_ELEMENTS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_AUTHORITY_LOGIC_ELEMENTS;


procedure p_AUTHORITY_LOGIC_GROUPS (p_operation varchar2
                                   ,p_key number
                                   ,p_merchant_id number
                                   ,p_old TB_AUTHORITY_LOGIC_GROUPS%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_AUTHORITY_LOGIC_GROUPS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' MERCHANT_ID="' || p_merchant_id ||'"'||
             ' NAME="' || p_old.NAME || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_AUTHORITY_LOGIC_GROUPS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_AUTHORITY_LOGIC_GROUPS;


procedure p_AUTHORITY_LOGIC_GROUP_XREF (p_operation varchar2
                                   ,p_key number
                                   ,p_merchant_id number
                                   ,p_old TB_AUTHORITY_LOGIC_GROUP_XREF%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_AUTHORITY_LOGIC_GROUP_XREF';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
             ' AUTHORITY_LOGIC_GROUP_ID="' || p_old.AUTHORITY_LOGIC_GROUP_ID || '"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
             ' PROCESS_ORDER="' || p_old.PROCESS_ORDER ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_AUTHORITY_LOGIC_GROUP_XREF', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_AUTHORITY_LOGIC_GROUP_XREF;

procedure p_APP_ERRORS (p_operation varchar2
                                   ,p_key number
                                   ,p_merchant_id number
                                   ,p_old TB_APP_ERRORS%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_APP_ERRORS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '300';

  /* build unique_ID XML */
  if p_operation = 'D' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' MERCHANT_ID="' || p_old.MERCHANT_ID ||'"'||
             ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
             ' ERROR_NUM="' || p_old.ERROR_NUM || '"'||
             ' ERROR_SEVERITY="0"' ||
             '/></unique_ids>';
             
  elsif p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' MERCHANT_ID="' || p_old.MERCHANT_ID ||'"'||
             ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
             ' ERROR_NUM="' || p_old.ERROR_NUM || '"'||
             ' ERROR_SEVERITY="' || p_old.ERROR_SEVERITY || '"' ||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_APP_ERRORS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_APP_ERRORS;

procedure p_ZONE_MATCH_PATTERNS (p_operation varchar2
                                   ,p_key number
                                   ,p_merchant_id number
                                   ,p_old TB_ZONE_MATCH_PATTERNS%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_ZONE_MATCH_PATTERNS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' MERCHANT_ID="' || p_old.MERCHANT_ID ||'"'||
             ' PATTERN="' || asEscapedXML(p_old.PATTERN) ||'"'||
             ' VALUE="' || asEscapedXML(p_old.VALUE) ||'"'||
         ' TYPE="' || p_old.TYPE || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_ZONE_MATCH_PATTERNS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_ZONE_MATCH_PATTERNS;

procedure p_ZONE_MATCH_CONTEXTS (p_operation varchar2
                                   ,p_key number
                                   ,p_merchant_id number
                                   ,p_old TB_ZONE_MATCH_CONTEXTS%rowtype)
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_ZONE_MATCH_CONTEXTS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' ZONE_MATCH_PATTERN_ID="' || p_old.ZONE_MATCH_PATTERN_ID ||'"'||
             ' ZONE_LEVEL_ID="' || p_old.ZONE_LEVEL_ID ||'"'||
         ' ZONE_ID="' || p_old.ZONE_ID || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_ZONE_MATCH_CONTEXTS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_ZONE_MATCH_CONTEXTS;


procedure p_CONTRIBUTING_AUTHORITIES (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_CONTRIBUTING_AUTHORITIES%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_CONTRIBUTING_AUTHORITIES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
             ' THIS_AUTHORITY_ID="' || p_old.THIS_AUTHORITY_ID ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
         ' MERCHANT_ID="' || p_old.MERCHANT_ID || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_CONTRIBUTING_AUTHORITIES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_CONTRIBUTING_AUTHORITIES;

procedure p_DELIVERY_TERMS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_DELIVERY_TERMS%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_DELIVERY_TERMS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' DELIVERY_TERM_CODE="' || p_old.DELIVERY_TERM_CODE ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
         ' MERCHANT_ID="' || p_old.MERCHANT_ID || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_DELIVERY_TERMS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_DELIVERY_TERMS;

procedure p_DATE_DETERMINATION_LOGIC (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_DATE_DETERMINATION_LOGIC%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_DATE_DETERMINATION_LOGIC';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' NAME="' || p_old.NAME ||'"'||
         ' MERCHANT_ID="' || p_old.MERCHANT_ID || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_DATE_DETERMINATION_LOGIC', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_DATE_DETERMINATION_LOGIC;

procedure p_DATE_DETERMINATION_RULES (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_DATE_DETERMINATION_RULES%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_DATE_DETERMINATION_RULES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' RULE_ORDER="' || p_old.RULE_ORDER ||'"'||
             ' DATE_TYPE="' || p_old.DATE_TYPE ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
         ' MERCHANT_ID="' || p_old.MERCHANT_ID || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_DATE_DETERMINATION_RULES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_DATE_DETERMINATION_RULES;

procedure p_RULE_QUALIFIERS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_RULE_QUALIFIERS%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_RULE_QUALIFIERS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' RULE_ID="' || p_old.RULE_ID ||'"'||
             ' RULE_QUALIFIER_TYPE="' || p_old.RULE_QUALIFIER_TYPE ||'"'||
             ' ELEMENT="' || p_old.ELEMENT ||'"'||
             ' AUTHORITY_ID="' || nvl(p_old.authority_id,'') ||'"'||
             ' REFERENCE_LIST_ID="' || nvl(p_old.reference_list_id,'') ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
             ' OPERATOR="' || DBMS_XMLGEN.CONVERT(p_old.OPERATOR) || '"'||
             ' VALUE="' || p_old.VALUE || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_RULE_QUALIFIERS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_RULE_QUALIFIERS;

procedure p_AUTHORITY_MATERIAL_SETS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_AUTHORITY_MATERIAL_SETS%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_AUTHORITY_MATERIAL_SETS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
             ' MATERIAL_SET_ID="' || p_old.MATERIAL_SET_ID ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
         ' MERCHANT_ID="' || p_old.MERCHANT_ID || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_AUTHORITY_MATERIAL_SETS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_AUTHORITY_MATERIAL_SETS;

procedure p_MATERIAL_SET_LIST_PRODUCTS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_MATERIAL_SET_LIST_PRODUCTS%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_MATERIAL_SET_LIST_PRODUCTS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' PRODUCT_CATEGORY_ID="' || p_old.PRODUCT_CATEGORY_ID ||'"'||
             ' MATERIAL_SET_LIST_ID="' || p_old.MATERIAL_SET_LIST_ID ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_MATERIAL_SET_LIST_PRODUCTS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_MATERIAL_SET_LIST_PRODUCTS;

procedure p_MATERIAL_SET_LISTS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_MATERIAL_SET_LISTS%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_MATERIAL_SET_LISTS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' NAME="' || p_old.NAME ||'"'||
         ' MERCHANT_ID="' || p_old.MERCHANT_ID || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_MATERIAL_SET_LISTS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_MATERIAL_SET_LISTS;

procedure p_MATERIAL_SETS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_MATERIAL_SETS%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_MATERIAL_SETS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' NAME="' || p_old.NAME ||'"'||
         ' MERCHANT_ID="' || p_old.MERCHANT_ID || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_MATERIAL_SETS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_MATERIAL_SETS;

procedure p_AUTHORITY_RATE_SET_RATES (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_AUTHORITY_RATE_SET_RATES%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_AUTHORITY_RATE_SET_RATES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' AUTHORITY_RATE_SET_ID="' || p_old.AUTHORITY_RATE_SET_ID ||'"'||
             ' PROCESS_ORDER="' || p_old.PROCESS_ORDER ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_AUTHORITY_RATE_SET_RATES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_AUTHORITY_RATE_SET_RATES;

procedure p_AUTHORITY_RATE_SETS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_AUTHORITY_RATE_SETS%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_AUTHORITY_RATE_SETS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' NAME="' || p_old.NAME ||'"'||
             ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
         ' MERCHANT_ID="' || p_old.MERCHANT_ID || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_AUTHORITY_RATE_SETS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_AUTHORITY_RATE_SETS;

procedure p_REFERENCE_LISTS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_REFERENCE_LISTS%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_REFERENCE_LISTS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' NAME="' || p_old.NAME ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
         ' MERCHANT_ID="' || p_old.MERCHANT_ID || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_REFERENCE_LISTS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_REFERENCE_LISTS;

procedure p_REFERENCE_VALUES (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_REFERENCE_VALUES%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_REFERENCE_VALUES';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' REFERENCE_LIST_ID="' || p_old.REFERENCE_LIST_ID ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
         ' VALUE="' || p_old.VALUE || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_REFERENCE_VALUES', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_REFERENCE_VALUES;

procedure p_RULE_OUTPUTS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_RULE_OUTPUTS%rowtype)
            
is
  gs_procName varchar2(100) := 'add_content_journal_entries.p_RULE_OUTPUTS';
  gs_loc      varchar2(100) := '100';
  v_uid         varchar2(4000);

begin
  gs_loc := '200';

  /* build unique_ID XML */
  if p_operation != 'I' then
    v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
             ' RULE_ID="' || p_old.RULE_ID ||'"'||
             ' START_DATE="' || to_char(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
         ' NAME="' || p_old.NAME || '"'||
             '/></unique_ids>';
  end if;

  /* add journal entry */
  gs_loc := '400';
  make_content_journal_entry ('TB_RULE_OUTPUTS', p_key, p_operation, v_uid, p_merchant_id);

exception
  when others then
    raise_application_error('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
end p_RULE_OUTPUTS;

PROCEDURE p_COMPLIANCE_AREAS ( p_operation VARCHAR2
                              ,p_key NUMBER
                              ,p_merchant_id NUMBER
                              ,p_old TB_COMPLIANCE_AREAS%ROWTYPE
                             )
IS
    gs_procName VARCHAR2(100) := 'add_content_journal_entries.p_COMPLIANCE_AREAS';
    gs_loc      VARCHAR2(100) := '100';
    v_uid       VARCHAR2(4000);

BEGIN
    gs_loc := '200';

    /* build unique_ID XML */
    IF p_operation != 'I' then
        v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
                 ' START_DATE="' || TO_CHAR(p_old.START_DATE, 'MM/DD/YYYY') ||'"'||
                 ' COMPLIANCE_AREA_UUID="' || p_old.COMPLIANCE_AREA_UUID ||'"'||
                 ' MERCHANT_ID="' || p_old.MERCHANT_ID ||'"'||
                 '/></unique_ids>';
    END IF;

    /* add journal entry */
    gs_loc := '400';
    make_content_journal_entry ('TB_COMPLIANCE_AREAS', p_key, p_operation, v_uid, p_merchant_id);

EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
END p_COMPLIANCE_AREAS;

PROCEDURE p_COMP_AREA_AUTHORITIES ( p_operation VARCHAR2
                                   ,p_key NUMBER
                                   ,p_merchant_id NUMBER
                                   ,p_old TB_COMP_AREA_AUTHORITIES%ROWTYPE
                                  )
IS
    gs_procName VARCHAR2(100) := 'add_content_journal_entries.p_COMP_AREA_AUTHORITIES';
    gs_loc      VARCHAR2(100) := '100';
    v_uid       VARCHAR2(4000);

BEGIN
    gs_loc := '200';

    /* build unique_ID XML */
    IF p_operation != 'I' THEN
        v_uid := '<?xml version="1.0"?><unique_ids><unique_id'||
                 ' COMPLIANCE_AREA_ID="' || p_old.COMPLIANCE_AREA_ID ||'"'||
                 ' AUTHORITY_ID="' || p_old.AUTHORITY_ID ||'"'||
                 '/></unique_ids>';
    END IF;
  
    /* add journal entry */
    gs_loc := '400';
    make_content_journal_entry ('TB_COMP_AREA_AUTHORITIES', p_key, p_operation, v_uid, p_merchant_id);

EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR('-20001', gs_procName||': '||gs_loc||': id='||p_key||';op='||p_operation||CHR(10)||SQLERRM);
END p_COMP_AREA_AUTHORITIES;

end add_content_journal_entries;
/