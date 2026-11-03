# Análisis del Proyecto: eco-air-backend

> **Fecha del análisis:** 2025  
> **Proyecto:** `eco-air-backend` — versión `0.0.1-SNAPSHOT` / imagen Docker `1.0.0`  
> **Estudiante / Operador:** ID `907839`

---

## Resumen Ejecutivo

**eco-air-backend** es un backend REST de monitoreo de calidad del aire, desarrollado en Java con Spring Boot 3. Su función principal es recibir y consultar alertas generadas por sensores ambientales distribuidos en distintas ubicaciones. El proyecto sirve como **aplicativo de referencia para un taller de Docker** universitario, donde el código en sí es simple pero el foco pedagógico está en la contenerización segura: construcción multietapa, aislamiento de privilegios en tiempo de ejecución, y calibración de límites de memoria con cgroups. El taller fue completado satisfactoriamente por el estudiante 907839, cumpliendo todos los retos planteados.

---

## 1. Dominio y Problema que Resuelve

El sistema modela un **sistema de alertas de calidad del aire (AQI — Air Quality Index)**. Recibe lecturas de sensores físicos que miden niveles de contaminación en diferentes puntos geográficos. Cuando un sensor detecta contaminación por encima de un umbral, genera una alerta con:

- **`sensorId`**: identificador del sensor origen
- **`location`**: ubicación geográfica donde se detectó la contaminación
- **`pollutionLevel`**: nivel numérico de contaminación medido (Double)
- **`alertType`**: tipo de alerta (e.g., clasificación por contaminante)
- **`timestamp`**: marca temporal de la detección
- **`status`**: estado de la alerta (`ACTIVE`, u otros estados del ciclo de vida)

El sistema permite crear alertas desde dispositivos externos (sensores IoT o sistemas intermediarios) y consultarlas filtrando por estado.

**Evidencia:** `Alert.java` — campos `sensorId`, `location`, `pollutionLevel`, `alertType`, `timestamp`, `status`; `pom.xml` — `<description>EcoAir Backend for air quality monitoring</description>`.

---

## 2. Tecnologías y Dependencias

### Stack Principal

| Tecnología | Versión | Rol |
|---|---|---|
| **Java** | 17 (LTS) | Lenguaje de programación |
| **Spring Boot** | 3.2.5 | Framework de aplicación |
| **Spring Web (MVC)** | (heredado de Boot 3.2.5) | Capa REST / API HTTP |
| **Spring Data JPA** | (heredado de Boot 3.2.5) | Abstracción de persistencia ORM |
| **Hibernate** | (incluido en JPA starter) | Implementación JPA / ORM |
| **H2 Database** | runtime | Base de datos en memoria |
| **Spring Actuator** | (heredado de Boot 3.2.5) | Endpoints de salud e info |
| **Maven** | 3.9.6 (wrapper) | Gestor de dependencias y build |

### Dependencias en `pom.xml`

```xml
spring-boot-starter-web          <!-- API REST -->
spring-boot-starter-data-jpa     <!-- ORM / Repositorios -->
spring-boot-starter-actuator     <!-- /actuator/health, /actuator/info -->
com.h2database:h2 (scope:runtime)<!-- Base de datos en memoria -->
spring-boot-starter-test (test)  <!-- Testing (JUnit, Mockito) -->
```

### Entorno de Contenedor

| Imagen | Rol |
|---|---|
| `maven:3.9.6-eclipse-temurin-17-alpine` | Etapa builder (compilación) |
| `eclipse-temurin:17-jre-alpine` | Etapa runtime (solo JRE, sin JDK/Maven) |

**Evidencia:** `pom.xml` completo; `Dockerfile` etapas `builder` y `runtime`.

---

## 3. Arquitectura y Estructura del Código

### Arquitectura General

La aplicación sigue la arquitectura en capas clásica de Spring Boot:

```
HTTP Request
     │
     ▼
┌─────────────────────┐
│   AlertController   │  (@RestController, /api/alerts)
└────────┬────────────┘
         │ usa
         ▼
┌─────────────────────┐
│  AlertRepository    │  (JpaRepository<Alert, Long>)
└────────┬────────────┘
         │ mapea
         ▼
┌─────────────────────┐
│   Alert (Entity)    │  (@Entity, tabla "alerts")
└─────────────────────┘
         │
         ▼
  H2 In-Memory DB
```

No hay capa de Servicio (Service layer) explícita — el controlador llama directamente al repositorio. Esto es apropiado para la escala del proyecto de taller.

### Estructura de Directorios

```
eco-air-backend/
├── src/main/java/com/ecoair/backend/
│   ├── EcoAirApplication.java          # Punto de entrada Spring Boot
│   ├── controller/
│   │   └── AlertController.java        # REST Controller
│   ├── model/
│   │   └── Alert.java                  # Entidad JPA
│   └── repository/
│       └── AlertRepository.java        # Repositorio Spring Data JPA
├── src/main/resources/
│   └── application.properties          # Configuración de la aplicación
├── pom.xml                             # Dependencias y build Maven
├── Dockerfile                          # Construcción multietapa
├── .dockerignore                       # Exclusiones del contexto Docker
├── FORENSIC_REPORT.md                  # Reporte forense del taller
├── audit_session.log                   # Log de sesión de auditoría Docker
└── reporte_taller_docker.html          # Reporte HTML del taller
```

### Clases Clave

#### `EcoAirApplication.java`
Punto de entrada estándar de Spring Boot. Anota con `@SpringBootApplication` que activa autoconfiguración, escaneo de componentes y configuración de beans.

#### `Alert.java` (modelo)
- Anotada con `@Entity` y `@Table(name = "alerts")`
- Clave primaria `id` de tipo `Long` con estrategia `IDENTITY` (autoincremental)
- Campos: `sensorId`, `location`, `pollutionLevel` (Double), `alertType`, `timestamp` (LocalDateTime), `status`
- Implementación manual de getters/setters (sin Lombok)

#### `AlertRepository.java`
- Extiende `JpaRepository<Alert, Long>` — hereda CRUD completo automáticamente
- Método personalizado: `findByStatus(String status)` — Spring Data deriva la query `SELECT * FROM alerts WHERE status = ?` sin código SQL manual

#### `AlertController.java`
- `@RestController` + `@RequestMapping("/api/alerts")`
- Inyección de dependencias via `@Autowired` en campo (podría mejorarse con inyección por constructor)

**Evidencia:** Todas las clases Java en `src/main/java/com/ecoair/backend/`.

---

## 4. API REST — Endpoints Expuestos

### Endpoints de Alertas (base: `/api/alerts`)

| Método | Ruta | Descripción | Body / Params |
|---|---|---|---|
| `GET` | `/api/alerts` | Retorna todas las alertas | — |
| `POST` | `/api/alerts` | Crea una nueva alerta | Body JSON con campos de `Alert` |
| `GET` | `/api/alerts/{id}` | Retorna una alerta por su ID | Path param: `id` (Long) |
| `GET` | `/api/alerts/active` | Retorna alertas con `status = "ACTIVE"` | — |

#### Ejemplo de Body para POST `/api/alerts`
```json
{
  "sensorId": "SENSOR-001",
  "location": "Bogotá Centro",
  "pollutionLevel": 85.5,
  "alertType": "PM2.5",
  "timestamp": "2026-10-20T21:00:00",
  "status": "ACTIVE"
}
```

### Endpoints de Actuator

| Ruta | Descripción |
|---|---|
| `/actuator/health` | Estado de salud del servicio |
| `/actuator/info` | Información de la aplicación |

### Consola H2 (solo desarrollo)

| Ruta | Descripción |
|---|---|
| `/h2-console` | Interfaz web para consultar la base de datos H2 |

**Puerto de escucha:** `8080` (expuesto también en Docker con `-p 8080:8080`)

**Evidencia:** `AlertController.java`; `application.properties` — `management.endpoints.web.exposure.include=health,info`; `spring.h2.console.path=/h2-console`.

---

## 5. Base de Datos

La aplicación usa **H2**, una base de datos **en memoria** (in-memory). Esto significa:

- **No hay persistencia entre reinicios**: cada vez que el contenedor o la aplicación se reinicia, los datos se pierden completamente
- **Esquema auto-generado**: Hibernate crea y elimina las tablas automáticamente con `ddl-auto=create-drop`
- **Sin configuración externa**: no requiere un servidor de base de datos separado

### Configuración (`application.properties`)

```properties
spring.datasource.url=jdbc:h2:mem:ecoairdb
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=true
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console
```

**Implicación para el taller:** La base de datos H2 en memoria es intencional para simplificar el despliegue Docker. En producción real se reemplazaría por PostgreSQL o MySQL con un volumen persistente.

**Evidencia:** `application.properties` completo.

---

## 6. Configuración Docker

### Dockerfile — Construcción Multietapa

El Dockerfile implementa un **multi-stage build** con dos etapas claramente diferenciadas:

#### Etapa 1: `builder`
```dockerfile
FROM maven:3.9.6-eclipse-temurin-17-alpine AS builder
ARG STUDENT_ID
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline -B       # Cachea dependencias
COPY src/ ./src/
RUN mvn package -DskipTests -B         # Compila y empaqueta
```

**Optimización clave:** Se copia `pom.xml` antes que `src/` para aprovechar el caché de capas de Docker. Si solo cambia el código fuente pero no las dependencias, Docker reutiliza la capa de `dependency:go-offline`, acelerando los builds subsecuentes.

#### Etapa 2: `runtime`
```dockerfile
FROM eclipse-temurin:17-jre-alpine AS runtime
ARG STUDENT_ID
RUN addgroup -S sensorgroup && adduser -S -u 10001 -G sensorgroup sensor_user
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 ..."
ENV OPERATOR_ID=${STUDENT_ID}
WORKDIR /app
COPY --from=builder /build/target/eco-air-backend.jar ./eco-air-backend.jar
RUN chown -R sensor_user:sensorgroup /app
USER sensor_user
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/eco-air-backend.jar"]
```

**Prácticas de seguridad implementadas:**
- Solo JRE (no JDK) en producción → superficie de ataque reducida
- Usuario sin privilegios `sensor_user` (UID 10001) → no corre como `root`
- `USE ContainerSupport` + `MaxRAMPercentage=75.0` → JVM respeta límites de cgroups
- Sin Maven ni código fuente `.java` en runtime → verificado con `docker exec`

### `.dockerignore`
Excluye `target/`, `.git/`, IDEs (`.idea/`, `.vscode/`), logs (`*.log`), y `.env`. Reduce el tamaño del contexto de build y evita subir artefactos o secretos locales.

### Imagen Final
- **Nombre:** `eco-air-backend:1.0.0`
- **Hash SHA256:** `128d483658e7f532ab86487fb87a7f250ef259770dd5f3d32ee7e7f69b4b6bb2`
- **Tamaño:** 453 MB
- **Memoria mínima operativa:** 128m (arranca en 13.6s)

**Evidencia:** `Dockerfile`; `.dockerignore`; `FORENSIC_REPORT.md`; `audit_session.log`.

---

## 7. Contexto del Taller — Los 3 Retos

El reporte forense (`FORENSIC_REPORT.md`) y el log de sesión (`audit_session.log`) documentan tres retos pedagógicos completados:

### Reto 1 — Construcción Multietapa ✅
Build exitoso con `--build-arg STUDENT_ID="907839"`. Se inyectó `OPERATOR_ID=907839` como variable de entorno en la imagen.

### Reto 2 — Auditoría Forense de Seguridad ✅
- **2.1 Desacoplamiento de capas:** Verificado con `docker history` — capas separadas para dependencias y código fuente.
- **2.2 Proceso no-root:** `docker top` confirmó UID `10001` (`sensor_user`), no `root` (UID 0).
- **2.3 Inmutabilidad de runtime:** Escritura en `/etc/crontab_fake` bloqueada con `Permission denied`.
- **2.4 Ausencia de artefactos de desarrollo:** `mvn` y archivos `.java` ausentes en la imagen de runtime.

### Reto 3 — Calibración de cgroups y OOM Killer ✅
- Con `48m`: `OOMKilled: true`, `ExitCode: 137`
- **Umbral mínimo: `128m`** — arranca en 13.6 segundos (dentro del límite de 15s exigido)
- Tabla de iteraciones: 48m ❌ → 128m ✅ → 160m ✅ → 192m ✅ → 256m ✅

---

## 8. Conclusiones

1. **El proyecto es funcionalmente correcto pero mínimo**: La API REST cubre las operaciones CRUD básicas necesarias para el taller. No hay autenticación, validación de entrada, ni capa de servicio.

2. **La arquitectura Docker es sólida**: El Dockerfile multietapa sigue mejores prácticas reales de producción (mínimo privilegio, imagen base ligera, optimización de caché de capas).

3. **H2 en memoria es intencional**: Simplifica el despliegue Docker para el taller, pero no es apta para producción.

4. **El taller fue completado exitosamente**: Los 7 puntos de verificación del `FORENSIC_REPORT.md` pasaron con ✅.

---

## 9. Recomendaciones (sin implementar)

| # | Problema | Recomendación |
|---|---|---|
| 1 | **Sin persistencia real** | Reemplazar H2 por PostgreSQL con volumen Docker o servicio externo. Usar `docker-compose` con un servicio `db` y variable `DATABASE_URL`. |
| 2 | **Inyección por campo (`@Autowired`)** | Cambiar a inyección por constructor en `AlertController` para mejor testeabilidad y cumplimiento de buenas prácticas de Spring. |
| 3 | **Sin validación de entrada** | Agregar `@Valid` y anotaciones de Bean Validation (`@NotNull`, `@Min`) en el modelo `Alert` y en los métodos del controlador. |
| 4 | **H2 Console habilitada** | Deshabilitar `spring.h2.console.enabled=true` en perfiles distintos al de desarrollo. En producción es un vector de exposición de datos. |
| 5 | **Sin capa de servicio** | Para proyectos que escalen, agregar una clase `AlertService` entre el controlador y el repositorio para separar lógica de negocio de lógica de presentación. |
| 6 | **Sin gestión de errores global** | Agregar un `@ControllerAdvice` con `@ExceptionHandler` para retornar respuestas de error JSON consistentes en lugar de páginas de error por defecto. |
| 7 | **`ddl-auto=create-drop`** | Cambiar a `validate` o usar Flyway/Liquibase para manejo de migraciones en entornos no-desarrollo. |
| 8 | **Sin tests escritos** | El starter de test está en el POM pero no hay tests implementados. Agregar tests de integración para los endpoints con `@SpringBootTest`. |

---

*Análisis realizado leyendo directamente: `pom.xml`, `Dockerfile`, `.dockerignore`, `application.properties`, `EcoAirApplication.java`, `Alert.java`, `AlertController.java`, `AlertRepository.java`, `FORENSIC_REPORT.md`, `audit_session.log`.*
