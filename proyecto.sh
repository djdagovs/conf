#!/bin/sh

if [ -z "$1" ]; then
    echo "Sintaxis: $0 nombre"
    exit 1
fi

echo "Creando el proyecto desde la plantilla básica de Yii2..."
composer create-project yiisoft/yii2-app-basic $1
echo "Extrayendo el esqueleto modificado del proyecto..."
curl -L https://github.com/ricpelo/pre/tarball/master | tar xvz --strip 1 -C $1
cd $1
echo "Modificando archivos con el nombre del proyecto..."
/bin/sed -i s/proyecto/$1/g db/* config/*
/bin/mv db/proyecto.sql db/$1.sql
echo "Ejecutando composer update..."
composer update
echo "Creando repositorio git..."
git init
git add .
git commit -m "Carga inicial"
if ! grep -q "$1.local" /etc/hosts > /dev/null
then
    echo "Añadiendo entrada para $1.local en /etc/hosts..."
    if grep -q "^$" /etc/hosts > /dev/null
    then
        sudo sed "s/^$/127.0.0.1	$1.local\n/" /etc/hosts
    else
        echo "127.0.0.1	$1.local" | sudo tee -a /etc/hosts
    fi
else
    echo "Ya existe una entrada para $1.local en /etc/hosts."
fi

