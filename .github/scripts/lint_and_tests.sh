#!/bin/bash
# ------------------------------------------------------------------------------
# Script Name:     lint_and_tests.sh
#
# Description:     Lints the project's shell scripts (*.sh) with shellcheck via
#                  Docker. This repo ships only shell scripts, so shellcheck is
#                  the sole quality gate.
#
# Usage:           ./lint_and_tests.sh [-v|--verbose] [-f|--force]
#
#                  By default the lint only runs when a *.sh file has changed
#                  since the most recent semver git tag (or when no tag exists).
#                  If nothing relevant changed, the script exits 0 without
#                  invoking shellcheck.
#
#                  -v, --verbose
#                    Show shellcheck's full output even when it passes. Off by
#                    default: a passing run prints only a summary line.
#
#                  -f, --force
#                    Always run shellcheck, skipping the change detection.
#
#                  Examples:
#                    ./lint_and_tests.sh
#                    ./lint_and_tests.sh -v
#                    ./lint_and_tests.sh --force
#
# Requirements:
#   - Docker must be installed and available on the system PATH
#
# Exit Codes:
#   - 0: shellcheck passed (or there was nothing to lint)
#   - Non-zero: one or more shellcheck findings were reported
# ------------------------------------------------------------------------------

set -uo pipefail

trap 'echo; echo "❌ Interrupted"; exit 130' INT

SHELLCHECK_DOCKER_IMAGE="koalaman/shellcheck:v0.11.0"

# ShellCheck has no `--config` flag; it auto-discovers a `.shellcheckrc` by walking up from each
# checked file. This repo keeps the canonical config under shellscript/ rather than the repo root,
# so run_shellcheck overlays it at the container's working dir (see below).
SHELLCHECKRC="shellscript/.shellcheckrc"

VERBOSE=false
FORCE=false

overall_exit_code=0

run_shellcheck() {
    echo
    echo "Running shell script lint using [${SHELLCHECK_DOCKER_IMAGE}]"
    # Lint every tracked *.sh file. `git ls-files` naturally excludes any build output.
    local files=()
    # shellcheck disable=SC2312  # git ls-files won't meaningfully fail here; its exit code is not needed
    mapfile -t files < <(git ls-files '*.sh')
    if [[ "${#files[@]}" -eq 0 ]]; then
        echo "✅ Shell script lint passed (no shell scripts found)"
        return
    fi

    # Overlay the shared .shellcheckrc at the container's working dir (read-only) so shellcheck
    # discovers it without mutating the host tree. If it's missing, fall back to shellcheck defaults.
    local config_mount=()
    if [[ -f "${SHELLCHECKRC}" ]]; then
        config_mount=(-v "${PWD}/${SHELLCHECKRC}:/app/.shellcheckrc:ro")
    else
        echo "⚠️ ${SHELLCHECKRC} not found; running with shellcheck defaults" >&2
    fi

    docker pull "${SHELLCHECK_DOCKER_IMAGE}" >/dev/null
    if output=$(docker run --rm \
        -v "${PWD}:/app" \
        "${config_mount[@]}" \
        -w /app \
        "${SHELLCHECK_DOCKER_IMAGE}" \
        "${files[@]}" 2>&1); then
        [[ "${VERBOSE}" == true && -n "${output}" ]] && echo "${output}"
        echo "✅ Shell script lint passed"
    else
        echo "${output}"
        echo "❌ Shell script lint failed"
        overall_exit_code=1
    fi
}

# Returns 0 if the lint should run: a *.sh file changed since the latest semver tag, or the pinned
# Docker image in this script changed (which wouldn't otherwise show up as a *.sh change).
shell_scripts_changed() {
    local latest_tag
    latest_tag=$(git tag --sort=-version:refname 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -1 || true)

    if [[ -z "${latest_tag}" ]]; then
        echo "No semver tag found; running shellcheck" >&2
        return 0
    fi

    echo "Checking for shell script changes since tag [${latest_tag}]..." >&2

    local file
    # shellcheck disable=SC2312  # the aggregated git output is what matters, not each command's exit code
    while IFS= read -r file; do
        [[ -z "${file}" ]] && continue
        if [[ "${file}" =~ \.sh$ ]]; then
            return 0
        fi
    done < <(
        {
            git diff --name-only "${latest_tag}..HEAD"
            git diff --name-only
            git diff --name-only --cached
            git ls-files --others --exclude-standard
        } | sort -u
    )

    # A bump to the pinned shellcheck image must also re-trigger the lint, since the image change
    # won't otherwise show up in the *.sh path detection above.
    local script_path=".github/scripts/lint_and_tests.sh"
    local script_diff
    script_diff=$(
        {
            git diff "${latest_tag}..HEAD" -- "${script_path}" 2>/dev/null
            git diff -- "${script_path}" 2>/dev/null
            git diff --cached -- "${script_path}" 2>/dev/null
        } | grep -E '^[+-][^+-]' || true
    )
    if grep -qE '^[+-][[:space:]]*SHELLCHECK_DOCKER_IMAGE=' <<<"${script_diff}"; then
        return 0
    fi

    return 1
}

# Parse flags (accepted in any position); no positional arguments are expected.
while [[ $# -gt 0 ]]; do
    case "${1}" in
    -v | --verbose) VERBOSE=true ;;
    -f | --force) FORCE=true ;;
    *)
        echo "❌ Unknown option: '${1}'. Supported: -v/--verbose, -f/--force"
        exit 1
        ;;
    esac
    shift
done

if [[ "${FORCE}" != true ]] && ! shell_scripts_changed; then
    echo "No shell script changes detected since last tag; nothing to run"
    exit 0
fi

run_shellcheck

if [[ "${overall_exit_code}" -ne 0 ]]; then
    echo
    echo "❌ Shell script lint failed"
    exit 1
fi
