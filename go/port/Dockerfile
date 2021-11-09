FROM golang:alpine AS build

WORKDIR /go/src

COPY . ./
RUN go mod download

RUN go build -o /port

FROM alpine

WORKDIR /

COPY --from=build /port /port

EXPOSE 80

CMD ["/port"]