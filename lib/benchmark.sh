__dcp_bench_name=()
__dcp_bench_start=()

__dcp_monotime=""
if ! __dcp_monotime="$(command -v monotime)" && [[ -x "${HOME}/.local/bin/monotime" ]]; then
  __dcp_monotime="${HOME}/.local/bin/monotime"
fi

__bench_start() {
  if [[ -z "$1" ]]; then
    return 1
  fi

  local start
  if ! start="$("${__dcp_monotime}")"; then
    return 1
  fi

  __dcp_bench_name+=("$1")
  __dcp_bench_start+=("${start}")
}

__bench_end() {
  local end
  if ! end="$("${__dcp_monotime}")"; then
    return 1
  fi

  local name_count start_count
  name_count="${#__dcp_bench_name[@]}"
  start_count="${#__dcp_bench_start[@]}"

  if ((name_count == 0 || start_count == 0)); then
    return 1
  fi

  local name duration
  name="${__dcp_bench_name[-1]}"
  duration="$((end - ${__dcp_bench_start[-1]}))"

  __dcp_bench_name=("${__dcp_bench_name[@]:0:$((name_count - 1))}")
  __dcp_bench_start=("${__dcp_bench_start[@]:0:$((start_count - 1))}")

  local i prefix
  for i in {1..${name_count}}; do
    prefix+=">"
  done

  printf '%b%s %b%s\e[0m took %b%dms\e[0m\n' \
         '\e[2;39;49m' "${prefix}" \
         '\e[0;32m' "${name}" \
         '\e[0;33m' "${duration}" \
         >&2
}
