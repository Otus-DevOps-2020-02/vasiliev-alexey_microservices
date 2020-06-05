
1. Проверили  требования по утилитам
    gcloud


2. Устанавливаем утилиты:
   * для криптографии

            cfssl
            cfssljson
    * для управления k8s

             kubectl

3. Создаем облачную инфраструктуру

* создаем VPC:

        gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom
* создаем подсеть

        gcloud compute networks subnets create kubernetes \
        --network kubernetes-the-hard-way \
        --range 10.240.0.0/24
* создаем правило firewall для всех протоколов внутри сети

        gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
        --allow tcp,udp,icmp \
        --network kubernetes-the-hard-way \
        --source-ranges 10.240.0.0/24,10.200.0.0/16

 * создаем правило firewall для  протоколов SSH, ICMP,  HTTPS  со своей локальной машины

        gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
        --allow tcp:22,tcp:6443,icmp \
        --network kubernetes-the-hard-way \
        --source-ranges 89.255.68.29/32

* резервируем публичный IP

        gcloud compute addresses create kubernetes-the-hard-way \
        --region $(gcloud config get-value compute/region)

* создаем инстансы  Kubernetes Controllers

        for i in 0 1 ; do
        gcloud compute instances create controller-${i} \
            --async \
            --boot-disk-size 200GB \
            --can-ip-forward \
            --image-family ubuntu-1804-lts \
            --image-project ubuntu-os-cloud \
            --machine-type n1-standard-1 \
            --private-network-ip 10.240.0.1${i} \
            --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
            --subnet kubernetes \
            --tags kubernetes-the-hard-way,controller
        done

* создаем инстансы  Kubernetes Workers

        for i in 0 1 ; do
        gcloud compute instances create worker-${i} \
            --async \
            --boot-disk-size 200GB \
            --can-ip-forward \
            --image-family ubuntu-1804-lts \
            --image-project ubuntu-os-cloud \
            --machine-type n1-standard-1 \
            --metadata pod-cidr=10.200.${i}.0/24 \
            --private-network-ip 10.240.0.2${i} \
            --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
            --subnet kubernetes \
            --tags kubernetes-the-hard-way,worker
        done


4. Подготовка CA и создание сертификатов TLS

    Certificate Authority
    1.
        cat > ca-config.json <<EOF
            {
            "signing": {
                "default": {
                "expiry": "8760h"
                },
                "profiles": {
                "kubernetes": {
                    "usages": ["signing", "key encipherment", "server auth", "client auth"],
                    "expiry": "8760h"
                }
                }
            }
            }
            EOF

    2

            cat > ca-csr.json <<EOF
            {
            "CN": "Kubernetes",
            "key": {
                "algo": "rsa",
                "size": 2048
            },
            "names": [
                {
                "C": "US",
                "L": "Portland",
                "O": "Kubernetes",
                "OU": "CA",
                "ST": "Oregon"
                }
            ]
            }
            EOF

    3

        cfssl gencert -initca ca-csr.json | cfssljson -bare ca

    Client and Server Certificates

    1.

        cat > admin-csr.json <<EOF
            {
            "CN": "admin",
            "key": {
                "algo": "rsa",
                "size": 2048
            },
            "names": [
                {
                "C": "US",
                "L": "Portland",
                "O": "system:masters",
                "OU": "Kubernetes The Hard Way",
                "ST": "Oregon"
                }
            ]
            }
            EOF
    2.

        cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes \
        admin-csr.json | cfssljson -bare admin

    The Kubelet Client Certificates

       for instance in worker-0 worker-1; do
        cat > ${instance}-csr.json <<EOF
        {
        "CN": "system:node:${instance}",
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
            "C": "US",
            "L": "Portland",
            "O": "system:nodes",
            "OU": "Kubernetes The Hard Way",
            "ST": "Oregon"
            }
        ]
        }
        EOF

        EXTERNAL_IP=$(gcloud compute instances describe ${instance} \
        --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

        INTERNAL_IP=$(gcloud compute instances describe ${instance} \
        --format 'value(networkInterfaces[0].networkIP)')

        cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
        -profile=kubernetes \
        ${instance}-csr.json | cfssljson -bare ${instance}
        done

The Controller Manager Client Certificate

1.

        cat > kube-controller-manager-csr.json <<EOF
        {
        "CN": "system:kube-controller-manager",
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
            "C": "US",
            "L": "Portland",
            "O": "system:kube-controller-manager",
            "OU": "Kubernetes The Hard Way",
            "ST": "Oregon"
            }
        ]
        }
        EOF

2.

        cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes \
        kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

The Kube Proxy Client Certificate
1.

       cat > kube-proxy-csr.json <<EOF
        {
        "CN": "system:kube-proxy",
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
            "C": "US",
            "L": "Portland",
            "O": "system:node-proxier",
            "OU": "Kubernetes The Hard Way",
            "ST": "Oregon"
            }
        ]
        }
        EOF

2.

        cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes \
        kube-proxy-csr.json | cfssljson -bare kube-proxy

The Scheduler Client Certificate

1.

        cat > kube-scheduler-csr.json <<EOF
        {
        "CN": "system:kube-scheduler",
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
            "C": "US",
            "L": "Portland",
            "O": "system:kube-scheduler",
            "OU": "Kubernetes The Hard Way",
            "ST": "Oregon"
            }
        ]
        }
        EOF
2.

        cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes \
        kube-scheduler-csr.json | cfssljson -bare kube-scheduler

The Kubernetes API Server Certificate
1.

    KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

2.

    KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

3.

    cat > kubernetes-csr.json <<EOF
    {
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
        "C": "US",
        "L": "Portland",
        "O": "Kubernetes",
        "OU": "Kubernetes The Hard Way",
        "ST": "Oregon"
        }
    ]
    }
    EOF
4.

    cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
    -profile=kubernetes \
    kubernetes-csr.json | cfssljson -bare kubernetes

The Service Account Key Pair
1.

    cat > service-account-csr.json <<EOF
    {
    "CN": "service-accounts",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
        "C": "US",
        "L": "Portland",
        "O": "Kubernetes",
        "OU": "Kubernetes The Hard Way",
        "ST": "Oregon"
        }
    ]
    }
    EOF

2.


    cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    service-account-csr.json | cfssljson -bare service-account


Distribute the Client and Server Certificates

    for instance in worker-0 worker-1; do
    gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
    done

    for instance in controller-0 controller-1; do
        gcloud compute scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ${instance}:~/
    done


5. Создание конфигурационных файлов Kubernetes для аутентификации

* Устанавливаем Kubernetes Public IP Address

        KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
        --region $(gcloud config get-value compute/region) \
        --format 'value(address)')


* Генерируем файлы конфигурации  kubelet (The kubelet Kubernetes Configuration File)

        for instance in worker-0 worker-1 ; do
        kubectl config set-cluster kubernetes-the-hard-way \
            --certificate-authority=ca.pem \
            --embed-certs=true \
            --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
            --kubeconfig=${instance}.kubeconfig

        kubectl config set-credentials system:node:${instance} \
            --client-certificate=${instance}.pem \
            --client-key=${instance}-key.pem \
            --embed-certs=true \
            --kubeconfig=${instance}.kubeconfig

        kubectl config set-context default \
            --cluster=kubernetes-the-hard-way \
            --user=system:node:${instance} \
            --kubeconfig=${instance}.kubeconfig

        kubectl config use-context default --kubeconfig=${instance}.kubeconfig
        done

* формируем файлы конфигурации для kube-proxy

        kubectl config set-cluster kubernetes-the-hard-way \
            --certificate-authority=ca.pem \
            --embed-certs=true \
            --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
            --kubeconfig=kube-proxy.kubeconfig

        kubectl config set-credentials system:kube-proxy \
            --client-certificate=kube-proxy.pem \
            --client-key=kube-proxy-key.pem \
            --embed-certs=true \
            --kubeconfig=kube-proxy.kubeconfig

        kubectl config set-context default \
            --cluster=kubernetes-the-hard-way \
            --user=system:kube-proxy \
            --kubeconfig=kube-proxy.kubeconfig

        kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

* формируем файлы конфигурации для kube-controller-manager

        kubectl config set-cluster kubernetes-the-hard-way \
            --certificate-authority=ca.pem \
            --embed-certs=true \
            --server=https://127.0.0.1:6443 \
            --kubeconfig=kube-controller-manager.kubeconfig

        kubectl config set-credentials system:kube-controller-manager \
            --client-certificate=kube-controller-manager.pem \
            --client-key=kube-controller-manager-key.pem \
            --embed-certs=true \
            --kubeconfig=kube-controller-manager.kubeconfig

        kubectl config set-context default \
            --cluster=kubernetes-the-hard-way \
            --user=system:kube-controller-manager \
            --kubeconfig=kube-controller-manager.kubeconfig

        kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

* формируем файлы конфигурации для kube-scheduler

        kubectl config set-cluster kubernetes-the-hard-way \
            --certificate-authority=ca.pem \
            --embed-certs=true \
            --server=https://127.0.0.1:6443 \
            --kubeconfig=kube-scheduler.kubeconfig

        kubectl config set-credentials system:kube-scheduler \
            --client-certificate=kube-scheduler.pem \
            --client-key=kube-scheduler-key.pem \
            --embed-certs=true \
            --kubeconfig=kube-scheduler.kubeconfig

        kubectl config set-context default \
            --cluster=kubernetes-the-hard-way \
            --user=system:kube-scheduler \
            --kubeconfig=kube-scheduler.kubeconfig

        kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig



* формируем файлы конфигурации для пользователя admin

        kubectl config set-cluster kubernetes-the-hard-way \
            --certificate-authority=ca.pem \
            --embed-certs=true \
            --server=https://127.0.0.1:6443 \
            --kubeconfig=admin.kubeconfig

        kubectl config set-credentials admin \
            --client-certificate=admin.pem \
            --client-key=admin-key.pem \
            --embed-certs=true \
            --kubeconfig=admin.kubeconfig

        kubectl config set-context default \
            --cluster=kubernetes-the-hard-way \
            --user=admin \
            --kubeconfig=admin.kubeconfig

        kubectl config use-context default --kubeconfig=admin.kubeconfig

* Загружаем конфигурации на сервера worker

        for instance in worker-0 worker-1; do
        gcloud compute scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
        done

* Загружаем конфигурации на сервера controller

        for instance in controller-0 controller-1; do
        gcloud compute scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
        done


6. Генерируем конфиг и ключ шифрования данных

        ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

создаем encryption-config.yaml

        cat > encryption-config.yaml <<EOF
            kind: EncryptionConfig
            apiVersion: v1
            resources:
            - resources:
                - secrets
                providers:
                - aescbc:
                    keys:
                        - name: key1
                        secret: ${ENCRYPTION_KEY}
                - identity: {}
            EOF

деплоим ключ ноды controller

        for instance in controller-0 controller-1 ; do
        gcloud compute scp encryption-config.yaml ${instance}:~/
        done

7. Поднимаем кластер etcd

Скачиваем бинарники etcd

        wget -q --show-progress --https-only --timestamping \
        "https://github.com/etcd-io/etcd/releases/download/v3.4.0/etcd-v3.4.0-linux-amd64.tar.gz"

Разархивируем и переносим в /usr/local/bin/

        tar -xvf etcd-v3.4.0-linux-amd64.tar.gz
        sudo mv etcd-v3.4.0-linux-amd64/etcd* /usr/local/bin/

Конфигурируем etcd Server

        sudo mkdir -p /etc/etcd /var/lib/etcd
        sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/

        INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
        http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

        ETCD_NAME=$(hostname -s)

Создаем etcd.service systemd unit file

        cat <<EOF | sudo tee /etc/systemd/system/etcd.service
        [Unit]
        Description=etcd
        Documentation=https://github.com/coreos

        [Service]
        Type=notify
        ExecStart=/usr/local/bin/etcd \\
        --name ${ETCD_NAME} \\
        --cert-file=/etc/etcd/kubernetes.pem \\
        --key-file=/etc/etcd/kubernetes-key.pem \\
        --peer-cert-file=/etc/etcd/kubernetes.pem \\
        --peer-key-file=/etc/etcd/kubernetes-key.pem \\
        --trusted-ca-file=/etc/etcd/ca.pem \\
        --peer-trusted-ca-file=/etc/etcd/ca.pem \\
        --peer-client-cert-auth \\
        --client-cert-auth \\
        --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
        --listen-peer-urls https://${INTERNAL_IP}:2380 \\
        --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
        --advertise-client-urls https://${INTERNAL_IP}:2379 \\
        --initial-cluster-token etcd-cluster-0 \\
        --initial-cluster controller-0=https://10.240.0.10:2380,controller-1=https://10.240.0.11:2380 \\
        --initial-cluster-state new \\
        --data-dir=/var/lib/etcd
        Restart=on-failure
        RestartSec=5

        [Install]
        WantedBy=multi-user.target
        EOF


  стартуем etcd Server

        sudo systemctl daemon-reload
        sudo systemctl enable etcd
        sudo systemctl start etcd


8. Устанавливаем Kubernetes Control Plane

* Создаем директрию для хранения конфигураций

        sudo mkdir -p /etc/kubernetes/config

* загружаем бинарники

        wget -q --show-progress --https-only --timestamping \
        "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-apiserver" \
        "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-controller-manager" \
        "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-scheduler" \
        "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl"

* делаем файлы исполняемыми + копируем  в директорию

        chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
        sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/

* конфигуриируем Kubernetes API Server

        sudo mkdir -p /var/lib/kubernetes/

        sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
            service-account-key.pem service-account.pem \
            encryption-config.yaml /var/lib/kubernetes/

            INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
             http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

* создаем kube-apiserver.service systemd unit file

        cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
        [Unit]
        Description=Kubernetes API Server
        Documentation=https://github.com/kubernetes/kubernetes

        [Service]
        ExecStart=/usr/local/bin/kube-apiserver \\
        --advertise-address=${INTERNAL_IP} \\
        --allow-privileged=true \\
        --apiserver-count=3 \\
        --audit-log-maxage=30 \\
        --audit-log-maxbackup=3 \\
        --audit-log-maxsize=100 \\
        --audit-log-path=/var/log/audit.log \\
        --authorization-mode=Node,RBAC \\
        --bind-address=0.0.0.0 \\
        --client-ca-file=/var/lib/kubernetes/ca.pem \\
        --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
        --etcd-cafile=/var/lib/kubernetes/ca.pem \\
        --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
        --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
        --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379 \\
        --event-ttl=1h \\
        --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
        --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
        --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
        --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
        --kubelet-https=true \\
        --runtime-config=api/all \\
        --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
        --service-cluster-ip-range=10.32.0.0/24 \\
        --service-node-port-range=30000-32767 \\
        --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
        --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
        --v=2
        Restart=on-failure
        RestartSec=5

        [Install]
        WantedBy=multi-user.target
        EOF

* Конфигурируем Kubernetes Controller Manager

        sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/

* создаем kube-controller-manager.service systemd unit file

        cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
        [Unit]
        Description=Kubernetes Controller Manager
        Documentation=https://github.com/kubernetes/kubernetes

        [Service]
        ExecStart=/usr/local/bin/kube-controller-manager \\
        --address=0.0.0.0 \\
        --cluster-cidr=10.200.0.0/16 \\
        --cluster-name=kubernetes \\
        --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
        --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
        --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
        --leader-elect=true \\
        --root-ca-file=/var/lib/kubernetes/ca.pem \\
        --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
        --service-cluster-ip-range=10.32.0.0/24 \\
        --use-service-account-credentials=true \\
        --v=2
        Restart=on-failure
        RestartSec=5

        [Install]
        WantedBy=multi-user.target
        EOF

* конфигурируем Kubernetes Scheduler

        sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/

* создаем конфигурационный файл для Kubernetes Scheduler - kube-scheduler.yaml

        cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
        apiVersion: kubescheduler.config.k8s.io/v1alpha1
        kind: KubeSchedulerConfiguration
        clientConnection:
        kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
        leaderElection:
        leaderElect: true
        EOF
* создаем kube-scheduler.service systemd unit file

        cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
        [Unit]
        Description=Kubernetes Scheduler
        Documentation=https://github.com/kubernetes/kubernetes

        [Service]
        ExecStart=/usr/local/bin/kube-scheduler \\
        --config=/etc/kubernetes/config/kube-scheduler.yaml \\
        --v=2
        Restart=on-failure
        RestartSec=5

        [Install]
        WantedBy=multi-user.target
        EOF


* Перестартовываем сервисы

        sudo systemctl daemon-reload
        sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
        sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler


* активируем Healthcheck

    устанавливаем nginx

        sudo apt-get update
        sudo apt-get install -y nginx


    Создаем конфигурацию NGINX

        cat > kubernetes.default.svc.cluster.local <<EOF
        server {
        listen      80;
        server_name kubernetes.default.svc.cluster.local;

        location /healthz {
            proxy_pass                    https://127.0.0.1:6443/healthz;
            proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
        }
        }
        EOF

Копируем  ее в директорию NGINX

        sudo mv kubernetes.default.svc.cluster.local \
            /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

        sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/
        sudo systemctl restart nginx
        sudo systemctl enable nginx

* RBAC for Kubelet Authorization

Создаем еонфигурационный файл доступа на любом из контроллеров

        cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
        apiVersion: rbac.authorization.k8s.io/v1beta1
        kind: ClusterRole
        metadata:
        annotations:
            rbac.authorization.kubernetes.io/autoupdate: "true"
        labels:
            kubernetes.io/bootstrapping: rbac-defaults
        name: system:kube-apiserver-to-kubelet
        rules:
        - apiGroups:
            - ""
            resources:
            - nodes/proxy
            - nodes/stats
            - nodes/log
            - nodes/spec
            - nodes/metrics
            verbs:
            - "*"
        EOF

Даем роль для пользователя kubernetes

        cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
        apiVersion: rbac.authorization.k8s.io/v1beta1
        kind: ClusterRoleBinding
        metadata:
        name: system:kube-apiserver
        namespace: ""
        roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: ClusterRole
        name: system:kube-apiserver-to-kubelet
        subjects:
        - apiGroup: rbac.authorization.k8s.io
            kind: User
            name: kubernetes
        EOF


* Создаем Kubernetes Frontend Load Balancer
Выполняем на  host  машине

        KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
            --region $(gcloud config get-value compute/region) \
            --format 'value(address)')

        gcloud compute http-health-checks create kubernetes \
            --description "Kubernetes Health Check" \
            --host "kubernetes.default.svc.cluster.local" \
            --request-path "/healthz"

        gcloud compute firewall-rules create kubernetes-the-hard-way-allow-health-check \
            --network kubernetes-the-hard-way \
            --source-ranges 209.85.152.0/22,209.85.204.0/22,35.191.0.0/16 \
            --allow tcp

        gcloud compute target-pools create kubernetes-target-pool \
            --http-health-check kubernetes

        gcloud compute target-pools add-instances kubernetes-target-pool \
        --instances controller-0,controller-1,controller-2

        gcloud compute forwarding-rules create kubernetes-forwarding-rule \
            --address ${KUBERNETES_PUBLIC_ADDRESS} \
            --ports 6443 \
            --region $(gcloud config get-value compute/region) \
            --target-pool kubernetes-target-pool


9. Поднимаем  Kubernetes Worker Nodes

* Устанвливаем пакеты

        sudo apt-get update
        sudo apt-get -y install socat conntrack ipset

* отключаем Swap


        sudo swapon --show &&  sudo swapoff -a

* Загружаем и устнавливаем бинарники

        wget -q --show-progress --https-only --timestamping \
        https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.15.0/crictl-v1.15.0-linux-amd64.tar.gz \
        https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
        https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz \
        https://github.com/containerd/containerd/releases/download/v1.2.9/containerd-1.2.9.linux-amd64.tar.gz \
        https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl \
        https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-proxy \
        https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubelet

создаем директории

        sudo mkdir -p \
        /etc/cni/net.d \
        /opt/cni/bin \
        /var/lib/kubelet \
        /var/lib/kube-proxy \
        /var/lib/kubernetes \
        /var/run/kubernetes


Устанавливаем бинари

        mkdir containerd
        tar -xvf crictl-v1.15.0-linux-amd64.tar.gz
        tar -xvf containerd-1.2.9.linux-amd64.tar.gz -C containerd
        sudo tar -xvf cni-plugins-linux-amd64-v0.8.2.tgz -C /opt/cni/bin/
        sudo mv runc.amd64 runc
        chmod +x crictl kubectl kube-proxy kubelet runc
        sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
        sudo mv containerd/bin/* /bin/


* Конфигуририуем   CNI Networking

        POD_CIDR=$(curl -s -H "Metadata-Flavor: Google" \
        http://metadata.google.internal/computeMetadata/v1/instance/attributes/pod-cidr)

Создаем сеть типа bridge

        cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
        {
            "cniVersion": "0.3.1",
            "name": "bridge",
            "type": "bridge",
            "bridge": "cnio0",
            "isGateway": true,
            "ipMasq": true,
            "ipam": {
                "type": "host-local",
                "ranges": [
                [{"subnet": "${POD_CIDR}"}]
                ],
                "routes": [{"dst": "0.0.0.0/0"}]
            }
        }
        EOF

Создаем сеть типа loopback

        cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
        {
            "cniVersion": "0.3.1",
            "name": "lo",
            "type": "loopback"
        }
        EOF

* Конфигурируем containerd

        sudo mkdir -p /etc/containerd/

        cat << EOF | sudo tee /etc/containerd/config.toml
        [plugins]
        [plugins.cri.containerd]
            snapshotter = "overlayfs"
            [plugins.cri.containerd.default_runtime]
            runtime_type = "io.containerd.runtime.v1.linux"
            runtime_engine = "/usr/local/bin/runc"
            runtime_root = ""
        EOF

    Создаем containerd.service systemd unit file


        cat <<EOF | sudo tee /etc/systemd/system/containerd.service
        [Unit]
        Description=containerd container runtime
        Documentation=https://containerd.io
        After=network.target

        [Service]
        ExecStartPre=/sbin/modprobe overlay
        ExecStart=/bin/containerd
        Restart=always
        RestartSec=5
        Delegate=yes
        KillMode=process
        OOMScoreAdjust=-999
        LimitNOFILE=1048576
        LimitNPROC=infinity
        LimitCORE=infinity

        [Install]
        WantedBy=multi-user.target
        EOF

* Конфигурируем Kubelet

        sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
        sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
        sudo mv ca.pem /var/lib/kubernetes/

создаем файл kubelet-config.yaml

        cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
        kind: KubeletConfiguration
        apiVersion: kubelet.config.k8s.io/v1beta1
        authentication:
        anonymous:
            enabled: false
        webhook:
            enabled: true
        x509:
            clientCAFile: "/var/lib/kubernetes/ca.pem"
        authorization:
        mode: Webhook
        clusterDomain: "cluster.local"
        clusterDNS:
        - "10.32.0.10"
        podCIDR: "${POD_CIDR}"
        resolvConf: "/run/systemd/resolve/resolv.conf"
        runtimeRequestTimeout: "15m"
        tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
        tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
        EOF

Создаем kubelet.service systemd unit file

        cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
        [Unit]
        Description=Kubernetes Kubelet
        Documentation=https://github.com/kubernetes/kubernetes
        After=containerd.service
        Requires=containerd.service

        [Service]
        ExecStart=/usr/local/bin/kubelet \\
        --config=/var/lib/kubelet/kubelet-config.yaml \\
        --container-runtime=remote \\
        --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
        --image-pull-progress-deadline=2m \\
        --kubeconfig=/var/lib/kubelet/kubeconfig \\
        --network-plugin=cni \\
        --register-node=true \\
        --v=2
        Restart=on-failure
        RestartSec=5

        [Install]
        WantedBy=multi-user.target
        EOF

Конфигурируем Kubernetes Proxy

    sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

Создаем конфигурационный файл kube-proxy-config.yaml

    cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
    kind: KubeProxyConfiguration
    apiVersion: kubeproxy.config.k8s.io/v1alpha1
    clientConnection:
    kubeconfig: "/var/lib/kube-proxy/kubeconfig"
    mode: "iptables"
    clusterCIDR: "10.200.0.0/16"
    EOF

Создаем kube-proxy.service systemd unit file


* Перестартовываем сервисы


10. Конфигурируем  kubectl for Remote Access

Выполняем на хостовой машине

    KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
        --region $(gcloud config get-value compute/region) \
        --format 'value(address)')

    kubectl config set-cluster kubernetes-the-hard-way \
        --certificate-authority=ca.pem \
        --embed-certs=true \
        --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

    kubectl config set-credentials admin \
        --client-certificate=admin.pem \
        --client-key=admin-key.pem

    kubectl config set-context kubernetes-the-hard-way \
        --cluster=kubernetes-the-hard-way \
        --user=admin

    kubectl config use-context kubernetes-the-hard-way


11. Создание Pod Network Routes

    создаем роуты для worker-ов

            for i in 0 1; do
        gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
            --network kubernetes-the-hard-way \
            --next-hop-address 10.240.0.2${i} \
            --destination-range 10.200.${i}.0/24
        done

12. Устанавливаем DNS Cluster Add-on

        kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml

13. Прогнали тесты работоспособности
