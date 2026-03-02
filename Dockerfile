FROM eclipse-temurin:25-jdk AS builder

WORKDIR /app

# Gradle wrapper & build config (layer cache)
COPY gradlew .
COPY gradle gradle
COPY build.gradle.kts settings.gradle.kts ./

COPY subproject/boot/build.gradle.kts subproject/boot/
COPY subproject/domain/build.gradle.kts subproject/domain/
COPY subproject/application/build.gradle.kts subproject/application/
COPY subproject/presentation/build.gradle.kts subproject/presentation/
COPY subproject/infrastructure/build.gradle.kts subproject/infrastructure/

# Stub source dirs for dependency resolution
RUN mkdir -p subproject/boot/src/main/kotlin \
             subproject/domain/src/main/kotlin \
             subproject/application/src/main/kotlin \
             subproject/presentation/src/main/kotlin \
             subproject/infrastructure/src/main/kotlin

RUN chmod +x gradlew && ./gradlew dependencies --no-daemon -q || true

# Source code
COPY subproject subproject

RUN ./gradlew :subproject:boot:bootJar --no-daemon -x test

# ── Runtime ──
FROM eclipse-temurin:25-jre

WORKDIR /app

RUN groupadd -r appgroup && useradd -r -g appgroup appuser

COPY --from=builder /app/subproject/boot/build/libs/*.jar app.jar

RUN chown appuser:appgroup app.jar
USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
