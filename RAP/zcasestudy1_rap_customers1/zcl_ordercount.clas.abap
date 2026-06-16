CLASS zcl_ordercount DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ordercount IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~calculate.
      DATA lt_original_data   TYPE STANDARD TABLE OF ZC_CS1_CUSTOMERS.
      DATA lt_calculated_data TYPE STANDARD TABLE OF ZC_CS1_CUSTOMERS.

      lt_original_data   = CORRESPONDING #( it_original_data ).
      lt_calculated_data = CORRESPONDING #( it_original_data ).

      IF lt_original_data IS INITIAL.
        RETURN.
      ENDIF.

      " 1. IDs sauber über ein Range-Konstrukt sammeln (Cloud-Standard)
      DATA lt_customer_range TYPE RANGE OF ZC_CS1_CUSTOMERS-customerid.

      lt_customer_range = VALUE #(
        FOR ls_orig IN lt_original_data
        ( sign = 'I' option = 'EQ' low = ls_orig-customerid )
      ).

      " 2. Aggregierter SELECT über die Datenbank (ohne FOR ALL ENTRIES)
      SELECT customerid, COUNT(*) AS ordercount
        FROM zcs1_custorders
        WHERE customerid IN @lt_customer_range
        GROUP BY customerid
        INTO TABLE @DATA(lt_order_counts).

      " 3. Das virtuelle Feld befüllen
      LOOP AT lt_calculated_data ASSIGNING FIELD-SYMBOL(<ls_calc>).
        " inline deklarierte Tabelle mit VALUE/LINE_EXISTS oder READ lesen
        READ TABLE lt_order_counts INTO DATA(ls_count)
          WITH KEY customerid = <ls_calc>-customerid.

        IF sy-subrc = 0.
          <ls_calc>-ordercount = |{ ls_count-ordercount }|.
        ELSE.
          <ls_calc>-ordercount = '0'.
        ENDIF.
      ENDLOOP.

      " 4. Daten zurückgeben
      ct_calculated_data = CORRESPONDING #( lt_calculated_data ).

  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.

*    " 1. Teilen Sie dem Framework mit, welches Datenbankfeld für die Berechnung gelesen werden muss
*    " Ersetzen Sie 'Customer' mit Ihrem tatsächlichen Schlüssel (z. B. Kunde oder Lieferant)
*    et_requested_orig_elements = VALUE #( BASE et_requested_orig_elements ( 'Customer' ) ).

  ENDMETHOD.

ENDCLASS.
