FROM golang:1.24.3-alpine AS builder

RUN apk update && apk add --no-cache git make nodejs npm

WORKDIR /easymosdns
RUN git clone https://github.com/signingup/easymosdns.git . && rm -rf .git

WORKDIR /mosdns
RUN git clone https://github.com/pmkol/mosdns.git .

WORKDIR /adguardhome
RUN git clone https://github.com/AdguardTeam/AdGuardHome.git . && git checkout v0.107.61

#build mosdns
WORKDIR /mosdns

RUN go mod download
RUN go build -trimpath -ldflags '-w -s -buildid=' -o /go/bin/mosdns

#build adguardhome
WORKDIR /adguardhome
RUN make init && make -j 1

FROM alpine:latest

RUN apk add --no-cache sed tzdata grep dcron openrc bash curl htop bc tcptraceroute nano wget ca-certificates jq iproute2 net-tools bind-tools

COPY --from=builder /go/bin/. /usr/local/bin/
COPY --from=builder /easymosdns /etc/mosdns
COPY --from=builder /adguardhome/AdGuardHome /usr/local/bin/

RUN wget http://www.vdberg.org/~richard/tcpping -O /usr/bin/tcpping
RUN chmod 755 /usr/bin/tcpping

COPY ./entrypoint.sh /usr/bin/

RUN chmod +x /usr/bin/entrypoint.sh

ENV TZ=UTC
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

EXPOSE 53
EXPOSE 5353
EXPOSE 9080

CMD ["/usr/bin/entrypoint.sh"]
