#!/bin/bash
# ============================================================================
# check_owned_transfer.sh
# Regression check for the 1.6.0 use-after-free crash (SIGSEGV) when loading
# an ISO image: run_bk_operation passed its owned worker/on_done delegates
# to IsoOperations.run without (owned), which made valac generate a call
# with NULL destroy-notify callbacks and release the closures right after
# the call. The worker thread then invoked freed closures.
#
# This script verifies the generated C code transfers ownership: the
# iso_operations_run call inside iso_master_run_bk_operation must pass
# non-NULL worker_target_destroy_notify / done_target_destroy_notify.
# ============================================================================

set -e
cd "$(dirname "$0")/.."

C_FILE=isomaster.c
if [ ! -f "$C_FILE" ]; then
    echo "SKIP: $C_FILE not found (run make -f Makefile.vala first)"
    exit 0
fi

python3 - "$C_FILE" <<'EOF'
import re, sys

src = open(sys.argv[1], encoding="utf-8", errors="replace").read()

# Extract the body of iso_master_run_bk_operation
m = re.search(r'^iso_master_run_bk_operation \(IsoMaster\* self,.*?\n\}\n',
              src, re.S | re.M)
if not m:
    print("FAIL: iso_master_run_bk_operation not found in generated C")
    sys.exit(1)
body = m.group(0)

call = re.search(r'iso_operations_run \(([^;]+)\);', body)
if not call:
    print("FAIL: iso_operations_run call not found in run_bk_operation body")
    sys.exit(1)

args = [a.strip() for a in call.group(1).split(",")]
# Signature: (self, worker, worker_target, worker_target_destroy_notify,
#             done, done_target, done_target_destroy_notify)
if len(args) < 7:
    print("FAIL: unexpected iso_operations_run argument count: %d" % len(args))
    sys.exit(1)

wt_dn = args[3]
dt_dn = args[6]
if wt_dn == "NULL" or dt_dn == "NULL":
    print("FAIL: delegate ownership not transferred to IsoOperations.run")
    print("  worker_target_destroy_notify = %s" % wt_dn)
    print("  done_target_destroy_notify   = %s" % dt_dn)
    print("  -> the worker thread would run freed closures (1.6.0 crash)")
    sys.exit(1)

print("PASS: delegate ownership transferred (worker dn=%s, done dn=%s)" % (wt_dn, dt_dn))
EOF
