@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS für custorders'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity zcs1cust_orders_r 
with parameters
    @EndUserText.label: 'Bitte Kundennummer eingeben:'    
    p_customerid : zcustomerid1
//    @Environment.systemField: #SYSTEM_DATE
//    p_ActualDate : abap.dats
    
as select from zcs1_custorders
 association[1..1] to zcs1customers_r as _customers on $projection.Customerid = _customers.Customerid 
 
{
    key orderid as Orderid,
        
    
    cast( customerid as zcustomerid1 ) as Customerid, 
    order_date as OrderDate,
    @Semantics.amount.currencyCode : 'Currency'
    order_total as OrderTotal,
    discount as Discount,
    info as Info,
    status as Status,
    currency as Currency,
//    created_by as CreatedBy,
//    created_at as CreatedAt,
//    local_last_changed_by as LocalLastChangedBy,
//    local_last_changed_at as LocalLastChangedAt,
//    last_changed_at as LastChangedAt,
    _customers
}

where customerid = $parameters.p_customerid 
   or $parameters.p_customerid = '*'
