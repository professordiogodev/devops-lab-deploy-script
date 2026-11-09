#!/usr/bin/env bash
rc=0
if [ -f deploy.sh ] && bash -n deploy.sh 2>/dev/null && grep -q 'set -euo pipefail' deploy.sh && grep -q '^[[:space:]]*trap ' deploy.sh; then echo "- ✅ deploy.sh is valid bash with strict mode and a trap"
else echo "- ❌ deploy.sh is missing, has a syntax error, or lacks 'set -euo pipefail' / a trap"; rc=1; fi
grep -q 'ALL CHECKS PASSED' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
