#!/bin/bash
set -euo pipefail

DEBIAN_DOCKER_IMAGE_VERSION="13.5"

update_debian_packages() {
    dockerfile="${1}"
    
    DEBIAN_START_MARKER="# BEGIN DEBIAN PACKAGES"
    DEBIAN_END_MARKER="# END DEBIAN PACKAGES"
    
    if ! grep -q "${DEBIAN_START_MARKER}" "${dockerfile}" || ! grep -q "${DEBIAN_END_MARKER}" "${dockerfile}"; then
        echo "❌ Could not find Debian marker lines in ${dockerfile}"
        return 1
    fi
    
    section_count=$(grep -c "${DEBIAN_START_MARKER}" "${dockerfile}")
    
    echo
    echo "🔍 Fetching latest dockerfile Debian package versions..."
    # Pull latest debian image
    docker pull "debian:${DEBIAN_DOCKER_IMAGE_VERSION}-slim" >/dev/null
    
    for ((section = 1; section <= section_count; section++)); do
        echo "--- Section ${section}/${section_count}"
        
        # Extract only the Nth section's package block
        package_block=$(awk -v start="${DEBIAN_START_MARKER}" -v end="${DEBIAN_END_MARKER}" -v n="${section}" '
            $0 ~ start { count++; if (count == n) in_block = 1 }
            in_block
            $0 ~ end && in_block { in_block = 0 }
        ' "${dockerfile}")
        
        # Extract the package names before '=' using regex
        # shellcheck disable=SC2312  # only the piped-through package list matters, not each stage's exit code
        mapfile -t package_names < <(echo "${package_block}" | grep -oP '^\s*[a-z0-9.+-]+(?==)' | sed 's/^[[:space:]]*//')
        
        if [[ "${#package_names[@]}" -eq 0 ]]; then
            echo "❌ No package names found in section ${section}"
            rm -f debian_block.txt "${dockerfile}.tmp"
            return 1
        fi
        
        unset debian_versions
        declare -A debian_versions
        
        # Single container: update apt once, then query all packages together
        versions_raw=$(docker run --rm "debian:${DEBIAN_DOCKER_IMAGE_VERSION}-slim" sh -c \
        "apt-get update -qq -o Acquire::Languages=none 2>/dev/null && apt-cache policy ${package_names[*]}")

        # shellcheck disable=SC2312  # the awk-parsed output is what matters, not the echo/awk exit codes
        while IFS='=' read -r pkg ver; do
            [[ -n "${pkg}" && -n "${ver}" ]] && debian_versions["${pkg}"]="${ver}"
            done < <(echo "${versions_raw}" | awk '
            /^[a-z0-9]/ { pkg=$1; sub(/:$/, "", pkg) }
            /Candidate:/  { print pkg "=" $2 }
        ')
        
        for package in "${package_names[@]}"; do
            version="${debian_versions["${package}"]:-}"
            if [[ -z "${version}" ]]; then
                echo "❌ Failed to get version for: ${package}"
                rm -f debian_block.txt "${dockerfile}.tmp"
                return 1
            fi
            echo "  ${package}=${version}"
        done
        
        # Build the updated install block for this section
        {
            echo "${DEBIAN_START_MARKER}"
            echo "RUN apt-get update && \\"
            echo "    apt-get install -yqq --no-install-recommends \\"
            for package in "${package_names[@]}"; do
                echo "        ${package}=\"${debian_versions[${package}]}\" \\"
            done
            echo "    && \\"
            echo "    apt-get autoremove && \\"
            echo "    apt-get clean && \\"
            echo "    rm -rf /var/lib/apt/lists/*"
            echo "${DEBIAN_END_MARKER}"
        } >debian_block.txt
        
        # Replace the Nth occurrence of the block with the new one
        awk -v start_marker="${DEBIAN_START_MARKER}" \
        -v end_marker="${DEBIAN_END_MARKER}" \
        -v target_section="${section}" '
        BEGIN {
            while ((getline line < "debian_block.txt") > 0) {
                block = block line ORS
            }
            close("debian_block.txt")
            sub(/\n$/, "", block)
        }
        $0 ~ start_marker {
            section_count++
            if (section_count == target_section) {
                print block
                in_target = 1
                next
            }
        }
        $0 ~ end_marker && in_target { in_target = 0; next }
        !in_target { print }
        ' "${dockerfile}" >"${dockerfile}.tmp"
        
        mv "${dockerfile}.tmp" "${dockerfile}"
    done
    
    rm -f debian_block.txt
    
    echo "✅ ${dockerfile#./} updated successfully with latest Debian packages"
}

update_debian_image_version() {
    local dockerfile="${1}"
    
    echo
    echo "🔍 Fetching latest Debian 13 image version..."
    
    local tags_json
    tags_json=$(curl -fsSL "https://hub.docker.com/v2/repositories/library/debian/tags?name=13.&page_size=25&ordering=last_updated")
    local latest_version
    latest_version=$(echo "${tags_json}" | jq -r '.results[].name' \
    | grep -P '^13\.[0-9]+-slim$' | sed 's/-slim//' | sort -t. -k2 -n | tail -1)
    
    if [[ -z "${latest_version}" ]]; then
        echo "⚠️ Could not determine latest Debian 13 point release from Docker Hub" >&2
        return 1
    fi
    
    echo "  Latest Debian version: ${latest_version}"
    
    # Dockerfile FROM line
    sed -i "s|FROM debian:[0-9.]*-slim|FROM debian:${latest_version}-slim|g" "${dockerfile}"
    
    # DEBIAN_DOCKER_IMAGE_VERSION in this script (used to spin up containers for apt checks)
    sed -i "s|DEBIAN_DOCKER_IMAGE_VERSION=\"[0-9.]*\"|DEBIAN_DOCKER_IMAGE_VERSION=\"${latest_version}\"|" "${BASH_SOURCE[0]}"
    
    echo "✅ Debian image updated to ${latest_version} in Dockerfile and script"
}

get_docker_ce_cli_version() {
    local codename="${1:-trixie}"
    local arch="${2:-amd64}"
    
    local url="https://download.docker.com/linux/debian/dists/${codename}/stable/binary-${arch}/Packages.gz"
    
    # IMPORTANT: send logs to stderr, not stdout
    echo "🔍 Fetching docker-ce-cli version from Docker APT repo..." >&2
    
    curl -fsSL "${url}" \
    | gunzip -c \
    | awk '
            /^Package: docker-ce-cli$/ { in_pkg=1 }
            in_pkg && /^Version:/ { print $2; exit }
            /^$/ { in_pkg=0 }
    '
}

update_docker_ce_cli() {
    local dockerfile="${1}"
    
    local version
    version=$(get_docker_ce_cli_version "trixie" | tr -d '\n')
    
    echo "  docker-ce-cli=${version}"
    
    awk -v ver="${version}" '
    {
        if ($0 ~ /docker-ce-cli=/) {
            sub(/docker-ce-cli="[^"]*"/, "docker-ce-cli=\"" ver "\"")
        }
        print
    }
    ' "${dockerfile}" > "${dockerfile}.tmp" && mv "${dockerfile}.tmp" "${dockerfile}"
}

get_github_action_version() {
    local action="${1}"
    local curl_args=(-fsSL)
    
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
    fi
    
    local version
    version=$(curl "${curl_args[@]}" "https://api.github.com/repos/${action}/releases/latest" | jq -r '.tag_name // empty')
    if [[ -z "${version}" ]]; then
        echo "⚠️ Could not fetch GitHub release version for ${action}" >&2
        return 1
    fi
    echo "${version}"
}

update_shellcheck_image() {
    local script="${1:-.github/scripts/lint_and_tests.sh}"

    if [[ ! -f "${script}" ]]; then
        echo "⚠️ ${script} not found, skipping shellcheck update"
        return 0
    fi

    echo
    echo "🔍 Fetching latest ShellCheck version..."

    # ShellCheck's Docker tags mirror its GitHub release tags (e.g. v0.11.0)
    local version
    # shellcheck disable=SC2310  # failure is handled explicitly with an early return
    if ! version=$(get_github_action_version "koalaman/shellcheck"); then
        return 1
    fi

    echo "  koalaman/shellcheck=${version}"
    sed -i "s|SHELLCHECK_DOCKER_IMAGE=\"koalaman/shellcheck:[^\"]*\"|SHELLCHECK_DOCKER_IMAGE=\"koalaman/shellcheck:${version}\"|" "${script}"

    echo "✅ ShellCheck image updated to ${version} in ${script}"
}

update_github_actions() {
    local workflows_dir=".github/workflows"
    
    if [[ ! -d "${workflows_dir}" ]]; then
        echo "⚠️ No workflows directory found at ${workflows_dir}, skipping"
        return 0
    fi
    
    echo
    echo "🔍 Fetching latest GitHub Action versions..."
    
    # Collect unique 'owner/repo@version' references from all workflow files
    # shellcheck disable=SC2312  # only the collected, sorted references matter, not each pipe stage's exit code
    mapfile -t action_refs < <(
        grep -rh 'uses:' "${workflows_dir}"/*.yml \
        | grep -oP 'uses:\s+\K[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+@\S+' \
        | sort -u
    )
    
    if [[ "${#action_refs[@]}" -eq 0 ]]; then
        echo "  No action references found in ${workflows_dir}"
        return 0
    fi
    
    for ref in "${action_refs[@]}"; do
        action="${ref%@*}"
        current_version="${ref#*@}"

        # shellcheck disable=SC2310  # a failed lookup is handled by skipping this action
        if ! latest_version=$(get_github_action_version "${action}"); then
            continue
        fi
        
        if [[ "${current_version}" == "${latest_version}" ]]; then
            echo "  ${action}=${latest_version} (already up-to-date)"
        else
            echo "  ${action}: ${current_version} → ${latest_version}"
            for workflow in "${workflows_dir}"/*.yml; do
                sed -i "s|${action}@${current_version}|${action}@${latest_version}|g" "${workflow}"
            done
        fi
    done
    
    echo "✅ ${workflows_dir} updated successfully with latest GitHub Actions"
}

# Runs an updater step, logging a warning but continuing if it fails so a single failed source
# doesn't abort the rest of the version bump. Invoking via "${@}" (rather than the function name
# directly in an || chain) keeps the intended failure tolerance without tripping SC2310.
run_update() {
    local description="${1}"
    shift
    if ! "${@}"; then
        echo "⚠️ ${description} failed, continuing..."
    fi
}

# Default paths assume the script is being run from the root of the project
dockerfile="${1:-./.devcontainer/Dockerfile}"

if [[ ! -f "${dockerfile}" ]]; then
    echo "❌ Dockerfile not found: ${dockerfile}"
    exit 1
fi

run_update "Debian image version update" update_debian_image_version "${dockerfile}"
run_update "Debian packages update"       update_debian_packages "${dockerfile}"
run_update "Docker CE CLI update"         update_docker_ce_cli "${dockerfile}"
run_update "ShellCheck image update"      update_shellcheck_image
run_update "GitHub Actions update"        update_github_actions
