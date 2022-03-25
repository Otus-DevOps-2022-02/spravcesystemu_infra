# spravcesystemu_infra
spravcesystemu Infra repository


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


