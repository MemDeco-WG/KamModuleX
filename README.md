# KamModuleX

Minimal Kam module entrypoint scaffold.

`kam.sh` loads the module-local kamfw runtime from:

```sh
$MODDIR/lib/kamfw/.kamfwrc
```

Then it delegates execution to:

```sh
kamfw run "$KAM_PHASE" -- "$@"
```

`KAM_PHASE` defaults to `install`, so the script works as a basic install entry
unless a caller selects another lifecycle phase.

## Validation

```sh
shellcheck -S warning -s bash kam.sh
bash -n kam.sh
```
