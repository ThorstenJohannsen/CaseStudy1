@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZCS1_ORDERITEMS'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_CS1_ORDERITEMS
  provider contract transactional_query
  as projection on ZR_CS1_ORDERITEMS
  association [1..1] to ZR_CS1_ORDERITEMS as _BaseEntity on $projection.Orderitem = _BaseEntity.Orderitem
{
  key Orderitem
//  Customerid,
//  Orderid,
//  Itemid,
//  Itemdescription,
//  @Semantics: {
//    Quantity.Unitofmeasure: 'Unit'
//  }
//  Quantity,
//  @Consumption: {
//    Valuehelpdefinition: [ {
//      Entity.Element: 'UnitOfMeasure', 
//      Entity.Name: 'I_UnitOfMeasureStdVH', 
//      Useforvalidation: true
//    } ]
//  }
//  Unit,
//  @Semantics: {
//    Amount.Currencycode: 'Currency'
//  }
//  Price,
//  @Semantics: {
//    Amount.Currencycode: 'Currency'
//  }
//  ItemTotal,
//  @Consumption: {
//    Valuehelpdefinition: [ {
//      Entity.Element: 'Currency', 
//      Entity.Name: 'I_CurrencyStdVH', 
//      Useforvalidation: true
//    } ]
//  }
//  Currency,
//  Info,
////  @Consumption: {
////    Valuehelpdefinition: [ {
////      Entity.Element: 'Currency', 
////      Entity.Name: 'I_CurrencyStdVH', 
////      Useforvalidation: true
////    } ]
////  }
////  CurrencyTarget,
////  @Semantics: {
////    Amount.Currencycode: 'CurrencyTarget'
////  }
////  ItemTotalTarget,
//  @Semantics: {
//    User.Createdby: true
//  }
//  CreatedBy,
//  @Semantics: {
//    Systemdatetime.Createdat: true
//  }
//  CreatedAt,
//  @Semantics: {
//    User.Localinstancelastchangedby: true
//  }
//  LocalLastChangedBy,
//  @Semantics: {
//    Systemdatetime.Localinstancelastchangedat: true
//  }
//  LocalLastChangedAt,
//  @Semantics: {
//    Systemdatetime.Lastchangedat: true
//  }
//  LastChangedAt,
//  _BaseEntity
}
