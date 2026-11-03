# FORENSIC REPORT — eco-air-backend
**Taller Docker: Contenerización, Seguridad de Runtime y Estrés de cgroups**

---

## Tabla de Identidad

| Campo | Valor |
|---|---|
| **Hash de la imagen** | `sha256:128d483658e7f532ab86487fb87a7f250ef259770dd5f3d32ee7e7f69b4b6bb2` |
| **Variable OPERATOR_ID** | `OPERATOR_ID=907839` |
| **Imagen** | `eco-air-backend:1.0.0` |
| **Comando de verificación hash** | `docker inspect --format='{{.Id}}' eco-air-backend:1.0.0` |
| **Comando de verificación OPERATOR_ID** | `docker exec eco_air_active env \| grep OPERATOR_ID` |

---

## Reto 1 — Construcción Multietapa

### Comando ejecutado
```bash
docker build --build-arg STUDENT_ID="907839" -t eco-air-backend:1.0.0 .
```

### Resultado
- Imagen construida exitosamente con dos etapas: `builder` y `runtime`
- Etapa builder: `maven:3.9.6-eclipse-temurin-17-alpine`
- Etapa runtime: `eclipse-temurin:17-jre-alpine`
- Tamaño final de la imagen: **453MB**
- `OPERATOR_ID=907839` inyectado correctamente vía `ARG STUDENT_ID`

---

## Reto 2 — Auditoría Forense

### 2.1 Verificación del Desacoplamiento de Capas

**Comando:**
```bash
docker history --human --format "table {{.Size}}\t{{.CreatedBy}}" eco-air-backend:1.0.0
```

**Salida:**
```
SIZE      CREATED BY
0B        ENTRYPOINT ["sh" "-c" "java $JAVA_OPTS -jar /app/eco-air-backend.jar"]
0B        EXPOSE map[8080/tcp:{}]
0B        USER sensor_user
49.5MB    RUN |1 STUDENT_ID=907839 /bin/sh -c chown -R sensor_user:sensorgroup /app
49.5MB    COPY /build/target/eco-air-backend.jar ./eco-air-backend.jar
8.19kB    WORKDIR /app
0B        ENV OPERATOR_ID=907839
0B        ENV JAVA_OPTS=-XX:+UseContainerSupport ...
41kB      RUN |1 STUDENT_ID=907839 /bin/sh -c addgroup -S sensorgroup && adduser ...
0B        ARG STUDENT_ID=907839
141MB     RUN /bin/sh -c set -eux; (JRE base layer)
44MB      RUN /bin/sh -c set -eux; apk add --no-cache ...
9.08MB    ADD alpine-minirootfs-3.24.2-x86_64.tar.gz /
```

**Análisis:** Cada instrucción del Dockerfile genera una capa independiente. La separación entre la descarga de dependencias (`pom.xml` + `dependency:go-offline`) y la compilación del código fuente (`src/`) permite reutilizar el caché de dependencias cuando solo cambia el código, reduciendo tiempos de build subsecuentes.

---

### 2.2 Inspección del Proceso del Host (Aislamiento de Privilegios)

**Comandos:**
```bash
docker run -d --name eco_air_active -p 8080:8080 eco-air-backend:1.0.0
docker top eco_air_active -o pid,user,comm
```

**Salida de `docker top`:**
```
PID     USER    COMMAND
959     10001   java
```

**Evidencia:** El proceso `java` se ejecuta bajo el UID `10001`, que corresponde al usuario `sensor_user`. No se ejecuta como `root` (UID 0). Esto confirma el aislamiento de privilegios configurado con `USER sensor_user` en el Dockerfile.

---

### 2.3 Test de Penetración — Comprobación de Inmutabilidad de Runtime

**Comando:**
```bash
docker exec eco_air_active touch /etc/crontab_fake
```

**Salida:**
```
touch: cannot touch '/etc/crontab_fake': Permission denied
```

**Evidencia:** El usuario `sensor_user` (UID 10001) no tiene permisos de escritura sobre directorios del sistema como `/etc`. El intento de crear un archivo malicioso fue bloqueado por el sistema operativo. Esto valida que el contenedor opera con el principio de mínimo privilegio.

---

### 2.4 Auditoría de Artefactos de Desarrollo

**Comandos:**
```bash
docker exec eco_air_active which mvn
docker exec eco_air_active find / -name "*.java" 2>/dev/null
```

**Salida de `which mvn`:**
```
(sin salida — comando no encontrado)
```

**Salida de `find *.java`:**
```
find: /root: Permission denied
find: /proc/tty/driver: Permission denied
(sin archivos .java encontrados)
```

**Explicación:** Gracias al build multietapa, la imagen de runtime (`eclipse-temurin:17-jre-alpine`) **no contiene** Maven, el JDK, ni ningún archivo `.java` del código fuente. Solo se copió el artefacto `.jar` compilado desde la etapa `builder`. Esto reduce la superficie de ataque eliminando todas las herramientas de desarrollo de la imagen de producción.

---

## Reto 3 — Calibración de cgroups y OOM Killer

### 3.1 Inducción del Colapso por Memoria (OOMKilled)

**Comando:**
```bash
docker run -d --name eco_air_crash -m 48m eco-air-backend:1.0.0
docker inspect eco_air_crash --format='Status: {{.State.Status}} | ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}'
```

**Salida:**
```
Status: exited | ExitCode: 137 | OOMKilled: true
```

**Explicación:** Con solo 48 MB asignados, la JVM no puede reservar el heap mínimo necesario para inicializar Spring Boot con Hibernate. El kernel Linux detecta que el proceso excede el límite del cgroup y lo termina con `SIGKILL` (señal 9 = ExitCode 137). El campo `OOMKilled: true` confirma que fue el OOM Killer del kernel quien terminó el proceso, no una excepción de la aplicación.

---

### 3.2 Calibración del Límite Operativo Mínimo

**Iteraciones realizadas:**

| Memoria | Estado | Tiempo de arranque | OOMKilled | Cumple < 15s |
|---|---|---|---|---|
| 48m | `exited` | — | `true` | ❌ |
| 128m | `running` | 13.63s | `false` | ✅ |
| 160m | `running` | 10.74s | `false` | ✅ |
| 192m | `running` | 11.37s | `false` | ✅ |
| 256m | `running` | 7.09s | `false` | ✅ |

**Umbral mínimo encontrado: `128m`**

**Log de confirmación (128m):**
```
2026-10-20T21:19:38.576594599Z  INFO 1 --- [eco-air-backend] [main]
com.ecoair.backend.EcoAirApplication : Started EcoAirApplication
in 13.639 seconds (process running for 14.429)
```

**Nota:** Con 112m el contenedor arranca pero tarda 27 segundos, superando el límite de 15s del enunciado. Con 128m arranca en 13.6s cumpliendo todos los criterios.

---

### 3.3 Consumo Final Calibrado — docker stats

**Comando:**
```bash
docker stats --no-stream eco_air_active
```

**Salida:**
```
CONTAINER ID   NAME             CPU %   MEM USAGE / LIMIT    MEM %   NET I/O         BLOCK I/O    PIDS
3076c221abd4   eco_air_active   0.20%   290.2MiB / 7.57GiB   3.74%   2.05kB / 126B   0B / 741kB   52
```

---

## Resumen de Evidencias

| Reto | Prueba | Resultado |
|---|---|---|
| R1 | Build multietapa con STUDENT_ID | ✅ BUILD SUCCESS |
| R2.1 | Desacoplamiento de capas | ✅ Capas separadas visibles |
| R2.2 | Proceso java no corre como root | ✅ UID 10001 (sensor_user) |
| R2.3 | Escritura en /etc bloqueada | ✅ Permission denied |
| R2.4 | Maven y .java ausentes en runtime | ✅ No encontrados |
| R3.1 | OOMKilled con 48m | ✅ OOMKilled: true, ExitCode: 137 |
| R3.2 | Umbral mínimo operativo | ✅ 128m — arranca en 13.6s |
