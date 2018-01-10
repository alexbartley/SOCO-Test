CREATE OR REPLACE FUNCTION content_repo."FFMTDATE_RANGE"
    (dStart_Date IN DATE,
     dEnd_Date IN DATE,
     check_time_in IN VARCHAR2 := 'NOTIME')
RETURN VARCHAR2
/*
 * fFmtDate_Range(a,b,'TIME'/'NOTIME') returns a string containing a date range
 * in the format 'BETWEEN x AND y'
 * Parameters:
 *      dStart_Date - The start date of the range. If NULL
 *          then use the min_start_date. If that is NULL, range
 *          has form '<= end_date'.
 *
 *      dEnd_Date - The end date of the range. If NULL
 *          then use the max_end_date. If that is NULL, range has
 *          form '>= start_date'.
 *
 *      check_time_in - If 'TIME' then use the time component
 *          of the dates as part of the comparison.
 *          If 'NOTIME' then strip off the time.
 *
 * -- Example 1: SELECT fFmtDate_Range(sysdate-40,sysdate+30,'NOTIME') FROM dual
 * -- Example 2: SELECT fFmtDate_Range(sysdate-40,null,'TIME') FROM dual
*/
IS
    /* String versions of parameters to place in return value */
    dStart_Datet VARCHAR2(30);
    dEnd_Datet VARCHAR2(30);

    /* Date mask for date<->character conversions. */
    mask_int VARCHAR2(15) := 'YYYYMMDD';

    /* Version of date mask which fits right into date range string */
    mask_string VARCHAR2(30) := NULL;

    /* The return value for the function. */
   return_value VARCHAR2(1000) := NULL;
BEGIN
    /*
    || Finalize the date mask. If user wants to use time, add that to
    || the mask. Then set the string version by embedding the mask
    || in single quotes and with a trailing paranthesis.
    */
    IF UPPER (check_time_in) = 'TIME'
    THEN
        mask_int := mask_int || ' HHMISS';
    END IF;
    /*
    || Convert mask. Example:
    ||      If mask is:             MMDDYYYY HHMISS
    ||      then mask string is: ', 'MMDDYYYY HHMISS')
    */
    mask_string := ''', ''' || mask_int || ''')';

    /* Now convert the dates to character strings using format mask */
   dStart_Datet := TO_CHAR (dStart_Date, mask_int);
    dEnd_Datet := TO_CHAR (dEnd_Date, mask_int);

    /* If both start and end are NULL, then return NULL. */
    IF dStart_Datet IS NULL AND dEnd_Datet IS NULL
    THEN
        return_value := NULL;

    /* If no start point then return "<=" format. */
    ELSIF dStart_Datet IS NULL
    THEN
        return_value := '<= TO_DATE (''' || dEnd_Datet || mask_string;

    /* If no end point then return ">=" format. */
    ELSIF dEnd_Datet IS NULL
    THEN
        return_value := '>= TO_DATE (''' || dStart_Datet || mask_string;

    /* Have start and end */
    ELSE
        return_value :=
          'BETWEEN TO_DATE (''' || dStart_Datet || mask_string ||
             ' AND TO_DATE (''' || dEnd_Datet || mask_string;
    END IF;

    RETURN return_value;

END fFmtDate_Range;

 
 
/