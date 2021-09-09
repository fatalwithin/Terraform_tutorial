FROM node:lts-alpine
#some other variants if lts won't work
#FROM node:current-alpine
#FROM node:alpine
#FROM node:16-alpine
#FROM node:14-alpine
#FROM node:12-alpine

ENV NODE_ENV=development

RUN mkdir /app
RUN groupadd -r signageos && useradd -r -s /bin/false -g signageos signageos
RUN chown -R signageos:signageos /app

WORKDIR /app

USER signageos

COPY --chown=signageos:signageos ["package.json", "package-lock.json*", "./"]

RUN npm i --development

COPY . .

EXPOSE 8080

CMD [ "npm", "start" ] 

#need to create .dockerignore with the following lines in it:
#node_modules
#npm-debug.log
#Dockerfile
#.dockerignore
#.git
#.gitignore



