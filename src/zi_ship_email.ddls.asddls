@AbapCatalog.sqlViewName: 'ZV_SHIP_EMAIL'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@Metadata.allowExtensions: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Eway Bill Transport Data'

define root view ZI_SHIP_EMAIL
  as select from yship_email as email
{
  key email.emailid,
      email.to_cc
}
