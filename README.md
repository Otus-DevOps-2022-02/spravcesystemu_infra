Исследовать способ подключения к someinternalhost в одну команду из вашего рабочего устройства, проверить работоспособность найденного решения и внести его в README.md в вашем репозитории Дополнительное задание:Дополнительное задание: Предложить вариант решения для подключения из консоли при помощи команды вида ssh someinternalhost из локальной консоли рабочего устройства, чтобы подключение выполнялось по алиасу someinternalhost и внести его в README.md в вашем репозитории


Нужно создать config file в ~/.ssh/ следующего вида:

  Host someinternalhost
  Hostname 10.128.0.7
  User appuser1
  IdentityFile ~/.ssh/vika
  ProxyCommand ssh -W %h:%p bastion

А также в файле ~/.bashrc прописать alias someinternalhost='ssh someinternalhost.

Подсматривала в эту статью https://dev.to/aws-builders/ssh-setup-and-tunneling-via-bastion-host-3kcc 




https://docs.pritunl.com/docs/installation 
