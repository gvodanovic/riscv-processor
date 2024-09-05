# CVA6 RISCV-Procesor

Este proyecto tiene como objetivo analizar [CVA6](https://github.com/openhwgroup/cva6), un procesador de 64 bits con arquitectura RISCV de 6 etapas desarrollado en el lenguaje de descripción de hardware **SystemVerilog**. 

## Primeros Pasos

A continuación se detallan ordenadamente los pasos necesarios para poder empezar con el proyecto. Se asume que se trabajara desde **Linux Debian**.

En este proyecto se utiliza [Docker](https://www.docker.com/), para evitar instalar todas las dependencias necesarias de CVA6 en el sistema operativo y lograr una mayor portabilidad. Se proveerá una imagen de Docker con todas las herramientas necesarias para trabajar con el procesador.

### 1) Instalación de Docker

Para instalar la herramienta se deben correr los siguientes comandos:

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
sudo xhost +local:docker
```

### Configuracion Opcional

Se recomienda realizar los siguientes pasos para facilitar el uso de la herramienta:

#### Hacer que Docker inicie automaticamente al encender la PC

```bash
sudo systemctl enable docker 
```

#### No tener que usar sudo para correr comandos de Docker

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

Para poder acceder al contenido del contenedor desde VSCode se debe instalar la extension `Docker`.

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

### 3) Descargar la Imagen

Ingresar al [Docker Hub](https://hub.docker.com/r/manuel313/cva6/tags) para ver cual es la tag de la imagen mas actualizada y luego descargarla:

```bash
docker pull manuel313/cva6:<tag>
```

Corroborar que se haya descargado correctamente:

```bash
docker images
```

### 4) Crear el Contenedor

Crear un contenedor `container_name` que sera manipulado mediante una terminal bash y el cual tendra permisos para ejecutar aplicaciones de interfaz grafica:

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
python3 cva6.py --target cv64a6_mmu --iss=$DV_SIMULATORS --iss_yaml=cva6.yaml \
--c_tests ../tests/custom/hello_world/hello_world.c \
--linker=../tests/custom/common/test.ld \
--gcc_opts="-static -mcmodel=medany -fvisibility=hidden -nostdlib \
-nostartfiles -g ../tests/custom/common/syscalls.c \
../tests/custom/common/crt.S -lgcc \
-I../tests/custom/env -I../tests/custom/common"
```

Una vez finalizado se creara una carpeta `out_year-month-day` con los resultados del test. Para visualizar los resultados se puede correr el siguiente comando:

```bash
cd out_year-month-day/veri-testharness_sim
gtkwave hello_world.cv64a6_mmu.vcd
```

Si se desea correr otro test, se debe cambiar el codigo `hello_world.c`. El mismo se encuentra en la carpeta `verif/tests/custom/hello_world`. Una vez modificado el codigo, se recomieda verificar que el mismo funcione correctamente antes de correr el test en el microprocesador:

```bash
gcc -Wall -Wextra -O3 -g -std=c99 -o program hello_world.c
./program
```

### Observaciones

Tras haber probado el test `hello_world.c` con varias instrucciones de C, se observo que el procesador no soporta todas las instrucciones del lenguaje. Por ejemplo, no puede manipular numeros en punto flotante y tampoco puede realizar operaciones de memoria como `malloc` o `free`. Tampoco se ha logrado que el procesador corra por mas de 2 millones de ciclos sin que el simulador falle.

## Crear/Actualizar Imagen de Docker

(TODO)

## Crear Proyecto en Vivado

(TODO)
