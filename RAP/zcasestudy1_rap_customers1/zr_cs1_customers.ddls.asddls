@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZCS1_CUSTOMERS'
@EndUserText.label: 'Customer'

@UI.headerInfo: { 
  typeName: 'Kunde',
  typeNamePlural: 'Kunden',
  title: { type: #STANDARD, value: 'Customerid' }, 
  description: { type: #STANDARD, value: 'Lastname' }
}


define root view entity ZR_CS1_CUSTOMERS
  as select from zcs1_customers as CUSTOMERS
  association [0..1] to I_Language as _Language on $projection.Language = _Language.Language
  association [0..1] to I_CurrencyStdVH as _Currency on $projection.Currency = _Currency.Currency
  association [0..1] to I_Country as _Country on $projection.Country = _Country.Country
  association [0..1] to ZCS1CUST_ORDERS_PPC as _OrderCount on $projection.Customerid = _OrderCount.Customerid
{
  key customerid            as Customerid,
      salutation            as Salutation,
      last_name             as LastName,
      first_name            as FirstName,
      company               as Company,
      street                as Street,
      city                  as City,
      
      @Consumption: {
        valueHelpDefinition: [ {
          entity.name: 'I_Country',
          entity.element: 'Country',
          useForValidation: true
        } ]
      }
      @ObjectModel.text.association: '_Country' // Referenz auf die Assoziation im View
      country               as Country,

      
      postcode              as Postcode,
      acc_lock              as AccLock,
      last_date             as LastDate,
      @Semantics.amount.currencyCode: 'Currency'
      sales_volume          as SalesVolume,
      @Semantics.amount.currencyCode: 'CurrencyTarget'
      sales_volume_target   as SalesVolumeTarget,
      change_rate_date      as ChangeRateDate,
      fax                   as Fax,
      phone                 as Phone,
      email                 as Email,
      url                   as Url,
      @ObjectModel.text.association: '_Currency' // Referenz auf die Assoziation im View
      currency              as Currency,
      @ObjectModel.text.association: '_Currency' // Referenz auf die Assoziation im View
      currency_target       as CurrencyTarget,

      @ObjectModel.text.association: '_Language' // Referenz auf die Assoziation im View
      language              as Language,
      weblogin              as Weblogin,
      webpw                 as Webpw,
      memo                  as Memo,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      
      _Language,
      _Country,
      _Currency,
      _OrderCount
}
