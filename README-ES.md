# Infraestructura de 3 Capas

Este repositorio contiene la arquitectura, las configuraciones y los pasos del despliegue de una infraestructura de tres capas implementada en Google Cloud Platform (GCP).
**IP Pública del servidor web:** `http://34.4.111.71`

## 1. Configuración de Red y Seguridad

Se creó una **VPC personalizada**, la cual funciona como una red virtual privada e aislada que permite la comunicación interna entre todos los componentes de la arquitectura. Dentro de esta VPC se definieron dos subredes:
* **Subred Pública:** Aloja los recursos y servidores que requieren exposición directa a Internet. Esta red tiene el bloque `10.0.1.0/24`.
- **Subred Privada:** Encapsula y aísla la base de datos para evitar que sea expuesta a la red externa, garantizando que solo respondan a peticiones de la red interna. Esta red tiene el bloque `10.0.2.0/24`.

## 2. Reglas de Firewall (Grupos de seguridad)
Luego se creo las reglas de firewall para restringir el trafico de entrada a los servidores, permitiendo el acceso a los puertos desde las ip especificadas. Esto agrega una capa de seguridad donde aseguramos quien puede acceder.
Parámetros de cada regla:

| **Nombre de Regla** | **Subred Destino** | **Protocolo / Puerto** | **Origen Permitido** | **Propósito**                                 |
| ------------------- | ------------------ | ---------------------- | -------------------- | --------------------------------------------- |
| `web`               | subred publica     | TCP / 80               | `0.0.0.0/0`          | Tráfico web público hacia Nginx               |
| `ssh-google`        | publica / privada  | TCP / 22               | `35.235.240.0/20`    | Conexión remota por SSH                       |
| `base-datos`        | subred privada     | TCP / 3306             | `10.0.1.0/24`        | Dar acceso a la base de datos al servidor web |
| `ssh-compu`         | subred publica     | TCP / 22               | `---`                | Conexión remota por SSH a mi computadora      |

## 3. Creación del servidor web

**Aprovisionamiento:** Se creo una instancia Compute Engine (Ubuntu) en la subred `10.0.1.0/24` con IP pública asignada para el acceso a internet. También se le agrego las llaves SSH correspondientes para la conexión a la consola.

**Instalación del servicio web:** Se accede remotamente por SSH y se instala nginx como servicio web.

```
sudo apt update
sudo apt install nginx
```

**Prueba del funcionamiento del servicio:** Se comprueba accediendo a la ip publica desde un navegador. Luego de confirmar el funcionamiento con el banner de Nginx se procede a desplegar la pagina web `index.html` en el directorio `/var/www/html/`.

## 4. Creación del servidor de base de datos

**Aprovisionamiento y Conectividad :** Se creo una instancia Compute Engine (Ubuntu) en la subred `10.0.2.0/24` sin IP pública, por lo que no dispone de conectividad directa a internet. Para eso se configuró **Cloud Router** y **Cloud NAT** en GCP para habilitar la descarga de paquetes desde Internet en la subred privada sin exponer la base de datos.

**Instalación y Configuración del Motor de BD:** Se accede remotamente por SSH y se instala mariadb como motor de base de datos.	

```
sudo apt install mariadb-server
```    

Luego se ejecuta el instalador seguro y se configura la contraseña de root. Tambien se cambia la configuración `/etc/mysql/mysql.conf.d/mysqld.cnf` de mariadb para escuchar las peticiones desde cualquier servidor `0.0.0.0`. Dado que las reglas de firewall ya limitan el trafico, la seguridad no se ve comprometida.
Reiniciamos el servicio para que funsione con la nueva configuración.

```
sudo systemctl restart mysql
```

Al final se creo un nuevo usuario con todos los permisos, que se usara específicamente para conectarnos desde la web y crear la base de datos.

```
CREATE USER 'Admin'@'%' IDENTIFIED BY 'ClaveSegura123!';
GRANT ALL PRIVILEGES ON *.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
```

**Creación de la Estructura de Datos y Usuarios:** Desde el servidor web, instalamos y nos conectamos a la base de datos con mariadb-client. 

```
sudo apt update
sudo apt install mariadb-client
```

Utilizamos el usuario `admin` para acceder remotamente a la consola de mariadb y crear la base de datos.

```
mariadb-client -h 10.0.2.5 -u admin -p
```
