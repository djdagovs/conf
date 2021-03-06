#!/bin/sh

. $(dirname $(readlink -f "$0"))/_lib/auxiliar.sh

netrc()
{
    if grep -qs "machine $1" ~/.netrc
    then
        perl -i -0pe "s/machine $1\n  login \w+\n  password \w+/machine $1\n  login $2\n  password $3/" ~/.netrc
    else
        asegura_salto_linea "$HOME/.netrc"
        echo "machine $1\n  login $2\n  password $3" >> ~/.netrc
    fi
}

crear_usuario_github()
{
    echo -n "Nombre de usuario en GitHub (NO el email): "
    read USUARIO
    if [ -n "$USUARIO" ]
    then
        echo "Creando configuración github.user..."
        github user "$USUARIO"
    fi
    echo $USUARIO
}

git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
git config --global push.default simple
# git config --global pull.rebase true

USER_NAME=$(git_user name)
if [ -n "$USER_NAME" ]
then
    echo -n "Configuración user.name ya creada. ¿Quieres cambiarla? (s/N): "
    read SN
    [ "$SN" = "s" ] && SN="S"
fi
if [ -z "$USER_NAME" ] || [ "$SN" = "S" ]
then
    echo -n "Nombre completo del programador: "
    read USER_NAME
    if [ -n "$USER_NAME" ]
    then
        echo "Creando configuración user.name..."
        git_user name "$USER_NAME"
    fi
fi

USER_EMAIL=$(git_user email)
if [ -n "$USER_EMAIL" ]
then
    echo -n "Configuración user.email ya creada. ¿Quieres cambiarla? (s/N): "
    read SN
    [ "$SN" = "s" ] && SN="S"
fi
if [ -z "$USER_EMAIL" ] || [ "$SN" = "S" ]
then
    echo -n "Dirección de email: "
    read USER_EMAIL
    if [ -n "$USER_EMAIL" ]
    then
        echo "Creando configuración user.email..."
        git_user email "$USER_EMAIL"
    fi
fi

if [ -z "$USER_NAME" ] || [ -z "$USER_EMAIL" ]
then
    echo "Configura el nombre y la dirección de email antes de continuar."
    exit 1
fi

USUARIO=$(github user)
if [ -n "$USUARIO" ]
then
    echo -n "Configuración github.user ya creada. ¿Quieres cambiarla? (s/N): "
    read SN
    [ "$SN" = "s" ] && SN="S"
fi
if [ -z "$USUARIO" ] || [ "$SN" = "S" ]
then
    USUARIO=$(crear_usuario_github)
fi

TOKEN=$(github token)
if [ -n "$TOKEN" ]
then
    echo -n "Token de GitHub ya creado. ¿Quieres cambiarlo? (s/N): "
    read SN
    [ "$SN" = "s" ] && SN="S"
fi
if [ -z "$TOKEN" ] || [ "$SN" = "S" ]
then
    if [ -z "$USUARIO" ]
    then
        echo "Para crear el token, debes indicar tu nombre de usuario en GitHub."
        echo -n "¿Quieres indicarlo ahora? (S/n): "
        read SN
        [ "$SN" = "n" ] && SN="N"
        if [ "$SN" != "N" ]
        then
            USUARIO=$(crear_usuario_github)
        fi
    fi
    if [ -n "$USUARIO" ]
    then
        DESC="Token de GitHub en $(hostname) $(date +%Y-%m-%d\ %H:%M)"
        JSON='{"scopes":["repo","gist"],"note":"'$DESC'"}'
        TOKEN=$(curl -s -u $USUARIO -d "$JSON" "https://api.github.com/authorizations" | grep '"token"')
        if [ -n "$TOKEN" ]
        then
            TOKEN=$(echo $TOKEN | cut -d":" -f2 | tr -d '", ')
            echo "Creando token de GitHub para git..."
            github token "$TOKEN"
        else
            echo "Ocurrió un error al crear el token de GitHub."
        fi
    fi
fi

if [ -n "$TOKEN" ]
then
    DEST=/usr/local/bin/ghi
    if [ -x $DEST ]
    then
        echo -n "Ghi ya instalado. ¿Desea actualizarlo? (S/n): "
        read SN
        [ "$SN" = "n" ] && SN="N"
    fi
    if [ "$SN" != "N" ]
    then
        echo "Instalando ghi en $DEST..."
        curl -sL "https://raw.githubusercontent.com/drazisil/ghi/master/ghi" | sudo tee $DEST > /dev/null
        sudo chmod a+x $DEST
    fi
    echo "Asignando parámetro ghi.token..."
    git config --global ghi.token $TOKEN
    DEST=/usr/local/bin/hub
    if [ -x $DEST ]
    then
        echo -n "GitHub-hub ya instalado. ¿Desea actualizarlo? (S/n): "
        read SN
        [ "$SN" = "n" ] && SN="N"
    fi
    if [ "$SN" != "N" ]
    then
        echo "Instalando GitHub-hub en $DEST..."
        VER="2.3.0-pre10"
        FILE="hub-linux-amd64-$VER"
        curl -sL "https://github.com/github/hub/releases/download/v$VER/$FILE.tgz" | tar xfz - --strip=2 "$FILE/bin/hub" -O | sudo tee $DEST > /dev/null
        sudo chmod a+x $DEST
    fi
    echo "Asignando parámetro hub.protocol = https..."
    git config --global hub.protocol https
    DEST=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/hub.zsh
    echo "Creando variable de entorno GITHUB_TOKEN en $DEST..."
    echo "export GITHUB_TOKEN=$TOKEN" > $DEST
fi

if [ -n "$USUARIO" ] && [ -n "$TOKEN" ]
then
    echo "Creando entradas en ~/.netrc..."
    [ -f ~/.netrc ] || touch ~/.netrc
    netrc "github.com" $USUARIO $TOKEN
    netrc "api.github.com" $USUARIO $TOKEN
fi
