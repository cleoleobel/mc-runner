# NEXUS FINAL PERFORMANCE BENCHMARK REPORT

**Date:** 2026-08-06  
**Auditor:** Performance Engineer (Antigravity AI)  

---

## 1. Spark Engine Health Benchmarks

Source: Empirical `/spark health` sampler run on live dedicated server instance.

```
> TPS from last 5s, 10s, 1m, 5m, 15m:
    19.99, 20.0, 20.0, 20.0, 20.0

> Tick durations (min/med/95%ile/max ms) from last 10s, 1m:
    0.2 / 1.5 / 7.4 / 31.9 ms (10s)
    0.2 / 2.0 / 27.2 / 90.4 ms (1m)

> CPU usage from last 10s, 1m, 15m:
    59%, 67%, 67%  (system)
    25%, 41%, 41%  (process)

> Memory usage:
    1.1 GB / 3.9 GB  (27% heap allocated)

> Disk usage:
    260.8 GB / 447.0 GB  (58%)
```

---

## 2. Chunky Pregeneration Benchmark

- **Command:** `chunky radius 500` & `chunky start`
- **Pregeneration Rate:** `19.0 chunks per second`
- **Region:** Overworld square region centered at (0, 0)
- **Status:** Operational without server lag or tick drops.

---

## 3. Dedicated Server Boot Benchmark

- **Boot Time:** `12.845 seconds` (world load) / `54.877 seconds` (full Forge container + ModernFix optimization)
- **Log Outcome:** `[Server thread/INFO] [net.minecraft.server.dedicated.DedicatedServer/]: Done (12.845s)! For help, type "help"`
- **Memory Footprint:** ~1.1 GB baseline server RAM.
