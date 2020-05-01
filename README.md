# vasiliev-alexey_microservices
vasiliev-alexey microservices repository

___
###  **Docker:  сети, docker-compose**
1. Изучили различные виды сетей  используемых в docker:
    - None
    - Host
    - bridge

2. Посомтрели на то как устроен  сетевой стек сетей docker
3. Изучили утилиту docker-compose и структуру docker-compose.yml
4. Сконфигурировали  приложение для использования сетей в compose-file и конфигурацию через env файлы

6. Задать имя проекта можно через переменную среды COMPOSE_PROJECT_NAME  или через параметр   -p, --project-name NAME при запуске docker-compose


ДЗ*
1. В процессе



___
###  **Домашнее задаание по теме Docker-образы && Микросервисы**
1. В VS-code  установили линтер Hadolint
2. Скачали исходники сайта и разместили их у  себя в репозитории
3. Создали на кадлый сервис по  Dockerfile и слепили из них образы
4. На основе созданных образов запустили сайт
5. Создали Docker Volume для MongoDb - для хранения состояния между перезапусками новых версий контейнеров
6. Убедились что сайт работает


ДЗ*
1. Создан файл с переменными. В запуске контейнеров  добавлен данный файл в качестве истоника данных об окружении.
2. Образы переведены на Alpine. Оптимизированы сблорки путем частичного уменьшеиня слоев и удалением кешей закачки пакетного менеджера apk

___
###  **Домашнее задаание по теме Технология контейнеризации. Введение в Docker**
1. Установили  docker-compose ( зачем ?) и docker-machine
2. Поигрались с   docker (изучили основные комманды)
3. Завели новый проект-песочницу в GCP
4. Через docker-machine в GCE - подняли новую машину с установленным  docker
5. Изучили примение Ansible  как провижининг в Packer
6. Создали Dockerfile  и сбилдили новый image
7. Через  docker-machine  развернули его в GCP
8. Затегировали образ, и залили его на  docker hub

ДЗ*
Выполнено

___
