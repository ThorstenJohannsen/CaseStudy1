@AbapCatalog.sqlViewName: 'ZCS1_PLZ'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS (Data Definition) für PLZ und Stadt'
@Metadata.ignorePropagatedAnnotations: true

define view ZCS1_I_ZIPCITY as select from zcs1_zipcity
{
    key postcode as Postcode,
    city as City

    
}
