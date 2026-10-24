# Image runtime seule : le jar est construit par Maven AVANT (cf. Jenkinsfile, "Build is Test").
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY target/calculator.jar app.jar
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}
EXPOSE 8080
USER 1000
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
