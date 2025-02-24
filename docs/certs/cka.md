---
title: Certified Kubernetes Administrator (CKA)
---

Appunti del corso https://learn.kodekloud.com/courses/cka-certification-course-certified-kubernetes-administrator

!!! note annotate "Per non diventare pazzi con vi"
    Nella shell lanciare `export KUBE_EDITOR=nano`

!!! note annotate "Repo ufficale con appunti"
    <https://github.com/kodekloudhub/certified-kubernetes-administrator-course>

## Core Concepts

### Docker vs containerd
Inizialmente Kubernetes è nato come orchestratore di container Docker e supportava solo Docker.
Ha iniziato a supportare anche altri engine attraverso dei magheggi e poi ha droppato il supporto a Docker per passare solo a containerd come predefinito

#### nerdctl
`nerdctl` è una cli docker-like per containerd alternativa a `ctr` (che è quella di default ed è limitata nelle funzionalità e utilizzata soprattutto per debug)

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

quindi riassumendo, kube-apiserver:

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


Il controller manager si occupa di controllare tutti i controller

Se il cluster è stato deployato con kubeadm, il controller manager è deployato come pod con nome kube-controller-manager-master e i settings sono dentro `/etc/kubernetes/manifests/kube-controller-manager.yaml`

altimenti in `/etc/systemd/system/kube-controller-manager.service`


### Kube Scheduler

è solo responsabile di decidere che pod va su che nodo, ma non crea direttamente il pod, quello è responsabilità del kubelet del nodo

La decisione dipende da vari fattori, come per esempio le risorse del nodo.

Se il cluster è stato deployato con kubeadm, lo scheduler è deployato come pod con nome kube-scheduler-master e i settings sono dentro `/etc/kubernetes/manifests/kube-scheduler.yaml`

altimenti in `/etc/systemd/system/kube-scheduler.service`


### Kubelet

L'agent kubelet sul nodo registra il nodo nel cluster, crea i pod, monitora lo stato dei pod e riporta le informazioni all'apiserver

kubelet NON viene deployato con kubeadm e va sempre installato manualmente


### Kube Proxy

kube-proxy è un processo che vive su ciascun nodo del cluster ed è responsabile di creare rules per forwardare il traffico dai services ai pod

kubeadm deploya kube-proxy come deamonset, quindi un pod di kube-proxy viene deployato su ciascun nodo del cluster


### Pods

Il pod è l'oggetto più piccolo che si può creare in kubernetes

I container del pod condividono la stessa sottorete e si possono riferire tra loro su localhost


per deployare un pod con kubectl:

- kubectl run nginx --image nginx` crea il pod con il container di nginx
- `kubectl run nginx --image nginx --port=80 --expose` crea il pod con il container di nginx e crea contestualmente un service di tipo clusterip che espode la porta del pod

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

Il ruolo del Replicaset è monitorare i pod e assicurasi che ce ne sia up sempre il numero definito.

Per capire che pod monitorare, si usano i selector e le label. La label del selector e quella del template del pod devono matchare, altrimenti in caso di scale up e scale down non si sa che pod usare.

Per scalare il replicaset, o si cambia il numero di repliche nel file oppure

- `kubectl scale --replicas=6 -f replicaset-definition.yml`
- `kubectl scale --replicas=6 replicaset myapp-replicaset`

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

- NodePort: espongono una porta interna su una porta del nodo
- ClusterIp: crea un virtual ip nel cluster per permettere la comunicazione tra diversi servizi
- LoadBalancer: per distribuire il carico tra diversi servizi

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
`<servicename>.<namespace>.<service>.<domain>`

es. `db-service.dev.svc.cluster.local`

- `kubectl create -f pod-definition.yml` crea il pod nel namespace default
- `kubectl create -f pod-definition.yml --namespace=dev` lo crea nel namespace dev

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

- <https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands>
- <https://kubernetes.io/docs/reference/kubectl/conventions/>


- <https://github.com/kodekloudhub/certified-kubernetes-administrator-course>

### Note Generali

#### Get All
Per ottenere la lista di tutti gli oggetti, `kubectl get all`

#### Kubectl
<https://kubernetes.io/docs/reference/kubectl/conventions/>

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

Il nodeName non è modificabile per un pod già creato, ma si può utilizzare un binding

```yaml title="binding-definition.yml"
apiVersion: v1
kind: Binding
metadata: 
    name: nginx
target:
    apiVersion: v1
    kind: Node
    name: node02
```

### Labels e selector

Le label sono proprietà applicate agli oggetti, i selector aiutano a filtrare gli oggetti per le loro label

Le annotations sono note informative

`kubectl get pods --selector app=App1`


### Taints and tolerations

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

### Node Selector
Le label possono essere applicate anche ai nodi per poi indirizzare la schedulazione dei pod

- `kubectl label nodes <node-name> <label-key>=<label-value>`
- `kubectl label nodes node01 size=Large`

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: nginx
spec:
    containers:
    - name: nginx
      image: nginx
    nodeSelector:
        size: Large
```

### Node affinity

L'affinity si usa per assicurarsi che un pod venga spawnato su un particolare nodo
Con ii nodeSelector non si possono usare combinazioni, con l'affinity si

=== "Node Selector"

    ```yaml title="pod-definition.yml"
    apiVersion: v1
    kind: Pod
    metadata: 
        name: nginx
    spec:
        containers:
        - name: nginx
        image: nginx
        nodeSelector:
            size: Large
    ```
=== "Node Affinity"

    ```yaml title="pod-definition.yml"
    apiVersion: v1
    kind: Pod
    metadata: 
        name: nginx
    spec:
        containers:
        - name: nginx
        image: nginx
        affinity:
            nodeAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                    nodeSelectorTerms:
                        - matchExpressions:
                          - key: size
                            operator: In
                            values:
                            - Large
    ```
Se le regole di affinity non matchano nessun nodo

esistenti:

- requiredDuringSchedulingIgnoredDuringExecution: se la regola non matcha, il pod non viene schedulato
- preferredDuringSchedulingIgnoredDuringExecution: se la regola non matcha, viene schedulato secondo lo scheduling normale

i cambi effettuati sul nodo durante l'esecuzione del pod non hanno impatti

plannate:
- requiredDuringSchedulingRequiredDuringExecution:
- preferredDuringSchedulingRequiredDuringExecution:

come sopra, solo che i cambi effettuati su nodo durante l'esecuzione causano l'evict del pod nel caso le regole non matchino più

<https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/>


### Taints and Tolerations vs Affinity

Taints e tolerations possono essere combinati con l'affinity per indirizzare precisamente dei pod su dei nodi specifici e prevenire che altri pod vengano schedulati su quei nodi

### Resource limits

- resource requests: sono le risorse minime del pod
- resource limits: risorse massime che il pod può usare

le risorse sono considerate per ciascun container all'interno del pod

se è specificato solo il limite, allora le requests vengono impostate uguale al limite

usando i limitrange si possono impostare limiti di default per tutti i pod del cluster

```yaml title="limit-range-cpu.yml"
apiVersion: v1
kind: LimitRange
metadata: 
    name: cpu-resource-constraint
spec:
    limits:
    - default:
        cpu: 500m
      defaultRequest:
        cpu: 500m
      max:
        cpu: "1"
      min:
        cpu: 100m
      type: Container
```

```yaml title="limit-range-memory.yml"
apiVersion: v1
kind: LimitRange
metadata: 
    name: cpu-resource-constraint
spec:
    limits:
    - default:
        memory: 1Gi
      defaultRequest:
        memory: 1Gi
      max:
        memory: 1Gi
      min:
        memory: 500Mi
      type: Container
```

i pod creati prima del limitrange non vengono modificati

i resource quota sono applicati a livello di namespace

```yaml title="resource-quota.yml"
apiVersion: v1
kind: ResourceQuota
metadata: 
    name: my-resource-quota
spec:
    hard:
        requests.cpu: 4
        requests.memory: 4Gi
        limits.cpu: 10
        limits.memory: 10Gi
```

### DeamonSet

i DeamonSet sono come i replicaset, ma si occupano di spawnare un pod per ciascun nodo.
se viene aggiunto un nodo, il deamonset spawna un nuovo pod

use cases:
- monitoring
- logs

eper esempio il kube-proxy è un deamonset

=== "DaemonSet"

    ```yaml title="daemonset-definition.yml"
    apiVersion: apps/v1
    kind: DaemonSet
    metadata: 
        name: monitoring-daemon
    spec:
        selector: 
            machtLabels:
                type: monitoring-agent
        template:
            metadata: 
                labels:
                    app: monitoring-agent
            spec:
                containers:
                    - name: monitoring-agent
                      image: monitoring-agent
    ```
=== "ReplicaSet"

    ```yaml title="replicaset-definition.yml"
    apiVersion: apps/v1
    kind: ReplicaSet
    metadata: 
        name: monitoring-daemon
    spec:
        selector: 
            machtLabels:
                type: monitoring-agent
        template:
            metadata: 
                labels:
                    app: monitoring-agent
            spec:
                containers:
                    - name: monitoring-agent
                      image: monitoring-agent
    ```

`kubectl get daemonset`

prima della versione 1.12 veniva usato nodeSelector per istruire su che nodo utilizzare, dalla 1.12 in poi viene utilizzata l'affinity


### Static Pods

kubelet può essere impostato per monitorare una folder sul noto in cui possono essere messi dei manifest di definizione di pod.

Kubelet cerca di mantenere il sistema in sync con i manifest, aggiornando lo stato dei pod in caso di modifiche o cancellazioni.

In questo modo possono essere creati solo pod, non deployment o replicaset.

I pod creati in questo modo sono detti static pods.

I pod creati in questo modo sono editabili solo sul nodo, da kubectl se ne vede solo una copia readonly

per trovare la folder, `ps -aux | grep kubelet` e poi cercare per il parametro --config


### Multiple Schedulers

per istruire un pod ad essere schedulato da un particolare scheduler si usa il valore di scheduler name


```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: nginx
spec:
    containers:
    - name: nginx
      image: nginx
    schedulerName: my-custom-scheduler
```

se lo scheduler non esiste o è mal configurato, il pod rimane in stato pending

per vedere che scheduler ha deployato che pod, si può usare il comando `kubectl get events -o wide` oppure si possono vedere i log dello scheduler con `kubectl logs my-custom-scheduler --namespace=kube-system`

### Scheduler Profiles

Quando vengono creati, i pod vengono messi in una scheduling queue in attesa di venire assegnati a un nodo.

Per ordinare i pod nella coda, si può usare una priorityclass

```yaml title="priorityclass-definition.yml"
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: 
    name: high-priority
spec:
    value: 1000000
    globalDefault: false
    description: "this priority class should be used for xys service pods only"
```

dove vegono ordinati per value

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: nginx
spec:
    priorityClassName: high-priority
    containers:
    - name: nginx
      image: nginx
      resources:
        requests:
          memory: "1Gi"
          cpu: 10
```

poi i pod entrano in una fase di filtering, dove i nodi che non possono runnare i pod vengono filtrati via

poi c'è la fase di score, dove ai nodi rimanenti viene assegnato uno score in base all'algoritmo di scheduling

alla fine c'è la fase di binding, dove viene fatto il binding tra pod e nodo scelto


- nella fase di scheduling viene usato il plugin di PrioritySort per ordinare i nodi nella coda
- nella fase di filtering viene usato NodeResourcesFit per eliminare i nodi senza abbastanza risorse, oppure NodeName nel caso sia indicato il nome del nodo nella definizione del pod, oppure NodeUnschedulable per filtrare via i nodi con flag Unschedulable a true (nel caso di cordon o drain)
- nella fase di Scoring viene usato NodeResourcesFit, oppure ImageLocality per dare uno score più alto ai nodi che hanno già l'immagine del container del pod
- nella fase di binding c'è il DefaultBinder

in ciascuno stage ci sono uno o più extension point nel quale ci si può inserire un plugin per modificare il comportamento di default


dalla v 1.18 di kubernetes si possono configurare più profile per la stessa KubeSchedulerConfiguration

```yaml title="my-scheduler-config.yml"
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
profiles: 
- schedulerName: my-scheduler-2
  plugins:
    score:
        disabled:
        - name: TaintToleration
        enabled:
        - name: MyCustomPluginA
        - name: MyCustomPluginB

- schedulerName: my-scheduler-3
  plugins:
    preScore:
        disabled:
        - name: '*'
    score:
        disabled:
        - name: '*'

- schedulerName: my-scheduler-4
```

<https://github.com/kubernetes/community/blob/master/contributors/devel/sig-scheduling/scheduling_code_hierarchy_overview.md>

<https://kubernetes.io/blog/2017/03/advanced-scheduling-in-kubernetes/>

<https://jvns.ca/blog/2017/07/27/how-does-the-kubernetes-scheduler-work/>

<https://stackoverflow.com/questions/28857993/how-does-kubernetes-scheduler-work>


### Admission Controller

oltre a usare certificati e RBAC per definire autenticazione e autorizzazione, si può scendere più nel dettaglio del contenuto dei manifest con un Admission controller, per esempio per permettere di usare immagini solo da certi registry, oppre eviare l'uso di tag latest, obbligare la presenza di certi metadata

l'admission controller può cambiare la request oppure effettuare certe azioni prima/dopo

esempio: NamespaceExists controlla che non siano create risorse in namespace che non esistono, è un admission controller base abilitato di default

NamespaceAutoProvision non è abilitato di default e crea il namespace in caso non esista

per vedere la lista degli admission controller abilitati `kube-apiserver -h | grep enable-admission-plugins`

il comando dev'essere eseguito nel controlplane

`kubectl exec kube-apiserver-controlplane -n kube-system -- kube-apiserver -h | grep enable-admission-plugins`

per abilitare un nuovo admission controller bisogna aggiungerlo al flag --enable-admission-plugins del kube-apiserver o nel suo manifest

stessa cosa per disabilitarlo

#### Validating and mutating Admission Controllers

i validating ac validano (NamespaceExists), i mutating ac modificano la request (DefaultStorageClass)

si possono specificare i propri admission criteria tramite i webhook MutatingAdmissionWbhook e ValidatingAdmissionWebhook

I webhook vengono validati per ultimi, passano come request un oggetto di tipo AdmissionReview con tutti i dettagli della richiesta e ritornano un AdmissionReview con response

il webhook server può essere deployato anche nel cluster stesso


```yaml title="my-admission-webhook.yml"
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
    name: "pod-policy.example.com"
    clientConfig:
        # url: "https://external-server.example.com
        service:
            namespace: "webhook-namespace"
            name: "webhook-service"
        caBundle: "aaaaaa.....aaaa"
    rules:
    - apiGroups: [""]
      apiVersion: ["v1"]
      operations: ["CREATE"]
      resources: ["pods"]
      scope: "Namespaced"
```

il service comunica tramite ssl quindi va creato un certificato

## Logging and Monitoring

### Monitoring
kubernetes non ha una soluzione buildtin per il monitoring e metriche

cAdvisor è un componente di kubelet che raccoglie le metriche del nodo e le espone tramite l'api server

`kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`

una volta installato, è possibile vedere l'utilizzo delle risorse con `kubectl top nodes` o `kubectl top pods`


### Application logs

per vedere i log di un pod `kubectl logs -f nome-pod`

per vedere i log di uno specifico container, `kubectl logs -f nome-pod nome-container`

## Application lifecycle management

### Rolling updates and rollback

quando si crea un rollout crea un nuovo deployment revision

`kubectl rollout status deployment/myapp-deployment`

per vedere la history dei deployment

`kubectl rollout history deployment/myapp-deployment`

ci sono due strategie: rolling e recreate

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
```

sull'aggiornamento di un deployment viene creato un nuovo replicaset e i vecchi pod vengono scalati progressivamente a 0 mentre i nuovi prendono il loro posto

`kubectl get replicasets`

per fare un rollback

`kubectl rollout undo deployment/myapp-deployment`

### Commands and arguments

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: ubuntu-sleeper
spec:
    containers:
        - name: ubuntu
          image: ubuntu
          command: ["sleep"]
          args: ["10"]
```

### Env vars

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: ubuntu-sleeper
spec:
    containers:
        - name: ubuntu
          image: ubuntu
          env:
          - name: APP_COLOR
            value: pink
          - name: APP_COLOR_FROM_CONFIGMAP
            valueFrom:
                configMapKeyRef:
                    name: config-map-name
                    key: APP_COLOR
          - name: APP_COLOR_FROM_SECRET
            valueFrom:
                secretKeyRef:
```

### Configmaps

`kubectl create configmap appconfig --from-literal=color=blue`

```yaml title="configmap-definition.yml"
apiVersion: v1
kind: ConfigMap
metadata: 
    name: app-config
data:
    APP_COLOR: blue
    APP_MODE: prod
```

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: ubuntu
spec:
    containers:
        - name: ubuntu
          image: ubuntu
          envFrom:
          - configMapRef:
            name: app-config
```

### Secrets

`kubectl create secret generic nome --from-literal=password=lallallero`

```yaml title="secret-definition.yml"
apiVersion: v1
kind: Secret
metadata: 
    name: app-secret
data:
    DB_HOST: Y2lhbw==
    DB_USER: Y2lhbw==
```
usando la sintassi imperativa i valori vengono già encodati

per convertire al volo in base64 `echo -n 'testo' | base64`

per decodare `echo -n 'Y2lhbw==' | base64 --decode`

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: ubuntu
spec:
    containers:
        - name: ubuntu
          image: ubuntu
          envFrom:
          - secretRef:
               name: app-secret
          env:
          - name: DB_PASSWORD
            valueFrom:
               secretKeyRef:
                  name: app-secret
                  key: DB_PASSWORD
          volume:
          - name: app-secret-volume
            secret:
               secretName: app-secret
```

i secret non sono criptati, ma encodati

tutti i pod o i deployment in un namespace condividono gli stessi secrets

su etcd non vengono criptati di default

#### Abilitare encryption at rest in etcd

<https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/>

### Multi container pods

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: ubuntu
spec:
    containers:
        - name: ubuntu
          image: ubuntu
        - name: busybox
          image: busybox
          
```

in un contesto multicontainer si possono usare delle immagini per fare un setup dell'ambiente. in questo caso si usa initContainers

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: myapp-container
    image: busybox:1.28
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
  initContainers:
  - name: init-myservice
    image: busybox
    command: ['sh', '-c', 'git clone  ;']
```

se l'initcontainer fallisce a completare, kubernetes lo restarta in automatico


### Autoscaling

#### Horizontal Pod Autoscaler

HPA (horizontal pod autoscaler) scala automaticamente il numero di pod basandosi su soglie impostate o custom metrics

`kubectl autoscale deployment my-app --cpu-percent=50 --min=1 --max=10` crea un hpa che monitora le risorse del pod rispetto alle sue resources e crea o distrugge pod di conseguenza

`kubectl get hpa`

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

#### Vertical Pod Autoscaler

Il resize delle risorse di un pod (vertical scaling) è ancora in alpha e il comportamento di default è cancellare il pod, aumentare le risorse e ricrearlo

per abilitarlo `FEATURE_GATES=InPlacePodVerticalScaling=true`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx
        resizePolicy:
          - resourceName: cpu
            restartPolicy: NotRequired
          - resourceName: memory
            restartPoliciy: RestartContainer
        resources:
          requests:
            cpu: "1"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
```

i pod windows non possono ancora essere resizati

il VPA va installato perchè non è buildtin come l'HPA

Il Recommender monitora il metric server e raccommanda i pod da scalare

L'updater intercetta le raccomandazioni delle risorse e controlla i pod esistenti, fa l'evict di quelli da mutare

L'admission controller applica le soglie raccomandate e restarta i pod aggiornati

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: "my-app"
      minAllowed:
        cpu: "250m"
      maxAllowed:
        cpu: "2"
      controlledResources: ["cpu"]
```


## Cluster maintenance

### OS Upgrades

per fare operazioni di manutenzione sull'os di un nodo, si può fare il drain del nodo per svuotarlo dai pod con `kubectl drain nomenodo`

in questo modo il nodo viene marcato come Unschedulable e bisogna farne l'uncordon con `kubectl uncordon nomenodo`

con `kubectl cordon nomenodo` si marca un nodo come Unschedulable e non vengono creati nuovi nodi

### Kubernetes Upgrades

Prima si fa l'upgrade del master node e poi i worker

per la durata dell'upgrade del master, le funzionalità di amministrazione e scheduling sono interrotte, ma i pod continuano ad essere operativi sui vari worker

- strategia 1: aggiornare tutti i worker contemporaneamente -> causa downtime dei pod
- strategia 2: aggiornare un nodo alla volta -> i pod vengono rischedulati sui nodi disponibili -> no downtime
- strategia 3: se si è su un ambiente cloud, è più comodo provisionare nuovi nodi già upgradati decommissionare i vecchi -> i pod vengono rischedulati

con `kubeadm upgrade plan` si ha una panoramica degli upgrade disponibili

<https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/>

step 0: drain del controlplane

step 1: update della versione del repository dentro `/etc/apt/sources.list.d/kubernetes.list`

step 2: `sudo apt update && sudo apt-cache madison kubeadm` per vedere l'ultima versione disponibile

step 3: upgrade di kubeadm con `sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm='1.3x.x' && sudo apt-mark hold kubeadm`

step 4: verifica con `sudo kubeadm upgrade plan`

step 5: `sudo kubeadm upgrade apply v1.3x.x`

step 6: upgrade di kubelet e kubectl con `sudo apt-mark unhold kubelet kubectl && sudo apt-get update && sudo apt-get install -y kubelet='1.3x.x-*' kubectl='1.3x.x-*' && sudo apt-mark hold kubelet kubectl`

step 7: restart di kubelet con `sudo systemctl daemon-reload && sudo systemctl restart kubelet`

step 8: uncordon del controlplane

per i worker gli step sono gli stessi tranne il 5, che è `sudo kubeadm upgrade node`


### Backup e restore

anche se il metodo preferibile è l'approccio dichiarativo in modo da avere tutti i manifest versionabili in un repository, potrebbero esserci oggetti creati in maniera imperativa

per recuperarli, il modo più sicuro e fare query sull'api-server in modo da ottenere TUTTO

`kubectl get all --all-namespaces -o yaml > all-deploy-services.yaml`

ci sono tool che usano apiserver per automatizzare i backup

per quanto riguarda etcd, i dati sono distribuiti sui vari nodi.

etcd ha una funzionalità di snapshot incorporata

`ETCDCTL_API=3 etcdctl snapshot save snapshot.db`

`ETCDCTL_API=3 etcdctl snapshot status snapshot.db`

per restorare uno snapshot etcd bisogna prima stoppare kube-apiserver

`ETCDCTL_API=3 etcdctl snapshot restore snapshot.db --data-dir /var/lib/etcd-from-backup`

per tutti i comandi etcdctl bisogna specificare l'endpoint del server, il cacert, il cert e la key

<https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster>

<https://github.com/etcd-io/website/blob/main/content/en/docs/v3.6/op-guide/recovery.md>


## Security

### Primitives

i nodi dovrebbero avere solo ssh key auth

l'autenticazione all'apiserver si può controllare con:

- username e password storati in file statici
- username e token storati in file statici
- certificati
- provider esterni tipo ldap
- service account

l'authorization con:

- RBAC
- ABAC (attribute based authorization control)
- node authorization
- webhook mode

tutti le comunicazioni tra l'api server e tutti gli altri componenti avviene con certificati TLS

tutte le applicazioni del cluster possono di default parlare tra di loro, la cosa si può restringere tramite network policies

### Authentication

kubernates nativamente non gestisce user account, si basa su fonti esterne. però gestisce service account

#### basic authentication

si crea un csv con 3 colonne: password, username, userid

si passa come argomento al kubeapiservice con `--basic-auth-file=miofile.csv`

per autenticare le chiamate, si specificano user e pass nella chiamata curl con `-u`

nel file ci può essere una quarta colonna per il gruppo dell'utente.

il file può anche essere composto da token, username, userid, gruppo.

in questo caso il token nella chiamata curl si mette nell'authorization header, es. `--header "Authorization: Bearer <token>"`

### TLS

per convenzione, i certificati criptati con chiave pubblica hanno estensione *.crt e *pem, mentre quelli con chiave privata *.key o *-key.pem

| Server | Cert | Public key |
|---|---|---|
| kube-api | apiserver.crt | apiserver.key |
| etcd-server | etcdserver.crt | etcdserver.key |
| kubelet | kubelet.crt | kubelet.key |


#### Creare i certificati

Certificato della certificate authority: ca.key

prima si genera la chiave privata `openssl genrsa -out ca.key 2048`

poi si genera la signing request `openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr`

con la signin request e la privatekey si crea il certificato firmato con `openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt`
    
---

Certificato client dell'admin

prima si genera la chiave privata `openssl genrsa -out admin.key 2048`

poi si genera la signing request `openssl req -new -key admin.key -subj "/CN=kube-admin" -out admin.csr`

nel CN ci va il nome dell'utente, e si può anche specificare il gruppo di appartenenza con il flag /O, es: `/CN=kube-admin/O=system:masters`

con la signin request e la privatekey si crea il certificato firmato con `openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -out admin.crt`

---

Per etcd bisogna generare dei certificati peer per ciascun nodo del cluster etcd e poi aggiungerli nelle opzioni di startup

Per l'apiserver bisogna specificare nel certificato tutti i nomi dns e gli ip con il quale può venir chiamato

`openssl genrsa -out apiserver.key 2048`

`openssl req -new -key apiserver.key -subj "/CN=kube-apiserver" -out apiserver.csr`

per farlo si crea un cnf file

```ini hl_lines="9-14"
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.2 = kubernetes.default.svc
DNS.2 = kubernetes.default.svc.cluster.local
IP.1 = 10.96.0.1
IP.2 = 172.17.0.87
```

I certificati dei kubelet devono avere come nome il nome del nodo

#### Visualizzare i certificati

se il cluster è stato deployato the hard way, i certificati sono stati generati a manutenzione

invece kubeadm o altri provisioning tool se ne occupano in automatico e sono indicati nelle spec dei vari static pods

per leggere il contenuto di un certificato `openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout`

nei log si possono trovare info utili `journalclt -u etcd.service -l` es. per k8s installato come service, mentre `kubectl logs etcd-master` per kubeadm

<https://github.com/mmumshad/kubernetes-the-hard-way/tree/master/tools>

#### Certificates api

kubernetes ha un sistema built-in per gestire i certificati e il loro rinnovo

- un utente genera la propria key con `openssl genrsa -out jane.key 2048`
- genera la signing request da firmare con `openssl req -new -key jane.key -subj "/CN=jane" -out jane.csr`
- l'amministratore crea il CertificateSigningRequestObject
  ```yaml title="jane-csr.yaml"
  apiVersion: certificates.k8s.io/v1
  kind: CertificateSigningRequest
  metadata
    name: jane
  spec:
    expirationSeconds: 600 #seconds
    usages:
    - digital signature
    - key encipherment
    - server auth
    request:
      <jane.crt in base64>
  ```
- l'amministratore può vedere tutte le richieste con `kubectl get csr`
- per approvare usa `kubectl certificate approve jane`
- a quel punto il certificato firmato si può ottenere con `kubectl get csr jane -o yaml` ma è encodato in base64 
- `echo "<testo encodato>" | base64 --decode`

tutte le operazioni relative ai certificati vengono fatte dal controller manager

### KubeConfig

il kubeconfig è un file di parametri letto automaticamente durante l'invocazione di kubectl, di default viene cercato in `$HOME/.kube/config`

è composto da 3 sezioni:

- cluster, dove vengono speficicati i vari cluster
- users, i vari utenti che hanno accesso ai cluster
- contexts, definiscono che user usare su che cluster

con la chiave `current-context` si setta l'accoppiata user-cluster da usare di default

con il comando `kubectl config view` si possono vedere i settings correnti

con `kubectl config use-context <nomecontext>` si può switchare di context, il nome del context dev'essere già presente nel kubeconfig

nel context del kubeconfig si può anche specificare un namespace da usare

### Api Groups

con il comando `kubectl proxy` si può far partire un proxy http locale per poter fare chiamate curl autenticate senza dover specificare key, cert e cacert

### RBAC

prima si crea il role

```yaml title="developer-role.yaml"
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
    name: developer
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list", "get", "create", "update", "delete"]
- apiGroups: [""]
  resources: ["ConfigMap"]
  verbs: ["create"]
```

poi si linka il ruolo all'utente con il rolebinding

```yaml title="devuser-developer-binding.yaml"
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
    name: devuser-developer-binding
subjects:
- kind: User
  name: dev-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

i role sono namespace-scoped, per specificare un namespace bisogna metterlo nei metadata

per vedere i ruoli `kubectl get roles`

per i rolebinding `kubectl get rolebindings`


per vedere se ho i permessi per fare qualcosa, `kubectl auth can-i create deployments`

posso impersonare un utente con `--as nomeutente`, posso vedere i permessi per un namespace con `--namespace` 

`kubectl auth can-i create pods --as dev-user --namespace test`

per restringere i permessi a risorse particolari

```yaml title="developer-role.yaml"
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
    name: developer
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list", "get", "create", "update", "delete"]
  resourceNames: ["blue", "orange"]
```


### Cluster roles

i role e i rolebinding sono relativi ai namespace, se non viene specificato un namespace viene sottointeso quello di default

i clusterrole si applicano a risorse trasversali, tipo nodi, pv, CertificateSigningRequest

`kubectl api-resources --namespaced=true` e `kubectl api-resources --namespaced=false`

esempi di utilizzo: cluster admin che può creare/eliminare nodi, oppure storage admin che può creare e cancellare persistentvolume


```yaml title="cluster-role.yaml"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
    name: cluster-administrator
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["list", "get", "create", "delete"]
```

```yaml title="cluster-admin-binding.yaml"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
    name: cluster-admin-role-binding
subjects:
- kind: User
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-administrator
  apiGroup: rbac.authorization.k8s.io
```

se si crea un clusterrole per una risorsa namespaced, le regole per quella risorsa saranno valide per tutti i namespace


### Service accounts

`kubectl create serviceaccount dashboard-sa` per creare l'account

`kubectl create token dashboard-sa` per creare il token

alla creazione viene staccato un token per permettere di autenticatsi

`kubectl describe serviceaccount dashbopard-sa`

il token è storato come secret

`kubectl describe secret nometoken`

se l'applicazione è hostata sul cluster, il secret può essere dirattamente montato come volume nel pod

ogni volta che viene creato un namespace, viene creato un serviceaccount di default che viene montato come volume in tutti i pod

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
    serviceAccountName: dashboard-sa # per passare le credenziali
    automountServiceAccountToken: false # di default è true
```

### Image Security

per usare immagini da un registry privato bisogna creare un secret di tipo docker-registry

```bash
kubectl create secret docker-registry regcred \
    --docker-server=private-registry.io \
    --docker-username=registry-user \
    --docker-password=registry-password \
    --docker-email=registry-user@org.com
```
```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: myapp-pod
spec:
    containers:
    - name: nginx
      image: private-registry.io/apps/asdasd
    imagePullSecrets:
    - name: regcred
```

### Security contexts

i security context possono essere configurati a livello di pod o di container: a livello di pod vengono applicati su tutti i container, ma se vengono definiti anche a livello di container, allora questi overridano quelli a livello di pod

```yaml title="pod-definition.yml"
apiVersion: v1
kind: Pod
metadata: 
    name: myapp-pod
spec:
    securityContext: # a livello di pod
        runAsUser: 1000
    containers:
    - name: ubuntu
      image: ubuntu
      command: ["sleep", "3600"]
      securityContext: # a livello di container
        runAsUser: 1000
        capabilities: # disponibili solo a livello di container e NON di pod
            add: ["MAC_ADMIN"] 
```

### Network policies

ingress = traffico dal client al server
egress = traffico dal server al client

le network policy vengono applicate ai pod, e servono a limitare il traffico su determiante porte e determinati pod

```yaml title="Allow ingress traffic from api-pod on port 3306"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: 
    name: db-policy
spec:
    podSelector:
       matchLabels:
          role: db
    policyTypes:
    - Ingress
    ingress:
    - from:
      - podSelector:
          matchLabels:
             name: api-pod
      ports:
      - protocol: TCP
        port: 3306   
```

```yaml title="Allow ingress traffic from pod within namespace"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: 
    name: db-policy
spec:
    podSelector:
       matchLabels:
          role: db
    policyTypes:
    - Ingress
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
             name: prod
      ports:
      - protocol: TCP
        port: 3306   
```

```yaml title="Allow ingress traffic from pod within namespace"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: 
    name: db-policy
spec:
    podSelector:
       matchLabels:
          role: db
    policyTypes:
    - Ingress
    ingress:
    - from:
      - podSelector:
          matchLabels:
             name: api-pod
        namespaceSelector:
          matchLabels:
             name: prod
      - ipBlock:
          cidr: 192.168.5.10/32
      ports:
      - protocol: TCP
        port: 3306   
```

le rules possono essere combinate per agire in AND, altrimenti vengono validate singolarmente

```yaml title="Allow ingress traffic from pod within namespace"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: 
    name: db-policy
spec:
    podSelector:
       matchLabels:
          role: db
    policyTypes:
    - Ingress
    - Egress
    ingress:
    - from:
      - podSelector:
          matchLabels:
             name: api-pod
    egress:
    - to:
      - ipBlock:
           cidr: 192.168.5.10/32
      ports:
      - protocol: TCP
        port: 3306   
```

### CRD

```yaml title="flight-crd.yaml"
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata: 
  name: flighttickets.flights.com
spec:
  scope: Namespaced
  group: flights.com
  names:
    kind: FlightTicket
    singular: flightticket
    plural: flighttickets
    shortNames:
    - ft
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              from:
                type: string
              to:
                type: string
              number:
                type: integer
                minimum: 1
                maximum: 10
```

```yaml title="flight-ticket.yaml"
apiVersion: flights.com/v1
kind: FlightTicket
metadata:
  name: my-flight-ticket
spec:
  from: Mumbai
  to: London
  number: 2
```

## Storage

### Container storage interface

Il container runtime interface è un'astrazione comune per dare supporto a diversi runtime (docker, cri-o, rkt)

allo stesso modo, la Container Networking interface astrae la gestione della rete (flannel, cilium)

per lo storage c'è la Container Storage Interface

### Volumes

```yaml title="esempio volume"
apiVersion: v1
kind: Pod
metadata:
  name: random-number-generator
spec:
  containers:
  - image: alpine
    name: alpine
    command: ["/bin/sh", "-c"]
    args: ["shuf -i 0-100 -n 1 >> /opt/number.out;"]
    volumeMounts:
    - mountPath: /opt
      name: data-volume

  volumes:
  - name: data-volume
    hostPath:
      path: /data
      type: Directory  
```

### Persistent Volumes

invece che definire il volume a livello di pod, si possono usare i PV configurati a livello di cluster

i PV possono poi essere usati dai pod tramite i PersistentVolumeClaims

```yaml title="pv-definition.yaml"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-vol1
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 1Gi
  hostPath:
    path: /data
```

### PersistentVolumeClaims

gli admin creano i PV, gli utenti usano i PVC per usare i volume

ogni PersistentVolume può essere bindato a un solo PVC

kubernetes individua il PV con sufficiente spazio richiesto nel claim e le altre proprietà richieste

se ci sono più match per il claim, si possono usare le label per indicare un PVC

se non ci sono match, iil PVC rimane in stato pending finchè non ci sono PV disponibili, a quel punto avviene il binding


```yaml title="pvc-definition.yaml"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  persistentVolumeReclaimPolicy: Retain # default
```

sulla cancellazione di un PVC, di default il volume rimane e non viene usato da altri claim (Retain), può essere cancellato insieme al PVC (Delete) oppure può essere svuotato per essere usato da altri claim (Recycle)


### Storage class

Static provisioning quando il volume è da creare a mano (es su uno storage esterno)

Dynamic provisioning quando viene creato in automatico da uno DefaultStorageClass


```yaml title="pvc-definition.yaml"
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: google-storage
provisioner: kubernetes.io/gce-pd
parameters: # specifici per provisioner
  type: pd-standard
  replication-type: none
```

usando la storageclassname dentro un pvc, non è necessario creare il volume perchè a questo penserà direttamente lo storage class

## Networking

porte standard:

|kube-api|6443|
|kubelet|10250|
|kube-scheduler|10259|
|kube-controller-manager|10257|
|services|30000-32767|
|etcd|2379|
|etcd-client|2380|

### Pod Networking

As an impact, the old weave net installation link won’t work anymore: –

kubectl apply -f “https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d ‘\n’)”

Instead of that, use the latest link below to install the weave net: –

kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

il CNI configurato si può vedere da `/etc/cni/net.d/`

di default viene installato sotto /opt/cni/bin


### Service networking

i services sono accessibili a tutti i nodi del cluster (ClusterIp)

un NodePort funziona come un ClusterIp, ma espone il servizio anche su tutti i nodi

per vedere le iptable di un service `iptables -L -t nat | grep nomeservice`

### Cluster DNS

di default, kubernates crea un record dns interno per ogni servizio

`nomeservizio.nomenamespace.svc.cluster.local`

per i pod si può abilitare, e il nome sarà con l'ip del pod sostituendo i . con -

`10-244-2-5.nomenamespace.pod.cluster.local`


### Core DNS

core dns viene deployato come pod nel cluster, nel file `/etc/coredns/Corefile` sono elencati i plugin configurati

### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: ingress-wear
spec:
    backend:
        serviceName: wear-service
        servicePort: 80
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: ingress-wear
spec:
    rules:
    - http:
        paths:
        - path: /wear
          pathType: Prefix
          backend:
            service:
              name: wear-service
              port:
                number: 80
        - path: /watch
          pathType: Prefix
          backend:
            service:
              name: watch-service
              port:
                number: 80
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: ingress-wear
spec:
    rules:
    - host: wear.my-online-store.com
      http:
        paths:
         - backend:
            service:
              name: wear-service
              port:
                number: 80
    - host: watch.my-online-store.com
      http:
        paths:
        - backend:
            service:
              name: watch-service
              port:
                number: 80
```

`kubectl create ingress ingress-test --rule="wear.my-online-store.com/wear*=wear-service:80"**`

<https://kubernetes.io/docs/concepts/services-networking/ingress>


### Gateway api

l'infrastructure provider configura il GatewayClass per definire che network provider usare (nginx, traefik)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
    name: example-class
spec:
    controllerName: example.com/gateway-controller
```

il cluster operator configurano i Gateway che sono istanze del GatewayClass

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
    name: example-gateway
spec:
    gatewayClassName: example-class
    listeners:
    - name: http
      protocol: HTTP
      port: 80
```

i dev configurano le HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
    name: example-httproute
spec:
    parentRefs:
    - name: example-gateway
    hostnames:
    - "www.example.com"
    rules:
    - matches:
        - path:
            type: PathPrefix
            value: /login
        backendRefs:
        - name: example-svc
          port: 8080
```

questo approccio è nativo, non è vendor specific e supporta configurazioni più complesse
