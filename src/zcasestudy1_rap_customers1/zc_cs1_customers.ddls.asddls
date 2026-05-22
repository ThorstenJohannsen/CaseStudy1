@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: { label: 'Kundenverwaltung' }
@ObjectModel: { sapObjectNodeType.name: 'ZCS1_CUSTOMERS' }
@AccessControl.authorizationCheck: #MANDATORY

@UI: {
  headerInfo: {
    typeName: 'Kunde',
    typeNamePlural: 'Kunden',
    title: { type: #STANDARD, value: 'Customerid' },
    description: { value: 'Company' }
  }
}

define root view entity ZC_CS1_CUSTOMERS
  provider contract transactional_query
  as projection on ZR_CS1_CUSTOMERS
  association [1..1] to ZR_CS1_CUSTOMERS as _BaseEntity on $projection.Customerid = _BaseEntity.Customerid
{
  @UI.facet: [
    { id: 'Header', purpose: #HEADER, type: #FIELDGROUP_REFERENCE, targetQualifier: 'HeaderData', position: 10 },
    { id: 'General', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'General', label: 'Allgemeine Daten', position: 20 },
    { id: 'Address', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'Address', label: 'Adresse', position: 30 },
    { id: 'Contact', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'Contact', label: 'Kontakt', position: 40 },
    { id: 'Sales', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'Sales', label: 'Vertrieb', position: 50 },
    { id: 'Admin', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'Admin', label: 'Administration', position: 60 }
  ]

  @UI: { lineItem: [{ position: 10 }],
         identification: [{ position: 10 }],
         fieldGroup: [{ qualifier: 'HeaderData', position: 10 }] }
  @EndUserText.label: 'Kundennummer'
  key Customerid,

  @UI: { fieldGroup: [{ qualifier: 'General', position: 10 }] }
  @EndUserText.label: 'Anrede'
  Salutation,

  @UI: { fieldGroup: [{ qualifier: 'General', position: 20 }] }
  @EndUserText.label: 'Nachname'
  LastName,

  @UI: { fieldGroup: [{ qualifier: 'General', position: 30 }] }
  @EndUserText.label: 'Vorname'
  FirstName,

  @UI: { identification: [{ position: 20 }],
         fieldGroup: [{ qualifier: 'General', position: 40 }] }
  @EndUserText.label: 'Firma'
  Company,

  @UI: { fieldGroup: [{ qualifier: 'Address', position: 10 }] }
  @EndUserText.label: 'Straße'
  Street,

  @UI: { fieldGroup: [{ qualifier: 'Address', position: 20 }] }
  @EndUserText.label: 'Stadt'
  City,

  @Consumption: {
    valueHelpDefinition: [{ entity.name: 'I_Country', entity.element: 'Country', useForValidation: true }] }
  @ObjectModel.text.association: '_Country'
  @UI: { fieldGroup: [{ qualifier: 'Address', position: 40 }] }
  @EndUserText.label: 'Land'
  Country,

  @UI: { identification: [{ position: 30 }],
         fieldGroup: [{ qualifier: 'HeaderData', position: 20 }] }
  @EndUserText.label: 'Anzahl Bestellungen'
  @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_ORDERCOUNT'
  virtual ORDERCOUNT: abap.char(256),

  @UI: { fieldGroup: [{ qualifier: 'Address', position: 30 }] }
  @EndUserText.label: 'Postleitzahl'
  Postcode,

  @UI: { fieldGroup: [{ qualifier: 'Admin', position: 10 }] }
  @EndUserText.label: 'Gesperrt'
  AccLock,

  @UI: { fieldGroup: [{ qualifier: 'Admin', position: 20 }] }
  @EndUserText.label: 'Letzte Änderung'
  LastDate,

  @Semantics: { amount.currencyCode: 'Currency' }
  @UI: { fieldGroup: [{ qualifier: 'Sales', position: 10 }] }
  @EndUserText.label: 'Umsatz'
  SalesVolume,

  @Semantics: { amount.currencyCode: 'CurrencyTarget' }
  @UI: { fieldGroup: [{ qualifier: 'Sales', position: 20 }] }
  @EndUserText.label: 'Umsatz Zielwährung'
  SalesVolumeTarget,

  @UI: { fieldGroup: [{ qualifier: 'Sales', position: 30 }] }
  @EndUserText.label: 'Umrechnungsdatum'
  ChangeRateDate,

  @UI: { fieldGroup: [{ qualifier: 'Contact', position: 10 }] }
  @EndUserText.label: 'Fax'
  Fax,

  @UI: { fieldGroup: [{ qualifier: 'Contact', position: 20 }] }
  @EndUserText.label: 'Telefon'
  Phone,

  @UI: { fieldGroup: [{ qualifier: 'Contact', position: 30 }] }
  @EndUserText.label: 'E-Mail'
  Email,

  @UI: { fieldGroup: [{ qualifier: 'Contact', position: 40 }] }
  @EndUserText.label: 'Webseite'
  Url,

  @Consumption: { valueHelpDefinition: [{ entity.element: 'Currency', entity.name: 'I_CurrencyStdVH', useForValidation: true }] }
  @ObjectModel.text.association: '_Currency'
  @UI.hidden: true
  Currency,

  @Consumption: { valueHelpDefinition: [{ entity.element: 'Currency', entity.name: 'I_CurrencyStdVH', useForValidation: true }] }
  @ObjectModel.text.association: '_Currency'
  @UI.hidden: true
  CurrencyTarget,

  @ObjectModel.text.association: '_Language'
  @UI: { fieldGroup: [{ qualifier: 'Admin', position: 30 }] }
  @EndUserText.label: 'Sprache'
  Language,

  @UI: { fieldGroup: [{ qualifier: 'Admin', position: 40 }] }
  @EndUserText.label: 'Weblogin'
  Weblogin,

  @UI.hidden: true
  Webpw,

  @UI: { fieldGroup: [{ qualifier: 'Admin', position: 50 }], multiLineText: true }
  @EndUserText.label: 'Notiz'
  Memo,

  @UI.hidden: true
  @Semantics: { user.createdBy: true }
  CreatedBy,
  @UI.hidden: true
  @Semantics: { systemDateTime.createdAt: true }
  CreatedAt,
  @UI.hidden: true
  @Semantics: { user.localInstanceLastChangedBy: true }
  LocalLastChangedBy,
  @UI.hidden: true
  @Semantics: { systemDateTime.localInstanceLastChangedAt: true }
  LocalLastChangedAt,
  @UI.hidden: true
  @Semantics: { systemDateTime.lastChangedAt: true }
  LastChangedAt,

  _BaseEntity,
  _Language,
  _Country,
  _Currency,
  _OrderCount
}
