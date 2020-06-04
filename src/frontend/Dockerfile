FROM node:8-alpine
WORKDIR /usr/src/app
COPY . .
RUN npm install
EXPOSE 8080
CMD [ "node", "app.js" ]