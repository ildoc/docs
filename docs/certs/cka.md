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


## Cluster maintenance
