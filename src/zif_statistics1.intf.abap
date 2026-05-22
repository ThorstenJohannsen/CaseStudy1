INTERFACE zif_statistics1 PUBLIC.
  "! <p class="shorttext synchronized">Durchschnittlicher Umsatz Bestellungen im GJ pro Kunde</p>
  "! @parameter iv_gjahr | Geschäftsjahr
  "! @parameter iv_kunnr | Kundennummer
  "! @parameter rv_avg   | Durchschnitt
  METHODS average_sales
    IMPORTING iv_gjahr TYPE gjahr
              iv_kunnr TYPE zcustomerid1
    RETURNING VALUE(rv_avg) TYPE zorder_total1.

  "! <p class="shorttext synchronized">Maximaler Einzelumsatz pro Kunde</p>
  "! @parameter iv_kunnr | Kundennummer
  "! @parameter rv_max   | Maximaler Umsatz
  METHODS max_sales
    IMPORTING iv_kunnr TYPE zcustomerid1
    RETURNING VALUE(rv_max) TYPE zorder_total1.

  "! <p class="shorttext synchronized">Durchschnittlicher Umsatz pro Tag im GJ</p>
  "! @parameter iv_gjahr | Geschäftsjahr
  "! @parameter rv_day   | Durchschnitt pro Tag
  METHODS day_sales
    IMPORTING iv_gjahr TYPE gjahr
    RETURNING VALUE(rv_day) TYPE zorder_total1.
ENDINTERFACE.
