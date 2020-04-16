data "ibm_is_image" "bootimage" {
    name =  var.boot_image_name
}

#Create a VPC for the application
resource "ibm_is_vpc" "vpc" {
  name = "${var.vpc_basename}-vpc1"
}

#Create a subnet for the application
resource "ibm_is_subnet" "subnet" {
  name = "${var.vpc_basename}-subnet1"
  vpc = ibm_is_vpc.vpc.id
  zone = var.vpc_zone
  ip_version = "ipv4"
  total_ipv4_address_count = 32
}

#Create an SSH key which will be used for provisioning by this template, and for debug purposes
resource "ibm_is_ssh_key" "public_key" {
  name = "${var.vpc_basename}-public-key"
  public_key = tls_private_key.vision_keypair.public_key_openssh
}

#Create a public floating IP so that the app is available on the Internet
resource "ibm_is_floating_ip" "fip1" {
  name = "${var.vpc_basename}-subnet-fip1"
  target = ibm_is_instance.vm.primary_network_interface.0.id
}

#Enable ssh into the instance for debug
resource "ibm_is_security_group_rule" "sg1-tcp-rule" {
  depends_on = [
    ibm_is_floating_ip.fip1
  ]
  group = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote = "0.0.0.0/0"


  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_instance" "vm" {
  name = "${var.vpc_basename}-vm1"
  image = data.ibm_is_image.bootimage.id
  profile = var.vm_profile

  primary_network_interface {
    subnet = ibm_is_subnet.subnet.id
  }

  vpc = ibm_is_vpc.vpc.id
  zone = var.vpc_zone

  keys = [ibm_is_ssh_key.public_key.id]

  timeouts {
    create = "10m"
    delete = "10m"
  }

}

#Create a ssh keypair which will be used to provision code onto the system - and also access the VM for debug if needed.
resource "tls_private_key" "vision_keypair" {
  algorithm = "RSA"
  rsa_bits = "2048"
}

#Provision the app onto the system
resource "null_resource" "provisioners" {

  triggers = {
    vmid = "${ibm_is_instance.vm.id}"
  }

  depends_on = [
    ibm_is_security_group_rule.sg1-tcp-rule
  ]

  provisioner "file" {
    source = "scripts"
    destination = "/tmp"
    connection {
      type = "ssh"
      user = "root"
      agent = "false"
      timeout = "1m"
      host = ibm_is_floating_ip.fip1.address
      private_key = tls_private_key.vision_keypair.private_key_pem
    }
  }


  provisioner "file" {
    content = <<ENDENVTEMPL
#!/bin/bash -xe
export DOCKERMOUNT=/var/lib/docker
ENDENVTEMPL
    destination = "/tmp/scripts/env.sh"
    connection {
      type = "ssh"
      user = "root"
      agent = "false"
      timeout = "1m"
      host = ibm_is_floating_ip.fip1.address
      private_key = tls_private_key.vision_keypair.private_key_pem
    }
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/scripts*/*",
      "/tmp/scripts/ramdisk_docker_create.sh",
      "/tmp/scripts/wait_bootfinished.sh",
      "/tmp/scripts/install_gpu_drivers.sh",
      "/tmp/scripts/install_docker.sh",
      "/tmp/scripts/install_nvidiadocker2.sh",
      "/tmp/scripts/run_tensorflow_test.sh ${var.icos_endpoint} ${var.icos_key} ${var.icos_secret} ${var.icos_bucket}" 
    ]
    connection {
      type = "ssh"
      user = "root"
      agent = "false"
      timeout = "5m"
      host = ibm_is_floating_ip.fip1.address
      private_key = tls_private_key.vision_keypair.private_key_pem
    }
  }
}
