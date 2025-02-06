---
title: Certified Argo Project Associate (CAPA)
---

# Certified Argo Project Associate (CAPA)

<figure markdown="span">
![CAPA](https://training.linuxfoundation.org/wp-content/uploads/2023/11/Training_Badge_CAPA-300x300.png){ loading=lazy, align=center }
</figure>


Appunti del corso [Devops and workflow management with Argo (LFS256)](https://training.linuxfoundation.org/training/devops-and-workflow-management-with-argo-lfs256/)

## Argo CD


## Workflow

La parte principale di un manifest di workflow è l'entrypoint e una lista di template

### Template

I template possono essere di tipo:

- container
- resource: per creare/modificare/cancellare una risorsa
- script: simile a un container, si usa per eseguire semplici script
- suspend: praticamente uno sleep

I template possono essere invocati in due modi:

- dag: per definire un grafo di dipendenze, utile in contesti complessi con esecuzioni condizionali
- steps: task da eseguire in sequenza o in parallelo

### Outputs

Gli step dei workflow possono leggere e scrivere degli output per passarsi i dati.
Questi output possono essere artifact, dati o valori e sono definiti da un name e da un path dove il dato viene prodotto.

### WorkflowTemplate

Un WorkflowTemplate è una risorsa che definisce un template che può essere condiviso o riutilizzato, permette di incapsulare logica, parametri e metadata.
Questa astrazione facilita la modularità e la riusabilità di template, riducendo la ridondanza e forzando la consistenza.

### Argo Workflow

Il workflow viene gestito ed eseguito dal Workflow Controller, che per ciascuno step crea un pod con 3 container:

- init: un template che continene un init container per inizializzare le operazioni
- main: un template che contiene il container principale e viene eseguito appena le inizializzazioni sono finite
- wait: un container che esegue task di cleanup, salvataggio di parametri e artefatti

### Use cases

Argo Workflow può essere utilizzato per:

- orchestrare pipeline di data processing, come per esempio degli ETL
- task di preprocessing, training model, valutazione e deployment di progetti machine learning
- pipeline di CI/CD
- batch processing e task ricorrenti, per esempio basati su cron schedule per automatizzare task di routine o generazione di reportistica

## Rollout

## Events

Argo Events permette la Event-Driven Architecture in Kubernetes, per rispondere agli eventi in maniera automatica e scalabile.

I componenti principali sono:

- event source: è chi genera l'evento. Può essere qualsiasi cosa, un webhook, un messaggio su una coda, un evento schedulato
- sensor: i sensor sono i listener degli eventi
- eventbus: è responsabile di trasmettere gli eventi dai source ai sensor
- trigger: sono i meccanismi per rispondere gli eventi rilevati dai sensor. Possono gestire una vasta gamma di azioni, dal far partire un workflow all'aggiornare una risorsa


TRA01_CBA_ALTEN_20250204
