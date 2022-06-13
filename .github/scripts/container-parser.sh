#!/usr/bin/env bash

# shellcheck source=/dev/null
source "$(dirname "${0}")/lib/functions.sh"

set -o errexit
set -o nounset
set -o pipefail
shopt -s lastpipe

show_help() {
    cat <<EOF
Usage: $(basename "$0") <options>
    -h, --help               Display help
    -f, --file               File to scan for container images
    --nothing                Enable nothing mode
EOF
}

main() {
    local file=
    local nothing=
    parse_command_line "$@"
    check "jo"
    check "jq"
    check "yq"
    entry
}

parse_command_line() {
    while :; do
        case "${1:-}" in
        -h | --help)
            show_help
            exit
            ;;
        -f | --file)
            if [[ -n "${2:-}" ]]; then
                file="$2"
                shift
            else
                echo "ERROR: '-f|--file' cannot be empty." >&2
                show_help
                exit 1
            fi
            ;;
        --nothing)
            nothing=1
            ;;
        *)
            break
            ;;
        esac
        shift
    done

    if [[ -z "$file" ]]; then
        echo "ERROR: '-f|--file' is required." >&2
        show_help
        exit 1
    fi

    if [[ -z "$nothing" ]]; then
        nothing=0
    fi
}

entry() {
    # create new array to hold the images
    images=()

    # look in hydrated flux helm releases
    chart_registry_url=$(chart_registry_url "${file}")
    chart_name=$(yq eval-all .spec.chart.spec.chart "${file}" 2>/dev/null)

    # look in helm values
    images+=("$(yq eval-all '[.. | select(has("repository")) | select(has("tag"))] | .[] | .repository + ":" + .tag' "${file}" 2>/dev/null)")

    # look in kubernetes deployments, statefulsets and daemonsets
    images+=("$(yq eval-all '.spec.template.spec.containers.[].image' "${file}" 2>/dev/null)")

    # look in kubernetes pods
    images+=("$(yq eval-all '.spec.containers.[].image' "${file}" 2>/dev/null)")

    # look in kubernetes cronjobs
    images+=("$(yq eval-all '.spec.jobTemplate.spec.template.spec.containers.[].image' "${file}" 2>/dev/null)")

    # look in docker compose
    images+=("$(yq eval-all '.services.*.image' "${file}" 2>/dev/null)")

    # remove duplicate values xD
    IFS=" " read -r -a images <<<"$(tr ' ' '\n' <<<"${images[@]}" | sort -u | tr '\n' ' ')"

    # create new array to hold the parsed images
    parsed_images=()
    # loop thru the images removing any invalid items
    for i in "${images[@]}"; do
        # loop thru each image and split on new lines (for when yq finds multiple containers in the same file)
        for b in ${i//\\n/ }; do
            if [[ -z "${b}" || "${b}" == "null" || "${b}" == "---" ]]; then
                continue
            fi
            parsed_images+=("${b}")
        done
    done
    # check if parsed_images array has items
    if ((${#parsed_images[@]})); then
        # convert the bash array to json and wrap array in an containers object
        jo -a "${parsed_images[@]}" | jq -c '{containers: [(.[])]}'
    fi
}

main "$@"
