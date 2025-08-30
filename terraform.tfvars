project_id    = "pj-na2-hub-control-01-prd-zzf"
region        = "northamerica-northeast1"
source_bucket = "filemage-private-c567eaa0"

# Multiple files/prefixes, multiple destinations
jobs = {
  # Capital Markets: keep "cm-" in filename
  capital_markets = {
    dest_project     = "pj-na2-cap-markets-0xw"
    dest_bucket      = "sb-na2-cap-markets-0xw2"
    include_prefixes = ["filemage-private-c567eaa0/filemage-private-c567eaa0/CM_","filemage-private-c567eaa0/filemage-private-c567eaa0/cm_"]          # matches cm-report.csv, cm-foo/bar.txt, etc.
    exclude_prefixes = []               # optional
  }

  # HR example: multiple prefixes to same destination
  #hr = {
  #  dest_project     = "pj-na2-cap-markets-0xw"
  #  dest_bucket      = "sb-na2-cap-markets-0xw"
  #  include_prefixes = ["cm-", "people-"]
  #}

  # AI Apps: two prefixes to one bucket
  #aiapps = {
  #  dest_project     = "pj-na2-aiapps-01-prd"
  #  dest_bucket      = "aiapps-drop-na2"
  #  include_prefixes = ["na2-", "ai-"]
  #}
}

overwrite_sink               = true
delete_source_after_transfer = false
