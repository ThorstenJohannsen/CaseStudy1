CLASS lhc_zr_cs1_customers000 DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION IMPORTING  REQUEST requested_authorizations FOR customers RESULT result,
      validateEmail          FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateEmail,
      validatePhone          FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validatePhone,
      validateFax            FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateFax,
      Determinate_getCity    FOR DETERMINE ON SAVE   IMPORTING keys FOR customers~Determinate_getCity,
      validateCurrencyTarget FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateCurrencyTarget,
*      SalesVolume            FOR DETERMINE ON SAVE   IMPORTING keys FOR customers~SalesVolume,
      setDefaults            FOR DETERMINE ON SAVE   IMPORTING keys FOR customers~setDefaults,
      trimEmail              FOR DETERMINE ON MODIFY IMPORTING keys FOR customers~trimEmail,
      CancelOrders           FOR MODIFY              IMPORTING keys
                                                                 FOR ACTION customers~CancelOrders   RESULT result,
      ShowStatistics         FOR MODIFY              IMPORTING keys
                                         FOR ACTION customers~ShowStatistics,
      updateCalculatedVolumes FOR MODIFY
        IMPORTING keys FOR ACTION customers~updateCalculatedVolumes.

ENDCLASS.

CLASS lhc_zr_cs1_customers000 IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.


METHOD showstatistics.
    " 1. Kunden lesen
    READ ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
      ENTITY customers
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_customers).

    " 2. Customizing: Welche Klasse + Interface nutzen?
    SELECT SINGLE FROM zcs1_statistic
      FIELDS class_name, interface_name
      WHERE active = @abap_true
      INTO @DATA(ls_stat).

    IF sy-subrc <> 0 OR ls_stat-class_name IS INITIAL.
      APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                    text     = 'Kein aktiver Eintrag in ZCS1_STATISTIC gefunden' ) )
             TO reported-customers.
      RETURN.
    ENDIF.

    " 3. RTTS Cloud Governance: Klasse + Interface prüfen bevor CREATE OBJECT
    DATA lo_class_descr TYPE REF TO cl_abap_classdescr.
    TRY.
        cl_abap_typedescr=>describe_by_name(
          EXPORTING p_name = ls_stat-class_name
          RECEIVING p_descr_ref = DATA(lo_typedescr_class) ).

        IF lo_typedescr_class->kind <> cl_abap_typedescr=>kind_class.
          APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = |{ ls_stat-class_name } ist keine Klasse| ) )
                 TO reported-customers.
          RETURN.
        ENDIF.

        lo_class_descr = CAST cl_abap_classdescr( lo_typedescr_class ).

        " Prüfen ob Klasse öffentlich instanziierbar
        IF lo_class_descr->create_visibility <> cl_abap_classdescr=>public.
          APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = |Klasse { ls_stat-class_name } nicht öffentlich| ) )
                 TO reported-customers.
          RETURN.
        ENDIF.
      CATCH cx_root.
        APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text = |Klasse { ls_stat-class_name } nicht freigegeben| ) )
               TO reported-customers.
        RETURN.
    ENDTRY.

    " 4. Pflichtmethoden prüfen: AVERAGE_SALES, MAX_SALES, DAY_SALES
    DATA(lt_required_methods) = VALUE string_table( ( `AVERAGE_SALES` ) ( `MAX_SALES` ) ( `DAY_SALES` ) ).
    LOOP AT lt_required_methods INTO DATA(lv_check_method).
      DATA(lv_class_method_fullname) = |{ ls_stat-interface_name }~{ lv_check_method }|.
      READ TABLE lo_class_descr->methods WITH KEY name = to_upper( lv_class_method_fullname ) TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |{ ls_stat-class_name }: Methode { lv_check_method } fehlt!| ) )
               TO reported-customers.
        RETURN.
      ENDIF.
    ENDLOOP.

    " 5. Pro Kunde: Klasse dynamisch instanziieren + Methoden aufrufen
    LOOP AT lt_customers INTO DATA(ls_customer).
      DATA: lv_max   TYPE zorder_total1,
            lv_avg   TYPE zorder_total1,
            lv_day   TYPE zorder_total1,
            lv_gjahr TYPE gjahr VALUE '2026'.

      TRY.
          " Dynamische Instanziierung
          DATA lo_object TYPE REF TO object.
          CREATE OBJECT lo_object TYPE (ls_stat-class_name).

          " Prüfen ob Interface implementiert
          DATA(lv_interface_implemented) = abap_false.
          LOOP AT lo_class_descr->interfaces INTO DATA(ls_implemented_interface).
            IF ls_implemented_interface-name = ls_stat-interface_name.
              lv_interface_implemented = abap_true. EXIT.
            ENDIF.
          ENDLOOP.

          IF lv_interface_implemented = abap_false.
            APPEND VALUE #( %tky = ls_customer-%tky
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text = |Klasse { ls_stat-class_name } implementiert { ls_stat-interface_name } nicht| ) )
                   TO reported-customers.
            CONTINUE.
          ENDIF.

          " Cloud-konformer Downcast auf Interface
          DATA lo_intf_descr TYPE REF TO cl_abap_objectdescr.
          cl_abap_typedescr=>describe_by_name( EXPORTING p_name = ls_stat-interface_name
                                               RECEIVING p_descr_ref = DATA(lo_typedescr_intf) ).
          lo_intf_descr = CAST cl_abap_objectdescr( lo_typedescr_intf ).
          DATA(lo_ref_descr) = cl_abap_refdescr=>create( lo_intf_descr ).

          DATA lo_dyn_intf_ref TYPE REF TO data.
          CREATE DATA lo_dyn_intf_ref TYPE HANDLE lo_ref_descr.
          ASSIGN lo_dyn_intf_ref->* TO FIELD-SYMBOL(<lo_intf_ptr>).
          <lo_intf_ptr> ?= lo_object.
          DATA lo_stat_if TYPE REF TO object.
          lo_stat_if = <lo_intf_ptr>.

          " Dynamische Methodenaufrufe
          DATA(lv_method_name) = |{ ls_stat-interface_name }~AVERAGE_SALES|.
          CALL METHOD lo_stat_if->(lv_method_name)
            EXPORTING
              iv_gjahr = lv_gjahr
              iv_kunnr = ls_customer-customerid
            RECEIVING
              rv_avg   = lv_avg.

          lv_method_name = |{ ls_stat-interface_name }~MAX_SALES|.
          CALL METHOD lo_stat_if->(lv_method_name)
            EXPORTING
              iv_kunnr = ls_customer-customerid
            RECEIVING
              rv_max   = lv_max.

          lv_method_name = |{ ls_stat-interface_name }~DAY_SALES|.
          CALL METHOD lo_stat_if->(lv_method_name)
            EXPORTING
              iv_gjahr = lv_gjahr
            RECEIVING
              rv_day   = lv_day.

          " Ergebnis als Erfolgsmeldung an UI
          APPEND VALUE #( %tky = ls_customer-%tky
                          %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-success
                                   text = |Max { lv_max DECIMALS = 2 } | &&
                                          |Ø { lv_avg DECIMALS = 2 } Tag { lv_day DECIMALS = 2 } | ) )
                 TO reported-customers.

        CATCH cx_sy_create_object_error INTO DATA(lx_create).
          APPEND VALUE #( %tky = ls_customer-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text = |Instanz-Fehler: { lx_create->get_text( ) }| ) )
                 TO reported-customers.
        CATCH cx_sy_dyn_call_error INTO DATA(lx_call).
          APPEND VALUE #( %tky = ls_customer-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text = |Aufruf-Fehler: { lx_call->get_text( ) }| ) )
                 TO reported-customers.
      ENDTRY.
    ENDLOOP.

*    " 6. UI Refresh triggern
*    result = VALUE #( FOR cust IN lt_customers ( %tky = cust-%tky %param = cust ) ).

*    LOOP AT lt_customers INTO DATA(ls_cust).
*      APPEND VALUE #(
*                        %tky   = ls_cust-%tky
*                        %param = ls_cust
*                      ) TO result.
*
*    ENDLOOP.

  ENDMETHOD.


  METHOD Determinate_getCity.
    READ ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
     ENTITY customers
     FIELDS ( postcode )
     WITH CORRESPONDING #( keys )
     RESULT DATA(lt_customers).

    DATA lt_update TYPE TABLE FOR UPDATE zr_cs1_customers000.
    "" Version 2 mit ASSIGNING
    LOOP AT lt_customers  ASSIGNING FIELD-SYMBOL(<ls_customers>). "" <ls_customers> = customers
      " Nur suchen, wenn eine PLZ da ist
      IF <ls_customers>-postcode IS NOT INITIAL.
        SELECT SINGLE FROM zcs1_i_zipcity
          FIELDS city "", country
          WHERE postcode = @<ls_customers>-postcode
          INTO ( @DATA(lv_city) ). "", @DATA(lv_country) ).

        IF sy-subrc = 0.
          " Nur updaten, wenn die Werte in der UI noch nicht passen
          APPEND VALUE #( %tky = <ls_customers>-%tky
                          City = lv_city ) TO lt_update.
          ""Country = lv_country ) TO lt_update.
        ENDIF.
      ENDIF.
    ENDLOOP.

    " 2. Gesammeltes Update (außerhalb des Loops!)
    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
        ENTITY customers
        UPDATE FIELDS ( City ) "" Country rausgenommen
        WITH lt_update.
    ENDIF.
  ENDMETHOD.


  METHOD validateEmail.
    READ ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
      ENTITY customers
      FIELDS ( Email ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers)
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).

    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Email IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Email = ''.RETURN. ENDIF.
      IF lo_validator->zif_cs1_validation~is_email_valid( ls_customer-Email ) = abap_false.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific
                      ) TO failed-customers.
        APPEND VALUE #(    %tky        = ls_customer-%tky
                           %state_area = 'VALIDATE_EMAIL'
                           %msg        = new_message_with_text(
                              severity = if_abap_behv_message=>severity-error
                              text     = |E-Mail-Adresse: { ls_customer-Email } ist ungültig expected format test@test.de| )
                        %element-Email = if_abap_behv=>mk-on
                        ) TO reported-customers.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validatePhone.
    READ ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
      ENTITY customers
      FIELDS ( Phone ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers)
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).
    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Phone IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Phone = ''.RETURN. ENDIF.
      IF lo_validator->zif_cs1_validation~is_phone_valid( ls_customer-Phone ) = abap_false.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific
                      ) TO failed-customers.
        APPEND VALUE #(    %tky        = ls_customer-%tky
                           %state_area = 'VALIDATE_Phone'
                           %msg        = new_message_with_text(
                              severity = if_abap_behv_message=>severity-error
                              text     = |Phone: { ls_customer-Phone } ist ungültig expected format +494055448899| )
                        %element-Phone = if_abap_behv=>mk-on
                      ) TO reported-customers.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateFax.
    READ ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
      ENTITY customers
      FIELDS ( Fax ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers)
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).
    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Fax IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Fax = ''.RETURN. ENDIF.
      IF lo_validator->zif_cs1_validation~is_fax_valid( ls_customer-Fax ) = abap_false.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific
                      ) TO failed-customers.
        APPEND VALUE #(  %tky        = ls_customer-%tky
                         %state_area = 'VALIDATE_Phone'
                         %msg        = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = |Fax: { ls_customer-Fax } ist ungültig expected format:e.g. +494055448899| )
                        %element-Fax = if_abap_behv=>mk-on
                      ) TO reported-customers.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD trimEmail.

    READ ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
      ENTITY customers
        FIELDS ( Email ) WITH CORRESPONDING #( keys )
        RESULT DATA(lt_customers).

    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Email IS NOT INITIAL.
      DATA(lv_email) = ls_customer-Email.
      CONDENSE lv_email NO-GAPS.

      IF lv_email <> ls_customer-Email.
        MODIFY ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
          ENTITY customers
            UPDATE FIELDS ( Email )
            WITH VALUE #( ( %tky  = ls_customer-%tky
                            Email = lv_email ) )
          FAILED   DATA(lt_failed)
          REPORTED DATA(lt_reported).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateCurrencyTarget.
    " 1. Daten der zu prüfenden Kunden einlesen
    READ ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
      ENTITY customers
        FIELDS ( CurrencyTarget )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).

    " 2. Hilfstabelle für die Datenbank-Abfrage (Existenzprüfung)
    DATA(lt_curr_filter) = lt_customers.
    DELETE lt_curr_filter WHERE CurrencyTarget IS INITIAL.
    SORT lt_curr_filter BY CurrencyTarget.
    DELETE ADJACENT DUPLICATES FROM lt_curr_filter COMPARING CurrencyTarget.

    " 3. Hashed Table gegen die Suchhilfe-View I_CurrencyStdVH
    TYPES: BEGIN OF ty_s_currency,
             Currency TYPE I_CurrencyStdVH-Currency,
           END OF ty_s_currency.
    DATA lt_valid_currencies TYPE HASHED TABLE OF ty_s_currency WITH UNIQUE KEY Currency.

    " 4. Einmaliger DB-Zugriff gegen die Suchhilfe
    IF lt_curr_filter IS NOT INITIAL.
      SELECT Currency FROM I_CurrencyStdVH WITH PRIVILEGED ACCESS
        FOR ALL ENTRIES IN @lt_curr_filter
        WHERE Currency = @lt_curr_filter-CurrencyTarget
        INTO TABLE @lt_valid_currencies.
    ENDIF.

    " 5. Validierungsschleife
    LOOP AT lt_customers ASSIGNING FIELD-SYMBOL(<ls_customer>).

      " Check 1: Pflichtfeldprüfung
      IF <ls_customer>-CurrencyTarget IS INITIAL.
        " failed stoppt den Speicherprozess (Save-Sequenz bricht ab)
        APPEND VALUE #( %tky = <ls_customer>-%tky ) TO failed-customers.

        " reported steuert die Fehlermeldung und die rote Markierung am Feld (%element)
        APPEND VALUE #( %tky = <ls_customer>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Bitte wählen Sie eine Zielwährung aus.' )
                        %element-currencytarget = if_abap_behv=>mk-on ) TO reported-customers.
        CONTINUE.
      ENDIF.

      " Check 2: Existenzprüfung gegen Suchhilfeeinträge (I_CurrencyStdVH)
      IF NOT line_exists( lt_valid_currencies[ Currency = <ls_customer>-CurrencyTarget ] ).
        " failed stoppt den Speicherprozess (Save-Sequenz bricht ab)
        APPEND VALUE #( %tky = <ls_customer>-%tky ) TO failed-customers.

        " reported steuert die Fehlermeldung und die rote Markierung am Feld (%element)
        APPEND VALUE #( %tky = <ls_customer>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |Währung { <ls_customer>-CurrencyTarget } entspricht keinem gültigen Suchhilfeeintrag!| )
                        %element-currencytarget = if_abap_behv=>mk-on ) TO reported-customers.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD setDefaults.
    " 1. Betroffene Instanzen lesen
    READ ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
      ENTITY customers
        FIELDS ( Language CurrencyTarget )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).

    " 2. Werte nur setzen, wenn sie noch leer sind (um User-Eingaben nicht zu überschreiben)
    MODIFY ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
      ENTITY customers
        UPDATE FIELDS ( Language CurrencyTarget )
        WITH VALUE #( FOR customer IN lt_customers
                         WHERE ( Language IS INITIAL AND CurrencyTarget IS INITIAL )
                         ( %tky           = customer-%tky
                           Language       = 'D'
                           CurrencyTarget = 'EUR' ) )
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD cancelorders.

    LOOP AT keys INTO DATA(ls_key).

      DATA(lv_customerid) = ls_key-%param-Customerid.

      IF lv_customerid IS INITIAL.
        APPEND VALUE #( %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text = 'Bitte einen Kunden auswählen' )
                      ) TO reported-customers.
        RETURN.
      ENDIF.

      " 1. Alle Orders vom Kunden lesen
      SELECT * FROM zcs1_custorders
        WHERE customerid = @lv_customerid
          AND status LIKE 'B%'
        INTO TABLE @DATA(lt_orders_to_update).

      IF lt_orders_to_update IS INITIAL.
        APPEND VALUE #( %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-information
                          text = |Keine Bestellungen für Kunde { lv_customerid } gefunden| )
                      ) TO reported-customers.
        CONTINUE.
      ENDIF.

      " 2. Erstes Zeichen von B auf S ändern
      LOOP AT lt_orders_to_update ASSIGNING FIELD-SYMBOL(<ls_order>).
        <ls_order>-status+0(1) = 'S'.   " BN -> SN, BN01 -> SN01
      ENDLOOP.

      " 2. Status per EML auf 'ST' updaten statt löschen
      MODIFY ENTITIES OF zr_cs1_custorders000
        ENTITY custorders
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR ls_order IN lt_orders_to_update
                      ( Orderid = ls_order-orderid
                        Status  = ls_order-status ) )
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported)
        MAPPED DATA(lt_mapped).

      " 3. Fehler prüfen
      IF lt_failed-custorders IS NOT INITIAL.
        APPEND VALUE #( %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text = |Fehler beim Stornieren der Bestellungen| )
                      ) TO reported-customers.
        CONTINUE.
      ENDIF.

      " 4. Erfolgsmeldung
      APPEND VALUE #( %msg = new_message_with_text(
                        severity = if_abap_behv_message=>severity-success
                        text = |{ lines( lt_orders_to_update ) } Bestellungen für Kunde { lv_customerid } storniert| )
                    ) TO reported-customers.
    ENDLOOP.

    result = VALUE #( FOR key IN keys ( %cid = key-%cid ) ).

  ENDMETHOD.



  METHOD updateCalculatedVolumes.
    DATA lt_updates TYPE TABLE FOR UPDATE zr_cs1_customers000.

    " 1. Die übergebenen Parameter auf die Update-Struktur des Kunden mappen
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      APPEND VALUE #(
        customerid                 = <ls_key>-customerid
        " Wichtig: Verwenden Sie hier exakt die CamelCase-Schreibweise aus Ihrer BDEF
        SalesVolume                = <ls_key>-%param-sales_volume
        SalesVolumeTarget          = <ls_key>-%param-sales_volume_target
        %control-SalesVolume       = if_abap_behv=>mk-on
        %control-SalesVolumeTarget = if_abap_behv=>mk-on
      ) TO lt_updates.
    ENDLOOP.

    " 2. Das Update im LOCAL MODE ausführen (hebelt das statische Readonly aus)
    MODIFY ENTITIES OF zr_cs1_customers000 IN LOCAL MODE
      ENTITY customers
        UPDATE FIELDS ( SalesVolume SalesVolumeTarget ) WITH lt_updates
      FAILED   failed
      REPORTED reported.
  ENDMETHOD.



ENDCLASS.

CLASS lsc_zr_cs1_customers DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS adjust_numbers REDEFINITION.
ENDCLASS.

CLASS lsc_zr_cs1_customers IMPLEMENTATION.
  METHOD adjust_numbers.
    DATA(lo_num) = NEW zcl_cs1_customer_import( ).
    LOOP AT mapped-customers ASSIGNING FIELD-SYMBOL(<ls_mapped>)
         USING KEY primary_key
         WHERE CustomerId IS INITIAL.
      DATA(lv_next) = lo_num->zif_cs1_validation~latenumbering( ).
      <ls_mapped>-CustomerId = |{ lv_next ALPHA = IN }|.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


