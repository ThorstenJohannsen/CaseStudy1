@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZCS1_STATISTIC'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_CS1_STATISTIC
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_CS1_STATISTIC
  association [1..1] to ZR_CS1_STATISTIC as _BaseEntity on $projection.STATID = _BaseEntity.STATID
{
  key StatID,
  InterfaceName,
  ClassName,
  Active,
  @Semantics: {
    User.Createdby: true
  }
  CreatedBy,
  @Semantics: {
    Systemdatetime.Createdat: true
  }
  CreatedAt,
  @Semantics: {
    User.Localinstancelastchangedby: true
  }
  LocalLastChangedBy,
  @Semantics: {
    Systemdatetime.Localinstancelastchangedat: true
  }
  LocalLastChangedAt,
  @Semantics: {
    Systemdatetime.Lastchangedat: true
  }
  LastChangedAt,
  _BaseEntity
}
