#!/bin/sh

# 
print_config_file (){
	echo "${CKAN_CONFIG}/${CKAN_CONFIG_FILE}"
}

# Inicializa TODAS las bases de ckan
init_db(){
	${CKAN_HOME}/bin/paster --plugin=ckan db init -c $(print_config_file)
}

# Inicializa bases para el datastore de ckan
init_datastore(){
	# Exportamos 
	export PGUSER=$DB_ENV_POSTGRES_USER;
	export PGPASSWORD=$DB_ENV_POSTGRES_PASS;
	export PGHOST=$DB_PORT_5432_TCP_ADDR;
	export PGDATABASE=$DB_ENV_POSTGRES_DB;
	export PGPORT=$DB_PORT_5432_TCP_PORT;
	
	# Creamos Role y Database para datastore
	psql -c "CREATE ROLE datastore_default WITH PASSWORD 'pass';"
	psql -c "CREATE DATABASE datastore_default OWNER $DB_ENV_POSTGRES_USER;"
	
	# Set permisos
	$CKAN_HOME/bin/paster --plugin=ckan datastore set-permissions -c $(print_config_file) | psql --set ON_ERROR_STOP=1
}


printf "Inicializando bases de datos... "
# Configuro e inicializo el plugin "DATASTORE"
init_datastore
rids=$?


# Inicializo de la base de datos por omision de CKAN
init_db
ridb=$?

# Sumo los codigos de error para simplificar la evaluacion de los mismos.
exit_code=$(($ridb + $rids))

if [[ exit_code -eq 0 ]];
	then 
	printf "[OK]\nBases de datos funcionales y listas!\n"
	exit 0
else
	printf "[FALLO]\nImposible inicializar las bases de datos!\n"
	exit 1
fi