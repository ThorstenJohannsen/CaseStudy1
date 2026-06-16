@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T125 Max. Umsatz des Kunden'
@Metadata.ignorePropagatedAnnotations: true
define view entity zcs1cust_orders_max as select from zcs1_custorders
{
//    key orderid as Orderid,
    key cast( customerid as zcustomerid1 ) as Customerid, 
    
 // 1. Maximaler Brutto-Wert pro Kunde
    @Semantics.amount.currencyCode : 'Currency'    
    max(order_total) as OrderTotalMax,

    // 2. Rabatt-Betrag der maximalen Bestellung
    @Semantics.amount.currencyCode : 'Currency'
    cast( (cast(discount as abap.dec(15,2)) * cast(max(order_total) as abap.dec(15,2))) / 100 
          as abap.dec(15,2) ) as DiscountAmountMax,

    // 3. Berechnung: MaxOrderTotal - DiscountAmount
    @Semantics.amount.currencyCode : 'Currency'
     cast( cast(max(order_total) as abap.dec(15,2)) - 
          ( (cast(discount as abap.dec(15,2)) * cast(max(order_total) as abap.dec(15,2))) / 100 )
          as abap.dec(15,2) ) as OrderTotalDiscount,
    
    currency as Currency
  
}
group by
//    orderid,
//    order_total,
    discount,
    customerid,
    currency


