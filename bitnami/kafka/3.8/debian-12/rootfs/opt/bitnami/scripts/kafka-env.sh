#!/bin/bash
# Copyright VMware, Inc.
# SPDX-License-Identifier: APACHE-2.0
#
# Environment configuration for kafka

# The values for all environment variables will be set in the below order of precedence
# 1. Custom environment variables defined below after Bitnami defaults
# 2. Constants defined in this file (environment variables with no default), i.e. BITNAMI_ROOT_DIR
# 3. Environment variables overridden via external files using *_FILE variables (see below)
# 4. Environment variables set externally (i.e. current Bash context/Dockerfile/userdata)

# Load logging library
# shellcheck disable=SC1090,SC1091
. /opt/bitnami/scripts/liblog.sh

export BITNAMI_ROOT_DIR="/opt/bitnami"
export BITNAMI_VOLUME_DIR="/bitnami"

# Logging configuration
export MODULE="${MODULE:-kafka}"
export BITNAMI_DEBUG="${BITNAMI_DEBUG:-false}"

# By setting an environment variable matching *_FILE to a file path, the prefixed environment
# variable will be overridden with the value specified in that file
kafka_env_vars=(
    KAFKA_MOUNTED_CONF_DIR
    KAFKA_INTER_BROKER_USER
    KAFKA_INTER_BROKER_PASSWORD
    KAFKA_CONTROLLER_USER
    KAFKA_CONTROLLER_PASSWORD
    KAFKA_CERTIFICATE_PASSWORD
    KAFKA_TLS_TRUSTSTORE_FILE
    KAFKA_TLS_TYPE
    KAFKA_TLS_CLIENT_AUTH
    KAFKA_OPTS
    KAFKA_CFG_SASL_ENABLED_MECHANISMS
    KAFKA_KRAFT_CLUSTER_ID
    KAFKA_SKIP_KRAFT_STORAGE_INIT
    KAFKA_CLIENT_LISTENER_NAME
    KAFKA_ZOOKEEPER_PROTOCOL
    KAFKA_ZOOKEEPER_PASSWORD
    KAFKA_ZOOKEEPER_USER
    KAFKA_ZOOKEEPER_TLS_KEYSTORE_PASSWORD
    KAFKA_ZOOKEEPER_TLS_TRUSTSTORE_PASSWORD
    KAFKA_ZOOKEEPER_TLS_TRUSTSTORE_FILE
    KAFKA_ZOOKEEPER_TLS_VERIFY_HOSTNAME
    KAFKA_ZOOKEEPER_TLS_TYPE
    KAFKA_CLIENT_USERS
    KAFKA_CLIENT_PASSWORDS
    KAFKA_HEAP_OPTS
    # AutoMQ add
    KAFKA_JVM_PERFORMANCE_OPTS
    LD_PRELOAD
    AUTOMQ_S3STREAM_STRICT
    AUTOMQ_ENABLE_LOCAL_CONFIG
    # AutoMQ server.properties need to be set
    AUTOMQ_S3_REGION
    AUTOMQ_BUCKET_NAME
    AUTOMQ_S3_WAL_PATH
    AUTOMQ_S3_ENDPOINT
    AUTOMQ_S3_PATH_STYLE
    AUTOMQ_METRICS_ENABLE
    AUTOMQ_METRICS_EXPORTER_TYPE
    AUTOMQ_METRICS_EXPORTER_PROM_HOST
    AUTOMQ_METRICS_EXPORTER_PROM_PORT
    KAFKA_S3_ACCESS_KEY
    KAFKA_S3_SECRET_KEY
)
for env_var in "${kafka_env_vars[@]}"; do
    file_env_var="${env_var}_FILE"
    if [[ -n "${!file_env_var:-}" ]]; then
        if [[ -r "${!file_env_var:-}" ]]; then
            export "${env_var}=$(< "${!file_env_var}")"
            unset "${file_env_var}"
        else
            warn "Skipping export of '${env_var}'. '${!file_env_var:-}' is not readable."
        fi
    fi
done
unset kafka_env_vars

# AutoMQ
export KAFKA_JVM_PERFORMANCE_OPTS="${KAFKA_JVM_PERFORMANCE_OPTS:--server -XX:+UseZGC -XX:ZCollectionInterval=5}"
export AUTOMQ_S3STREAM_STRICT="${AUTOMQ_S3STREAM_STRICT:-false}"
export AUTOMQ_ENABLE_LOCAL_CONFIG="${AUTOMQ_ENABLE_LOCAL_CONFIG:-true}"
export LD_PRELOAD="${LD_PRELOAD:-/usr/lib/x86_64-linux-gnu/libjemalloc.so.2}"
# AutoMQ server.properties needed env
export AUTOMQ_S3_REGION="${AUTOMQ_S3_REGION:-cn-northwest-1}"
export AUTOMQ_BUCKET_NAME="${AUTOMQ_BUCKET_NAME:-automq-kafka-data}"
export AUTOMQ_S3_WAL_PATH="${AUTOMQ_S3_WAL_PATH:-/tmp/kraft-combined-logs/s3wal}"
export AUTOMQ_S3_ENDPOINT="${AUTOMQ_S3_ENDPOINT:-https://s3.cn-northwest-1.amazonaws.com.cn}"
export AUTOMQ_S3_PATH_STYLE="${AUTOMQ_S3_PATH_STYLE:-false}"
export AUTOMQ_METRICS_ENABLE="${AUTOMQ_METRICS_ENABLE:-true}"
export AUTOMQ_METRICS_EXPORTER_TYPE="${AUTOMQ_METRICS_EXPORTER_TYPE:-prometheus}"
export AUTOMQ_METRICS_EXPORTER_PROM_HOST="${AUTOMQ_METRICS_EXPORTER_PROM_HOST:-127.0.0.1}"
export AUTOMQ_METRICS_EXPORTER_PROM_PORT="${AUTOMQ_METRICS_EXPORTER_PROM_PORT:-9090}"
export KAFKA_S3_ACCESS_KEY="${KAFKA_S3_ACCESS_KEY:-}"
export KAFKA_S3_SECRET_KEY="${KAFKA_S3_SECRET_KEY:-}"



# Paths
export KAFKA_BASE_DIR="${BITNAMI_ROOT_DIR}/kafka"
export KAFKA_VOLUME_DIR="/bitnami/kafka"
export KAFKA_DATA_DIR="${KAFKA_VOLUME_DIR}/data"
export KAFKA_CONF_DIR="${KAFKA_BASE_DIR}/config"
export KAFKA_CONF_FILE="${KAFKA_CONF_DIR}/server.properties"
export KAFKA_MOUNTED_CONF_DIR="${KAFKA_MOUNTED_CONF_DIR:-${KAFKA_VOLUME_DIR}/config}"
export KAFKA_CERTS_DIR="${KAFKA_CONF_DIR}/certs"
export KAFKA_INITSCRIPTS_DIR="/docker-entrypoint-initdb.d"
export KAFKA_LOG_DIR="${KAFKA_BASE_DIR}/logs"
export KAFKA_HOME="$KAFKA_BASE_DIR"
export PATH="${KAFKA_BASE_DIR}/bin:${BITNAMI_ROOT_DIR}/java/bin:${PATH}"

# System users (when running with a privileged user)
export KAFKA_DAEMON_USER="kafka"
export KAFKA_DAEMON_GROUP="kafka"

# Kafka runtime settings
export KAFKA_INTER_BROKER_USER="${KAFKA_INTER_BROKER_USER:-user}"
export KAFKA_INTER_BROKER_PASSWORD="${KAFKA_INTER_BROKER_PASSWORD:-bitnami}"
export KAFKA_CONTROLLER_USER="${KAFKA_CONTROLLER_USER:-controller_user}"
export KAFKA_CONTROLLER_PASSWORD="${KAFKA_CONTROLLER_PASSWORD:-bitnami}"
export KAFKA_CERTIFICATE_PASSWORD="${KAFKA_CERTIFICATE_PASSWORD:-}"
export KAFKA_TLS_TRUSTSTORE_FILE="${KAFKA_TLS_TRUSTSTORE_FILE:-}"
export KAFKA_TLS_TYPE="${KAFKA_TLS_TYPE:-JKS}"
export KAFKA_TLS_CLIENT_AUTH="${KAFKA_TLS_CLIENT_AUTH:-required}"
export KAFKA_OPTS="${KAFKA_OPTS:-}"

# Kafka configuration overrides
export KAFKA_CFG_SASL_ENABLED_MECHANISMS="${KAFKA_CFG_SASL_ENABLED_MECHANISMS:-PLAIN,SCRAM-SHA-256,SCRAM-SHA-512}"
export KAFKA_KRAFT_CLUSTER_ID="${KAFKA_KRAFT_CLUSTER_ID:-}"
export KAFKA_SKIP_KRAFT_STORAGE_INIT="${KAFKA_SKIP_KRAFT_STORAGE_INIT:-false}"
export KAFKA_CLIENT_LISTENER_NAME="${KAFKA_CLIENT_LISTENER_NAME:-}"

# ZooKeeper connection settings
export KAFKA_ZOOKEEPER_PROTOCOL="${KAFKA_ZOOKEEPER_PROTOCOL:-PLAINTEXT}"
export KAFKA_ZOOKEEPER_PASSWORD="${KAFKA_ZOOKEEPER_PASSWORD:-}"
export KAFKA_ZOOKEEPER_USER="${KAFKA_ZOOKEEPER_USER:-}"
export KAFKA_ZOOKEEPER_TLS_KEYSTORE_PASSWORD="${KAFKA_ZOOKEEPER_TLS_KEYSTORE_PASSWORD:-}"
export KAFKA_ZOOKEEPER_TLS_TRUSTSTORE_PASSWORD="${KAFKA_ZOOKEEPER_TLS_TRUSTSTORE_PASSWORD:-}"
export KAFKA_ZOOKEEPER_TLS_TRUSTSTORE_FILE="${KAFKA_ZOOKEEPER_TLS_TRUSTSTORE_FILE:-}"
export KAFKA_ZOOKEEPER_TLS_VERIFY_HOSTNAME="${KAFKA_ZOOKEEPER_TLS_VERIFY_HOSTNAME:-true}"
export KAFKA_ZOOKEEPER_TLS_TYPE="${KAFKA_ZOOKEEPER_TLS_TYPE:-JKS}"

# Authentication
export KAFKA_CLIENT_USERS="${KAFKA_CLIENT_USERS:-user}"
export KAFKA_CLIENT_PASSWORDS="${KAFKA_CLIENT_PASSWORDS:-bitnami}"

# Java settings
# AutoMQ min spec is 1c8g.
export KAFKA_HEAP_OPTS="${KAFKA_HEAP_OPTS:--Xms5g -Xmx5g -XX:MetaspaceSize=96m}"

# Custom environment variables may be defined below
