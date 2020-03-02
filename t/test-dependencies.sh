#!/usr/bin/env mache
#!/usr/bin/env bash

curl -s https://raw.githubusercontent.com/bas080/bash-tap/e3cff71c808e0413aa40d1b0db987a09ebead6f0/bash-tap
cat <<'EOF'
compile() {
  swipl -O --goal=main --stand_alone=true -o dammen -c ./src/*.pl
}
EOF
