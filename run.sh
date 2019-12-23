set -euo pipefail

# For testing, you can run with DEBUG=1, and data will not be sent to honeycomb
# (--debug sets the log level, --debug_stdout says to write events to stdout
# instead of sending to honecomb)
if ! [[ -z "${DEBUG:-}" ]]; then
    HTDEBUG="--debug --debug_stdout"
fi

if ! [[ -z "${ADD_PARAMS:-}" ]]; then
    ADD_PARAMS_ARR=($(echo "${ADD_PARAMS}"));
    ADDITIONAL_FLAGS=""
    for (( i = 1 ; i < ${#ADD_PARAMS_ARR[@]} ; i+=2 )); do
        FIELD_NAME="${ADD_PARAMS_ARR[$i]}"
        FIELD_VALUE="${ADD_PARAMS_ARR[$((i + 1))]}"
        ADDITIONAL_FLAGS+="--add_field \"${FIELD_NAME}\"=\"${FIELD_VALUE}\" "
    done
fi

# In-cluster gcloud auth
if [[ "${GOOGLE_APPLICATION_CREDENTIALS_JSON:-}" != "" ]]; then
    echo $GOOGLE_APPLICATION_CREDENTIALS_JSON > service-account.key
    export GOOGLE_APPLICATION_CREDENTIALS=service-account.key
fi

./cloudsqltail -project ${PROJECT_ID} -subscription ${SUBSCRIPTION_NAME} | \
./honeytail ${HTDEBUG:-} \
    -k="${HONEYCOMB_WRITEKEY:-unset}" \
    --dataset="${DATASET:-postgres}" \
    --parser=postgresql \
    --postgresql.log_line_prefix='[%t]: [%p]: [%l-1] db=%d,user=%u' \
    "${ADDITIONAL_FLAGS:-}" \
    -f -
