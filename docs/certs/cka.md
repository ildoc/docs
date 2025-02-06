---
title: Certified Kubernetes Administrator (CKA)
---

Appunti del corso https://learn.kodekloud.com/courses/cka-certification-course-certified-kubernetes-administrator

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


