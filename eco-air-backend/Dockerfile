# ============================================================
# Etapa 1: builder
# ============================================================
FROM maven:3.9.6-eclipse-temurin-17-alpine AS builder

ARG STUDENT_ID

WORKDIR /build

# 1. Copiar solo el pom.xml para cachear dependencias
COPY pom.xml .

# 2. Descargar dependencias (capa cacheada si pom.xml no cambia)
RUN mvn dependency:go-offline -B

# 3. Copiar el código fuente
COPY src/ ./src/

# 4. Empaquetar omitiendo pruebas
RUN mvn package -DskipTests -B

# ============================================================
# Etapa 2: runtime
# ============================================================
FROM eclipse-temurin:17-jre-alpine AS runtime

ARG STUDENT_ID

# Crear grupo y usuario sin privilegios
RUN addgroup -S sensorgroup && \
    adduser -S -u 10001 -G sensorgroup sensor_user

# Variables de entorno ergonómicas para la JVM
ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:InitialRAMPercentage=50.0 \
               -Djava.security.egd=file:/dev/./urandom"

# Inyectar ID del estudiante como variable de entorno
ENV OPERATOR_ID=${STUDENT_ID}

WORKDIR /app

# Copiar solo el .jar desde la etapa builder
COPY --from=builder /build/target/eco-air-backend.jar ./eco-air-backend.jar

# Cambiar titularidad del directorio /app al usuario sin privilegios
RUN chown -R sensor_user:sensorgroup /app

# Cambiar al usuario sin privilegios antes del ENTRYPOINT
USER sensor_user

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/eco-air-backend.jar"]
