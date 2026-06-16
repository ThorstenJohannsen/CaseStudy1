@EndUserText.label: 'T210 Übergabe der OrderTotal für SalesVolume'
define abstract entity ZCS1_A_UpdateSalesVolumen
{
    key customerid      : zcustomerid1;
    // Die Annotationen verknüpfen den Betrag mit dem Währungsfeld
    @Semantics.amount.currencyCode: 'Currency'
    sales_volume        : zorder_total1;
    // Die Annotationen verknüpfen den Betrag mit dem Währungsfeld
    @Semantics.amount.currencyCode: 'Currency'
    sales_volume_target : zorder_total1;
    // Technisches Referenzfeld für die Syntaxprüfung
    Currency            : abap.cuky(5); 
}
