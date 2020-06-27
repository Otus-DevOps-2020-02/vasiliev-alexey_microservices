# vasiliev-alexey_microservices
vasiliev-alexey microservices repository


###  **Kubernetes. Мониторинг и логирование**
1. Установлен Prometheus с помощью helm chart'а.
2. Настроены сборки метрик с приложений для Prometheus.
3.  Установлена Grafana.
4.  Настроены графики для различных пространств и разверток с использованием variables (dashboard'ы приведены в kubernetes/Grafana_dashboard).
5.  Установлен Elasticksearch с Kibana.



###  **CI/CD в Kubernetes**

1.  Установлен helm версии 2 и 3.
2.  Создан манифест Tiller и применен к инфраструктуре kubernetes.
3.  Созданы Chart'ы для компонентов приложения.
4.  Проинсталлировано приложение и все его компоненты с использованием helm.  
5.  Настроено взаимодействие между компонентами через общий Chart.
6.  Установлен gitlab с omnibus с помощью Helm. (нужно не забывать ставить галочку про устаревшие права в GCE).
7.  Созданы проекты UI, Comment и Post для создания через pipeline gitlab контейнеров этих приложний и заливка их в dockerhub.
8.  Создан центральный проект reddit-deploy для автоматического развертывания инфраструктуры в разных environment'ах.
9.  Для каждого приложения создан свой .gitlab-ci.yml конфиг для разных pipeline.
10. Модернизированы .gitlab-ci.yml конфиги всех приложений для развертывания с разных версий helm.




###  **Kubernetes: Networks, Storages**
1. Детально изучили абстракцию Service
2. Изучили тип подключения ClusterIP
3. Изучили тип подключения NodePort
4. Изучили тип подключения LoadBalancer
5. Изучили тип подключения Ingress
5. Изучили конфигурацию Secret
6. Настроили TLS Termination
7. Настроили Network Policy для нашего приложения в GKE
8. Изучили механизмы хранения данных (Volume): emptyDir, gcePersistentDisk
9. Изучили механизм выделения и нахначения ресурсов хранения для K8s: PersistentVolume, PersistentVolumeClaim  

__
###  **Основные модели безопасности и контроллеры в Kubernetes**

1. Установили локально cubectl , minicube
2. Ознакомились со конфигурацией и структурой  комманд Kubectl
3. Изменили созданные ранее Deployment-ы приложения reddit
4. Задеплоили их на кластер и сконфигурровали для работы готового приложения
5. Создали ресурсы с типом Services - для сетевого взапимодействия Pod-ов
6. Создали свой Namespaces  dev - и развернули там  отдельную версию
7. Развернули кластер  Kubernetes в GKE
8. Создали проект для создания клатсера из  terraform

___
###  **Введение в Kubernetes**
1. Установили Kubernetes (5 бинарников и куча конфигов :) ). В связи с лимитам GCE (4 публичных IP  адреса) - пришлось сократить до 4 нод. [Журнал работ по лекциям](kubernetes/the_hard_way/k8s_hard_way.md)
2. Создали конфиги деплоя микросервисов приложения reddit
3. Протестировали что все конфиги успешно деплоятся на созданный кластер

___
###  **Логирование и распределенная трассировка**
1. Установлен код измененного приложения
2. Создан и настроен контейнер fluentd для сбора лог сообщений и пересылки их в контейнер с Elasticsearch
3. Настроено развертывания контейнера Elasticsearch и Kibana для сбора логов и отображения в графическом виде
4. Настроен сбор лог сообщений с сервисов post и ui с использованием fluentd
5. Рассмотрено отображение лог сообщений в elasticsearch и kibana
6. Настроен парсинг лог сообщений с использованием конфигурации fluentd при помощи json формата отображения логов, grok патернов и регулярных выражений
7. Рассмотрен вариант отслеживания проблем и задержек в web приложении с использование zipkin.
8. В задании со * была анализирована причина некоректного работа микросервиса post. С применением инструментов Zipkin и git diff была найдена ошибка в коде создающая проблему в задержки открытия поста на портале. При запросе записи в БД процесс засыпал на 3 секунды.Найденная фукнция time.sleep(3) в коде (post_app.py 167):

        app.post_read_db_seconds.observe(resp_time)
        time.sleep(3)
        log_event('info', 'post_find',
                  'Successfully found the post information',
                  {'post_id': id})

___
###  **Введение в мониторинг. Системы мониторинга**
1. Развернули контейнер с Prometheus - посмотрели его встроенные метрики
2. В ранее созадную конфигурацию микросервисов внесли сервис по мониторингу,  и проверили что они выключились в  endpoint
3. Поигрались с health-checks для нашей конфигурации микросервисов
4. Добавили NodeExporter  в конфигурацию. проверили ее работу
5. Добавили MongoExporter  в конфигурацию. проверили ее работу
6. Добавили BlackboxExporter  в конфигурацию. проверили ее работу
7. Написали Makefile для сборки и отправки образов на hub

Ссылки на созданные образы:

https://hub.docker.com/r/avasiliev/ui
        https://hub.docker.com/r/avasiliev/comment
        https://hub.docker.com/r/avasiliev/post
        https://hub.docker.com/r/avasiliev/prometheus
        https://hub.docker.com/r/avasiliev/mongo_exporter
        https://hub.docker.com/r/avasiliev/blackbox_exporter

ДЗ*
1. Создан [Dockerfile](monitoring/mongo_exporter/Dockerfile) c mongo-exporter от Pecrona, подключен к сервисам
2. Создан [Dockerfile](monitoring/blackbox_exporter/Dockerfile)  подключен к сервисам
3. Создан [Makefile](Makefile)   для сборки и отгрузки контейнеров
___
###  **Мониторинг приложенияи инфраструктурыи инфраструктуры**
1. Создали отдельный docker-compose конфигурацию для сервисов мониторинга
2. Подключили сервис cAdvisor - и посмотриели на его работу
3. Подключили сервис Grafana, настроили источник данных Prometheus, импортировали дашборд
4. Создали свой  дашборд и добавили  туда несколько панелей с Графиками, Гистограммами, Перцнетилями
5. Построили панель с бизнес метриками
6. Добавили сервис с алертами, проверили его работспособность


Ссылки на созданные образы:

https://hub.docker.com/r/avasiliev/ui
        https://hub.docker.com/r/avasiliev/comment
        https://hub.docker.com/r/avasiliev/post
        https://hub.docker.com/r/avasiliev/prometheus
        https://hub.docker.com/r/avasiliev/mongo_exporter
        https://hub.docker.com/r/avasiliev/blackbox_exporter
        https://hub.docker.com/r/avasiliev/alertmanager

___
###  **Введение в мониторинг. Системы мониторинга**
1. Развернули контейнер с Prometheus - посмотрели его встроенные метрики
2. В ранее созадную конфигурацию микросервисов внесли сервис по мониторингу,  и проверили что они выключились в  endpoint
3. Поигрались с health-checks для нашей конфигурации микросервисов
4. Добавили NodeExporter  в конфигурацию. проверили ее работу
5. Добавили MongoExporter  в конфигурацию. проверили ее работу
6. Добавили BlackboxExporter  в конфигурацию. проверили ее работу
7. Написали Makefile для сборки и отправки образов на hub

Ссылки на созданные образы:

https://hub.docker.com/r/avasiliev/ui
        https://hub.docker.com/r/avasiliev/comment
        https://hub.docker.com/r/avasiliev/post
        https://hub.docker.com/r/avasiliev/prometheus
        https://hub.docker.com/r/avasiliev/mongo_exporter
        https://hub.docker.com/r/avasiliev/blackbox_exporter


ДЗ*
1. Создан [Dockerfile](monitoring/mongo_exporter/Dockerfile) c mongo-exporter от Pecrona, подключен к сервисам
2. Создан [Dockerfile](monitoring/blackbox_exporter/Dockerfile)  подключен к сервисам
3. Создан [Makefile](Makefile)   для сборки и отгрузки контейнеров
___
###  **Устройство Gitlab CI. Построение процесса непрерывной поставки**
1. Развернули Gitlab CI  через Docker образ в режиме Omnibus
2. Зашли под пользователем  root и скофигурировали  безопасноть.
3. Создали группу проектов homework и проект example
4. Добавили наши исходники в проект и запушили его на CI
5. Создали pipeline и поигрались с ним в  stag-и , job-ы, environment
6. Создали и зарегистрировали runner
7. Залили исходники  reddit. создали Job для  его сборки и деплоя
8. Сконфигурировали создание динамических окружений

ДЗ*
1.  Сконфигурирован build_job для сборки  docker образа
2.  Сконфигурирован deploy_dev_job для деплоя  docker образа
3.  Создан [скрипт для  создания runner](gitlab-ci/runners.sh)
4.  Настроена интеграция для  slack канала  https://devops-team-otus.slack.com/archives/CV7FRK4QM

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
1. Исходники монтируются через  volume
2. Используется параметризиорванная комманда запуска



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
