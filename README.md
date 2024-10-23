# CVA6 RISCV-Procesor

Este proyecto tiene como objetivo analizar [CVA6](https://github.com/openhwgroup/cva6), un procesador de 64 bits con arquitectura RISCV de 6 etapas desarrollado en el lenguaje de descripcion de hardware **SystemVerilog**. 

## Primeros Pasos

A continuacion se detalla ordenadamente los pasos necesarios para poder empezar con el proyecto. Se asume que se trabajara desde un sistema operativo **Linux Debian**.

En este proyecto se utiliza [Docker](https://www.docker.com/), para evitar instalar todas las dependencias necesarias de CVA6 en el sistema operativo y lograr una mayor portabilidad. Se proveera una imagen de Docker con todas las herramientas necesarias para trabajar con el procesador.

### 1) Instalación de Docker

Para instalar la herramienta se debe correr los  comandos:

```bash
sudo apt-get update
sudo apt install docker.io
```

Verificar que se haya instalado correctamente:

```bash
sudo docker version
```

Permitir a Docker acceso al server X (GUI). Este comando debe ser ejecutado cada vez que se inicie la PC. Se recomienda agregarlo al archivo `.bashrc`:

```bash
xhost +local:docker
```

### Configuracion opcional

Se recomienda realizar los siguientes pasos para facilitar el uso de la herramienta Docker:

#### Hacer que Docker inicie automaticamente al encender la PC

```bash
sudo systemctl enable docker 
```

#### No tener que usar sudo para correr comandos de Docker

Reemplazar `<user_name>` por el nombre de usuario de la PC (se puede obtener corriendo `whoami`).

```bash
sudo groupadd docker
sudo usermod -aG docker <user_name>
newgrp docker
ls -l /var/run/docker.sock
```

Al finalizar deberia aparecer lo siguiente:

```bash
srw-rw---- 1 root docker 0 <date> /var/run/docker.sock
```

#### Acceder al contenido del contenedor desde VSCode

Para poder acceder al contenido del contenedor desde VSCode se debe instalar la extension `Docker` en el apartado de `Extensions`.

### 2) Iniciar Docker

Iniciar el servicio:

```bash
sudo systemctl start docker
```

Verificar que se haya iniciado correctamente:

```bash
sudo systemctl status docker
```

Para apagar el servicio correr:

```bash
sudo systemctl stop docker
```

### 3) Descargar la imagen

Ingresar a [Docker Hub](https://hub.docker.com/r/manuel313/cva6/tags) para ver cual es la tag de la imagen mas actualizada y luego descargarla (reemplazar `<tag>` por la tag deseada):

```bash
docker pull manuel313/cva6:<tag>
```

Corroborar que se haya descargado correctamente:

```bash
docker images
```

### 4) Crear el Contenedor

Crear un contenedor `container_name` que sera manipulado mediante una terminal bash y el cual tendra permisos para ejecutar aplicaciones de interfaz grafica (reemplazar `<tag>` por la tag de la imagen descargada y `<container_name>` por el nombre de contenedor deseado):

```bash
docker run -it --name <container_name> -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix manuel313/cva6:<tag> bash
```

Salir del contenedor corriendo el siguiente comando desde su terminal:
    
```bash
exit
```

### 5) Iniciar/Cerrar el Contenedor

Una vez creado el contenedor, para iniciarlo correr:

```bash
docker start <container_name>
```

Para ingresar al contenedor correr:

```bash
docker exec -e DISPLAY=$DISPLAY -it <container_name> bash
```

Para salir del contenedor correr desde la terminal del mismo:

```bash
exit
```

Para detener el contenedor correr:

```bash
docker stop <container_name>
```

## Correr el primer Test

Para verificar que todo este funcionando correctamente, ejecutar un test `hello_world.c` sobre el procesador CVA6. Dentro del contenedor correr los siguientes comandos:

```bash
source verif/sim/setup-env.sh
cd ./verif/sim
export DV_SIMULATORS=veri-testharness
export TRACE_FAST=1
python3 cva6.py --target cv64a6_imafdc_sv39 --iss=$DV_SIMULATORS --iss_yaml=cva6.yaml \
--c_tests ../tests/custom/hello_world/hello_world.c \
--linker=../tests/custom/common/test.ld \
--gcc_opts="-static -mcmodel=medany -fvisibility=hidden -nostdlib \
-nostartfiles -g ../tests/custom/common/syscalls.c \
../tests/custom/common/crt.S -lgcc \
-I../tests/custom/env -I../tests/custom/common"
```

Una vez finalizado se creara una carpeta `out_year-month-day` con los resultados del test. Para visualizar los resultados se puede correr el siguiente comando (reemplazando `<year-month-day>` por la fecha de la carpeta):

```bash
cd out_<year-month-day>/veri-testharness_sim
gtkwave hello_world.cv64a6_imafdc_sv39.vcd
```

Si se desea correr otro test, se debe cambiar el codigo `hello_world.c`. El mismo se encuentra en la carpeta `verif/tests/custom/hello_world`. Una vez modificado el codigo, se recomieda verificar que el mismo funcione correctamente antes de correr el test en el microprocesador:

```bash
gcc -Wall -Wextra -O3 -g -std=c99 -o program hello_world.c
./program
```

### Limitaciones

Tras haber probado el test `hello_world.c` con varias instrucciones de C, se observo que el procesador no soporta todas las instrucciones del lenguaje:
- `printf` no puede imprimir variables pero si strings. Por ejemplo, `printf("Hello World\n");` funciona correctamente mientras que `printf("%d\n", 5);` no.
- Las unicas librerias que soporta son `stdio.h` y `stdint.h`.
- No puede correr por mas de 2 millones de ciclos.


## Crear Imagen Docker

En caso de querer crear una imagen de Docker con las herramientas basicas para trabajar con el procesador, se debe seguir los siguientes pasos.

Primero, ubicarse en la carpeta raiz de este proyecto y correr el comando (reemplazando `<username>` y `<tag>` por los valores deseados): 

```bash
docker build -t <username>/cva6:<tag>
```

Luego crear un contenedor con esta nueva imagen. Para ello, seguir los pasos detallados en la seccion [Crear el Contenedor](#4-crear-el-contenedor) y [Iniciar/Cerrar el Contenedor](#5-iniciar/cerrar-el-contenedor). Una vez dentro del contenedor, se debe correr la secuencia de comandos:

```bash
source verif/sim/setup-env.sh
export DV_SIMULATORS=veri-testharness
bash verif/regress/smoke-tests.sh
```

Se recomienda ejecutar el test `hello_world.c` para verificar que todo este funcionando correctamente. En la seccion [Correr el primer Test](#correr-el-primer-test) se detallan los pasos a seguir.

Por ultimo, se debe salir del contenedor y cerrarlo. Una vez apagado, se debe crear una nueva imagen a partir del contenedor modificado, corriendo el comando (reemplazando `<username>` y `<tag>` por los valores anteriores y `<container_name>` por el nombre del contenedor):

```bash
docker commit <container_name> <username>/cva6:<tag>
```

Verificar que la imagen se haya creado correctamente:

```bash
docker images
```

## Crear Proyecto en Vivado

(TODO)
