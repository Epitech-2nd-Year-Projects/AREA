FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:20-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules node_modules
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
ENV PORT=8081
COPY --from=build /app ./
EXPOSE 8081
CMD ["npm","start"]

