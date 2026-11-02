# Optimized Keycloak image: build-time options are baked in so startup is fast.
FROM quay.io/keycloak/keycloak:26.8 AS builder

ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true

WORKDIR /opt/keycloak
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.8
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Runtime defaults for running behind a TLS-terminating platform/proxy.
# Baked in so the container works even when the platform ignores .env / docker-compose.
# Any of these can still be overridden by setting the same env var on the platform.
ENV KC_HTTP_ENABLED=true \
    KC_HTTP_HOST=0.0.0.0 \
    KC_HTTP_PORT=8000 \
    KC_PROXY_HEADERS=xforwarded

EXPOSE 8000 9000

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
