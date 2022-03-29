# spravcesystemu_infra
spravcesystemu Infra repository

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
  



