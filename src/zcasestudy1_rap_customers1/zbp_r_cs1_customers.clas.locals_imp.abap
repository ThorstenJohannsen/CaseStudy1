CLASS lhc_zr_cs1_customers DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      "! Globale Berechtigungen prüfen - wird beim App-Start aufgerufen
      get_global_authorizations FOR GLOBAL AUTHORIZATION IMPORTING  REQUEST requested_authorizations FOR customers RESULT result,

      "! Validierung: Email-Format prüfen vor dem Speichern
      validateEmail          FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateEmail,

      "! Validierung: Telefonnummer-Format prüfen vor dem Speichern
      validatePhone          FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validatePhone,

      "! Validierung: Fax-Format prüfen vor dem Speichern
      validateFax            FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateFax,

      "! Determination: Stadt/Land automatisch aus PLZ ermitteln
      Determinate_getCity    FOR DETERMINE ON SAVE   IMPORTING keys FOR customers~Determinate_getCity,

      "! Validierung: Zielwährung gegen I_CurrencyStdVH prüfen
      validateCurrencyTarget FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateCurrencyTarget,

      "! Determination: SalesVolumeTarget aus SalesVolume umrechnen
      SalesVolume            FOR DETERMINE ON SAVE   IMPORTING keys FOR customers~SalesVolume,

      "! Determination: Defaults setzen wenn Felder initial: Language=D, Currency=EUR
      setDefaults            FOR DETERMINE ON SAVE   IMPORTING keys FOR customers~setDefaults,

      "! Determination: Leerzeichen aus Email entfernen bei jeder Änderung
      trimEmail              FOR DETERMINE ON MODIFY IMPORTING keys FOR customers~trimEmail,

      "! Action: Bestellungen stornieren - Status B* -> S*
      CancelOrders           FOR MODIFY IMPORTING keys FOR ACTION customers~CancelOrders   RESULT result,
      "! Action: Statistiken dynamisch über Customizing-Klasse berechnen
      ShowStatistics         FOR MODIFY IMPORTING keys FOR ACTION customers~ShowStatistics RESULT result.



ENDCLASS.

CLASS lhc_zr_cs1_customers IMPLEMENTATION.

  "! <p class="shorttext synchronized">Stadt aus PLZ ermitteln</p>
  "! Wird bei Save getriggert wenn Postcode geändert wurde
  METHOD Determinate_getCity.
    " 1. Betroffene Kunden lesen
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
     ENTITY customers
     FIELDS ( postcode )
     WITH CORRESPONDING #( keys )
     RESULT DATA(lt_customers).

    DATA lt_update TYPE TABLE FOR UPDATE zr_cs1_customers.

    " 2. Für jeden Kunden Stadt aus PLZ-Tabelle lesen
    LOOP AT lt_customers ASSIGNING FIELD-SYMBOL(<ls_customers>).
      IF <ls_customers>-postcode IS NOT INITIAL.
        " Lookup in Customizing-Tabelle ZCS1_I_ZIPCITY
        SELECT SINGLE FROM zcs1_i_zipcity
          FIELDS city
          WHERE postcode = @<ls_customers>-postcode
          INTO @DATA(lv_city).

        IF sy-subrc = 0.
          " Update-Request sammeln
          APPEND VALUE #( %tky = <ls_customers>-%tky
                          City = lv_city ) TO lt_update.
        ENDIF.
      ENDIF.
    ENDLOOP.

    " 3. Massen-Update aller geänderten Städte
    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zr_cs1_customers IN LOCAL MODE
        ENTITY customers
        UPDATE FIELDS ( City )
        WITH lt_update.
    ENDIF.
  ENDMETHOD.

  "! <p class="shorttext synchronized">Globale Berechtigungen</p>
  "! Aktuell leer - hier würde man Create/Update/Delete global prüfen
  METHOD get_global_authorizations.
  ENDMETHOD.

  "! <p class="shorttext synchronized">Email validieren</p>
  "! Prüft Format test@test.de über zcl_cs1_customer_import
  METHOD validateEmail.
    " 1. Email-Felder der geänderten Kunden lesen
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
      FIELDS ( Email ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).

    " 2. Jede Email gegen Validator-Klasse prüfen
    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Email IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Email = ''. RETURN. ENDIF.

      " Wenn Format ungültig: failed + rote Markierung am Feld
      IF lo_validator->zif_cs1_validation~is_email_valid( ls_customer-Email ) = abap_false.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific
                      ) TO failed-customers.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %state_area = 'VALIDATE_EMAIL'
                        %msg        = new_message_with_text(
                           severity = if_abap_behv_message=>severity-error
                           text     = |E-Mail-Adresse: { ls_customer-Email } ist ungültig expected format test@test.de| )
                        %element-Email = if_abap_behv=>mk-on  ) TO reported-customers.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  "! <p class="shorttext synchronized">Telefon validieren</p>
  "! Prüft Format +494055448899
  METHOD validatePhone.
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
      FIELDS ( Phone ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).

    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Phone IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Phone = ''. RETURN. ENDIF.

      IF lo_validator->zif_cs1_validation~is_phone_valid( ls_customer-Phone ) = abap_false.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific
                      ) TO failed-customers.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %state_area = 'VALIDATE_Phone'
                        %msg        = new_message_with_text(
                           severity = if_abap_behv_message=>severity-error
                           text     = |Phone: { ls_customer-Phone } ist ungültig expected format +494055448899| )
                        %element-Phone = if_abap_behv=>mk-on
                      ) TO reported-customers.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  "! <p class="shorttext synchronized">Fax validieren</p>
  "! Gleiches Format wie Telefon
  METHOD validateFax.
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
      FIELDS ( Fax ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).

    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Fax IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Fax = ''. RETURN. ENDIF.

      IF lo_validator->zif_cs1_validation~is_fax_valid( ls_customer-Fax ) = abap_false.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific
                      ) TO failed-customers.
        APPEND VALUE #( %tky        = ls_customer-%tky
                         %state_area = 'VALIDATE_Phone'
                         %msg        = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = |Fax: { ls_customer-Fax } ist ungültig expected format:e.g. +494055448899| )
                        %element-Fax = if_abap_behv=>mk-on
                      ) TO reported-customers.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  "! <p class="shorttext synchronized">Leerzeichen aus Email entfernen</p>
  "! Läuft bei MODIFY, also sofort bei Eingabe
  METHOD trimEmail.
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
        FIELDS ( Email ) WITH CORRESPONDING #( keys )
        RESULT DATA(lt_customers).

    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Email IS NOT INITIAL.
      DATA(lv_email) = ls_customer-Email.
      CONDENSE lv_email NO-GAPS.

      " Nur updaten wenn sich was geändert hat
      IF lv_email <> ls_customer-Email.
        MODIFY ENTITIES OF zr_cs1_customers IN LOCAL MODE
          ENTITY customers
            UPDATE FIELDS ( Email )
            WITH VALUE #( ( %tky  = ls_customer-%tky
                            Email = lv_email ) ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  "! <p class="shorttext synchronized">Zielwährung validieren</p>
  "! Pflichtfeld + Existenz in I_CurrencyStdVH
  METHOD validateCurrencyTarget.
    " 1. CurrencyTarget lesen
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
        FIELDS ( CurrencyTarget )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).

    " 2. Alle eingegebenen Währungen sammeln für Massen-Check
    DATA(lt_curr_filter) = lt_customers.
    DELETE lt_curr_filter WHERE CurrencyTarget IS INITIAL.
    SORT lt_curr_filter BY CurrencyTarget.
    DELETE ADJACENT DUPLICATES FROM lt_curr_filter COMPARING CurrencyTarget.

    " 3. Einmalig gegen SAP-Standardwährungen prüfen
    TYPES: BEGIN OF ty_s_currency,
             Currency TYPE I_CurrencyStdVH-Currency,
           END OF ty_s_currency.
    DATA lt_valid_currencies TYPE HASHED TABLE OF ty_s_currency WITH UNIQUE KEY Currency.

    IF lt_curr_filter IS NOT INITIAL.
      SELECT Currency FROM I_CurrencyStdVH
        FOR ALL ENTRIES IN @lt_curr_filter
        WHERE Currency = @lt_curr_filter-CurrencyTarget
        INTO TABLE @lt_valid_currencies.
    ENDIF.

    " 4. Jede Zeile validieren
    LOOP AT lt_customers ASSIGNING FIELD-SYMBOL(<ls_customer>).
      " Check 1: Pflichtfeld
      IF <ls_customer>-CurrencyTarget IS INITIAL.
        APPEND VALUE #( %tky = <ls_customer>-%tky ) TO failed-customers.
        APPEND VALUE #( %tky = <ls_customer>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Bitte wählen Sie eine Zielwährung aus.' )
                        %element-currencytarget = if_abap_behv=>mk-on ) TO reported-customers.
        CONTINUE.
      ENDIF.

      " Check 2: Existiert Währung?
      IF NOT line_exists( lt_valid_currencies[ Currency = <ls_customer>-CurrencyTarget ] ).
        APPEND VALUE #( %tky = <ls_customer>-%tky ) TO failed-customers.
        APPEND VALUE #( %tky = <ls_customer>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |Währung { <ls_customer>-CurrencyTarget } entspricht keinem gültigen Suchhilfeeintrag!| )
                        %element-currencytarget = if_abap_behv=>mk-on ) TO reported-customers.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  "! <p class="shorttext synchronized">SalesVolume in Zielwährung umrechnen</p>
  "! Nutzt cl_exchange_rates für Umrechnung
  METHOD SalesVolume.
*    " 1. Relevante Felder lesen
*    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
*      ENTITY customers
*        FIELDS ( SalesVolume Currency CurrencyTarget )
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_customers).
*
*    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
*    DATA lt_customers_update TYPE TABLE FOR UPDATE zr_cs1_customers\\customers.
*
*    " 2. Für jeden Kunden umrechnen
*    LOOP AT lt_customers ASSIGNING FIELD-SYMBOL(<fs_customer>).
*      " Nur wenn alle Felder gefüllt
*      IF <fs_customer>-SalesVolume    IS INITIAL OR
*         <fs_customer>-Currency       IS INITIAL OR
*         <fs_customer>-CurrencyTarget IS INITIAL.
*        CONTINUE.
*      ENDIF.
*
*      DATA lv_converted_amount TYPE zr_cs1_customers-SalesVolumeTarget.
*
*      TRY.
*          " Standard SAP Währungsumrechnung
*          cl_exchange_rates=>convert_to_foreign_currency(
*            EXPORTING
*              local_amount     = <fs_customer>-SalesVolume
*              local_currency   = <fs_customer>-Currency
*              foreign_currency = <fs_customer>-CurrencyTarget
*              date             = lv_today
*            IMPORTING
*              foreign_amount   = lv_converted_amount
*          ).
*
*          " Für Massen-Update sammeln
*          APPEND VALUE #( %tky              = <fs_customer>-%tky
*                          SalesVolumeTarget = lv_converted_amount
*                          %control-SalesVolumeTarget = if_abap_behv=>mk-on ) TO lt_customers_update.
*
*        CATCH cx_exchange_rates INTO DATA(lx_rates).
*          " Fehler wenn kein Kurs vorhanden
*          APPEND VALUE #( %tky = <fs_customer>-%tky
*                          %msg = zcx_cs1_customer_failed=>new_message(
*                                   i_textid   = zcx_cs1_customer_failed=>Umrechnungsfehler
*                                   i_severity = if_abap_behv_message=>severity-error
*                                   i_v1       = <fs_customer>-CurrencyTarget
*                                   i_v4       = |{ <fs_customer>-SalesVolume }| )
*                        ) TO reported-customers.
*      ENDTRY.
*    ENDLOOP.
*
*    " 3. Ein Massen-Update statt Loop-Updates
*    IF lt_customers_update IS NOT INITIAL.
*      MODIFY ENTITIES OF zr_cs1_customers IN LOCAL MODE
*         ENTITY customers
*           UPDATE FIELDS ( SalesVolumeTarget )
*           WITH lt_customers_update.
*    ENDIF.
  ENDMETHOD.

  "! <p class="shorttext synchronized">Default-Werte setzen</p>
  "! Language=D, CurrencyTarget=EUR wenn initial
  METHOD setDefaults.
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
        FIELDS ( Language CurrencyTarget )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).

    " Nur setzen wenn beide leer - überschreibt keine User-Eingabe
    MODIFY ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
        UPDATE FIELDS ( Language CurrencyTarget )
        WITH VALUE #( FOR customer IN lt_customers
                         WHERE ( Language IS INITIAL AND CurrencyTarget IS INITIAL )
                         ( %tky           = customer-%tky
                           Language       = 'D'
                           CurrencyTarget = 'EUR' ) ).
  ENDMETHOD.

  "! <p class="shorttext synchronized">Action: Bestellungen stornieren</p>
  "! Ändert Status von B* auf S* für alle Orders des Kunden
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

      " 1. Alle offenen Bestellungen Status B* lesen
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

      " 2. Erstes Zeichen B -> S: BN01 -> SN01
      LOOP AT lt_orders_to_update ASSIGNING FIELD-SYMBOL(<ls_order>).
        <ls_order>-status+0(1) = 'S'.
      ENDLOOP.

      " 3. Status per EML updaten
      MODIFY ENTITIES OF zr_cs1_custorders000
        ENTITY custorders
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR ls_order IN lt_orders_to_update
                      ( Orderid = ls_order-orderid
                        Status  = ls_order-status ) )
        FAILED DATA(lt_failed).

      " 4. Erfolgs/Fehlermeldung
      IF lt_failed-custorders IS NOT INITIAL.
        APPEND VALUE #( %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text = |Fehler beim Stornieren der Bestellungen| )
                      ) TO reported-customers.
      ELSE.
        APPEND VALUE #( %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-success
                          text = |{ lines( lt_orders_to_update ) } Bestellungen Stioniert für Kunde { lv_customerid } | )
                      ) TO reported-customers.
      ENDIF.
    ENDLOOP.

    result = VALUE #( FOR key IN keys ( %cid = key-%cid ) ).


  ENDMETHOD.


  "Statistiken dynamisch berechnen
  "Liest Klasse+Interface aus ZCS1_STATISTIC und ruft Methoden dynamisch auf

METHOD showstatistics.
    " 1. Kunden lesen
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
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

*    ENDLOOP.

  ENDMETHOD.


ENDCLASS.

"! <p class="shorttext synchronized">Late Numbering für CustomerId</p>
CLASS lsc_zr_cs1_customers DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS adjust_numbers REDEFINITION.
ENDCLASS.

CLASS lsc_zr_cs1_customers IMPLEMENTATION.
  METHOD adjust_numbers.
    " Bei Create ohne CustomerId: Nummer aus Nummernkreis ziehen
    DATA(lo_num) = NEW zcl_cs1_customer_import( ).
    LOOP AT mapped-customers ASSIGNING FIELD-SYMBOL(<ls_mapped>)
         USING KEY primary_key
         WHERE CustomerId IS INITIAL.
      DATA(lv_next) = lo_num->zif_cs1_validation~latenumbering( ).
      <ls_mapped>-CustomerId = |{ lv_next ALPHA = IN }|.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
