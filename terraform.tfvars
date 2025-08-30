project_id    = "pj-na2-hub-control-01-prd-zzf"
region        = "northamerica-northeast1"
source_bucket = "filemage-private-c567eaa0"

# Multiple files/prefixes, multiple destinations
jobs = {
  # Capital Markets: keep "cm-" in filename
  capital_markets = {
    dest_project     = "pj-na2-cap-markets-0xw"
    dest_bucket      = "sb-na2-cap-markets-0xw2"
    include_prefixes = ["filemage-private-c567eaa0/CM_","filemage-private-c567eaa0/cm_"]          # matches cm-report.csv, cm-foo/bar.txt, etc.
    exclude_prefixes = []               # optional
  }

  # AA example: multiple prefixes to same destination
  #aa = {
  #  dest_project     = "pj-na2-adv-analytics-gxd"
  #  dest_bucket      = "sb-na2-adv-analytics-gxd"
  #  include_prefixes = ["filemage-private-c567eaa0/AA_", "filemage-private-c567eaa0/aa_"]
  #}

  # AD Apps: two prefixes to one bucket
  #aiapps = {
  #  dest_project     = "pj-na2-adv-data-02c"
  #  dest_bucket      = "sb-na2-adv-data-02c"
  #  include_prefixes = ["filemage-private-c567eaa0/AD_", "filemage-private-c567eaa0/ad_"]
  #}

  # AD Apps: two prefixes to one bucket
  #aiapps = {
  #  dest_project     = "pj-na2-adv-data-02c"
  #  dest_bucket      = "sb-na2-adv-data-02c"
  #  include_prefixes = ["filemage-private-c567eaa0/AD_", "filemage-private-c567eaa0/ad_"]
  #}
}

overwrite_sink               = true
delete_source_after_transfer = true
