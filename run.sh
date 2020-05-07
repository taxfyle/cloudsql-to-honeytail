set -euo pipefail

# For testing, you can run with DEBUG=1, and data will not be sent to honeycomb
# (--debug sets the log level, --debug_stdout says to write events to stdout
# instead of sending to honecomb)
if ! [[ -z "${DEBUG:-}" ]]; then
    HTDEBUG="--debug --debug_stdout"
fi

ADDITIONAL_FLAGS=()
if ! [[ -z "${ADD_PARAMS:-}" ]]; then
    ADD_PARAMS_ARR=()
    while IFS='' read val; do
        ADD_PARAMS_ARR+=("$val")
    done < <(xargs -n1 <<<"$ADD_PARAMS")
    if (( ${#ADD_PARAMS_ARR[@]} % 2 == 1 )); then
        echo "Invalid number of additional parameters. Must be divisble by two."
        echo "Please ensure you escape params with spaces with single or double"
        echo "quotes and not with backslashes before the spaces."
        exit 1
    fi

    for (( i = 0 ; i < ${#ADD_PARAMS_ARR[@]} ; i+=2 )); do
        FIELD_NAME="${ADD_PARAMS_ARR[$i]}"
        FIELD_VALUE="${ADD_PARAMS_ARR[$((i + 1))]}"
        ADDITIONAL_FLAGS+=("--add_field")
        ADDITIONAL_FLAGS+=("${FIELD_NAME}=${FIELD_VALUE}")
    done
fi

# In-cluster gcloud auth
if [[ "${GOOGLE_APPLICATION_CREDENTIALS_JSON:-}" != "" ]]; then
    echo $GOOGLE_APPLICATION_CREDENTIALS_JSON > service-account.key
    export GOOGLE_APPLICATION_CREDENTIALS=service-account.key
fi

./cloudsqltail -project ${PROJECT_ID} -subscription ${SUBSCRIPTION_NAME} -recv-routines 1 | \
./honeytail ${HTDEBUG:-} \
    -k="${HONEYCOMB_WRITEKEY:-unset}" \
    --dataset="${DATASET:-postgres}" \
    --parser=postgresql \
    --postgresql.log_line_prefix='[%t]: [%p]: [%l-1] db=%d,user=%u' \
    "${ADDITIONAL_FLAGS[@]}" \
    -f -
