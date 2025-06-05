# Use a minimal Java image
FROM openjdk:17-jdk-slim

# Add metadata
LABEL maintainer="thani2808"

# Set the working directory
WORKDIR /app

# Copy the built JAR (replace with exact name if needed)
COPY target/*.jar app.jar

# Expose port (must match Spring Boot server.port)
EXPOSE 9002

# Start the application
ENTRYPOINT ["java", "-jar", "app.jar"]
