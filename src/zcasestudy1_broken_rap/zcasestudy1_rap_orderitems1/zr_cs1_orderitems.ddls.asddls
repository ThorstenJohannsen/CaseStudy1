@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZCS1_ORDERITEMS'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_CS1_ORDERITEMS
  as select from zcs1_orderitems as ORDERITEMS
{
  key orderitem as Orderitem
//  customerid as Customerid,
//  orderid as Orderid,
//  itemid as Itemid,
//  itemdescription as Itemdescription,
//  @Semantics.quantity.unitOfMeasure: 'Unit'
//  quantity as Quantity,
//  @Consumption.valueHelpDefinition: [ {
//    entity.name: 'I_UnitOfMeasureStdVH', 
//    entity.element: 'UnitOfMeasure', 
//    useForValidation: true
//  } ]
//  unit as Unit,
//  @Semantics.amount.currencyCode: 'Currency'
//  price as Price,
//  @Semantics.amount.currencyCode: 'Currency'
//  item_total as ItemTotal,
//  @Consumption.valueHelpDefinition: [ {
//    entity.name: 'I_CurrencyStdVH', 
//    entity.element: 'Currency', 
//    useForValidation: true
//  } ]
//  currency as Currency,
//  info as Info,
//  @Consumption.valueHelpDefinition: [ {
//    entity.name: 'I_CurrencyStdVH', 
//    entity.element: 'Currency', 
//    useForValidation: true
//  } ]
//  currency_target as CurrencyTarget,
//  @Semantics.amount.currencyCode: 'CurrencyTarget'
//  item_total_target as ItemTotalTarget,
//  @Semantics.user.createdBy: true
//  created_by as CreatedBy,
//  @Semantics.systemDateTime.createdAt: true
//  created_at as CreatedAt,
//  @Semantics.user.localInstanceLastChangedBy: true
//  local_last_changed_by as LocalLastChangedBy,
//  @Semantics.systemDateTime.localInstanceLastChangedAt: true
//  local_last_changed_at as LocalLastChangedAt,
//  @Semantics.systemDateTime.lastChangedAt: true
//  last_changed_at as LastChangedAt
}
