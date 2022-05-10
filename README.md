# spravcesystemu_infra
spravcesystemu Infra repository

#  ДЗ №11 Разработка и тестирование Ansible ролей и плейбуков

    1.Устанавливаем Vagrant
    2.Описываем локальную инфраструктуру в Vagrantfile
    3.Дорабатываем роли и учимся использовать provisioner
    4.Переделываем deploy.yml
    5.Проверяем сборку в Vagrant
    6.Устанавливаем pip, а затем с помощью его virtualenv
    7.Устанавливаем все необходимые пакеты pip install -r requirements.txt
    8.Создаем заготовку molecule с помощью команды molecule init scenario --scenario-name default -r db -d vagrant
    9.Добавляем собственнные тесты
    10.Тестируем конфигурацию


#  ДЗ №10 Ansible: работа с ролями и окружениями

    1.Создаем ветку ansible-3
    2.С помощью ansible-galaxy создаем заготовки полроли
    3.Переводим наши плейбуки в роли
    4.Модифицируем плейбуки на запуск ролей
    5.Проверяем фунцкионал ролей
    6.Модифицируем ansible.cfg и вводим переменные окружения для сред prod и stage
    7.Организуем плейбуки согласно Best Practices
    8.Используем community роли на примере jdauphant.nginx
    9.Учимся использовать ansible-vault
    10.Проверяем функционал

#  ДЗ №9 Деплой и управление конфигурацией с Ansible

    1.Создаем ветку ansible-2
    2.Создаем плейбук reddit_app.yml заполняем его и тестируем
    3.Создаем плейбук на несколько сценариев reddit_app2.yml
    4.Разбиваем наш плейбук на несколько: app.yml, db.yml, deploy.yml и переименовываем наши старые плейбуки
    5.Модифицируем наши провижионеры в packer, меняеем их на ansible и перезапекаем образы, указываем новые образы в переменных терраформа.

#  ДЗ №8 Управление конфигурацией. Основные DevOps инструменты.Знакомство с Ansible

1.Устанавливаем python и ansible, проверяем версии
2.Создадим инвентори файл ansible/inventory , в котором укажем информацию о созданном инстансе приложения и параметры подключения к нему по SSH

```
appserver ansible_host=35.195.186.154 ansible_user=appuser \
ansible_private_key_file=~/.ssh/appuser
```
$ ansible appserver -i ./inventory -m ping

3.Создадим для удобства ansible.cfg

```
[defaults]
inventory = ./inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
```
4.Изменим инвентори
```
[app] # ⬅ Это название группы
appserver ansible_host=35.195.74.54 # ⬅ Cписок хостов в данной группе
[db]
dbserver ansible_host=35.195.162.174
```
5. Проверим выполнение команд

$ ansible app -m command -a 'ruby -v'
$ ansible app -m command -a 'bundler -v'
$ ansible app -m command -a 'ruby -v; bundler -v'

6.Создадим простой плейбук ansible/clone.yml и протестируем работу.

#  ДЗ №7 Принципы организации инфраструктурного кода и работа над инфраструктурой в команде на примере Terraform

1.Создаем branch terraform-2 и зададим IP для инстанса с приложением в виде внешнего ресурса. Для этого определим ресурсы yandex_vpc_network и yandex_vpc_subnet в конфигурационном файле main.tf

```
resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```
2. Для того чтобы использовать созданный IP адрес в нашем ресурсе VM нам необходимо сослаться на атрибуты ресурса, который этот IP создает, внутри конфигурации ресурса VM. В конфигурации ресурса VM определите, IP адрес для создаваемого
инстанса

```
network_interface {
subnet_id = yandex_vpc_subnet.app-subnet.id
nat = true
}
```
* $ terraform destroy --auto-approve
* $ terraform plan
* $ terraform apply --auto-approve

3.Далее необходимо создать два новых шаблона db.json и app.json в директории packer

При помощи шаблона db.json должен собираться образ VM, содержащий установленную MongoDB. Шаблон app.json должен использоваться для сборки образа VM, с установленными Ruby. 

```
            "image_name": "reddit-app-base-{{timestamp}}",
            "image_family": "reddit-app-base",

            "disk_name": "reddit-app-base",
```

4.Затем выполняем:

```
packer validate -var-file=./variables.json ./app.json
packer build -var-file=./variables.json ./app.json
packer validate -var-file=./variables.json ./db.json
packer build -var-file=./variables.json ./db.json
```
5.Разобьем конфиг main.tf на несколько конфигов. Создадим файл app.tf, куда вынесем конфигурацию для VM с приложением.
Нужно объявить переменную в variables.tf и задать в terraform.tfvars:

```
variable app_disk_image {
  description = "disk image for reddit app"
  default     = "reddit-app-base"
}
variable db_disk_image {
  description = "disk image for mongodb"
  default     = "reddit-db-base"
  
```
```
app_disk_image            = "reddit-app-base"
db_disk_image             = "reddit-db-base"
```

app.tf

```
resource "yandex_compute_instance" "app" {
name = "reddit-app"
labels = {
tags = "reddit-app"
}
resources {
cores = 1
memory = 2
}
boot_disk {
initialize_params {
image_id = var.app_disk_image
}
}
network_interface {
subnet_id = yandex_vpc_subnet.app-subnet.id
nat = true
}
```
db.tf

```
resource "yandex_compute_instance" "db" {
  name = "reddit-db"
  labels = {
    tags = "reddit-db"
  }

  resources {
    cores  = 1
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```
Оставляем в main.tf

```
provider "yandex" {
  version                  = "~> 0.43"
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}
```

outputs.tf

```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
output "external_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}
```
Проверяем

* $ terraform destroy --auto-approve
* $ terraform plan
* $ terraform apply --auto-approve

6.Разбивая нашу конфигурацию нашей инфраструктуры на отдельные конфиг файлы, мы готовили для себя почву для работы с модулями. Внутри директории terraform создаём директорию modules, в которой мы будет определять модули.


modules/db/variables.tf

```
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
  variable db_disk_image {
  description = "Disk image for reddit db"
  default = "reddit-db-base"
}
variable subnet_id {
description = "Subnets for modules"
}

```

modules/app/variables.tf

```
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default = "reddit-app-base"
}
variable subnet_id {
description = "Subnets for modules"
}

```

outputs.tf
```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```
И удаляем из дириктории app.tf, db.tf и vpc.tf

7. В main прописываем модули

```
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
module "app" {
  source          = "./modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  subnet_id       = var.subnet_id
}

module "db" {
  source          = "./modules/db"
  public_key_path = var.public_key_path
  db_disk_image   = var.db_disk_image
  subnet_id       = var.subnet_id
}

```
8.И редактируем outputs.tf

```
output "external_ip_address_app" {
  value = module.app.external_ip_address_app
}
output "external_ip_address_db" {
  value = module.db.external_ip_address_db
}

```
9.Чтобы начать использовать модули, нам нужно сначала их загрузить из указанного источника. В нашем случае источником модулей будет просто локальная папка на диске. Используем команду для загрузки модулей. В директории terraform: Модули будут загружены в директорию .terraform, в которой уже содержится провайдер source

```
terraform get
```

```
terraform plan; terraform apply --auto-approve

```
10.Всё то же самое делаем для stage

```
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
module "app" {
  source          = "../modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  subnet_id       = var.subnet_id
}

module "db" {
  source          = "../modules/db"
  public_key_path = var.public_key_path
  db_disk_image   = var.db_disk_image
  subnet_id       = var.subnet_id
}

```

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





ДЗ №5 Сборка образов VM при помощи Packer

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





ДЗ №4 Деплой тестового приложения

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

1 & 2) Исследовать способ подключения к someinternalhost в одну команду из вашего рабочего устройства, проверить работоспособность найденного решения и внести его в README.md в вашем репозитории Дополнительное задание:Дополнительное задание: Предложить вариант решения для подключения из консоли при помощи команды вида ssh someinternalhost из локальной консоли рабочего устройства, чтобы подключение выполнялось по алиасу someinternalhost и внести его в README.md в вашем репозитории


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
  



