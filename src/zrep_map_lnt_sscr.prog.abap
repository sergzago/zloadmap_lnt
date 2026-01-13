*&---------------------------------------------------------------------*
*& Include          ZREP_MAP_LNT_SSCR
*&---------------------------------------------------------------------*
TABLES sscrfields.

SELECTION-SCREEN BEGIN OF BLOCK block_1 WITH FRAME TITLE TEXT-002.
PARAMETERS: p_file  TYPE string MODIF ID m02.
SELECTION-SCREEN COMMENT /1(79) text001.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN PUSHBUTTON /1(40) templ USER-COMMAND templ MODIF ID m03.
SELECTION-SCREEN END OF BLOCK block_1.

INITIALIZATION.
  text001 = |Формат файла (xls): КодSPAR, ГрЗакуп, КодЛента, НаимТовара, БЕИ, НДС, ГрМэп |.
