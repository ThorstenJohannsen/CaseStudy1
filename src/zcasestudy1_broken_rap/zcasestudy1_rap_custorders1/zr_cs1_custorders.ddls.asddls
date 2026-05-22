@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZCS1_CUSTORDERS'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_CS1_CUSTORDERS
  as select from zcs1_custorders as CUSTORDERS
  association [1..1] to ZR_CS1_CUSTOMERS as _Customer on $projection.Customerid = _Customer.Customerid
{
  key orderid as Orderid,
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_CS1_CUSTOMERS', element: 'Customerid' } }]
  customerid as Customerid,
  order_date as OrderDate,
  @Semantics.amount.currencyCode: 'Currency'
  order_total as OrderTotal,
  discount as Discount,
  info as Info,
  status as Status,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_CurrencyStdVH', 
    entity.element: 'Currency', 
    useForValidation: true
  } ]
  currency as Currency,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_CurrencyStdVH', 
    entity.element: 'Currency', 
    useForValidation: true
  } ]
//_Customer.CurrencyTarget as Currency_Target,

//  @Semantics.amount.currencyCode: 'Currency'
//  order_total_target as OrderTotalTarget,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  // Assoziation einfügen
  _Customer
}
