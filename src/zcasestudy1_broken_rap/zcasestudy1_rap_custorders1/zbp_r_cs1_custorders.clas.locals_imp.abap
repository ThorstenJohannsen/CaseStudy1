CLASS lhc_zr_cs1_custorders DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR custorders
        RESULT result,

      determinatedgetOrderTotal FOR DETERMINE ON SAVE
        IMPORTING
            keys FOR custorders~determinatedgetOrderTotal.

ENDCLASS.

CLASS lhc_zr_cs1_custorders IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.



   METHOD determinatedgetOrderTotal.
 DATA reported_record LIKE LINE OF reported-custorders.

    " 1. Bestellungen aus dem Buffer lesen
    READ ENTITIES OF zr_cs1_custorders IN LOCAL MODE
      ENTITY custorders
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    " 2. Zielwährung vom verknüpften Kunden lesen
    READ ENTITIES OF zr_cs1_customers
      ENTITY customers
        FIELDS ( CurrencyTarget )
        WITH VALUE #( FOR ord IN lt_orders ( Customerid = ord-Customerid ) )
      RESULT DATA(lt_customers).

    LOOP AT lt_orders ASSIGNING FIELD-SYMBOL(<fs_order>).
      " A) Zielwährung vom Kunden bestimmen
      DATA(lv_target_curr) = VALUE #( lt_customers[ KEY entity
                                              Customerid = <fs_order>-Customerid ]-CurrencyTarget OPTIONAL ).

      IF lv_target_curr IS INITIAL.
        lv_target_curr = 'USD'. " Fallback
      ENDIF.

      " B) Netto-Betrag berechnen (nach Discount)
      DATA(lv_discount_perc) = COND zorder_total1( WHEN <fs_order>-Discount IS INITIAL THEN 0
                                                   ELSE <fs_order>-Discount ).
      DATA(lv_net_local) = CONV zorder_total1( <fs_order>-OrderTotal * ( 1 - ( lv_discount_perc / 100 ) ) ).

      " C) Währungsumrechnung
      TRY.
          DATA lv_order_target_val TYPE zorder_total1.

          cl_exchange_rates=>convert_to_foreign_currency(
            EXPORTING
              date             = <fs_order>-OrderDate
              foreign_currency = lv_target_curr
              local_amount     = lv_net_local
              local_currency   = <fs_order>-Currency
            IMPORTING
              foreign_amount   = lv_order_target_val
          ).

          " D) Update der Bestellung (NUR OrderTotalTarget)
          IF <fs_order>-OrderTotalTarget <> lv_order_target_val.
              MODIFY ENTITIES OF zr_cs1_custorders IN LOCAL MODE
                ENTITY custorders
                  UPDATE FIELDS ( OrderTotalTarget )
                  WITH VALUE #( ( %tky              = <fs_order>-%tky
                                  OrderTotalTarget  = lv_order_target_val ) ).
          ENDIF.

        CATCH cx_exchange_rates INTO DATA(lx_ex).
          APPEND VALUE #( %tky = <fs_order>-%tky
                          %msg = zcx_cs1_customer_failed=>new_message(
                                   i_textid   = zcx_cs1_customer_failed=>Umrechnungsfehler
                                   i_severity = if_abap_behv_message=>severity-error
                                   i_v1       = <fs_order>-currency
                                   i_v2       = lv_target_curr
                                   i_v3       = <fs_order>-orderdate
                                   i_v4       = <fs_order>-orderid ) ) TO reported-custorders.
          CONTINUE.
      ENDTRY.

      " E) Aggregation auf den Kunden (SalesVolume)
      SELECT orderid, order_total, discount, order_total_target
        FROM zcs1_custorders
        WHERE customerid = @<fs_order>-customerid
        INTO TABLE @DATA(lt_all_orders).

      DATA(lv_cust_sum_local) = VALUE zorder_total1( ).
      DATA(lv_cust_sum_target) = VALUE zorder_total1( ).
      DATA(lv_current_order_found) = abap_false.

      LOOP AT lt_all_orders ASSIGNING FIELD-SYMBOL(<fs_row_sum>).
        IF <fs_row_sum>-orderid = <fs_order>-orderid.
          lv_current_order_found = abap_true.
          <fs_row_sum>-order_total = <fs_order>-OrderTotal.
          <fs_row_sum>-discount = <fs_order>-Discount.
          <fs_row_sum>-order_total_target = lv_order_target_val.
        ENDIF.

        DATA(lv_row_disc_perc) = COND zorder_total1( WHEN <fs_row_sum>-discount IS INITIAL THEN 0 ELSE <fs_row_sum>-discount ).
        lv_cust_sum_local  += <fs_row_sum>-order_total * ( 1 - ( lv_row_disc_perc / 100 ) ).
        lv_cust_sum_target += <fs_row_sum>-order_total_target.
      ENDLOOP.

      IF lv_current_order_found = abap_false.
        lv_cust_sum_local  += lv_net_local.
        lv_cust_sum_target += lv_order_target_val.
      ENDIF.

      MODIFY ENTITIES OF zr_cs1_customers
        ENTITY customers
          UPDATE FIELDS ( SalesVolume SalesVolumeTarget )
          WITH VALUE #( ( Customerid        = <fs_order>-Customerid
                          SalesVolume       = lv_cust_sum_local
                          SalesVolumeTarget = lv_cust_sum_target ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
