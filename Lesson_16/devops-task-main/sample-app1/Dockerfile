FROM node:lts-alpine
#some other variants if lts won't work
#FROM node:current-alpine
#FROM node:alpine
#FROM node:16-alpine
#FROM node:14-alpine
#FROM node:12-alpine
ENV USER=signageos
ENV UID=12345
ENV GID=23456

RUN mkdir /app

#    --disabled-password prevents prompt for a password
#    --gecos "" circumvents the prompt for "Full Name" etc. on Debian-based systems
RUN adduser \
    --disabled-password \
    --gecos "" \
    --uid "$UID" \
    "$USER"

RUN chown -R $USER /app

WORKDIR /app

# ensures rootless approach so the app could work in Openshift out of the box
USER $USER

COPY --chown=$USER ./ ./

RUN npm i

EXPOSE 8080

CMD [ "npm", "start" ]



