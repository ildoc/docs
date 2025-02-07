---
title: Certified Kubernetes Administrator (CKA)
---

Appunti del corso https://learn.kodekloud.com/courses/cka-certification-course-certified-kubernetes-administrator

!!! note annotate "Per non diventare pazzi con vi"
    Nella shell lanciare `export KUBE_EDITOR=nano`

## Core Concepts

### Docker vs containerd
Inizialmente Kubernetes è nato come orchestratore di container Docker e supportava solo Docker.
Ha iniziato a supportare anche altri engine attraverso dei magheggi e poi ha droppato il supporto a Docker per passare solo a containerd come predefinito

#### nerdctl
`nerdctl` è una cli docker-like per containerd alternativa a `ctr` che è quella di default ed è limitata nelle funzionalità e utilizzata soprattutto per debug

- supporta docker compose
- supporta le nuove feature di containerd
    - encrypted container images
    - lazy pulling
    - p2p image distribution
    - image signing and verifying
    - namespace in kubernetes

=== "Docker"

    ``` bash
    $ docker

    $ docker run --name redis redis:alpine

    $ docker run --name webserver -p 80:80 -d nginx
    ```

=== "nerdctl"

    ``` bash
    $ nerdctl

    $ nerdctl run --name redis redis:alpine

    $ nerdctl run --name webserver -p 80:80 -d nginx
    ```

#### crictl
`crictl` è un'interfaccia per interagire con container runtime compatibili con CRI (container runtime interface), praticamente è un'astrazione rispetto a usare il comando specifico per lo specifico runtime

oltre ai comandi docker-style, crictl è a conoscenza dei pod

### ETCD

etcd è un key-value store
ascolta di default sulla porta 2379

il client di default è `etcdctl`

per storare un dato
`./etcdctl set key1 value1`

per ottenere un dato
`./etcdctl get key1`


ci sono differenze tra le api della versione 2 e la versione 3
`./etcdctl version`

di default ormai la versione delle api è la 3, ma si può impostare con
`ETCDCTL_API=3 ./etcdctl <comando>`

oppure impostare come variabile locale
```bash
export ETCDCTL_API=3
./etcdctl <comando>
```

=== "v2"

    ``` bash
    ./etcdctl set key1 value1

    ./etcdctl get key1
    ```

=== "v3"

    ``` bash
    ./etcdctl put key1 value1

    ./etcdctl get key1
    ```

#### etcd in kubernetes
in Kubernetes etcd viene usato per storare gli stati delle risorse

`kubectl exec etcd-master -n kube-system etcctl get / --prefix -keys-only`


### Kube Api server

Al comando di creazione di un pod, kube-apiserver autentica e valida la richiesta, crea la risorsa sul cluster ETCD e ritorna l'ok.
kube-scheduler realizza che c'è un pod non assegnato a nessun nodo, identifica il nodo su cui crearlo e lo comunica a kube-apiserver.
kube-apiserver aggiorna l'informazione nel cluster ETCD e passa l'informazione al kubelet del nodo corrispondente.
kubelet crea il pod e istruisce il container runtime engine di deployare l'immagine dell'applicazione.
una volta fatto, il kubelet aggiorna lo stato su kube-apiserver, che a sua volta aggiorna il cluster etcd

kube-apiserver è il centro di ogni modifica che viene fatta al cluster.

quindi:

1. Autentica l'utente
2. Valida la richiesta
3. Ottiene i dati
4. Aggiorna ETCD
5. Comunica con lo scheduler
6. Comunica con i kubelet

kube-apiserver è l'unico componente che legge e scrive su etcd.

Se il cluster è stato deployato con kubeadm, i settings dell'apiserver si trovano sul pod kube-apiserver-master dentro `/etc/kubernetes/manifests/kube-apiserver.yaml`

altrimenti sta in `/etc/systemd/system/kube-apiserver.service`

### Kube controller manager

Un controller è un processo che monitora continuamente lo stato dei componenti del sistema e lavora per portare il sistema allo stato desiderato.

Il Node controller monitora lo stato dei nodi tramite l'apiserver:

- ogni 5 secondi fa il check dello stato dei nodi
- se un nodo manca un check viene marcato come unreachable
- se per i successivi 40 secondi rimane unreachable allora è unreachable
- dopo 5 minuti i pod vengono spostati su un nuovo nodo


Il replication controller monitora lo stato dei replicaset e si assicura che siano creati il numero di pod corretti.
Se un pod muore ne spawna uno nuovo.


il controller manager si occupa di controllare tutti i controller

Se il cluster è stato deployato con kubeadm, il controller manager è deployato come pod con nome kube-controller-manager-master
i settings sono dentro `/etc/kubernetes/manifests/kube-controller-manager.yaml`

altimenti in `/etc/systemd/system/kube-controller-manager.service`


### Kube Scheduler

è solo responsabile di decidere che pod va su che nodo, ma non crea direttamente il pod, quello è responsabilità del kubelet del nodo

la decisione dipende da vari fattori, come per esempio le risorse del nodo

Se il cluster è stato deployato con kubeadm, lo scheduler è deployato come pod con nome kube-scheduler-master
i settings sono dentro `/etc/kubernetes/manifests/kube-scheduler.yaml`

altimenti in `/etc/systemd/system/kube-scheduler.service`


### Kubelet

l'agent kubelet sul nodo, registra il nodo nel cluster, crea i pod, monitora lo stato dei pod e riporta le informazioni all'apiserver

kubelet NON viene deployato con kubeadm e va sempre installato manualmente


### Kube Proxy

kube-proxy è un processo che vive su ciascun nodo del cluster ed è responsabile di creare rules per forwardare il traffico dai services ai pod

kubeadm deploya kube-proxy come deamonset, quindi un pod di kube-proxy viene deployato su ciascun nodo del cluster


### Pods

il pod è l'oggetto più piccolo che si può creare in kubernetes

i container del pod condividono la stessa sottorete e si possono riferire tra loro su localhost


per deployare un pod con kubectl:

`kubectl run nginx --image nginx` crea il pod con il container di nginx
`kubectl run nginx --image nginx --port=80 --expose` crea il pod con il container di nginx e crea contestualmente un service di tipo clusterip che espode la porta del pod

#### yaml

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: myapp-pod
    labels:
        app: myapp
        type: front-end
spec:
    containers:
        - name: nginx-container
          image: nginx
```
`kubectl create -f pod-definition.yml`


### ReplicaSet

I ReplicaSet sono la versione nuova del ReplicationController


=== "ReplicationController"
    ```yaml title="rc-definition.yml"
    apiVersion: v1
    kind: ReplicationController
    metadata: 
        name: myapp-rc
        labels:
            app: myapp
            type: front-end
    spec:
        template:
            metadata: 
                name: myapp-pod
                labels:
                    app: myapp
                    type: front-end
            spec:
                containers:
                    - name: nginx-container
                    image: nginx
        replicas: 3
    ```
    `kubectl create -f rc-definition.yml`

=== "ReplicaSet"
    ```yaml title="replicaset-definition.yml"
    apiVersion: apps/v1
    kind: ReplicaSet
    metadata: 
        name: myapp-replicaset
        labels:
            app: myapp
            type: front-end
    spec:
        template:
            metadata: 
                name: myapp-pod
                labels:
                    app: myapp
                    type: front-end
            spec:
                containers:
                    - name: nginx-container
                    image: nginx
        replicas: 3
        selector: 
            machtLabels:
                type: front-end
    ```
    `kubectl create -f replicaset-definition.yml`

Il ruolo del Replicaset è monitorare i pod e assicurasi che ce ne sia up sempre il numero definito.
Per capire che pod monitorare, si usano i selector e le label


Per scalare il replicaset, o si cambia il numero di repliche nel file oppure

`kubectl scale --replicas=6 -f replicaset-definition.yml`
`kubectl scale --replicas=6 replicaset myapp-replicaset`

usando il comando scale e indicando il file, il numero di repliche nel file NON viene aggiornato

### Deployments

```yaml title="deployment-definition.yml"
apiVersion: apps/v1
kind: Deployment
metadata: 
    name: myapp-deployment
    labels:
        app: myapp
        type: front-end
spec:
    template:
        metadata: 
            name: myapp-pod
            labels:
                app: myapp
                type: front-end
        spec:
            containers:
                - name: nginx-container
                image: nginx
    replicas: 3
    selector: 
        machtLabels:
            type: front-end
```
Il deployment crea il replicaset e a sua volta i pod


### Services

I service permettono la connettività tra pod

NodePort: espongono una porta interna su una porta del nodo
ClusterIp: crea un virtual ip nel cluster per permettere la comunicazione tra diversi servizi
LoadBalancer: per distribuire il carico tra diversi servizi

La porta del pod è la TargetPort
La porta del service è la Port
La porta del nodo per accedere al servizio dall'esterno è la NodePort (range 30000-32767)

#### NodePort

```yaml title="service-definition.yml"
apiVersion: v1
kind: Service
metadata: 
    name: myapp-service
spec:
    type: NodePort
    ports:
      - targetPort: 80
        port: 80
        nodePort: 30008
    selector:
        app: myapp
        type: front-end
```
`kubectl create -f service-definition.yml`

In caso di più pod su nodi diversi, il servizio mappa la porta su ciascuno dei nodi del cluster

#### ClusterIp

I clusterIp si possono utilizzare per gruppare l'accesso a diverse tipologie di pod (tutti i fe, tutti i be, tutti i db, ecc.) con un virtual ip interno al cluster

```yaml title="service-definition.yml"
apiVersion: v1
kind: Service
metadata: 
    name: myapp-service
spec:
    type: ClusterIp
    ports:
      - targetPort: 80
        port: 80
    selector:
        app: myapp
        type: front-end
```
`kubectl create -f service-definition.yml`

#### LoadBalancer

Per accedere ai servizi esposti su più nodi dai NodePort bilanciando le richieste

```yaml title="service-definition.yml"
apiVersion: v1
kind: Service
metadata: 
    name: myapp-service
spec:
    type: LoadBalancer
    ports:
      - targetPort: 80
        port: 80
        nodePort: 30008
```
`kubectl create -f service-definition.yml`

funziona solo in ambienti supportati (GCP, AWS, Azure), altrimenti equivale al funzionamento di un nodeport


### Namespace

I namespace servono a gruppare risorse (isolation).
Le risorse all'interno dello stesso namespace si vedono tra di loro solo per il nome.

Per raggiungere risorse di un altro namespace, si può usare 
<servicename>.<namespace>.<service>.<domain>
es. `db-service.dev.svc.cluster.local`

`kubectl create -f pod-definition.yml` crea il pod nel namespace default
`kubectl create -f pod-definition.yml --namespace=dev` lo crea nel namespace dev

altrimenti si può spostare l'indicazione del namespace dentro la il manifest della risorsa, sotto metadata

```yaml title="namespace-definition.yml"
apiVersion: v1
kind: Namespace
metadata: 
    name: dev
```
`kubectl create -f namespace-definition.yml`
oppure
`kubectl create namespace dev`


per switchare il namespace di default
`kubectl config set-context $(kubectl config current-context) --namespace=dev`

per vedere tutti i pod in tutti namespace
`kubectl get pods --all-namespaces`

#### ResourceQuota

Servono a limitare le risorse di un namespace

```yaml title="rq-definition.yml"
apiVersion: v1
kind: ResourceQuota
metadata: 
    name: compute-quota
    namespace: dev
spec:
    hard:
        pods: "10"
        requests.cpu: "4"
        requests.memory: 5Gi
        limits.cpu: "10"
        limits.memory: 10Gi
```
`kubectl create -f rq-definition.yml`

### Imperative vs declarative

L'approccio dichiaravito (kubectl apply) è più veloce in contesti reali perchè si evita di dover fare check se le risorse esistano o meno e permette di utilizzare file di manifest che possono essere versionati o modificati da altre persone

L'approccio imperativo (kubectl create/edit/run/...) è più veloce per fare operazioni puntuali su risorse delle quali non è necessario persistere lo stato, in quanto eventuali file di manifest non vengono aggiornati contestualmente al comando.
Non dover creare un file per poi applicarlo è più rapido.

Un approccio ibrido può essere chiamarte il comando imperativo con i flag `--dry-run=client -o yaml > nomefile.yaml` per farsi creare il manifest, modificarlo e poi applicarlo con kubectl apply

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands
https://kubernetes.io/docs/reference/kubectl/conventions/


https://github.com/kodekloudhub/certified-kubernetes-administrator-course


## Scheduling

Lo scheduling è l'assegnazione di un nodo a un pod

ogni pod ha un campo `nodeName` nel manifest che di solito non viene specificato, lo scheduler controlla tutti i nodi e identica il nodo migliore in base al suo algoritmo

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: nginx
    labels:
        app: nginx
spec:
    containers:
    - name: nginx
      image: nginx
      ports:
      - containerPort: 8080
    nodeName: node02
```

### Manual scheduling

il nodename non è modificabile per un pod già creato, ma si può utilizzare un binding

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Binding
metadata: 
    name: nginx
target:
    apiVersion: v1
    kind: Node
    name: node02
```

#### Labels e selector

Le label sono proprietà applicate agli oggetti, i selector aiutano a filtrare gli oggetti per le loro label

Le annotations sono note informative

`kubectl get pods --selector app=App1`


#### Taints and tolerations

con i taints si possono restringere i nodi su cui spawnare i pod
una toleration permette di overridare il taint

Esempio: applicando un taint a un nodo, nessun pod ci viene schedulato sopra.
Aggiungendo una toleration ad alcuni pod, questi possono essere schedulati sul nodo con il taint

I taint sono applicati ai nodi
`kubectl taint nodes node-name key=value:taint-effect`

taint-effect:
- NoSchedule: evita che il pod venga schedulato sul nodo
- PreferNoSchedule: il sistema prova a evitare di schedulare pod sul nodo
- NoExecute: i pod non vengono schedulati sul nodo e quelli presenti vengono evicted se non hanno toleration

Le toleration vengono applicate ai pod
per esempio un nodo con `kubectl taint nodes node1 app=blue:NoSchedule` avrà una toleration fatta così

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: nginx
spec:
    containers:
    - name: nginx
      image: nginx
    tolerations:
    - key: app
      operator: "Equal"
      value: "blue"
      effect: "NoSchedule"
```

Taint e toleration non dicono a un pod di andare su un nodo in particolare, indicano solo che un nodo può accettare pod con particolari toleration

Per indicare a un pod di preferire un nodo a un altro, bisogna utilizzare l'affinity.

Di default in un cluster kubernetes il master node ha il taint noschedule

`kubectl describe node node01 | grep Taint`

per rimuovere un taint il comando è lo stesso ma con un - alla fine
es. `kubectl taint nodes node1 app=blue:NoSchedule-`














## Note generali

### Nano come editor
Per non diventare pazzi con vi, nella shell lanciare `export KUBE_EDITOR=nano`

### Repo con appunti

https://github.com/kodekloudhub/certified-kubernetes-administrator-course

### Get All
Per ottenere la lista di tutti gli oggetti, `kubectl get all`

### Kubectl
https://kubernetes.io/docs/reference/kubectl/conventions/

Create an NGINX Pod

`kubectl run nginx --image=nginx`

Generate POD Manifest YAML file (-o yaml). Don’t create it(–dry-run)

`kubectl run nginx --image=nginx --dry-run=client -o yaml`

Create a deployment

`kubectl create deployment --image=nginx nginx`

Generate Deployment YAML file (-o yaml). Don’t create it(–dry-run)

`kubectl create deployment --image=nginx nginx --dry-run=client -o yaml`

Generate Deployment YAML file (-o yaml). Don’t create it(–dry-run) and save it to a file.

`kubectl create deployment --image=nginx nginx --dry-run=client -o yaml > nginx-deployment.yaml`

Make necessary changes to the file (for example, adding more replicas) and then create the deployment.

`kubectl create -f nginx-deployment.yaml`

OR

In k8s version 1.19+, we can specify the –replicas option to create a deployment with 4 replicas.

`kubectl create deployment --image=nginx nginx --replicas=4 --dry-run=client -o yaml > nginx-deployment.yaml`
