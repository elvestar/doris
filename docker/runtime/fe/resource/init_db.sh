set -eo pipefail
shopt -s nullglob

# logging functions
# usage: doris_[note|warn|error] $log_meg
#    ie: doris_warn "task may fe risky!"
#   out: 2023-01-08T19:08:16+08:00 [Warn] [Entrypoint]: task may fe risky!
doris_log() {
    local type="$1"
    shift
    # accept argument string or stdin
    local text="$*"
    if [ "$#" -eq 0 ]; then text="$(cat)"; fi
    local dt="$(date -Iseconds)"
    printf '%s [%s] [InitDB]: %s\n' "$dt" "$type" "$text"
}
doris_note() {
    doris_log Note "$@"
}
doris_warn() {
    doris_log Warn "$@" >&2
}
doris_error() {
    doris_log ERROR "$@" >&2
    exit 1
}

# check to see if this file is being run or sourced from another script
_is_sourced() {
    [ "${#FUNCNAME[@]}" -ge 2 ] &&
        [ "${FUNCNAME[0]}" = '_is_sourced' ] &&
        [ "${FUNCNAME[1]}" = 'source' ]
}

# Execute sql script, passed via stdin
# usage: docker_process_sql sql_script
docker_process_sql() {
    set +e
    mysql -uroot -P${FE_QUERY_PORT} -h${FE_SERVICE_NAME} --comments "$@" 2>/dev/null
}

set_root_admin_password() {
    set +e
    local is_set_admin_passwd=false
    if [ ${DORIS_ADMIN_PASSWD} ]; then
        for i in {1..10}; do
            docker_process_sql <<<"SET PASSWORD FOR 'admin' = PASSWORD('${DORIS_ADMIN_PASSWD}');"
            set_passwd_status=$?
            if [[ "${set_passwd_status}" == 0 ]]; then
                doris_note "Set admin password successfully"
                is_set_admin_passwd=true
                break
            else
                doris_note "Set admin password failed, wait next~"
            fi
            sleep 5
        done
    fi
    if ! [[ $is_set_admin_passwd ]]; then
        doris_error "Failed to set admin password! Tried 10 times! Maybe FE Start Failed!"
    fi
}

create_storage_resource() {
    set +e
    local is_create_storage_resource=false
    local resource_id="DEFAULT_RESOURCE_ID"
    if [ ${AWS_ENDPOINT} -a ${AWS_BUCKET} -a ${AWS_ROOT_PATH} ]; then
        for i in {1..10}; do
            docker_process_sql <<<"SHOW RESOURCES;" | grep "${resource_id}"
            show_resource_status=$?
            if [[ "${show_resource_status}" == 0 ]]; then
                doris_note "Storage resource ${resource_id} already exist"
                is_create_storage_resource=true
                break
            fi
            docker_process_sql <<<"CREATE RESOURCE '${resource_id}' PROPERTIES('type'='s3', 'AWS_ENDPOINT'='${AWS_ENDPOINT}', 'AWS_REGION'='${AWS_REGION}', 'AWS_BUCKET'='${AWS_BUCKET}', 'AWS_ROOT_PATH'='${AWS_ROOT_PATH}', 'AWS_ACCESS_KEY'='${AWS_ACCESS_KEY}', 'AWS_SECRET_KEY'='${AWS_SECRET_KEY}'); create storage policy ${resource_id} properties('storage_resource'='${resource_id}', 'cooldown_ttl'='1d');"
            create_storage_resource_status=$?
            if [[ "${create_storage_resource_status}" == 0 ]]; then
                doris_note "Create storage resource ${resource_id} successfully"
                is_create_storage_resource=true
                break
            else
                doris_note "Create storage resource failed, wait next~"
            fi
            sleep 5
        done
    fi
    if ! [[ $is_create_storage_resource ]]; then
        doris_error "Failed to create storage resource! Tried 10 times! Maybe FE Start Failed!"
    fi
}

_main() {
    sleep 10
    set_root_admin_password
    create_storage_resource
}

if ! _is_sourced; then
  _main "$@"
fi