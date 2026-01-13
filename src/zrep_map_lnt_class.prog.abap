*&---------------------------------------------------------------------*
*& Include          ZREP_SD_PUR_DOC_CLASS
*&---------------------------------------------------------------------*
CLASS lcl_app DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      file_open_dialog,
      at_selection_screen,
      at_selection_screen_output.

    TYPES:
      BEGIN OF ts_param,
        file     TYPE string,
        from_row TYPE i,
        from_col TYPE i,
        to_col   TYPE i,
      END OF ts_param.

    METHODS:
      constructor
        IMPORTING
          is_param TYPE ts_param,
      main,
      on_user_command FOR EVENT added_function OF cl_salv_events
        IMPORTING e_salv_function.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ts_xls_ext,
        row_number    TYPE i, "Номер строки в файле
        material      TYPE matnr,
        maktx         TYPE makt-maktx,
        meins         type meins,
        material_long type matnr, "Длинный код Ленты
        material_lnt  TYPE matnr, "c length 18,
        maktx_lnt     type makt-maktx,
        meins_lnt     TYPE meins,
        min_price     TYPE p length 13 decimals 4,
        ekgrp         type ekgrp,
        mwskz         type mwskz,
        mapgr         type c length 4,
        i_log         TYPE REF TO zif_log,
      END OF ts_xls_ext,
      tt_xls_ext TYPE STANDARD TABLE OF ts_xls_ext WITH DEFAULT KEY
                  WITH NON-UNIQUE SORTED KEY row COMPONENTS row_number.

    TYPES BEGIN OF ts_xls_orig.
    TYPES row_number TYPE i. "Номер строки в файле
    INCLUDE TYPE zst_map_lnt_xls_data.
    TYPES min_price type p length 13 decimals 4.
    TYPES END OF ts_xls_orig.

    TYPES:
      tt_xls_orig TYPE STANDARD TABLE OF ts_xls_orig WITH DEFAULT KEY.
    DATA:
      ms_param      TYPE ts_param,
      lt_data_ext   TYPE tt_xls_ext,
      mi_log        TYPE REF TO zif_log,
      lo_alv        TYPE REF TO cl_salv_table,
      lo_functions TYPE REF TO cl_salv_functions_list,
      lo_sorts type ref to cl_salv_sorts,
      lo_sort type ref to cl_salv_sort,
      mo_container  TYPE REF TO cl_gui_docking_container.
*      mo_split_cont TYPE REF TO cl_gui_splitter_container,
*      mo_cont_head  TYPE REF TO cl_gui_container,
*      mo_cont_pos   TYPE REF TO cl_gui_container.

    METHODS:
      _check_selection_screen,
      _load
        IMPORTING
          iv_file      TYPE string
        EXPORTING
          et_data_file TYPE tt_xls_orig,
      _read_excel_file
        IMPORTING
          iv_file              TYPE string
        RETURNING
          VALUE(rv_excel_data) TYPE xstring,
      _parse_file_data
        IMPORTING
          iv_file       TYPE string
          iv_excel_data TYPE xstring
        EXPORTING
          et_data_file  TYPE tt_xls_orig,
      _check_file_data
        IMPORTING
          it_data_file TYPE tt_xls_orig
        EXPORTING
          et_data_ext  TYPE tt_xls_ext,
      _add_msg_param
        IMPORTING
          iv_param TYPE swc_elem
          iv_row   TYPE i OPTIONAL
        CHANGING
          ci_log   TYPE REF TO zif_log,
      _init_alv,
      _setup_alv
        importing
          io_alv TYPE REF TO cl_salv_table,
      _save_data,
      _refresh_alv
        IMPORTING
          io_alv TYPE REF TO cl_gui_alv_grid.


ENDCLASS.
CLASS lcl_app IMPLEMENTATION.
  METHOD at_selection_screen.
    CHECK sscrfields-ucomm = 'TEMPL'.
    zcl_template_helper=>export_template( 'Z_LOAD_MAP' ).
  ENDMETHOD.
  METHOD at_selection_screen_output.
    templ = TEXT-003.
  ENDMETHOD.
  METHOD file_open_dialog.
    DATA:
      lt_files  TYPE filetable,
      lv_rcode  TYPE i,
      lv_action TYPE i.

    cl_gui_frontend_services=>file_open_dialog(
      EXPORTING
        file_filter       = cl_gui_frontend_services=>filetype_excel
*        initial_directory = 'C:\'
      CHANGING
        file_table        = lt_files
        rc                = lv_rcode
        user_action       = lv_action
      EXCEPTIONS
        OTHERS            = 1
    ).
    CHECK sy-subrc IS INITIAL AND lv_action = cl_gui_frontend_services=>action_ok.

    p_file = VALUE #( lt_files[ 1 ] OPTIONAL ).
  ENDMETHOD.
  METHOD constructor.
*        IMPORTING
*          is_param TYPE ty_param,
    FREE:
      ms_param.

    mi_log ?= zcl_log_syst=>new( ).
    ms_param = is_param.
    ms_param-from_row = 2.
    ms_param-from_col = 1.
    ms_param-to_col = 7.
  ENDMETHOD.
  METHOD main.
    _check_selection_screen( ).

    _load(
      EXPORTING
          iv_file = ms_param-file
      IMPORTING
          et_data_file = DATA(lt_data_file)
     ).

    CHECK lt_data_file IS NOT INITIAL.

    _check_file_data(
      EXPORTING
        it_data_file     = lt_data_file
      IMPORTING
        et_data_ext = lt_data_ext
    ).
    _init_alv( ).
    call screen 0100.
  ENDMETHOD.
  METHOD _check_selection_screen.
    IF ms_param-file IS INITIAL.
      "Необходимо заполнить все обязательные поля
      MESSAGE s001 DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.

    IF cl_gui_frontend_services=>file_exist( ms_param-file ) IS INITIAL.
      "Файл с указанным именем не существует
      MESSAGE s002 DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDMETHOD.
  METHOD _load.

    mi_log->reset( ).
    DATA(lv_excel_data) = _read_excel_file( iv_file = ms_param-file ).

    _parse_file_data(
      EXPORTING
         iv_file = ms_param-file
         iv_excel_data = lv_excel_data
      IMPORTING
         et_data_file  = et_data_file ).

  ENDMETHOD.
  METHOD _read_excel_file.
*        IMPORTING
*          iv_file              TYPE string
*        RETURNING
*          VALUE(rv_excel_data) TYPE xstring,

    TYPES: t_xline  TYPE x LENGTH 1000,
           tt_xline TYPE STANDARD TABLE OF t_xline.

    DATA lt_data TYPE tt_xline.

    CLEAR rv_excel_data.

    cl_gui_frontend_services=>gui_upload(
      EXPORTING
        filename     = iv_file
        filetype     = 'BIN'
      IMPORTING
        filelength   =  DATA(lv_filelength)
      CHANGING
        data_tab     = lt_data
      EXCEPTIONS
        OTHERS       = 1
    ).

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
        INTO zcl_msg_helper=>last_message.

      mi_log->add_msg( sy ).
      RETURN.
    ENDIF.

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_filelength
      IMPORTING
        buffer       = rv_excel_data
      TABLES
        binary_tab   = lt_data
      EXCEPTIONS
        OTHERS       = 1.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
        INTO zcl_msg_helper=>last_message.

      mi_log->add_msg( sy ).
      RETURN.
    ENDIF.
  ENDMETHOD.
  METHOD _parse_file_data.
*        IMPORTING
*          iv_file       TYPE string
*          iv_excel_data TYPE xstring
*        EXPORTING
*          et_data_file  TYPE tt_xls_orig.
    DATA lo_sheet TYPE REF TO cl_fdt_xl_spreadsheet.
    FIELD-SYMBOLS <fs_in_table>  TYPE STANDARD TABLE.

    CLEAR et_data_file[].

    CHECK iv_excel_data IS NOT INITIAL.

    TRY.
        "Import
        CREATE OBJECT lo_sheet
          EXPORTING
            document_name = iv_file
            xdocument     = iv_excel_data.

        lo_sheet->if_fdt_doc_spreadsheet~get_worksheet_names(
          IMPORTING
            worksheet_names = DATA(lt_worksheets) ).

        LOOP AT lt_worksheets ASSIGNING FIELD-SYMBOL(<fs_worksheet>).

          IF <fs_worksheet> EQ 'Data'.
            CONTINUE. " Templates in Cloud have a dummy Sheet named 'Data'
          ENDIF.

          "Get sheet data
          DATA(lref_table) = lo_sheet->if_fdt_doc_spreadsheet~get_itab_from_worksheet( <fs_worksheet> ).
          ASSIGN lref_table->* TO <fs_in_table>.
          IF <fs_in_table> IS NOT ASSIGNED.
            CONTINUE.
          ENDIF.

          "Convert data to ITAB
          LOOP AT <fs_in_table> ASSIGNING FIELD-SYMBOL(<fs_in_line>).

            IF <fs_in_line> IS INITIAL.
              CONTINUE.
            ENDIF.

            DATA(lv_sheet_line) = sy-tabix.

            IF lv_sheet_line < ms_param-from_row.
              CONTINUE.
            ENDIF.

            APPEND INITIAL LINE TO et_data_file ASSIGNING FIELD-SYMBOL(<s_data>).
            <s_data>-row_number = lv_sheet_line - 1.

            DO ms_param-to_col TIMES.
              IF sy-index < ms_param-from_col.
                CONTINUE.
              ENDIF.

              ASSIGN COMPONENT sy-index OF STRUCTURE <fs_in_line> TO FIELD-SYMBOL(<fs_in_value>).
              CHECK sy-subrc = 0.

              CASE sy-index.
                WHEN 1.
                  "код товара SAP - код Молл
                  <s_data>-material  = <fs_in_value>.
                when 2.
                  <s_data>-ekgrp = <fs_in_value>.
                WHEN 3.
                  "Код товара SAP - код Ленты
                  DATA(lv_length) = strlen( <fs_in_value> ).
                  if lv_length GE 6.
                    <s_data>-material_lnt = substring( val = <fs_in_value> off = lv_length - 6 len = 6 ).
                  endif.
                  <s_data>-material_long  = <fs_in_value>.
                WHEN 4.
                  <s_data>-maktx_lnt = <fs_in_value>.
                WHEN 5.
                  CASE <fs_in_value>.
                    WHEN 'ШТ'.
                      <s_data>-meins_lnt = 'ST'.
                    WHEN 'КГ'.
                      <s_data>-meins_lnt = 'KG'.
                    WHEN 'Г'.
                      <s_data>-meins_lnt = 'G'.
                  ENDCASE.
                WHEN 6.
                  case <fs_in_value>.
                    when '0.1'.
                      <s_data>-mwskz = 'P5'.
                    when '0.2'.
                      <s_data>-mwskz = '6P'.
                    when '0'.
                      <s_data>-mwskz = 'P0'.
                    when '0.0'.
                      <s_data>-mwskz = 'P0'.
                    when 'нет НДС'.
                      <s_data>-mwskz = 'P0'.
                  endcase.
                WHEN 7.
                  <s_data>-mapgr = <fs_in_value>.
              ENDCASE.
            ENDDO.
          ENDLOOP.

          EXIT. "Только первый лист
        ENDLOOP.

      CATCH cx_fdt_excel_core ##NO_HANDLER.
    ENDTRY.

    IF et_data_file[] IS INITIAL.
      "В файле нет данных
      MESSAGE e003 INTO zcl_msg_helper=>last_message.
      mi_log->add_msg( sy ).
    ENDIF.

  ENDMETHOD.
  METHOD _check_file_data.
*        IMPORTING
*          it_data_file TYPE tt_xls_orig
*        EXPORTING
*          et_data_ext  TYPE tt_xls_ext.
    TYPES:
      BEGIN OF ts_matnr,
        matnr TYPE matnr,
        maktx TYPE makt-maktx,
        meins type meins,
        matnr_lnt type matnr,
        maktx_lnt type makt-maktx,
        meins_lnt type meins,
        mapgr type c length 4,
      END OF ts_matnr.
    DATA:
      lt_matnr TYPE STANDARD TABLE OF ts_matnr
      WITH NON-UNIQUE SORTED KEY main COMPONENTS matnr.

  select mara~matnr
      ,a~atwrt as strenght
      ,a1~atwrt as volume
      ,mara~ntgew
      ,zm~activ_mrc
      ,zm~z_mrc_volume
      ,mvke~kondm
    into table @data(lt_alco)
    from mara
      left join inob on mara~matnr eq inob~objek and inob~obtab eq 'MARAT' and inob~klart eq '026'
      left join ausp as a on a~objek eq inob~cuobj and a~atinn = 6 "ZSTRENGHT
      "left join cabn as cn on a~atinn eq cn~atinn and cn~atnam eq 'ZSTRENGHT'
      left join ausp as a1 on a1~objek eq inob~cuobj and a1~atinn = 1  "ZVOLUME
      "join cabn as cn1 ON a1~atinn eq cn1~atinn and cn1~atnam eq 'ZVOLUME'
      left join mvke on mvke~matnr eq mara~matnr and mvke~vkorg eq 'RU01' and mvke~vtweg eq '01'
      join ztlo_mrc as zm on zm~kondm eq mvke~kondm and zm~activ_mrc eq 'X'.

    CLEAR: et_data_ext.

    LOOP AT it_data_file ASSIGNING FIELD-SYMBOL(<s_data_file>).
      append CORRESPONDING #( <s_data_file> ) to et_data_ext ASSIGNING FIELD-SYMBOL(<s_data_ext>).
      IF <s_data_ext>-material IS NOT INITIAL.
        CALL FUNCTION 'CONVERSION_EXIT_MATNL_INPUT'
          EXPORTING
            input  = <s_data_ext>-material
          IMPORTING
            output = <s_data_ext>-material
          EXCEPTIONS
            OTHERS = 1.
        IF sy-subrc IS INITIAL.
         CALL FUNCTION 'CONVERSION_EXIT_MATNL_INPUT'
            EXPORTING
              input  = <s_data_ext>-material_lnt
            IMPORTING
              output = <s_data_ext>-material_lnt
            EXCEPTIONS
              OTHERS = 1.

         CALL FUNCTION 'CONVERSION_EXIT_MATNL_INPUT'
            EXPORTING
              input  = <s_data_ext>-material_long
            IMPORTING
              output = <s_data_ext>-material_long
            EXCEPTIONS
              OTHERS = 1.
          IF sy-subrc is initial.
            READ TABLE lt_matnr
             TRANSPORTING NO FIELDS
             WITH KEY matnr = <s_data_ext>-material
             BINARY SEARCH.
            IF sy-subrc <> 0.
              INSERT VALUE #( matnr = <s_data_ext>-material ) INTO lt_matnr INDEX sy-tabix.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSE.
*        "Не заполнено значение в столбце &1
*        MESSAGE e005 WITH 'Код товара SAP/Материал'(009) INTO zcl_msg_helper=>last_message.
*        _add_msg_param( EXPORTING iv_param = ''
*                        CHANGING  ci_log   = <s_data_ext>-i_log ).
      ENDIF.
    endloop.
    IF lt_matnr[] IS NOT INITIAL.
      SELECT
        a~matnr,
        b~maktx,
        a~meins
        FROM mara AS a
        LEFT JOIN makt AS b
          ON b~matnr = a~matnr
         AND b~spras = @sy-langu
        INTO CORRESPONDING FIELDS OF TABLE @lt_matnr
        FOR ALL ENTRIES IN @lt_matnr
        WHERE a~matnr = @lt_matnr-matnr.
    ENDIF.

    LOOP AT et_data_ext ASSIGNING <s_data_ext>
                      WHERE material IS NOT INITIAL.
      ASSIGN lt_matnr[ KEY main COMPONENTS matnr = <s_data_ext>-material ]
           TO FIELD-SYMBOL(<s_matnr>).
      IF sy-subrc = 0.
        READ TABLE lt_alco into data(ls_alco) with key matnr = <s_matnr>-matnr.
        if sy-subrc = 0.
          REPLACE ',' IN ls_alco-strenght with '.'.
* Получаем запись ЦУ ZMOC по группе цен материала
          select single a934~vkorg
            ,a934~vtweg
            ,a934~kondm
            ,a934~knumh
            ,konp~kzbzg
            ,konp~kbetr
            into @data(ls_zmoc)
          from a934
            join konp on konp~knumh eq a934~knumh and konp~kappl eq a934~kappl
          where a934~kappl eq 'V'
            and a934~kschl eq 'ZMOC'
            and a934~kondm eq @ls_alco-kondm
            and a934~datab le @sy-datum and a934~datbi ge @sy-datum.
* Проверяем, есть ли шкалы. Если да, то получаем значение по шкале и считаем цену
          if sy-subrc = 0.
            if ls_zmoc-kzbzg eq 'C'. "Есть шкалы
*  Получаем шкалу по крепости алкоголя
              SELECT SINGLE max( konm~kstbm ) into @data(lv_kstbm)
                FROM a934
                JOIN konm  ON konm~knumh eq a934~knumh
              WHERE a934~kappl eq 'V' AND a934~kschl eq 'ZMOC'
                AND a934~kondm eq @ls_alco-kondm AND konm~kstbm LT @ls_alco-strenght
                and a934~datab le @sy-datum and a934~datbi ge @sy-datum.
* Получаем цену по группе материала и шкале
              SELECT SINGLE konm~kbetr into @data(lv_kbetr)
                FROM a934
                JOIN konm  ON konm~knumh eq a934~knumh
              WHERE a934~kappl eq 'V' AND a934~kschl eq 'ZMOC'
                AND a934~kondm eq @ls_alco-kondm AND konm~kstbm EQ @lv_kstbm
                and a934~datab le @sy-datum and a934~datbi ge @sy-datum.
              if sy-subrc = 0.
                IF ls_alco-kondm EQ '10' AND ls_alco-volume GT '0.375' AND ls_alco-volume LE '0.5'.
                  <s_data_ext>-min_price = lv_kbetr.
                ELSE.
                  if ls_alco-z_mrc_volume > 0.
                    <s_data_ext>-min_price = ls_alco-volume / ls_alco-z_mrc_volume * lv_kbetr.
                  else.
                    <s_data_ext>-min_price = lv_kbetr.
                  endif.
                ENDIF.
              endif.
            else.
              <s_data_ext>-min_price = ls_zmoc-kbetr.
            endif.
          endif.
        endif.
        <s_data_ext>-maktx = <s_matnr>-maktx.
        <s_data_ext>-meins = <s_matnr>-meins.
      ENDIF.
    ENDLOOP.
    delete et_data_ext where maktx is initial or material_lnt is initial.
  ENDMETHOD.
  METHOD _init_alv.

    mo_container = NEW #(
      repid = sy-repid
      dynnr = '0100'
      extension = 10000
    ).
    TRY.
      cl_salv_table=>factory(
        EXPORTING
          r_container = mo_container
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = lt_data_ext ).
    CATCH cx_salv_msg INTO DATA(lx_salv_msg).
      " Обработка ошибок
      MESSAGE lx_salv_msg->get_text( ) TYPE 'E'.
    ENDTRY.
    _setup_alv( EXPORTING io_alv = lo_alv  ).
    lo_alv->display( ).
  ENDMETHOD.
  METHOD _setup_alv.
    data: lv_icon type string,
          lt_fcat type lvc_t_fcat,
          ls_fcat type lvc_s_fcat.
*
    data: lo_functions type ref to cl_salv_functions_list.
**   Включаем все функции alv-представления
       lo_functions = io_alv->get_functions( ).
       lo_functions->set_all( ).
*
       data(lo_columns) = io_alv->get_columns( ).
       lo_columns->get_column( 'ROW_NUMBER' )->set_visible( if_salv_c_bool_sap=>false ).
       lo_columns->get_column( 'MIN_PRICE' )->set_short_text( 'Мин.опт.ц' ).
       lo_columns->get_column( 'MIN_PRICE' )->set_medium_text( 'Мин.опт.цена' ).
       lo_columns->get_column( 'MIN_PRICE' )->set_long_text( 'Миним.оптовая цена' ).
       lo_columns->get_column( 'MATERIAL_LONG' )->set_short_text( 'Дл.кодЛент' ).
       lo_columns->get_column( 'MATERIAL_LONG' )->set_medium_text( 'Длин.код Ленты' ).
       lo_columns->get_column( 'MATERIAL_LONG' )->set_long_text( 'Длинный код Ленты' ).
       lo_columns->get_column( 'MATERIAL_LNT' )->set_short_text( 'Код Ленты' ).
       lo_columns->get_column( 'MATERIAL_LNT' )->set_medium_text( 'Код Ленты' ).
       lo_columns->get_column( 'MATERIAL_LNT' )->set_long_text( 'Код Ленты' ).
       lo_columns->get_column( 'MAKTX_LNT' )->set_short_text( 'НаимЛенты' ).
       lo_columns->get_column( 'MAKTX_LNT' )->set_medium_text( 'Наименование Ленты' ).
       lo_columns->get_column( 'MAKTX_LNT' )->set_long_text( 'Наименование материала Ленты' ).
       lo_columns->get_column( 'MEINS_LNT' )->set_short_text( 'ЕИ Ленты' ).
       lo_columns->get_column( 'MEINS_LNT' )->set_medium_text( 'Ед.Изм. Ленты' ).
       lo_columns->get_column( 'MEINS_LNT' )->set_long_text( 'Единицы измерения Ленты' ).
       lo_columns->get_column( 'MAPGR' )->set_short_text( 'Группа' ).
       lo_columns->get_column( 'MAPGR' )->set_medium_text( 'Группа' ).
       lo_columns->get_column( 'MAPGR' )->set_long_text( 'Группа' ).

**
***   Сортируем по коду материала
       lo_sorts = io_alv->get_sorts( ).
       lo_sort = lo_sorts->add_sort(
          columnname = 'MATERIAL'
          position = 1
          sequence = if_salv_c_sort=>sort_up ).
       try.
         clear lv_icon.
         call method lo_functions->add_function
           exporting
             name = 'SAVE'
             icon = lv_icon
             text = |{ 'Сохранить'(t03)  }|
             tooltip = |{ 'Сохранить'(t03)  }|
             position = 2.
          CATCH cx_salv_msg cx_salv_existing cx_salv_wrong_call ##NO_HANDLER.
       endtry.
*
       data(lo_events) = io_alv->get_event( ).
       set handler on_user_command for lo_events.
  ENDMETHOD.
    METHOD _add_msg_param.
    CHECK ci_log IS BOUND.

    ci_log->parameter = iv_param.
    IF iv_row IS SUPPLIED.
      ci_log->row = iv_row.
    ENDIF.
    ci_log->add_msg( sy ).
    FREE ci_log->parameter.
  ENDMETHOD.
  METHOD _refresh_alv.
    data: ls_stable type lvc_s_stbl.

    ls_stable-row = abap_true.
    ls_stable-col = abap_true.

*    _get_main_data( ).
*    call method lo_alv->refresh
*      exporting
*        s_stable = ls_stable.
  ENDMETHOD.
*  METHOD exit_0100.
*    CASE sy-ucomm.
*      WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
*        LEAVE TO CURRENT TRANSACTION.
*    ENDCASE.
*  ENDMETHOD.
  METHOD on_user_command.
    CASE e_salv_function.
      WHEN 'SAVE'.
        _save_data( ).
    ENDCASE.
  ENDMETHOD.
  METHOD _save_data.
    data: lv_answer type c length 1,
          lt_zmaplnt type table of zmaplnt,
          del_cnt type SYST_DBCNT,
          lt_ex_matnr type table of matnr,
          lt_new type standard table of zmaplnt.

    call function 'POPUP_TO_CONFIRM'
     exporting
       titlebar       = 'Подтверждение'
       text_question  = 'Очистить таблица ZMAPLNT?'
       "display_cancel_button  = ''
     importing
       answer         = lv_answer.
   case lv_answer.
     when '1'.
       delete from zmaplnt.
       del_cnt = sy-dbcnt.
     when '2'.
       del_cnt = 0.
   endcase.
   if lv_answer ne 'A'.
       select matnr from zmaplnt into table lt_ex_matnr.
*       lt_zmaplnt = VALUE #(
*          for ls_xls IN lt_data_ext
*          ( mandt       = sy-mandt
*            matnr       = ls_xls-material
*            maktx       = ls_xls-maktx
*            meins       = ls_xls-meins
*            matnr_long  = ls_xls-material_long
*            matnr_lenta = ls_xls-material_lnt
*            maktx_lenta = ls_xls-maktx_lnt
*            meins_lenta = ls_xls-meins_lnt
*            min_price   = ls_xls-min_price
*            ekgrp       = ls_xls-ekgrp
*            mwskz       = ls_xls-mwskz
*            )
*          ).
*       insert zmaplnt from table lt_zmaplnt.
      LOOP AT lt_data_ext INTO DATA(ls_xls).
  " Проверяем, существует ли уже такой material
           READ TABLE lt_ex_matnr WITH KEY table_line = ls_xls-material
           TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
    " Добавляем только новые записи
        APPEND VALUE #(
          mandt       = sy-mandt
          matnr       = ls_xls-material
          maktx       = ls_xls-maktx
          meins       = ls_xls-meins
          matnr_long  = ls_xls-material_long
          matnr_lenta = ls_xls-material_lnt
          maktx_lenta = ls_xls-maktx_lnt
          meins_lenta = ls_xls-meins_lnt
          min_price   = ls_xls-min_price
          ekgrp       = ls_xls-ekgrp
          mwskz       = ls_xls-mwskz
          mapgr       = ls_xls-mapgr
          ) TO lt_new.
      ENDIF.
      ENDLOOP.

      IF lt_new IS NOT INITIAL.
        INSERT zmaplnt FROM TABLE lt_new.
        message | Удалено { del_cnt } записей. Добавлено { sy-dbcnt } записей | type 'I'.
      else.
        message | Нет добавленных записей | type 'I'.
      ENDIF.
    endif.
  ENDMETHOD.

ENDCLASS.
