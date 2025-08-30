project_id    = "pj-na2-hub-control-01-prd-zzf"
region        = "northamerica-northeast1"
source_bucket = "filemage-private-c567eaa0"

# Multiple files/prefixes, multiple destinations
jobs = {
  # Capital Markets
  capital_markets = {
    dest_project     = "pj-na2-cap-markets-0xw"
    dest_bucket      = "sb-na2-cap-markets-0xw2"
    include_prefixes = ["filemage-private-c567eaa0/CM_", "filemage-private-c567eaa0/cm_"]
    exclude_prefixes = []
  }

  # AA example: multiple prefixes to same destination
  adv_analytics = {
    dest_project     = "pj-na2-adv-analytics-gxd"
    dest_bucket      = "sb-na2-adv-analytics-gxd"
    include_prefixes = ["filemage-private-c567eaa0/DS_", "filemage-private-c567eaa0/ds_"]
    exclude_prefixes = []
  }

  # AD Apps: two prefixes to one bucket
  adv_data = {
    dest_project     = "pj-na2-adv-data-02c"
    dest_bucket      = "sb-na2-adv-data-02c"
    include_prefixes = ["filemage-private-c567eaa0/AD_", "filemage-private-c567eaa0/ad_"]
    exclude_prefixes = []
  }

  audit_ADV = {
    dest_project     = "pj-na2-audit-adv-p1v"
    dest_bucket      = "sb-na2-audit-adv-p1v"
    include_prefixes = ["filemage-private-c567eaa0/AU_", "filemage-private-c567eaa0/au_"]
    exclude_prefixes = []
  }

  ent_ai = {
    dest_project     = "pj-na2-ent-ai-ag-7ec"
    dest_bucket      = "sb-na2-ent-ai-ag-7ec"
    include_prefixes = ["filemage-private-c567eaa0/AG_", "filemage-private-c567eaa0/ag_"]
    exclude_prefixes = []
  }

  ent_digital = {
    dest_project     = "pj-na2-ent-digital-6wq"
    dest_bucket      = "sb-na2-ent-digital-6wq"
    include_prefixes = ["filemage-private-c567eaa0/ED_", "filemage-private-c567eaa0/ed_"]
    exclude_prefixes = []
  }

  innovation = {
    dest_project     = "pj-na2-innovation-ww4"
    dest_bucket      = "sb-na2-innovation-ww4"
    include_prefixes = ["filemage-private-c567eaa0/IN_", "filemage-private-c567eaa0/in_"]
    exclude_prefixes = []
  }

  opr_risk = {
    dest_project     = "pj-na2-opr-risk-pcw"
    dest_bucket      = "sb-na2-opr-risk-pcw"
    include_prefixes = ["filemage-private-c567eaa0/OR_", "filemage-private-c567eaa0/or_"]
    exclude_prefixes = []
  }

  translation = {
    dest_project     = "pj-na2-translation-cgy"
    dest_bucket      = "sb-na2-translation-cgy"
    include_prefixes = ["filemage-private-c567eaa0/TR_", "filemage-private-c567eaa0/tr_"]
    exclude_prefixes = []
  }

  us_dmo = {
    dest_project     = "pj-na2-us-dmo-ud-6m6"
    dest_bucket      = "sb-na2-us-dmo-ud-6m6"
    include_prefixes = ["filemage-private-c567eaa0/UD_", "filemage-private-c567eaa0/ud_"]
    exclude_prefixes = []
  }

}

overwrite_sink               = true
delete_source_after_transfer = true
