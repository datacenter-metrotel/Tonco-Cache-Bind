#!/bin/bash

# Definir el directorio de trabajo
DIR="/var/spool/Tronco"
rm -f ./domains.list 
rm -f ./tronco.list
# Descargar Tronco (https://tranco-list.eu/)
wget --inet4-only https://tranco-list.eu/download/G6VXK/full -O tronco.list

# Crear el directorio si no existe
if [[ ! -d "$DIR" ]]; then
    mkdir -p "$DIR"
fi

# Verificar si el archivo tronco.list existe en el directorio actual
if [[ ! -f "tronco.list" ]]; then
    echo "El archivo tronco.list no existe en el directorio actual."
    exit 1
fi

# Leer solo las primeras 10000 líneas del archivo tronco.list
head -n 10000 tronco.list | while IFS= read -r line
do
    # Eliminar caracteres de retorno de carro (CR)
    line=$(echo "$line" | tr -d '\r')

    # Separar la línea por la coma
    num=$(echo "$line" | cut -d',' -f1)
    domain=$(echo "$line" | cut -d',' -f2 | awk '{print $1}')

    # Generar la línea con el comando dig
    echo "$domain" >> "$DIR/domains.list"
done

# Definir el directorio de trabajo donde se encuentra domains.list


# Verificar si el archivo domains.list existe en el directorio de trabajo
if [[ ! -f "$DIR/domains.list" ]]; then
    echo "El archivo domains.list no existe en el directorio $DIR."
    exit 1
fi

# Función para ejecutar dig para un dominio
function query_dns {
    domain=$1
    dig $domain @127.0.0.1 
}

# Exportar la función para que esté disponible para xargs
export -f query_dns

# Leer el archivo domains.list y usar xargs para ejecutar dig en paralelo
# Limitar a 50 dominios por segundo
cat "$DIR/domains.list" | xargs -n1 -P50 -I{} bash -c 'sleep 0.02; query_dns "{}"'
cat "$DIR/alexa.list" | xargs -n1 -P50 -I{} bash -c 'sleep 0.02; query_dns "{}"'

echo "Se han ejecutado las consultas DNS para los dominios en $DIR/domains.list"