#!/usr/bin/env bash
set -euo pipefail

# Dependencies
for tool in curl jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing dependency: $tool" >&2
        exit 1
    fi
done

API_BASE=${API_BASE:-http://localhost:8080}
COOKIE_JAR=${COOKIE_JAR:-}
if [[ -z "${COOKIE_JAR}" ]]; then
    COOKIE_JAR="$(mktemp -t area_cookies.XXXXXX)"
    CLEANUP_COOKIE_JAR=1
else
    CLEANUP_COOKIE_JAR=0
fi

trap cleanup EXIT

cleanup() {
    if [[ ${CLEANUP_COOKIE_JAR:-0} -eq 1 && -f "$COOKIE_JAR" ]]; then
        rm -f "$COOKIE_JAR"
    fi
}

API_STATUS=0
API_BODY=""

api_request() {
    local method=$1
    local path=$2
    local data=${3:-}
    local headers=(-H "Accept: application/json")

    if [[ "$method" != "GET" && -n "$data" ]]; then
        headers+=(-H "Content-Type: application/json" --data "$data")
    fi

    local response status body
    response=$(curl -sS -w "\n%{http_code}" -X "$method" "${headers[@]}" -b "$COOKIE_JAR" -c "$COOKIE_JAR" "$API_BASE$path" || true)
    status=$(printf '%s\n' "$response" | tail -n 1)
    body=$(printf '%s\n' "$response" | sed '$d')

    API_STATUS=$status
    API_BODY=$body
}

prompt_secret() {
    read -rsp "$1" value
    echo
    printf '%s' "$value"
}

prompt() {
    read -rp "$1" value
    printf '%s' "$value"
}

notify() {
    echo "[$(date +%H:%M:%S)] $*" >&2
}

trim() {
    local value="$*"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

register_user() {
    local email password body
    email=$(prompt "Email: ")
    password=$(prompt_secret "Password: ")

    body=$(jq -nc --arg email "$email" --arg password "$password" '{email:$email,password:$password}')
    api_request POST "/v1/users" "$body"

    case "$API_STATUS" in
    201|202)
        echo "$API_BODY" | jq '.'
        notify "Registration queued; check email logs for the verification token."
        ;;
    409)
        notify "User already registered; continuing."
        ;;
    *)
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Registration failed (HTTP $API_STATUS)" >&2
        ;;
    esac
}

verify_email() {
    local token body
    token=$(prompt "Verification token: ")
    body=$(jq -nc --arg token "$token" '{token:$token}')
    api_request POST "/v1/auth/verify" "$body"

    if [[ "$API_STATUS" == "200" ]]; then
        echo "$API_BODY" | jq '.'
        notify "Email verified."
    else
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Verification failed (HTTP $API_STATUS)" >&2
    fi
}

login_user() {
    local email password body
    email=$(prompt "Email: ")
    password=$(prompt_secret "Password: ")
    body=$(jq -nc --arg email "$email" --arg password "$password" '{email:$email,password:$password}')
    api_request POST "/v1/auth/login" "$body"

    if [[ "$API_STATUS" == "200" ]]; then
        echo "$API_BODY" | jq '.'
        if ! grep -q area_session "$COOKIE_JAR"; then
            echo "Login succeeded but session cookie missing." >&2
        fi
    else
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Login failed (HTTP $API_STATUS)" >&2
    fi
}

list_components() {
    local params=()
    local kind provider available choice
    choice=$(prompt "Filter by kind? [a]ction/[r]eaction/[n]one (default n): ")
    case "$choice" in
    a|A) kind="action" ;;
    r|R) kind="reaction" ;;
    *) kind="" ;;
    esac
    if [[ -n "$kind" ]]; then
        params+=("kind=$kind")
    fi
    provider=$(prompt "Filter by provider (leave blank for all): ")
    if [[ -n "$provider" ]]; then
        params+=("provider=$provider")
    fi
    available=$(prompt "Only show subscribed components? [y/N]: ")
    local path="/v1/components"
    if [[ "$available" =~ ^[Yy]$ ]]; then
        path="/v1/components/available"
    fi
    if [[ ${#params[@]} -gt 0 ]]; then
        path="$path?$(IFS='&'; echo "${params[*]}")"
    fi
    api_request GET "$path"
    if [[ "$API_STATUS" == "200" ]]; then
        echo "$API_BODY" | jq '.components'
    else
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "List failed (HTTP $API_STATUS)" >&2
    fi
}

list_identities() {
    api_request GET "/v1/identities"
    if [[ "$API_STATUS" == "200" ]]; then
        echo "$API_BODY" | jq '.identities'
    else
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Unable to list identities (HTTP $API_STATUS)" >&2
    fi
}

oauth_connect() {
    local provider redirect body state code_verifier code
    provider=$(prompt "OAuth provider (e.g. github, google): ")
    redirect=$(prompt "Redirect URI [default https://oauth.pstmn.io/v1/callback]: ")
    if [[ -z "$redirect" ]]; then
        redirect="https://oauth.pstmn.io/v1/callback"
    fi

    body=$(jq -nc --arg redirect "$redirect" '{redirectUri:$redirect}')
    api_request POST "/v1/oauth/$provider/authorize" "$body"
    if [[ "$API_STATUS" != "200" ]]; then
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Authorization failed (HTTP $API_STATUS)" >&2
        return
    fi

    state=$(echo "$API_BODY" | jq -r '.state // empty')
    code_verifier=$(echo "$API_BODY" | jq -r '.codeVerifier // empty')
    notify "Open in browser: $(echo "$API_BODY" | jq -r '.authorizationUrl')"
    if [[ -n "$state" ]]; then
        notify "State: $state"
    fi
    if [[ -n "$code_verifier" ]]; then
        notify "Code verifier saved for exchange."
    fi

    code=$(prompt "Paste the authorization code once redirected: ")
    body=$(jq -nc \
        --arg code "$code" \
        --arg redirect "$redirect" \
        --arg state "$state" \
        --arg codeVerifier "$code_verifier" \
        '{
            code: $code,
            redirectUri: $redirect,
            state: (if $state == "" then null else $state end),
            codeVerifier: (if $codeVerifier == "" then null else $codeVerifier end)
        }')
    api_request POST "/v1/oauth/$provider/exchange" "$body"
    if [[ "$API_STATUS" == "200" ]]; then
        echo "$API_BODY" | jq '.'
        notify "OAuth identity linked."
    else
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Exchange failed (HTTP $API_STATUS)" >&2
    fi
}

subscribe_provider() {
    local provider scopes_input payload status
    provider=$(prompt "Provider to subscribe (e.g. github, google): ")
    provider=$(trim "$provider")
    provider=$(printf '%s' "$provider" | tr '[:upper:]' '[:lower:]')
    if [[ -z "$provider" ]]; then
        echo "Provider name is required." >&2
        return 1
    fi

    scopes_input=$(prompt "Additional scopes (comma separated, optional): ")
    scopes_input=$(trim "$scopes_input")
    payload=""
    if [[ -n "$scopes_input" ]]; then
        payload=$(jq -nc --arg scopes "$scopes_input" '{
            scopes: ($scopes
                | split(",")
                | map(gsub("^\\s+|\\s+$"; ""))
                | map(select(length>0))
            )
        }')
    fi

    api_request POST "/v1/services/$provider/subscribe" "$payload"
    if [[ "$API_STATUS" != "200" ]]; then
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Subscription request failed (HTTP $API_STATUS)" >&2
        return 1
    fi

    status=$(echo "$API_BODY" | jq -r '.status // empty')
    if [[ "$status" == "subscribed" ]]; then
        echo "$API_BODY" | jq '.subscription'
        notify "Provider $provider subscribed."
        return 0
    fi

    if [[ "$status" != "authorization_required" ]]; then
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Unexpected subscription response for $provider." >&2
        return 1
    fi

    local auth auth_url state code_verifier
    auth=$(echo "$API_BODY" | jq -c '.authorization')
    if [[ -z "$auth" || "$auth" == "null" ]]; then
        echo "Subscription authorization payload missing." >&2
        return 1
    fi

    auth_url=$(echo "$auth" | jq -r '.authorizationUrl // empty')
    state=$(echo "$auth" | jq -r '.state // empty')
    code_verifier=$(echo "$auth" | jq -r '.codeVerifier // empty')
    if [[ -z "$auth_url" ]]; then
        echo "Authorization URL missing from response." >&2
        return 1
    fi

    notify "Open in browser: $auth_url"
    if [[ -n "$state" ]]; then
        notify "State: $state"
    fi
    if [[ -n "$code_verifier" ]]; then
        notify "Code verifier saved for exchange."
    fi

    local redirect
    redirect=$(prompt "Redirect URI [default https://oauth.pstmn.io/v1/callback]: ")
    redirect=$(trim "$redirect")
    if [[ -z "$redirect" ]]; then
        redirect="https://oauth.pstmn.io/v1/callback"
    fi

    if [[ -n "$state" ]]; then
        local returned_state
        returned_state=$(prompt "State from redirect (press Enter to skip): ")
        returned_state=$(trim "$returned_state")
        if [[ -n "$returned_state" && "$returned_state" != "$state" ]]; then
            echo "Warning: state mismatch between request and response." >&2
        fi
    fi

    local code
    code=$(prompt "Paste the authorization code once redirected: ")
    code=$(trim "$code")
    if [[ -z "$code" ]]; then
        echo "Authorization code is required." >&2
        return 1
    fi

    local exchange
    exchange=$(jq -nc \
        --arg code "$code" \
        --arg redirect "$redirect" \
        --arg verifier "$code_verifier" \
        '{code: $code}
         | (if ($redirect | length) > 0 then .redirectUri = $redirect else . end)
         | (if ($verifier | length) > 0 then .codeVerifier = $verifier else . end)')

    api_request POST "/v1/services/$provider/subscribe/exchange" "$exchange"
    if [[ "$API_STATUS" == "200" ]]; then
        echo "$API_BODY" | jq '{subscription: .subscription, identity: .identity}'
        notify "Subscription completed for $provider."
    else
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Subscription exchange failed (HTTP $API_STATUS)" >&2
        return 1
    fi
}

fetch_components() {
    local kind=$1
    local provider_filter=$2
    local path="/v1/components"
    local query=()
    if [[ -n "$kind" ]]; then
        query+=("kind=$kind")
        path="/v1/components"
    fi
    if [[ -n "$provider_filter" ]]; then
        query+=("provider=$provider_filter")
    fi
    if [[ ${#query[@]} -gt 0 ]]; then
        path="$path?$(IFS='&'; echo "${query[*]}")"
    fi
    api_request GET "$path"
    if [[ "$API_STATUS" != "200" ]]; then
        return 1
    fi
    return 0
}

select_component() {
    local kind=$1
    local provider_filter=${2:-}
    if ! fetch_components "$kind" "$provider_filter"; then
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Unable to fetch components (HTTP $API_STATUS)" >&2
        return 1
    fi
    local components
    components=$(echo "$API_BODY" | jq -c '.components')
    local count
    count=$(echo "$components" | jq 'length')
    if (( count == 0 )); then
        echo "No components available for the given filters." >&2
        return 1
    fi

    echo "Available components:" >&2
    for ((i=0; i<count; i++)); do
        local item name display provider desc id
        item=$(echo "$components" | jq -c ".[$i]")
        name=$(echo "$item" | jq -r '.name')
        display=$(echo "$item" | jq -r '.displayName')
        provider=$(echo "$item" | jq -r '.provider.name')
        desc=$(echo "$item" | jq -r '.description // ""')
        id=$(echo "$item" | jq -r '.id')
        printf "  [%d] %s (%s) – %s\n" $((i+1)) "$display" "$provider" "$id" >&2
        if [[ -n "$desc" ]]; then
            printf "      %s\n" "$desc" >&2
        fi
    done

    local choice
    choice=$(prompt "Select component [1-$count]: ")
    if [[ -z "$choice" ]]; then
        choice=1
    fi
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > count )); then
        echo "Invalid selection." >&2
        return 1
    fi
    echo "$components" | jq -c ".[$((choice-1))]"
}

select_identity() {
    local provider=$1
    while true; do
        api_request GET "/v1/identities"
        if [[ "$API_STATUS" != "200" ]]; then
            echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
            echo "Unable to fetch identities (HTTP $API_STATUS)" >&2
            return 1
        fi
        local filtered count
        filtered=$(echo "$API_BODY" | jq --arg provider "$provider" '[.identities[] | select(.provider == $provider)]')
        count=$(echo "$filtered" | jq 'length')
        if (( count == 0 )); then
            notify "No $provider identity linked. Starting OAuth flow."
            if ! oauth_connect "$provider"; then
                return 1
            fi
            continue
        fi
        echo "Linked $provider identities:" >&2
        for ((i=0; i<count; i++)); do
            local item subject id expires
            item=$(echo "$filtered" | jq -c ".[$i]")
            id=$(echo "$item" | jq -r '.id')
            subject=$(echo "$item" | jq -r '.subject')
            expires=$(echo "$item" | jq -r '.expiresAt // "n/a"')
            printf "  [%d] %s – %s (expires %s)\n" $((i+1)) "$id" "$subject" "$expires" >&2
        done
        local choice
        choice=$(prompt "Select identity [1-$count]: ")
        if [[ -z "$choice" ]]; then
            choice=1
        fi
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > count )); then
            echo "Invalid selection." >&2
            return 1
        fi
        echo "$filtered" | jq -r ".[$((choice-1))].id"
        return 0
    done
}

read_enum_value() {
    local param default_json options_json
    param=$1
    default_json=$2
    options_json=$3
    local count
    count=$(echo "$options_json" | jq 'length')
    for ((i=0; i<count; i++)); do
        local option label value
        option=$(echo "$options_json" | jq -c ".[$i]")
        value=$(echo "$option" | jq -r '.value')
        label=$(echo "$option" | jq -r '.label // ""')
        printf "    (%d) %s %s\n" $((i+1)) "$value" "${label:+- $label}" >&2
    done
    local choice
    while true; do
        choice=$(prompt "    Choose option [1-$count]: ")
        if [[ -z "$choice" && -n "$default_json" && "$default_json" != "null" ]]; then
            echo "$default_json"
            return 0
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= count )); then
            echo "$options_json" | jq -c ".[$((choice-1))].value"
            return 0
        fi
        echo "    Invalid choice." >&2
    done
}

collect_params() {
    local component_json=$1
    local params='{}'
    local count
    count=$(echo "$component_json" | jq '(.metadata.parameters // []) | length')
    if (( count == 0 )); then
        echo '{}'
        return 0
    fi

    for ((i=0; i<count; i++)); do
        local param key label required type helper default_json default_display provider value_json answer
        param=$(echo "$component_json" | jq -c ".metadata.parameters[$i]")
        key=$(echo "$param" | jq -r '.key')
        label=$(echo "$param" | jq -r '.label // .key')
        required=$(echo "$param" | jq -r '.required // false')
        type=$(echo "$param" | jq -r '.type // "text"')
        helper=$(echo "$param" | jq -r '.helperText // empty')
        default_json=$(echo "$param" | jq -c '.default // empty')
        if [[ "$default_json" == "" || "$default_json" == "null" ]]; then
            default_display=""
        else
            default_display=$(printf '%s' "$default_json" | jq -r 'if type=="string" then . else tostring end')
        fi
        provider=$(echo "$param" | jq -r '.provider // empty')

        echo "  Parameter: $label ($key) [$type]" >&2
        if [[ -n "$helper" ]]; then
            echo "    $helper" >&2
        fi
        if [[ -n "$default_display" ]]; then
            echo "    Default: $default_display" >&2
        fi

        value_json=""
        while true; do
            case "$type" in
            identity)
                if [[ -z "$provider" ]]; then
                    echo "    Missing provider metadata for identity parameter." >&2
                    break
                fi
                answer=$(select_identity "$provider") || return 1
                value_json=$(jq -nc --arg v "$answer" '$v')
                break
                ;;
            enum)
                options=$(echo "$param" | jq -c '.options // []')
                value_json=$(read_enum_value "$param" "$default_json" "$options")
                break
                ;;
            integer)
                answer=$(prompt "    Value: ")
                if [[ -z "${answer//[[:space:]]/}" ]]; then
                    if [[ "$required" == "true" && -z "$default_json" ]]; then
                        echo "    Value required." >&2
                        continue
                    elif [[ -n "$default_json" ]]; then
                        value_json=$default_json
                    fi
                    break
                fi
                if ! [[ "$answer" =~ ^-?[0-9]+$ ]]; then
                    echo "    Enter a valid integer." >&2
                    continue
                fi
                value_json=$(jq -nc --arg v "$answer" '($v|tonumber)')
                break
                ;;
            text|textarea|password|datetime|timezone|email|url)
                answer=$(prompt "    Value: ")
                if [[ -z "${answer//[[:space:]]/}" ]]; then
                    if [[ "$required" == "true" && -z "$default_json" ]]; then
                        echo "    Value required." >&2
                        continue
                    elif [[ -n "$default_json" ]]; then
                        value_json=$default_json
                    fi
                    break
                fi
                value_json=$(jq -nc --arg v "$answer" '$v')
                break
                ;;
            emailList|stringList)
                answer=$(prompt "    Comma separated values: ")
                if [[ -z "${answer//[[:space:]]/}" ]]; then
                    if [[ "$required" == "true" && -z "$default_json" ]]; then
                        echo "    Value required." >&2
                        continue
                    elif [[ -n "$default_json" ]]; then
                        value_json=$default_json
                    else
                        value_json='[]'
                    fi
                    break
                fi
                value_json=$(jq -nc --arg csv "$answer" '($csv | split(",") | map(gsub("^\\s+|\\s+$";"")) | map(select(length>0)))')
                break
                ;;
            keyValue|json|object)
                answer=$(prompt "    JSON value: ")
                if [[ -z "${answer//[[:space:]]/}" ]]; then
                    if [[ "$required" == "true" && -z "$default_json" ]]; then
                        echo "    Value required." >&2
                        continue
                    elif [[ -n "$default_json" ]]; then
                        value_json=$default_json
                    fi
                    break
                fi
                if ! echo "$answer" | jq empty >/dev/null 2>&1; then
                    echo "    Invalid JSON." >&2
                    continue
                fi
                value_json="$answer"
                break
                ;;
            *)
                answer=$(prompt "    Value: ")
                if [[ -z "${answer//[[:space:]]/}" ]]; then
                    if [[ "$required" == "true" && -z "$default_json" ]]; then
                        echo "    Value required." >&2
                        continue
                    elif [[ -n "$default_json" ]]; then
                        value_json=$default_json
                    fi
                    break
                fi
                value_json=$(jq -nc --arg v "$answer" '$v')
                break
                ;;
            esac
        done

        if [[ -z "$value_json" ]]; then
            continue
        fi
        params=$(jq --arg key "$key" --argjson val "$value_json" '. + {($key): $val}' <<<"$params")
    done

    echo "$params"
}

create_area() {
    local area_name area_desc action_json action_params reactions params_json reaction_list_json
    area_name=$(prompt "Area name: ")
    area_desc=$(prompt "Area description (optional): ")

    echo "Select action component:"
    action_json=$(select_component "action") || return 1
    action_params=$(collect_params "$action_json") || return 1

    reaction_list_json='[]'
    while true; do
        echo "Select reaction component:"
        local reaction_json reaction_params reaction_payload add_more
        reaction_json=$(select_component "reaction") || return 1
        reaction_params=$(collect_params "$reaction_json") || return 1
        reaction_payload=$(jq -nc \
            --arg componentId "$(echo "$reaction_json" | jq -r '.id')" \
            --argjson params "$reaction_params" \
            '{componentId:$componentId, params:$params}')
        reaction_list_json=$(jq --argjson reaction "$reaction_payload" '. + [$reaction]' <<<"$reaction_list_json")

        add_more=$(prompt "Add another reaction? [y/N]: ")
        if [[ ! "$add_more" =~ ^[Yy]$ ]]; then
            break
        fi
    done

    params_json=$(jq -nc \
        --arg name "$area_name" \
        --arg description "$area_desc" \
        --arg actionId "$(echo "$action_json" | jq -r '.id')" \
        --argjson actionParams "$action_params" \
        --argjson reactions "$reaction_list_json" \
        '{
            name: $name,
            description: (if ($description | length) > 0 then $description else null end),
            action: {
                componentId: $actionId,
                params: $actionParams
            },
            reactions: $reactions
        }')

    api_request POST "/v1/areas" "$params_json"
    if [[ "$API_STATUS" == "201" ]]; then
        echo "$API_BODY" | jq '.'
        local execute_now area_id
        area_id=$(echo "$API_BODY" | jq -r '.id')
        execute_now=$(prompt "Trigger this area immediately? [y/N]: ")
        if [[ "$execute_now" =~ ^[Yy]$ ]]; then
            api_request POST "/v1/areas/$area_id/execute"
            if [[ "$API_STATUS" == "202" ]]; then
                notify "Execution accepted."
            else
                echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
                echo "Failed to enqueue execution (HTTP $API_STATUS)" >&2
            fi
        fi
    else
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Area creation failed (HTTP $API_STATUS)" >&2
    fi
}

list_areas() {
    api_request GET "/v1/areas"
    if [[ "$API_STATUS" == "200" ]]; then
        echo "$API_BODY" | jq '.areas'
    else
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Unable to list areas (HTTP $API_STATUS)" >&2
    fi
}

execute_area() {
    api_request GET "/v1/areas"
    if [[ "$API_STATUS" != "200" ]]; then
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Unable to list areas (HTTP $API_STATUS)" >&2
        return
    fi
    local areas count
    areas=$(echo "$API_BODY" | jq -c '.areas')
    count=$(echo "$areas" | jq 'length')
    if (( count == 0 )); then
        echo "No areas available." >&2
        return
    fi
    for ((i=0; i<count; i++)); do
        local item id name
        item=$(echo "$areas" | jq -c ".[$i]")
        id=$(echo "$item" | jq -r '.id')
        name=$(echo "$item" | jq -r '.name')
        printf "  [%d] %s – %s\n" $((i+1)) "$name" "$id"
    done
    local choice
    choice=$(prompt "Select area [1-$count]: ")
    if [[ -z "$choice" ]]; then
        echo "Selection required." >&2
        return
    fi
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > count )); then
        echo "Invalid selection." >&2
        return
    fi
    local area_id
    area_id=$(echo "$areas" | jq -r ".[$((choice-1))].id")
    api_request POST "/v1/areas/$area_id/execute"
    if [[ "$API_STATUS" == "202" ]]; then
        notify "Execution accepted."
    else
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Failed to trigger area (HTTP $API_STATUS)" >&2
    fi
}

delete_area() {
    api_request GET "/v1/areas"
    if [[ "$API_STATUS" != "200" ]]; then
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Unable to list areas (HTTP $API_STATUS)" >&2
        return
    fi

    local areas count
    areas=$(echo "$API_BODY" | jq -c '.areas')
    count=$(echo "$areas" | jq 'length')
    if (( count == 0 )); then
        echo "No areas available." >&2
        return
    fi

    for ((i=0; i<count; i++)); do
        local item id name status
        item=$(echo "$areas" | jq -c ".[$i]")
        id=$(echo "$item" | jq -r '.id')
        name=$(echo "$item" | jq -r '.name')
        status=$(echo "$item" | jq -r '.status')
        printf "  [%d] %s – %s (%s)\n" $((i+1)) "$name" "$id" "$status"
    done

    local choice
    choice=$(prompt "Select area to delete [1-$count]: ")
    if [[ -z "$choice" ]]; then
        echo "Selection required." >&2
        return
    fi
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > count )); then
        echo "Invalid selection." >&2
        return
    fi

    local area_json area_id confirm
    area_json=$(echo "$areas" | jq -c ".[$((choice-1))]")
    area_id=$(echo "$area_json" | jq -r '.id')
    confirm=$(prompt "Delete area $(echo "$area_json" | jq -r '.name')? [y/N]: ")
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        notify "Deletion cancelled."
        return
    fi

    api_request DELETE "/v1/areas/$area_id"
    if [[ "$API_STATUS" == "200" || "$API_STATUS" == "204" ]]; then
        notify "Area deleted."
    else
        echo "$API_BODY" | jq '.' 2>/dev/null || echo "$API_BODY"
        echo "Failed to delete area (HTTP $API_STATUS)" >&2
    fi
}

show_menu() {
    cat <<EOF

AREA helper – API_BASE=$API_BASE

1) Register user
2) Verify email
3) Login
4) List components
5) List identities
6) OAuth connect provider
7) Subscribe provider
8) Create area
9) List areas
10) Execute area
11) Delete area
0) Exit
EOF
}

main_loop() {
    while true; do
        show_menu
        local choice
        choice=$(prompt "Select option: ")
        case "$choice" in
        1) register_user ;;
        2) verify_email ;;
        3) login_user ;;
        4) list_components ;;
        5) list_identities ;;
        6) oauth_connect ;;
        7) subscribe_provider ;;
        8) create_area ;;
        9) list_areas ;;
        10) execute_area ;;
        11) delete_area ;;
        0|"") break ;;
        *) echo "Unknown option." ;;
        esac
    done
}

main_loop
