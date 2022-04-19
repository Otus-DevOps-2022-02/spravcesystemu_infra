variable cloud_id {
  description = "Cloud"
}
variable folder_id {
  description = "Folder"
}
variable zone {
  description = "Zone"
  default = "ru-central1-a"
}
variable region_id {
  description = "region"
  default     = "ru-central1"
}
variable image_id {
  description = "Disk image"
}
variable service_account_key_file {
  description = "key .json"
}
variable private_key_path {
  description = "path to private key"
}
variable instances {
  description = "count instances"
  default     = 1
}
variable db_disk_image {
  description = "disk image for mongodb"
  default     = "reddit-db-base"
}
variable access_key {
  description = "key id"
  default = "ajeagqh9t8ies6lsl2op"
}
variable secret_key {
  description = "secret key"
  default = "YCNiX9Ptiyj_9Dphv8ML1EipONj2dA0nAZGMBJxb"
}
variable bucket_name {
  description = "bucket name"
  default = "spravcesystemu"
}

