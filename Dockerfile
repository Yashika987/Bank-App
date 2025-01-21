#--------------Stage 1---------------#
#Import a maven docker Image
FROM maven:3.8.3-openjdk-17 as builder

#This line provides metadata about who to contact if there are issues or questions about the Docker image
LABEL maintainer="Yashika Maheshwari <yahika.m1996@gmail.com>"

#Add labels to the image to filter out if we have multiple application running
LABEL app=bankapp

#Set working directory
WORKDIR /src

#Copy source code from local to container
COPY . /src

#Build application and skip test cases
RUN mvn clean install -DskipTests=true

#--------------Stage2-----------------#

#Import small size java image
FROM openjdk:17-alpine as deployer

#Copy build from Stage 1
COPY --from=builder /src/target/*.jar /src/target/bankapp.jar

#Expose application port
EXPOSE 8080

#Start the application
ENTRYPOINT ["java", "-jar", "/src/target/bankapp.jar"]

