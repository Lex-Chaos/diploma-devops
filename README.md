# Дипломный практикум в Yandex.Cloud - Боровик А.А.

## Выполнение

### Подготовка

Задание выполнялось на виртуальной машине Ubuntu 24.04
На машине должны быть установлены:

- terraform v1.11.4
- ansible [core 2.18.6]
- docker version 28.2.2
- kubectl v1.32.6
- Python 3.12.3
- jq-1.7
- OpenSSL 3.0.13
- base64 9.4
- Yandex Cloud CLI 0.148.0 linux/amd64
- gh version 2.74.2
  
Кроме этого необходимо:

- На Yandex Cloud создать организацию, пользователя и папку для проекта
- Выполнить yc init (для аутентификации)
- Создать аккаунт на github
- Выполнить gh auth login  (для аутентификации)
- Создать аккаунт на dockerhub
- Выполнить docker login (для аутентификации)

### Создание инфраструктуры

В папке проекта выполнить скрипт [generate-auth.py](https://github.com/Lex-Chaos/diploma-devops/blob/main/generate-auth.py):

```python
python3 generate-auth.py
```

Произойдёт создание переменных для terraform в файлах `yandex-auth.auto.tfvars`:

![generate-auth.py](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/01-auth-generate.png)

После этого надо перейти в папку `terraform/sa-and-bucket/` и применить [манифесты создания сервисного аккаунта и бакета](https://github.com/Lex-Chaos/diploma-devops/blob/main/terraform/sa-and-buket):

```bash
terraform init
terraform apply
```

Произойдёт создание бакета и сервисного аккаунта:

![backet](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/02-backet-tfinit.png)

![generate-auth.py](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/03-backet-tfapply.png)

Далее необходимо перейти в папку `terraform/infrastruct` и применить [манифесты создания инфраструктуры](https://github.com/Lex-Chaos/diploma-devops/blob/main/terraform/infrastruct):

```bash
terrform apply
```

Будет сформирована инфраструктура:

![generate-auth.py](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/04-infr-tfapply.png)

![generate-auth.py](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/05-yandex-infr.png)

В процессе создания инфраструктуры формируется файл inventory для работы с ansible.

### Создание кластера

Необходимо подождать некоторое время (в инстансах устанавливаются необходимые пакеты), перейти в папку `ansible/` и применить [манифест создания кластера](https://github.com/Lex-Chaos/diploma-devops/blob/main/ansible):

```bash
ansible-playbook -i inventory k8s-cluster.yml
```

Будет создан кластер из одной maste-ноды и двух worker-нод:

![cluster](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/06-ansible-cluster.png)

После этого для формирования необходимых секретов в github нужно выполнить в корневой папке проекта скрипт [set-secrets.sh](https://github.com/Lex-Chaos/diploma-devops/blob/main/set-secrets.sh):

![set-secrets.sh](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/07-set-secrets.png):

### Установка мониторинга

Необходимо перейти в папку [monitor/](https://github.com/Lex-Chaos/diploma-devops/blob/main/monitor): и выполнить установку `helm`:

```bash
ansible-playbook -i ../ansible/inventory helm-install.yml
```

А затем установку системы мониторинга:

```bash
ansible-playbook -i ../ansible/inventory monitoring.yml
```

Дашборды grafana доступны по адресу, выведенному по окончании формирования инфраструктуры (логин: admin, пароль: admin):

![grafana](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/08-grafana.png)

### Создание образа тестового приложения

Необходимо перейти в папку `docker` [docker](https://github.com/Lex-Chaos/diploma-devops/blob/main/docker) и выполнить:

```bash
docker build -t $DOCKERHUB_USERNAME/diploma-nginx-app:latest -f nginx-app.dockerfile .
```

Будет создан образ приложения:

![image](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/09-app-image.png)

После необходимо отправить его в `dockerhub`:

```bash
docker push $DOCKERHUB_USERNAME/diploma-nginx-app:latest
```

![imagepush](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/10-app-imagepush.png)

Образ появится в репозитории:

![dockerhub](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/11-dockerhub.png)

### Установка тестового приложения

Необходимо перейти в папку [app/](https://github.com/Lex-Chaos/diploma-devops/blob/main/app) и выполнить:

```bash
sed "s|\${DOCKERHUB_USERNAME}|$DOCKERHUB_USERNAME|g" app-deployment.yml | kubectl apply -f -
```

Приложение развернётся в пространстве `app`:

![app](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/12-app-in-namespace.png)

И будет доступно по адресу, полученному после создания инфраструктуры:

![page1](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/13-page1.png)

### CI/CD

1.После изменения файлов инфраструктуры отправим коммит в репозиторий:

![infr git push](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/14-infr-git-push.png)

![infr changed](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/15-infr-change.png)

Запуск [workflow](https://github.com/Lex-Chaos/diploma-devops/blob/main/.github/workflows/infrastruct.yml) произойдёт только еcли файлы инфраструктуры были изменены.

Создастся артефакт, который потом можно использовать для работы с `ansible`:

![artefact](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/16-artefact.png)

2.Изменим файл страницы и отправим проект в репозиторий:

![build-push](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/17-build-git-push.png)

Запуск [workflow](https://github.com/Lex-Chaos/diploma-devops/blob/main/.github/workflows/build.yml) произойдёт только при изменении файлов для приложения.

![build change](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/18-build-change.png)

В репозитории появится образ с тегом:

![build dockerhub](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/19-build-hub.png)

3.Изменим файл страницы и отправим в репозиторий с тегом:

![deploy-push](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/20-deploy-git-push.png)

Запуск [workflow](https://github.com/Lex-Chaos/diploma-devops/blob/main/.github/workflows/deploy.yml) произойдёт только при изменении файлов для приложения, деплоя и добавлении тега.

![debloy change](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/21-deploy-change.png)

В репозитории появится образ с тегом и обновится образ latest:

![deploy dockerhub](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/22-deploy-hub.png)

Страница обновилась:

![page-final](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/23-page-final.png)

### Удаление инфраструктуры

Удаляю инфраструктуру:

![infr destroy](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/24-infr-destroy.png)

И бакет:

![bucket destroy](https://github.com/Lex-Chaos/diploma-devops/blob/main/img/25-bucket-destroy.png)