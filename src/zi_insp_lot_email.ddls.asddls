@AbapCatalog.sqlViewName: 'ZV_ILOT_EMAIL'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Inspection lot email'
@Metadata.allowExtensions: true
define root view ZI_INSP_LOT_EMAIL
  as select from yinsp_lot_email as email
{
  
  key email.lot_type,
  key email.plant,
  key email.emailid,
  email.to_cc
}
