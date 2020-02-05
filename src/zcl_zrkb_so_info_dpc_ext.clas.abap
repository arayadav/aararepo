class ZCL_ZRKB_SO_INFO_DPC_EXT definition
  public
  inheriting from ZCL_ZRKB_SO_INFO_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY
    redefinition .
protected section.

  methods ZSALESORDER_SETS_CREATE_ENTITY
    redefinition .
  methods ZSALESORDER_SETS_GET_ENTITYSET
    redefinition .
  methods ZSO_HEADERSET_GET_ENTITY
    redefinition .
  methods ZSO_ITEMSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZRKB_SO_INFO_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.

    DATA: BEGIN OF ls_order_data.
        INCLUDE           TYPE zcl_zrkb_so_info_mpc=>ts_zso_header.
    DATA: zso_nav_prop    TYPE zcl_zrkb_so_info_mpc=>tt_zso_item,
          END OF ls_order_data.
    DATA: lt_items        TYPE STANDARD TABLE OF bapisditm,
          lt_itemsx       TYPE STANDARD TABLE OF bapisditmx,
          lt_partners     TYPE STANDARD TABLE OF bapiparnr,
          lt_cond         TYPE STANDARD TABLE OF bapicond,
          lt_condx        TYPE STANDARD TABLE OF bapicondx,
          lt_return       TYPE STANDARD TABLE OF bapiret2,
          lt_so           TYPE STANDARD TABLE OF sales_key,
          lt_hdr          TYPE STANDARD TABLE OF bapisdhd,
          lt_itms         TYPE STANDARD TABLE OF bapisdit,
          lt_schedule     TYPE STANDARD TABLE OF bapischdl,
          lt_schedulex    TYPE STANDARD TABLE OF bapischdlx,
          ls_header       TYPE bapisdhd1,
          ls_headerx      TYPE bapisdhd1x,
          ls_items        TYPE bapisditm,
          ls_itemsx       TYPE bapisditmx,
          ls_partners     TYPE bapiparnr,
          ls_cond         TYPE bapicond,
          ls_condx        TYPE bapicondx,
          ls_baiview      TYPE order_view,
          ls_so           TYPE sales_key,
          ls_zso_nav_prop TYPE zcl_zrkb_so_info_mpc=>ts_zso_item,
          ls_schedule     TYPE bapischdl,
          ls_schedulex    TYPE bapischdlx,
          lv_sales_doc    TYPE vbeln_va.

    CLEAR: lt_items[], lt_itemsx[], lt_partners[],
           lt_cond[],  lt_condx[],  lt_return[],
           lt_so[], lt_hdr[], lt_itms[],
           lt_schedule[], lt_schedulex[],
           ls_header,  ls_headerx,  ls_items,
           ls_itemsx,  ls_partners, ls_cond,
           ls_condx,   ls_order_data, ls_baiview,
           ls_so,      ls_zso_nav_prop, ls_schedule,
           ls_schedulex,lv_sales_doc.
    BREAK rbinnu.
    DATA(lv_entity_set_name) = io_tech_request_context->get_entity_set_name( ).

    CASE lv_entity_set_name.
      WHEN 'ZSO_HeaderSet'.
        io_data_provider->read_entry_data( IMPORTING es_data = ls_order_data ).
        MOVE-CORRESPONDING ls_order_data TO ls_header.
        ls_headerx-doc_type     = abap_true.
        ls_headerx-sales_org    = abap_true.
        ls_headerx-distr_chan   = abap_true.
        ls_headerx-division     = abap_true.
        ls_headerx-purch_no_c   = abap_true.

        ls_header-incoterms1    = 'FOB'.
        ls_headerx-incoterms1   = abap_true.
        ls_header-incoterms2    = 'QWERTYUI'.
        ls_headerx-incoterms2   = abap_true.
        ls_header-pmnttrms      = '0001'.
        ls_headerx-pmnttrms     = abap_true.
        ls_headerx-updateflag   = 'I'.

        ls_partners-partn_role  = 'WE'.
        ls_partners-partn_numb  = ls_order_data-partn_numb.
        APPEND ls_partners TO lt_partners.
        ls_partners-partn_role  = 'AG'.
        APPEND ls_partners TO lt_partners.

        LOOP AT ls_order_data-zso_nav_prop INTO DATA(ls_order_items).
          MOVE-CORRESPONDING ls_order_items TO ls_items.
          ls_items-material = |{ ls_order_items-material ALPHA = IN }|.
          ls_itemsx-itm_number    = ls_order_items-itm_number.
          ls_itemsx-updateflag    = 'I'.
          ls_itemsx-material      = ls_itemsx-plant      = ls_itemsx-target_qty =
          ls_itemsx-gross_wght    = ls_itemsx-net_weight = ls_itemsx-untof_wght =
          abap_true.
          APPEND: ls_items   TO lt_items,
                  ls_itemsx  TO lt_itemsx.

          ls_schedule-itm_number  = ls_schedulex-itm_number = ls_items-itm_number.
          ls_schedule-req_qty     = ls_order_items-target_qty.
          ls_schedulex-req_qty    = abap_true.
          APPEND: ls_schedule   TO lt_schedule,
                  ls_schedulex  TO lt_schedulex.
          ls_condx-itm_number     = ls_cond-itm_number  = ls_items-itm_number.
          ls_condx-cond_st_no     = ls_cond-cond_st_no  = '001'.
          ls_condx-cond_count     = ls_cond-cond_count  = '01'.
          ls_condx-cond_type      = ls_cond-cond_type   = 'PR00'.
          ls_condx-cond_value     = ls_cond-cond_value  = 100.
          ls_condx-currency       = ls_cond-currency    = 'USD'.
          APPEND: ls_cond  TO lt_cond,
                  ls_condx TO lt_condx.

        ENDLOOP.

        IF lt_items[] IS NOT INITIAL.
          CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
            EXPORTING
              order_header_in      = ls_header
              order_header_inx     = ls_headerx
            IMPORTING
              salesdocument        = lv_sales_doc
            TABLES
              return               = lt_return
              order_items_in       = lt_items
              order_items_inx      = lt_itemsx
              order_partners       = lt_partners
              order_schedules_in   = lt_schedule
              order_schedules_inx  = lt_schedulex
              order_conditions_in  = lt_cond
              order_conditions_inx = lt_condx.
          LOOP AT lt_return INTO DATA(ls_return)
                            WHERE type EQ 'A'
                            OR    type EQ 'E'.
            EXIT.
          ENDLOOP.
          IF sy-subrc IS NOT INITIAL.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
              EXPORTING
                wait = abap_true.

            CLEAR: lt_so[], lt_hdr[], lt_itms[], lt_items[],
                   ls_order_data, ls_header, ls_baiview, ls_so,
                   ls_zso_nav_prop.

            ls_baiview-header = abap_true.
            ls_baiview-item   = abap_true.
            ls_so-vbeln = lv_sales_doc.
            APPEND ls_so TO lt_so.

            CALL FUNCTION 'BAPISDORDER_GETDETAILEDLIST'
              EXPORTING
                i_bapi_view       = ls_baiview
              TABLES
                sales_documents   = lt_so
                order_headers_out = lt_hdr
                order_items_out   = lt_itms.
            READ TABLE lt_hdr INTO DATA(ls_hdr) INDEX 1.
            IF sy-subrc IS INITIAL.
              MOVE-CORRESPONDING: ls_hdr   TO ls_order_data.
              ls_order_data-vbeln           = ls_hdr-doc_number.
              ls_order_data-purch_no_c      = ls_hdr-purch_no.
              ls_order_data-partn_numb      = ls_hdr-sold_to.
              ls_order_data-erdat           = ls_hdr-rec_date.
              ls_order_data-erzet           = ls_hdr-rec_time.
              ls_order_data-ernam           = ls_hdr-created_by.
              LOOP AT lt_itms INTO DATA(ls_itms).
                MOVE-CORRESPONDING ls_itms TO ls_zso_nav_prop.
                ls_zso_nav_prop-vbeln       = ls_itms-doc_number.
                ls_zso_nav_prop-pstyv       = ls_itms-item_categ.
                ls_zso_nav_prop-mvgr5       = ls_itms-prc_group5.
                ls_zso_nav_prop-gross_wght  = ls_itms-gross_weig.
                ls_zso_nav_prop-untof_wght  = ls_itms-unit_of_wt.
                ls_zso_nav_prop-store_loc   = ls_itms-stge_loc.
                APPEND ls_zso_nav_prop TO ls_order_data-zso_nav_prop.
              ENDLOOP.
              copy_data_to_ref( EXPORTING is_data = ls_order_data
                                CHANGING  cr_data = er_deep_entity ).
            ENDIF.
          ELSE.
            CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
            CALL METHOD mo_context->get_message_container( )->add_messages_from_bapi(
                      EXPORTING
                           it_bapi_messages          = lt_return
                           iv_determine_leading_msg  = /iwbep/if_message_container=>gcs_leading_msg_search_option-first ).
            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                textid            = /iwbep/cx_mgw_busi_exception=>business_error
                message_container = mo_context->get_message_container( ).
          ENDIF.
        ENDIF.

      WHEN OTHERS.
    ENDCASE.

  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entity.

    CONSTANTS: lc_posnr TYPE posnr_va VALUE '000000',
               lc_sp    TYPE parvw    VALUE 'AG',
               lc_expand_tech_clause TYPE string VALUE 'ZSO_NAV_PROP'.

    DATA: BEGIN OF ls_order_data.
        INCLUDE     TYPE zcl_zrkb_so_info_mpc=>ts_zso_header.
    DATA: order_items TYPE zcl_zrkb_so_info_mpc=>tt_zso_item,
          END OF ls_order_data.
    DATA: lv_vbeln       TYPE vbeln_va,
          ls_order_items TYPE zcl_zrkb_so_info_mpc=>ts_zso_item.

    CLEAR: lv_vbeln, ls_order_data, ls_order_items.
    READ TABLE it_key_tab INTO DATA(ls_key_tab) WITH KEY name = 'Vbeln'.
    IF sy-subrc IS INITIAL.
      lv_vbeln = |{ ls_key_tab-value ALPHA = IN }|.
    ENDIF.
    IF lv_vbeln IS NOT INITIAL.
      SELECT SINGLE vbeln, erdat, erzet, ernam,
                    auart, vkorg, vtweg, spart
                    FROM vbak
                    INTO @DATA(ls_vbak)
                    WHERE vbeln EQ @lv_vbeln.
      IF sy-subrc IS NOT INITIAL.
        CLEAR ls_vbak.
      ELSE.
        ls_order_data-vbeln      = ls_vbak-vbeln.
        ls_order_data-erdat      = ls_vbak-erdat.
        ls_order_data-erzet      = ls_vbak-erzet.
        ls_order_data-doc_type   = ls_vbak-auart.
        ls_order_data-sales_org  = ls_vbak-vkorg.
        ls_order_data-distr_chan = ls_vbak-vtweg.
        ls_order_data-division   = ls_vbak-spart.
      ENDIF.
      SELECT SINGLE vbeln, posnr, parvw, kunnr
             FROM vbpa
             INTO @DATA(ls_vbpa)
             WHERE vbeln EQ @lv_vbeln
             AND   posnr EQ @lc_posnr
             AND   parvw EQ @lc_sp.
      IF sy-subrc IS NOT INITIAL.
        CLEAR ls_vbpa.
      ELSE.
        ls_order_data-partn_numb = ls_vbpa-kunnr.
      ENDIF.
      SELECT SINGLE vbeln, posnr, bstkd
             FROM vbkd
             INTO @DATA(ls_vbkd)
             WHERE vbeln EQ @lv_vbeln
             AND   posnr EQ @lc_posnr.
      IF sy-subrc IS NOT INITIAL.
        CLEAR ls_vbkd.
      ELSE.
        ls_order_data-purch_no_c = ls_vbkd-bstkd.
      ENDIF.
      SELECT vbeln, posnr, matnr, pstyv,
             zmeng, brgew, ntgew, gewei,
             werks, lgort, mvgr5
             FROM vbap
             INTO TABLE @DATA(lt_vbap)
             WHERE vbeln EQ @lv_vbeln.
      IF sy-subrc IS INITIAL.
        SORT lt_vbap BY vbeln posnr.
        LOOP AT lt_vbap INTO DATA(ls_vbap).
          ls_order_items-vbeln      = ls_vbap-vbeln.
          ls_order_items-itm_number = ls_vbap-posnr.
          ls_order_items-material   = ls_vbap-matnr.
          ls_order_items-gross_wght = ls_vbap-brgew.
          ls_order_items-net_weight = ls_vbap-ntgew.
          ls_order_items-target_qty = ls_vbap-zmeng.
          ls_order_items-plant      = ls_vbap-werks.
          ls_order_items-store_loc  = ls_vbap-lgort.
          ls_order_items-untof_wght = ls_vbap-gewei.
          ls_order_items-pstyv      = ls_vbap-pstyv.
          ls_order_items-mvgr5      = ls_vbap-mvgr5.
          APPEND ls_order_items TO ls_order_data-order_items.
        ENDLOOP.
      ENDIF.
      copy_data_to_ref( EXPORTING is_data = ls_order_data
                        CHANGING  cr_data = er_entity ).
*      INSERT lc_expand_tech_clause INTO TABLE et_expanded_tech_clauses.
    ENDIF.

  ENDMETHOD.


  METHOD zsalesorder_sets_create_entity.

*-------------------------------------------------------------
*  Data declaration
*-------------------------------------------------------------
    DATA imp_flag TYPE zif_zrkb_sales_order_create=>boolean.
    DATA imp_input TYPE zif_zrkb_sales_order_create=>zrkb_create_so.
    DATA sales_order TYPE zif_zrkb_sales_order_create=>vbeln_va.
    DATA lv_rfc_name TYPE tfdir-funcname.
    DATA lv_destination TYPE rfcdest.
    DATA lv_subrc TYPE syst-subrc.
    DATA lv_exc_msg TYPE /iwbep/mgw_bop_rfc_excep_text.
    DATA lx_root TYPE REF TO cx_root.
    DATA ls_request_input_data TYPE zcl_zrkb_so_info_mpc=>ts_zsalesorder_set.
    DATA ls_entity TYPE REF TO data.
    DATA lo_tech_read_request_context TYPE REF TO /iwbep/cl_sb_gen_read_aftr_crt.
    DATA ls_key TYPE /iwbep/s_mgw_tech_pair.
    DATA lt_keys TYPE /iwbep/t_mgw_tech_pairs.
    DATA lv_entityset_name TYPE string.
    DATA lv_entity_name TYPE string.
    FIELD-SYMBOLS: <ls_data> TYPE any.
    DATA ls_converted_keys LIKE er_entity.
    DATA lo_dp_facade TYPE REF TO /iwbep/if_mgw_dp_facade.
    DATA lv_text    TYPE bapi_msg.

*-------------------------------------------------------------
*  Map the runtime request to the RFC - Only mapped attributes
*-------------------------------------------------------------
* Get all input information from the technical request context object
* Since DPC works with internal property names and runtime API interface holds external property names
* the process needs to get the all needed input information from the technical request context object
* Get request input data
    io_data_provider->read_entry_data( IMPORTING es_data = ls_request_input_data ).

* Map request input fields to function module parameters
    imp_flag = ls_request_input_data-flag.
    imp_input-vbeln = ls_request_input_data-vbeln.
    imp_input-sales_org = ls_request_input_data-sales_org.
    imp_input-distr_chan = ls_request_input_data-distr_chan.
    imp_input-division = ls_request_input_data-division.
    imp_input-doc_type = ls_request_input_data-doc_type.
    imp_input-purch_no_c = ls_request_input_data-purch_no_c.
    imp_input-partn_numb = ls_request_input_data-partn_numb.
    imp_input-itm_number = ls_request_input_data-itm_number.
    imp_input-material = ls_request_input_data-material.
    imp_input-plant = ls_request_input_data-plant.
    imp_input-store_loc = ls_request_input_data-store_loc.
    imp_input-target_qty = ls_request_input_data-target_qty.
    imp_input-gross_wght = ls_request_input_data-gross_wght.
    imp_input-net_weight = ls_request_input_data-net_weight.
    imp_input-untof_wght = ls_request_input_data-untof_wght.
    imp_input-erdat = ls_request_input_data-erdat.
    imp_input-erzet = ls_request_input_data-erzet.
    imp_input-ernam = ls_request_input_data-ernam.
    imp_input-error = ls_request_input_data-error.

* Get RFC destination
    lo_dp_facade = /iwbep/if_mgw_conv_srv_runtime~get_dp_facade( ).
    lv_destination = /iwbep/cl_sb_gen_dpc_rt_util=>get_rfc_destination( io_dp_facade = lo_dp_facade ).

*-------------------------------------------------------------
*  Call RFC function module
*-------------------------------------------------------------
    lv_rfc_name = 'ZRKB_SALES_ORDER_CREATE'.

    IF lv_destination IS INITIAL OR lv_destination EQ 'NONE'.

      TRY.
          CALL FUNCTION lv_rfc_name
            EXPORTING
              imp_flag       = imp_flag
              imp_input      = imp_input
            IMPORTING
              sales_order    = sales_order
            EXCEPTIONS
              system_failure = 1000 message lv_exc_msg
              OTHERS         = 1002.

          lv_subrc = sy-subrc.
*in case of co-deployment the exception is raised and needs to be caught
        CATCH cx_root INTO lx_root.
          lv_subrc = 1001.
          lv_exc_msg = lx_root->if_message~get_text( ).
      ENDTRY.

    ELSE.

      CALL FUNCTION lv_rfc_name DESTINATION lv_destination
        EXPORTING
          imp_flag              = imp_flag
          imp_input             = imp_input
        IMPORTING
          sales_order           = sales_order
        EXCEPTIONS
          system_failure        = 1000 MESSAGE lv_exc_msg
          communication_failure = 1001 MESSAGE lv_exc_msg
          OTHERS                = 1002.

      lv_subrc = sy-subrc.

    ENDIF.
    IF sales_order IS NOT INITIAL.
      lv_text = sales_order.
      DATA(lo_container) = me->mo_context->get_message_container( ).
      CALL METHOD lo_container->add_message_text_only
        EXPORTING
          iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-success
          iv_msg_text               = lv_text
          iv_error_category         = /iwbep/if_message_container=>gcs_error_category-processing
          iv_is_leading_message     = abap_true
          iv_add_to_response_header = abap_true.
    ENDIF.
**-------------------------------------------------------------
**  Map the RFC response to the caller interface - Only mapped attributes
**-------------------------------------------------------------
**-------------------------------------------------------------
** Error and exception handling
**-------------------------------------------------------------
* IF lv_subrc <> 0.
** Execute the RFC exception handling process
*   me->/iwbep/if_sb_dpc_comm_services~rfc_exception_handling(
*     EXPORTING
*       iv_subrc            = lv_subrc
*       iv_exp_message_text = lv_exc_msg ).
* ENDIF.
*
** Call RFC commit work
* me->/iwbep/if_sb_dpc_comm_services~commit_work(
*        EXPORTING
*          iv_rfc_dest = lv_destination
*     ) .
**-------------------------------------------------------------------------*
**             - Read After Create -
**-------------------------------------------------------------------------*
* CREATE OBJECT lo_tech_read_request_context.
*
** Create key table for the read operation
*
* ls_key-name = 'VBELN'.
* ls_key-value = imp_input-vbeln.
* IF ls_key IS NOT INITIAL.
*   APPEND ls_key TO lt_keys.
* ENDIF.
*
* ls_key-name = 'SALES_ORG'.
* ls_key-value = imp_input-sales_org.
* IF ls_key IS NOT INITIAL.
*   APPEND ls_key TO lt_keys.
* ENDIF.
*
* ls_key-name = 'DISTR_CHAN'.
* ls_key-value = imp_input-distr_chan.
* IF ls_key IS NOT INITIAL.
*   APPEND ls_key TO lt_keys.
* ENDIF.
*
* ls_key-name = 'DIVISION'.
* ls_key-value = imp_input-division.
* IF ls_key IS NOT INITIAL.
*   APPEND ls_key TO lt_keys.
* ENDIF.
*
* ls_key-name = 'DOC_TYPE'.
* ls_key-value = imp_input-doc_type.
* IF ls_key IS NOT INITIAL.
*   APPEND ls_key TO lt_keys.
* ENDIF.
*
* ls_key-name = 'PURCH_NO_C'.
* ls_key-value = imp_input-purch_no_c.
* IF ls_key IS NOT INITIAL.
*   APPEND ls_key TO lt_keys.
* ENDIF.
*
* ls_key-name = 'PARTN_NUMB'.
* ls_key-value = imp_input-partn_numb.
* IF ls_key IS NOT INITIAL.
*   APPEND ls_key TO lt_keys.
* ENDIF.
*
* ls_key-name = 'ITM_NUMBER'.
* ls_key-value = imp_input-itm_number.
* IF ls_key IS NOT INITIAL.
*   APPEND ls_key TO lt_keys.
* ENDIF.
*
** Set into request context object the key table and the entity set name
* lo_tech_read_request_context->set_keys( EXPORTING  it_keys = lt_keys ).
* lv_entityset_name = io_tech_request_context->get_entity_set_name( ).
* lo_tech_read_request_context->set_entityset_name( EXPORTING iv_entityset_name = lv_entityset_name ).
* lv_entity_name = io_tech_request_context->get_entity_type_name( ).
* lo_tech_read_request_context->set_entity_type_name( EXPORTING iv_entity_name = lv_entity_name ).
*
** Call read after create
* /iwbep/if_mgw_appl_srv_runtime~get_entity(
*   EXPORTING
*     iv_entity_name     = iv_entity_name
*     iv_entity_set_name = iv_entity_set_name
*     iv_source_name     = iv_source_name
*     it_key_tab         = it_key_tab
*     io_tech_request_context = lo_tech_read_request_context
*     it_navigation_path = it_navigation_path
*   IMPORTING
*     er_entity          = ls_entity ).
*
** Send the read response to the caller interface
* ASSIGN ls_entity->* TO <ls_data>.
* er_entity = <ls_data>.

  ENDMETHOD.


  METHOD zsalesorder_sets_get_entityset.

    CONSTANTS: lc_vbeln TYPE char30   VALUE 'VBELN',
               lc_posnr TYPE posnr_va VALUE '000000',
               lc_sp    TYPE parvw    VALUE 'AG'.

    DATA: lv_vbeln TYPE vbeln_va,
          ls_ent   TYPE zcl_zrkb_so_info_mpc=>ts_zsalesorder_set.

    CLEAR: ls_ent, lv_vbeln.

    DATA(lt_filters) =
    io_tech_request_context->get_filter( )->get_filter_select_options( ).

    READ TABLE lt_filters INTO DATA(ls_filters)
                          WITH KEY property = lc_vbeln.
    IF sy-subrc IS INITIAL.

      LOOP AT ls_filters-select_options INTO DATA(ls_so).
        CONDENSE ls_so-low NO-GAPS.
        lv_vbeln = ls_so-low.
      ENDLOOP.

    ENDIF.

    IF lv_vbeln IS NOT INITIAL.

      lv_vbeln = |{ lv_vbeln ALPHA = IN }|.

      SELECT SINGLE vbeln, erdat, erzet, ernam,
                    auart, vkorg, vtweg, spart
                    FROM vbak
                    INTO @DATA(ls_vbak)
                    WHERE vbeln EQ @lv_vbeln.
      IF sy-subrc IS INITIAL.

        SELECT vbeln, posnr,
               parvw, kunnr
               FROM vbpa
               INTO TABLE @DATA(lt_vbpa)
               WHERE vbeln EQ @lv_vbeln
               AND   posnr EQ @lc_posnr.
        IF sy-subrc IS INITIAL.

          SORT lt_vbpa BY vbeln posnr parvw.

        ELSE.

          CLEAR lt_vbpa[].

        ENDIF.

        SELECT SINGLE vbeln, posnr, bstkd
               FROM vbkd
               INTO @DATA(ls_vbkd)
               WHERE vbeln EQ @lv_vbeln
               AND   posnr EQ @lc_posnr.
        IF sy-subrc IS NOT INITIAL.

          CLEAR ls_vbkd.

        ENDIF.

        SELECT vbeln, posnr, matnr,
               zmeng, brgew, ntgew,
               gewei, werks, lgort
               FROM vbap
               INTO TABLE @DATA(lt_vbap)
               WHERE vbeln EQ @lv_vbeln.
        IF sy-subrc IS INITIAL.

          SORT lt_vbap BY vbeln posnr.

          LOOP AT lt_vbap INTO DATA(ls_vbap).

            ls_ent-vbeln        = ls_ent-sales_order
                                = ls_vbak-vbeln.
*            ls_ent-erdat        = ls_vbak-erdat.
            ls_ent-erzet        = ls_vbak-erzet.
            ls_ent-ernam        = ls_vbak-ernam.
            ls_ent-doc_type     = ls_vbak-auart.
            ls_ent-sales_org    = ls_vbak-vkorg.
            ls_ent-distr_chan   = ls_vbak-vtweg.
            ls_ent-division     = ls_vbak-spart.
            ls_ent-itm_number   = ls_vbap-posnr.
            ls_ent-material     = ls_vbap-matnr.
            ls_ent-gross_wght   = ls_vbap-brgew.
            ls_ent-net_weight   = ls_vbap-ntgew.
            ls_ent-plant        = ls_vbap-werks.
            ls_ent-store_loc    = ls_vbap-lgort.
            ls_ent-target_qty   = ls_vbap-zmeng.
            ls_ent-untof_wght   = ls_vbap-gewei.
            READ TABLE lt_vbpa INTO DATA(ls_vbpa)
                               WITH KEY vbeln = ls_vbap-vbeln
                                        posnr = lc_posnr
                                        parvw = lc_sp
                               BINARY SEARCH.
            IF sy-subrc IS INITIAL.
              ls_ent-partn_numb = ls_vbpa-kunnr.
            ENDIF.
            ls_ent-purch_no_c   = ls_vbkd-bstkd.
            APPEND ls_ent TO et_entityset.
          ENDLOOP.

        ELSE.

          CLEAR lt_vbap[].

        ENDIF.

      ELSE.

        CLEAR ls_vbak.

      ENDIF.

    ENDIF.

  ENDMETHOD.


  METHOD zso_headerset_get_entity.

    CONSTANTS: lc_vbeln TYPE char30   VALUE 'Vbeln',
               lc_posnr TYPE posnr_va VALUE '000000',
               lc_sp    TYPE parvw    VALUE 'AG'.

    DATA: lv_vbeln TYPE vbeln_va.

    CLEAR: lv_vbeln.
    READ TABLE it_key_tab INTO DATA(ls_key_tab) WITH KEY name = lc_vbeln.
    IF sy-subrc IS INITIAL.
      lv_vbeln = |{ ls_key_tab-value ALPHA = IN }|.
    ENDIF.
    IF lv_vbeln IS NOT INITIAL.
      SELECT SINGLE vbeln, erdat, erzet, ernam,
                    auart, vkorg, vtweg, spart
             FROM vbak
             INTO @DATA(ls_vbak)
             WHERE vbeln EQ @lv_vbeln.
      IF sy-subrc IS INITIAL.
        MOVE-CORRESPONDING ls_vbak TO er_entity.
        er_entity-sales_org   = ls_vbak-vkorg.
        er_entity-distr_chan  = ls_vbak-vtweg.
        er_entity-division    = ls_vbak-spart.
        er_entity-doc_type    = ls_vbak-auart.
      ENDIF.
      SELECT SINGLE vbeln, posnr, bstdk
             FROM vbkd
             INTO @DATA(ls_vbkd)
             WHERE vbeln EQ @lv_vbeln
             AND   posnr EQ @lc_posnr.
      IF sy-subrc IS INITIAL.
        er_entity-purch_no_c = ls_vbkd-bstdk.
      ENDIF.
      SELECT SINGLE vbeln, posnr, parvw, kunnr
             FROM vbpa
             INTO @DATA(ls_vbpa)
             WHERE vbeln EQ @lv_vbeln
             AND   posnr EQ @lc_posnr
             AND   parvw EQ @lc_sp.
      IF sy-subrc IS INITIAL.
        er_entity-partn_numb = ls_vbpa-kunnr.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD zso_itemset_get_entityset.

    CONSTANTS: lc_vbeln TYPE char30   VALUE 'Vbeln'.

    DATA: lv_vbeln TYPE vbeln_va,
          ls_ent   TYPE zcl_zrkb_so_info_mpc=>ts_zso_item.

    CLEAR: lv_vbeln, ls_ent.
    READ TABLE it_key_tab INTO DATA(ls_key_tab) WITH KEY name = lc_vbeln.
    IF sy-subrc IS INITIAL.
      lv_vbeln = |{ ls_key_tab-value ALPHA = IN }|.
    ENDIF.
    IF lv_vbeln IS NOT INITIAL.
      SELECT vbeln, posnr, matnr, pstyv,
             zmeng, brgew, ntgew, gewei,
             werks, lgort, mvgr5
             FROM vbap
             INTO TABLE @DATA(lt_vbap)
             WHERE vbeln EQ @lv_vbeln.
      IF sy-subrc IS INITIAL.
        SORT lt_vbap BY vbeln posnr.
        LOOP AT lt_vbap INTO DATA(ls_vbap).
          CLEAR ls_ent.
          ls_ent-vbeln        = ls_vbap-vbeln.
          ls_ent-itm_number   = ls_vbap-posnr.
          ls_ent-material     = ls_vbap-matnr.
          ls_ent-gross_wght   = ls_vbap-brgew.
          ls_ent-net_weight   = ls_vbap-ntgew.
          ls_ent-plant        = ls_vbap-werks.
          ls_ent-store_loc    = ls_vbap-lgort.
          ls_ent-target_qty   = ls_vbap-zmeng.
          ls_ent-untof_wght   = ls_vbap-gewei.
          ls_ent-pstyv        = ls_vbap-pstyv.
          ls_ent-mvgr5        = ls_vbap-mvgr5.
          APPEND ls_ent TO et_entityset.
        ENDLOOP.
      ENDIF.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
