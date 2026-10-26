# SC26 CPU Reproduction Exact Summary (Machine-Generated from verify_runs_report.json)

| Problem | Job | Node (Ranks x Threads) | Phase Means (analyse / prep_or_factor / solve) | Framework Mean (s) | Original float128 Residual | Peak RSS Sum (Bytes / MiB) | Accepted |
|---|---|---|---|---|---|---|---|
| T2-low | `9275742` | `c3n06` (`16x1`) | `0.008101` / `21.742348` / `6.548338` | **`28.300503`** | **`5.885605e-07`** | `15605833728` (`11246.1289 MiB`) | `True` |
| T7 | `9275743` | `c3n06` (`16x1`) | `0.010479` / `4.454646` / `17.554605` | **`22.023256`** | **`1.601450e-09`** | `67250155520` (`44571.5898 MiB`) | `True` |
| T9-RHS01 | `9275744` | `c3n24` (`1x16`) | `62.651993` / `9.049722` / `1.557171` | **`73.353634`** | **`1.487011e-16`** | `24630075392` (`23489.0703 MiB`) | `True` |
| T5 | `9275745` | `c3n99` (`96x1`) | `0.003328` / `10.312005` / `176.673475` | **`186.989168`** | **`2.576043e-09`** | `202786639872` (`144244.4922 MiB`) | `True` |

| Problem | CMakeCache SHA256 | Binary SHA256 |
|---|---|---|
| 02 | `e75650db1a748783b0802b955ca162e52d6a98d50b35ec6286c7d3aec42205cb` | `bc629226457cff919173680a3d20713fa5a51f9a3c74b7369c6ef742d52c9d4b` |
| 07 | `3d111b52c2d68698db1691172634849b8b7da286c7272df493a1e02da1d11d3e` | `fb0dee16980b39839a2d4b84486e4a1938f48911e50e62a27c19de859aba7865` |
| 09 | `848fced144c37e4fa04cf74f80aaba64862831437bd2d6a64f65fce0ba2ab3bd` | `086638171919081315ca3499fa0c4e8da96d8a70c9d6a2e285398b8ae52db065` |
| 05 | `95de8a5047030299f5e3a808dffcae025cadc6901b6640ca1a26493aa0289971` | `f79e84245640606d6eabc7b66de56f951590ebd0da037a98dd8e3f53b5098f98` |
