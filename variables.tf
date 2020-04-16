variable "vpc_basename" {
  description = "Denotes the name of the VPC that IBM Visual Insights will be deployed into. Resources associated with IBM Visual Insights will be prepended with this name. Keep this at 25 characters or fewer."
  default = "ibm-tensorflow"
}

variable "boot_image_name" {
  description = "name of the base image for the virtual server (should be an Ubuntu 18.04 base)"
  default = "ibm-ubuntu-18-04-3-minimal-ppc64le-2"
}

variable "vpc_region" {
  description = "Target region to create this instance of IBM Visual Insights. Valid values are 'us-south' only at this time."
  default = "us-south"
}

variable "vpc_zone" {
  description = "Target availbility zone to create this instance of IBM Visual Insights. Valid values are 'us-south-1' 'us-south-2' or 'us-south-3' at this time."
  default = "us-south-2"
}

variable "vm_profile" {
  description = "What resources or VM profile should we create for compute? 'gp2-24x224x2' provides 2 GPUs, and 'gp2-32x256x4' provides 4 GPUs. Valid values must be POWER9 GPU profiles from https://cloud.ibm.com/docs/vpc?topic=vpc-profiles#gpu ."
  default = "gp2-24x224x2"
}

variable "icos_bucket" {
  description = "Name of the ICOS bucket where results are written"
  default = "tensorflow-results"
}

variable "icos_endpoint" {
  description = "IBM Cloud Object Storage endpoint"
}

variable "icos_key" {
  description = "IBM Cloud Object Stoage key"
}

variable "icos_secret" {
  description = "IBM Cloud Object Storage secret"
}