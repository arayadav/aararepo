"#autoformat
*&---------------------------------------------------------------------*
*& Report ztest_atc
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*

REPORT ztest_atc.

DATA(lv_lifnr) = '0000000001'.

    SELECT SINGLE lifnr, land1, name1
      FROM zvendor_test( p_lifnr = @lv_lifnr )
       INTO @DATA(ls_lfa1).

      WRITE: ls_lfa1.
