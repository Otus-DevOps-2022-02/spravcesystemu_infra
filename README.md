# spravcesystemu_infra
spravcesystemu Infra repository


#  ДЗ №6 Практика IaC с использованием Terraform

1.Скачиваем и устанавливаем Terraform по ссылке https://www.terraform.io/downloads

2.Проверяем версию terraform -v

3.Создаем .gitignore со следующим содержимым

```
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
```

4.Создаем сервисный аккаунт YC
* https://cloud.yandex.ru/docs/iam/quickstart-sa
* https://cloud.yandex.com/en-ru/docs/iam/operations/iam-token/create-for-sa#keys-create

5.Редактируем main.tf и приводим его к такому виду:

```
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  resources {
    cores  = 2
    memory = 2
  }

boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = var.image_id
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = var.subnet_id
    nat       = true
  }
    metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

connection {
  type = "ssh"
  host = yandex_compute_instance.app.network_interface.0.nat_ip_address
  user = "ubuntu"
  agent = false
  # путь до приватного ключа
  private_key = file(var.private_key_path)
  }

provisioner "file" {
  source = "files/puma.service"
  destination = "/tmp/puma.service"
}

provisioner "remote-exec" {
  script = "files/deploy.sh"
  }
}
```

6.Содержимое terraform.tfvars

```
cloud_id = "xyz"
folder_id = "zyx"
zone = "ru-central1-a"
image_id = "yzx"
public_key_path = "~/.ssh/yc.pub"
subnet_id = "xxx"
service_account_key_file = "key.json"
private_key_path = "~/.ssh/yc"
instances = 1

```

7.Содержимое variables.tf

```
variable cloud_id {
  description = "Cloud"
}
variable folder_id {
  description = "Folder"
}
variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
variable region_id {
  description = "region"
  default     = "ru-central1"
}
variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable image_id {
  description = "Disk image"
}
variable subnet_id {
  description = "Subnet"
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
```

8. Содержимое outputs.tf

```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}

output "loadbalancer_ip_address" {
  value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
}
```
9.Использованные комманды

```
terraform taint yandex_compute_instance.app
terraform plan
terraform apply
terraform destroy -auto-approve
terraform apply -auto-approve
```
10.Задание с **

Создаем lb.tf, сначала необходимо создать target group
```
resource "yandex_lb_target_group" "loadbalancer" {
  name      = "lb-group"
  folder_id = var.folder_id
  region_id = var.region_id

  target {
    address = yandex_compute_instance.app.network_interface.0.ip_address
      subnet_id = var.subnet_id
  }
}
```
и сам балансировщик с указанимем target_group

```
resource "yandex_lb_network_load_balancer" "lb" {
  name = "loadbalancer"
  type = "external"

  listener {
    name        = "listener"
    port        = 80
    target_port = 9292

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.loadbalancer.id

    healthcheck {
      name = "tcp"
      tcp_options {
        port = 9292
      }
    }
  }
}
```

#  ДЗ №5 Сборка образов VM при помощи Packer

1.Создала новую ветку packer-base

2.Перенесла наработки в config-scripts

3.Создала сервисный аккаунт:

	$ yc config list
	$ SVC_ACCT="<придумайте имя>"
	$ FOLDER_ID="<замените на собственный>"
	$ yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID

4.Даем ему права editor

	$ ACCT_ID=$(yc iam service-account get $SVC_ACCT | \
				grep ^id | \
				awk '{print $2}')
	$ yc resource-manager folder add-access-binding --id $FOLDER_ID \
	    --role editor \
	    --service-account-id $ACCT_ID

5.Создала IAM key (хранить за пределами репозитория)

	$ yc iam key create --service-account-id $ACCT_ID --output <вставьте свой путь>/key.json

6.Далее создала Packer шаблон ubuntu16.json

```
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `key`}}",
            "folder_id": "xyz",
            "source_image_family": "ubuntu-1604-lts",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "use_ipv4_nat": "true",
            "disk_name": "reddit-base",
            "disk_size_gb": "20",
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}

```
7.Выполняем проверку и запускаем образ

	$ packer validate ./ubuntu16.json
	$ packer build ./ubuntu16.json

8.Построение bake-образа. image_family у получившегося образа reddit-full.

```

{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `key`}}",
            "folder_id": "{{user `fid`}}",
            "source_image_family": "{{user `image`}}",
            "image_name": "reddit-full-{{timestamp}}",
            "image_family": "reddit-full",
            "ssh_username": "ubuntu",
            "use_ipv4_nat": "true",
            "disk_name": "reddit-base",
            "disk_size_gb": "20",
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "file",
            "source": "files/puma.service",
            "destination": "/tmp/puma.service"
        },
        {
            "type": "shell",
            "inline": [
                "sudo mv /tmp/puma.service /etc/systemd/system/puma.service",

                "cd /opt",
                "sudo apt-get install -y git",
                "sudo chmod -R 0777 /opt",
                "git clone -b monolith https://github.com/express42/reddit.git",
                "cd reddit && bundle install",
                "sudo systemctl daemon-reload && sudo systemctl start puma && sudo systemctl enable puma"
            ]
        }
    ]
}

```


```

{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `key`}}",
            "folder_id": "{{user `fid`}}",
            "source_image_family": "{{user `image`}}",
            "image_name": "reddit-full-{{timestamp}}",
            "image_family": "reddit-full",
            "ssh_username": "ubuntu",
            "use_ipv4_nat": "true",
            "disk_name": "reddit-base",
            "disk_size_gb": "20",
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "file",
            "source": "files/puma.service",
            "destination": "/tmp/puma.service"
        },
        {
            "type": "shell",
            "inline": [
                "sudo mv /tmp/puma.service /etc/systemd/system/puma.service",

                "cd /opt",
                "sudo apt-get install -y git",
                "sudo chmod -R 0777 /opt",
                "git clone -b monolith https://github.com/express42/reddit.git",
                "cd reddit && bundle install",
                "sudo systemctl daemon-reload && sudo systemctl start puma && sudo systemctl enable puma"
            ]
        }
    ]
}

```


Смотрела сюда 
* https://github.com/puma/puma/blob/master/docs/systemd.md
* https://www.packer.io/docs/provisioners/file
* https://www.packer.io/docs/provisioners/shell

Смотрела сюда 
* https://github.com/puma/puma/blob/master/docs/systemd.md
* https://www.packer.io/docs/provisioners/file
* https://www.packer.io/docs/provisioners/shell


#  ДЗ №4 Деплой тестового приложения

testapp_IP = 51.250.73.28
testapp_port = 9292



``` yc compute instance create \ 
--name reddit-app \ 
--hostname reddit-app \ 
--memory=4 \ 
--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \ 
--network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \ 
--metadata serial-port-enable=1 \ 
--ssh-key ~/.ssh/appuser.pub \ 
--zone ru-central1-a \ 
--metadata-from-file=./setup.sh 
```

#  ДЗ №3 Знакомство с облачной инфраструктурой Yandex Cloud


Нужно создать config file в ~/.ssh/ следующего вида:

```  Host someinternalhost
  Hostname 10.128.0.7
  User appuser1
  IdentityFile ~/.ssh/vika
  ProxyCommand ssh -W %h:%p bastion 
  
  ```

А также в файле ~/.bashrc прописать 
``` alias someinternalhost='ssh someinternalhost.```

Подсматривала в эту статью https://dev.to/aws-builders/ssh-setup-and-tunneling-via-bastion-host-3kcc 

3) При установке Pritunl использовала официальную документацию https://docs.pritunl.com/docs/installation 
``` 
bastion_IP = 84.252.129.165
someinternalhost_IP = 10.128.0.7

```
  