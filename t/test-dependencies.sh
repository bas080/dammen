#!/usr/bin/env mache
#!/usr/bin/env bash

curl -s https://raw.githubusercontent.com/bas080/bash-tap/83132cc81696a49f4e4c66b126a63bcba0633018/bash-tap
cat <<'EOF'

BIN="$(mktemp -u)"
compile() {
  swipl -O --goal=main --stand_alone=true -o $BIN -c ./src/*.pl &> /dev/null
}
EOF
