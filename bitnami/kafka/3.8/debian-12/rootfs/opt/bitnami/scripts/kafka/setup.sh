#!/bin/bash
# Copyright VMware, Inc.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

## AutoMQ: setting AutoMQ configuration by environment
setup_value() {
  key=$1
  value=$2
  file=$3
  # replace special characters
  value=${value//&/\\&}
  value=${value//#//\\#/}
  echo "setup_value: key=${key}, value=${value}, file=${file}"
  sed -i "s|^${key}=.*$|${key}=${value}|" "${file}"
}

turn_on_auto_balancer() {
    role=$1
    file_name=$2
    auto_balancer_setting_for_all "${file_name}"
    if [[ "${role}" == "broker" ]]; then
        auto_balancer_setting_for_broker_only "${file_name}"
    elif [[ "${role}" == "controller" ]]; then
        auto_balancer_setting_for_controller_only "${file_name}"
    elif [[ "${role}" == "server" ]]; then
        auto_balancer_setting_for_controller_only "${file_name}"
        auto_balancer_setting_for_broker_only "${file_name}"
    fi
}


for role in "broker" "controller" "server"; do
      setup_value "node.id" "${AUTOMQ_NODE_ID}" "${kafka_dir}/config/kraft/${role}.properties"
      setup_value "controller.quorum.voters" "${quorum_voters}" "${kafka_dir}/config/kraft/${role}.properties"
      setup_value "s3.region" "${AUTOMQ_REGION}" "${kafka_dir}/config/kraft/${role}.properties"
      setup_value "s3.bucket" "${AUTOMQ_BUCKET_NAME}" "${kafka_dir}/config/kraft/${role}.properties"
      setup_value "log.dirs" "${AUTOMQ_LOG_DIRS}/kraft-${role}-logs" "${kafka_dir}/config/kraft/${role}.properties"
      setup_value "s3.wal.path" "${AUTOMQ_WAL_PATH}/wal" "${kafka_dir}/config/kraft/${role}.properties"
      setup_value "s3.endpoint" "${AUTOMQ_ENDPOINT}" "${kafka_dir}/config/kraft/${role}.properties"
      add_or_setup_value "s3.path.style" "${AUTOMQ_PATH_STYLE}" "${kafka_dir}/config/kraft/${role}.properties"
      # turn on auto_balancer
      turn_on_auto_balancer "${role}" "${kafka_dir}/config/kraft/${role}.properties"

      # setup metrics exporter
      add_or_setup_value "s3.telemetry.metrics.enable" "true" "${kafka_dir}/config/kraft/${role}.properties"
      add_or_setup_value "s3.telemetry.metrics.level" "DEBUG" "${kafka_dir}/config/kraft/${role}.properties"
      add_or_setup_value "s3.telemetry.metrics.exporter.type" "otlp" "${kafka_dir}/config/kraft/${role}.properties"
      add_or_setup_value "s3.telemetry.exporter.otlp.endpoint" "http://metrics.hellocorp.site" "${kafka_dir}/config/kraft/${role}.properties"
      add_or_setup_value "s3.telemetry.exporter.report.interval.ms" "10000" "${kafka_dir}/config/kraft/${role}.properties"
done



set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/libfs.sh
. /opt/bitnami/scripts/libos.sh
. /opt/bitnami/scripts/libkafka.sh

# Load Kafka environment variables
. /opt/bitnami/scripts/kafka-env.sh

# Map Kafka environment variables
kafka_create_alias_environment_variables

# Dinamically set node.id/broker.id/controller.quorum.voters if the _COMMAND environment variable is set
kafka_dynamic_environment_variables

# Set the default tuststore locations before validation
kafka_configure_default_truststore_locations
# Ensure Kafka user and group exist when running as 'root'
am_i_root && ensure_user_exists "$KAFKA_DAEMON_USER" --group "$KAFKA_DAEMON_GROUP"
# Ensure directories used by Kafka exist and have proper ownership and permissions
for dir in "$KAFKA_LOG_DIR" "$KAFKA_CONF_DIR" "$KAFKA_MOUNTED_CONF_DIR" "$KAFKA_VOLUME_DIR" "$KAFKA_DATA_DIR"; do
    if am_i_root; then
        ensure_dir_exists "$dir" "$KAFKA_DAEMON_USER" "$KAFKA_DAEMON_GROUP"
    else
        ensure_dir_exists "$dir"
    fi
done

# Kafka validation, skipped if server.properties was mounted at either $KAFKA_MOUNTED_CONF_DIR or $KAFKA_CONF_DIR
[[ ! -f "${KAFKA_MOUNTED_CONF_DIR}/server.properties" && ! -f "$KAFKA_CONF_FILE" ]] && kafka_validate
# Kafka initialization, skipped if server.properties was mounted at $KAFKA_CONF_DIR
[[ ! -f "$KAFKA_CONF_FILE" ]] && kafka_initialize

# Initialise KRaft metadata storage if process.roles configured
if grep -q "^process.roles=" "$KAFKA_CONF_FILE" && ! is_boolean_yes "$KAFKA_SKIP_KRAFT_STORAGE_INIT" ; then
    kafka_kraft_storage_initialize
fi
# Configure Zookeeper SCRAM users
if is_boolean_yes "${KAFKA_ZOOKEEPER_BOOTSTRAP_SCRAM_USERS:-}"; then
    kafka_zookeeper_create_sasl_scram_users
fi
# KRaft controllers may get stuck starting when the controller quorum voters are changed.
# Workaround: Remove quorum-state file when scaling up/down controllers (Waiting proposal KIP-853)
# https://cwiki.apache.org/confluence/display/KAFKA/KIP-853%3A+KRaft+Voter+Changes
if [[ -f "${KAFKA_DATA_DIR}/__cluster_metadata-0/quorum-state" ]] && grep -q "^controller.quorum.voters=" "$KAFKA_CONF_FILE" && kafka_kraft_quorum_voters_changed; then
    warn "Detected inconsitences between controller.quorum.voters and quorum-state, removing it..."
    rm -f "${KAFKA_DATA_DIR}/__cluster_metadata-0/quorum-state"
fi
# Ensure custom initialization scripts are executed
kafka_custom_init_scripts
