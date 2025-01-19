# Comandi utili per la shell

## oh-my-zsh
un framework costruito su zsh

``` bash title="Per installare oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## bat
come `cat` ma con syntax-highlighting e supporto a git

## fzf
fuzzy finder con un sacco di funzionalità per trovare velocemente all'interno di molti file

``` bash title="comando figo per esplorare una cartella di codice"
fzf --preview 'bat --color=always {}'
```
supporta il pipe da altri comandi e si possono fare robe tipo
``` bash
docker ps | fzf --preview 'docker inspect {1}'
```

## tldr
alternativa a man, con i colori.

per installarlo serve il pacchetto `tlrc`