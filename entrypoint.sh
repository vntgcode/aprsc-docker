#!/bin/sh
set -e

exec 1>&2 

CONFIG_FILE="/aprsc/aprsc.conf"

# Environment variables with defaults
APRSC_SERVER_ID="${APRSC_SERVER_ID:-NOCALL}"
APRSC_PASSCODE="${APRSC_PASSCODE:--1}"
APRSC_MY_ADMIN="${APRSC_MY_ADMIN:-NOCALL}"
APRSC_MY_EMAIL="${APRSC_MY_EMAIL:-NOEMAIL@CONTAINER}"
APRSC_RUN_DIR="${APRSC_RUN_DIR:-data}"

# Listener configuration
APRSC_ENABLE_FULL_FEED="${APRSC_ENABLE_FULL_FEED:-yes}"
APRSC_FULL_FEED_PORT="${APRSC_FULL_FEED_PORT:-10152}"
APRSC_ENABLE_IGATE="${APRSC_ENABLE_IGATE:-yes}"
APRSC_IGATE_PORT="${APRSC_IGATE_PORT:-14580}"
APRSC_ENABLE_UDP_SUBMIT="${APRSC_ENABLE_UDP_SUBMIT:-yes}"
APRSC_UDP_SUBMIT_PORT="${APRSC_UDP_SUBMIT_PORT:-8080}"

# HTTP status configuration
APRSC_HTTP_STATUS_PORT="${APRSC_HTTP_STATUS_PORT:-14501}"
APRSC_HTTP_UPLOAD_PORT="${APRSC_HTTP_UPLOAD_PORT:-8080}"

# Uplink configuration
APRSC_UPLINK_ENABLED="${APRSC_UPLINK_ENABLED:-no}"
APRSC_UPLINK_SERVER="${APRSC_UPLINK_SERVER:-rotate.aprs2.net}"
APRSC_UPLINK_PORT="${APRSC_UPLINK_PORT:-10152}"
APRSC_UPLINK_TYPE="${APRSC_UPLINK_TYPE:-full}"

# Timeout configuration
APRSC_UPSTREAM_TIMEOUT="${APRSC_UPSTREAM_TIMEOUT:-15s}"
APRSC_CLIENT_TIMEOUT="${APRSC_CLIENT_TIMEOUT:-48h}"

# Resource limits
APRSC_MAX_CLIENTS="${APRSC_MAX_CLIENTS:-500}"
APRSC_FILE_LIMIT="${APRSC_FILE_LIMIT:-10000}"

# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    # Generate configuration file

cat > "$CONFIG_FILE" << EOF

# Server identification
ServerId $APRSC_SERVER_ID
PassCode $APRSC_PASSCODE

# Administrator information
MyAdmin "$APRSC_MY_ADMIN"
MyEmail $APRSC_MY_EMAIL

# Directories
RunDir $APRSC_RUN_DIR

# Timeouts
UpstreamTimeout $APRSC_UPSTREAM_TIMEOUT
ClientTimeout $APRSC_CLIENT_TIMEOUT

# Resource limits
MaxClients $APRSC_MAX_CLIENTS
FileLimit $APRSC_FILE_LIMIT

EOF

    # Add listeners based on environment variables
    if [ "$APRSC_ENABLE_FULL_FEED" = "yes" ]; then
        cat >> "$CONFIG_FILE" << EOF
# Full feed port
Listen "Full feed" fullfeed tcp :: $APRSC_FULL_FEED_PORT hidden
Listen "" fullfeed udp :: $APRSC_FULL_FEED_PORT hidden

EOF
    fi

    if [ "$APRSC_ENABLE_IGATE" = "yes" ]; then
        cat >> "$CONFIG_FILE" << EOF
# Client-defined filters port
Listen "Client-Defined Filters" igate tcp :: $APRSC_IGATE_PORT
Listen "" igate udp :: $APRSC_IGATE_PORT

EOF
    fi

    if [ "$APRSC_ENABLE_UDP_SUBMIT" = "yes" ]; then
        cat >> "$CONFIG_FILE" << EOF
# UDP submission port
Listen "UDP submit" udpsubmit udp :: $APRSC_UDP_SUBMIT_PORT

EOF
    fi

    # Add HTTP configuration
    cat >> "$CONFIG_FILE" << EOF
# HTTP status page
HTTPStatus 0.0.0.0 $APRSC_HTTP_STATUS_PORT

# HTTP upload
HTTPUpload 0.0.0.0 $APRSC_HTTP_UPLOAD_PORT

EOF

    # Add uplink if enabled
    if [ "$APRSC_UPLINK_ENABLED" = "yes" ]; then
        cat >> "$CONFIG_FILE" << EOF
# Uplink configuration
Uplink "$APRSC_UPLINK_SERVER" $APRSC_UPLINK_TYPE tcp $APRSC_UPLINK_SERVER $APRSC_UPLINK_PORT

EOF
    fi

    echo "Configuration file generated successfully"
    echo "----Details------" 
    echo "Server ID: $APRSC_SERVER_ID"
    echo "Uplink enabled: $APRSC_UPLINK_ENABLED"
    echo "Admin: $APRSC_MY_ADMIN"
    echo "Email: $APRSC_MY_EMAIL"
    echo ""

    # Show warning if using default callsign
    if [ "$APRSC_SERVER_ID" = "NOCALL" ]; then
        echo ""
        echo "Error: Using default callsign 'NOCALL'"
        echo "Please set APRSC_SERVER_ID environment variable to your callsign"
        echo "Example: -e APRSC_SERVER_ID=YOUR-CALL"
        exit 3
    fi

    # Show warning if using invalid passcode
    if [ "$APRSC_PASSCODE" = "-1" ]; then
        echo ""
        echo "Error: Using invalid passcode"
        echo "Please set APRSC_PASSCODE environment variable"
        echo "Generate at: https://n5dux.com/ham/aprs-passcode/"
        exit 4
    fi
else
    echo "Using existing configuration file: $CONFIG_FILE"

fi

# Execute aprsc with all arguments
exec "$@"