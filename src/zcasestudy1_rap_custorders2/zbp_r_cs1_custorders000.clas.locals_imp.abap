CLASS lhc_zr_cs1_custorders000 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR custorders
        RESULT result,
      determinationgetOrderTotal FOR DETERMINE ON SAVE
        IMPORTING keys FOR custorders~determinationgetOrderTotal.
ENDCLASS.

CLASS lhc_zr_cs1_custorders000 IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD determinationgetOrderTotal.
    DATA reported_record LIKE LINE OF reported-custorders.

    " ==========================================
    " 1. BUFFER-DATEN DER BESTELLUNGEN LESEN
    " ==========================================
    READ ENTITIES OF zr_cs1_custorders000 IN LOCAL MODE
      ENTITY custorders
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    IF lt_orders IS INITIAL.
      RETURN.
    ENDIF.

    " ==========================================
    " 2. KUNDEN-STAMMDATEN PER SQL LESEN
    " ==========================================
    SELECT customerid, currency, currency_target
      FROM zcs1_customers
      FOR ALL ENTRIES IN @lt_orders
      WHERE customerid = @lt_orders-Customerid
      INTO TABLE @DATA(lt_customers).

    " ==========================================
    " 3. HISTORISCHE DATENBANK-BESTELLUNGEN LESEN
    " ==========================================
    SELECT customerid, orderid, order_total, discount, currency, order_date
      FROM zcs1_custorders
      FOR ALL ENTRIES IN @lt_customers
      WHERE customerid = @lt_customers-customerid
      INTO TABLE @DATA(lt_db_orders).

    " Lokale Struktur für die Berechnungen definieren
    TYPES: BEGIN OF ts_cust_calc,
             customerid          TYPE zcs1_customers-customerid,
             sales_volume        TYPE zorder_total1,
             sales_volume_target TYPE zorder_total1,
           END OF ts_cust_calc.
    DATA lt_calc_updates TYPE TABLE OF ts_cust_calc.

    " ==========================================
    " 4. SCHLEIFE ÜBER ALLE BETROFFENEN KUNDEN
    " ==========================================
    LOOP AT lt_customers ASSIGNING FIELD-SYMBOL(<fs_customer>).
      DATA(lv_cust_sum_local)  = VALUE zorder_total1( ).
      DATA(lv_cust_sum_target) = VALUE zorder_total1( ).

      " Typisierung der Währungen zur Vermeidung des C(3)-Fehlers
      DATA lv_target_curr TYPE zcurrency_target1.
      DATA lv_local_curr  TYPE zcurrency1.

      lv_target_curr = COND #( WHEN <fs_customer>-currency_target IS INITIAL THEN 'USD'
                               ELSE <fs_customer>-currency_target ).
      lv_local_curr  = COND #( WHEN <fs_customer>-currency IS INITIAL THEN 'EUR'
                               ELSE <fs_customer>-currency ).

      " ------------------------------------------------------------
      " A) Bestehende Bestellungen des Kunden verarbeiten
      " ------------------------------------------------------------
      LOOP AT lt_db_orders ASSIGNING FIELD-SYMBOL(<fs_db_order>) WHERE customerid = <fs_customer>-customerid.

        ASSIGN lt_orders[ KEY entity Customerid = <fs_customer>-customerid
                                       Orderid    = <fs_db_order>-orderid ] TO FIELD-SYMBOL(<fs_buf_order>).

        DATA(lv_current_total) = COND zorder_total1( WHEN sy-subrc = 0 THEN <fs_buf_order>-OrderTotal ELSE <fs_db_order>-order_total ).
        DATA(lv_current_disc)  = COND zorder_total1( WHEN sy-subrc = 0 THEN <fs_buf_order>-Discount  ELSE <fs_db_order>-discount ).
        DATA(lv_current_curr)  = COND #( WHEN sy-subrc = 0 THEN <fs_buf_order>-Currency  ELSE <fs_db_order>-currency ).
        DATA(lv_current_date)  = COND #( WHEN sy-subrc = 0 THEN <fs_buf_order>-OrderDate  ELSE <fs_db_order>-order_date ).

        " Anforderung 3: Rabatt einrechnen
        DATA(lv_net_local) = CONV zorder_total1( lv_current_total * ( 1 - ( lv_current_disc / 100 ) ) ).

        " Anforderung 4: Umrechnung für SalesVolume (Lokale Kundenwährung)
        DATA lv_vol_val TYPE zorder_total1.
        IF lv_current_curr = lv_local_curr.
          lv_vol_val = lv_net_local.
        ELSE.
          TRY.
              cl_exchange_rates=>convert_to_foreign_currency(
                EXPORTING date             = lv_current_date
                          foreign_currency = lv_local_curr " Redundante Konvertierung entfernt
                          local_amount     = lv_net_local
                          local_currency   = lv_current_curr " Redundante Konvertierung entfernt
                IMPORTING foreign_amount   = lv_vol_val ).
            CATCH cx_exchange_rates INTO DATA(lx_ex_vol).
              lv_vol_val = lv_net_local.
          ENDTRY.
        ENDIF.

        " Anforderung 4: Umrechnung für SalesVolumeTarget (Kunden-Zielwährung)
        DATA lv_target_val TYPE zorder_total1.
        IF lv_current_curr = lv_target_curr.
          lv_target_val = lv_net_local.
        ELSE.
          TRY.
              cl_exchange_rates=>convert_to_foreign_currency(
                EXPORTING date             = lv_current_date
                          foreign_currency = lv_target_curr " Redundante Konvertierung entfernt
                          local_amount     = lv_net_local
                          local_currency   = lv_current_curr " Redundante Konvertierung entfernt
                IMPORTING foreign_amount   = lv_target_val ).
            CATCH cx_exchange_rates INTO DATA(lx_ex_tar).
              IF <fs_buf_order> IS ASSIGNED.
                APPEND VALUE #( %tky = <fs_buf_order>-%tky
                                %msg = zcx_cs1_customer_failed=>new_message(
                                         i_textid   = zcx_cs1_customer_failed=>Umrechnungsfehler
                                         i_severity = if_abap_behv_message=>severity-error
                                         i_v1       = lv_current_curr
                                         i_v2       = CONV string( lv_target_curr )
                                         i_v3       = lv_current_date
                                         i_v4       = <fs_buf_order>-orderid ) ) TO reported-custorders.
              ENDIF.
              CONTINUE.
          ENDTRY.
        ENDIF.

        lv_cust_sum_local  += lv_vol_val.
        lv_cust_sum_target += lv_target_val.
      ENDLOOP.

      " ------------------------------------------------------------
      " B) Komplett neue Bestellungen verarbeiten
      " ------------------------------------------------------------
      LOOP AT lt_orders ASSIGNING <fs_buf_order> WHERE Customerid = <fs_customer>-customerid.
        IF NOT line_exists( lt_db_orders[ customerid = <fs_customer>-customerid orderid = <fs_buf_order>-Orderid ] ).

          DATA(lv_new_net) = CONV zorder_total1( <fs_buf_order>-OrderTotal * ( 1 - ( <fs_buf_order>-Discount / 100 ) ) ).

          DATA lv_new_vol TYPE zorder_total1.
          IF <fs_buf_order>-Currency = lv_local_curr.
            lv_new_vol = lv_new_net.
          ELSE.
            TRY.
                cl_exchange_rates=>convert_to_foreign_currency(
                  EXPORTING date             = <fs_buf_order>-OrderDate
                            foreign_currency = lv_local_curr
                            local_amount     = lv_new_net
                            local_currency   = <fs_buf_order>-Currency
                  IMPORTING foreign_amount   = lv_new_vol ).
              CATCH cx_exchange_rates INTO DATA(lx_dummy1).
                lv_new_vol = lv_new_net.
            ENDTRY.
          ENDIF.

          DATA lv_new_tar TYPE zorder_total1.
          IF <fs_buf_order>-Currency = lv_target_curr.
            lv_new_tar = lv_new_net.
          ELSE.
            TRY.
                cl_exchange_rates=>convert_to_foreign_currency(
                  EXPORTING date             = <fs_buf_order>-OrderDate
                            foreign_currency = lv_target_curr
                            local_amount     = lv_new_net
                            local_currency   = <fs_buf_order>-Currency
                  IMPORTING foreign_amount   = lv_new_tar ).
              CATCH cx_exchange_rates INTO DATA(lx_dummy2).
                lv_new_tar = lv_new_net.
            ENDTRY.
          ENDIF.

          lv_cust_sum_local  += lv_new_vol.
          lv_cust_sum_target += lv_new_tar.
        ENDIF.
      ENDLOOP.

      " Für eventuelle andere Logiken in der Methode mitspeichern
      APPEND VALUE #( customerid          = <fs_customer>-customerid
                      sales_volume        = lv_cust_sum_local
                      sales_volume_target = lv_cust_sum_target ) TO lt_calc_updates.

      " ==========================================
      " 5. DIRECT UPDATE FÜR FIORI UI (IN DER SCHLEIFE)
      " ==========================================
      MODIFY ENTITIES OF zr_cs1_customers
        ENTITY customers
          UPDATE FIELDS ( SalesVolume SalesVolumeTarget )
          WITH VALUE #( ( %tky-Customerid   = <fs_customer>-customerid
                          Customerid        = <fs_customer>-customerid
                          SalesVolume       = lv_cust_sum_local
                          SalesVolumeTarget = lv_cust_sum_target ) )
        REPORTED DATA(lt_reported_cust)
        FAILED   DATA(lt_failed_cust).

      " Fehlerbehandlung: Meldet Fehler direkt an die Fiori-Maske zurück
      IF lt_failed_cust IS NOT INITIAL.
        LOOP AT lt_reported_cust-customers ASSIGNING FIELD-SYMBOL(<fs_rep_cust>).
          IF <fs_buf_order> IS ASSIGNED.
            APPEND VALUE #( %tky = <fs_buf_order>-%tky
                            %msg = <fs_rep_cust>-%msg ) TO reported-custorders.
          ENDIF.
        ENDLOOP.
      ENDIF.

    ENDLOOP.

    " ==========================================
    " 5. MASSEN-UPDATE ÜBER CORRESPONDING-MAPPING
    " ==========================================



*    DATA(lo_update_customers) = NEW zcl_cs1_update_customers(  ).
*    DATA(lv_success) = lo_update_customers->zif_update_customers~update( lt_calc_updates ).
*
*    IF lv_success = abap_true.
*      " Globaler Erfolgs-Hinweis in Fiori (wird als Toast oder Pop-up angezeigt)
*      APPEND VALUE #(
*        %msg = new_message_with_text(
*                 severity = if_abap_behv_message=>severity-success
*                 text     = 'Kundenumsatz wurde erfolgreich aktualisiert!'
*               )
*      ) TO reported-custorders.
*
*    ELSE.
*
*      " Globaler Fehler-Hinweis in Fiori
*      APPEND VALUE #(
*        %msg = new_message_with_text(
*                 severity = if_abap_behv_message=>severity-error
*                 text     = 'Aktualisierung des Kundenumsatzes fehlgeschlagen.'
*               )
*      ) TO reported-custorders.
*    ENDIF.

  ENDMETHOD.

ENDCLASS.
