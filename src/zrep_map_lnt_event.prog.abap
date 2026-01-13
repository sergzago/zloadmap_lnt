*&---------------------------------------------------------------------*
*& Include          ZREP_SD_PUR_DOC_EVENT
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.
  lcl_app=>at_selection_screen( ).

AT SELECTION-SCREEN OUTPUT.
  lcl_app=>at_selection_screen_output( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  lcl_app=>file_open_dialog( ).

START-OF-SELECTION.
  DATA(go_app) = NEW lcl_app( is_param = VALUE #( file  = p_file ) ) ##NEEDED.
  go_app->main( ).
