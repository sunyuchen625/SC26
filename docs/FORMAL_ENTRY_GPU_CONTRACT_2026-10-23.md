# SC26 delivery requirements and remaining interface checks

Updated 27 October 2026. The execution schedule is the [current delivery plan](DELIVERY_PLAN_2026-10-27.md), with the [teammate work order](SC26_队友交接工单_2026-10-24.md). The authoritative submission instructions are page one of the [official template downloaded on 26 October](../资料/SolverChallenge26报告模板_2026-10-26官网下载.docx); the resource chat reports that its 27 October download has identical text. [Source record and extracted instructions](../logs/2026-10-27/delivery-update/official-source-record.json) preserve the checked scope.

## Established submission procedure

Submit to **solverchallenge@sina.com**. Use subject `SolverChallenge26材料提交_队伍名称_版本号` and archive name `SolverChallenge26_队伍名称_版本号.zip`. The archive has report, source/run scripts and solve-video directories. Organize source by problem, then platform; each problem's Markdown explains dependencies, build, launch, parameters and node/rank/thread/GPU resources. Name videos by problem and platform. Large videos may be supplied through accessible download links with extraction codes in the email.

Each problem requires a video covering job submission to the compute node through successful solving. The teacher's 25 October 11:06 reply, recorded in resource chat `01a0d246-ce59-7b90-85ab-854b63965a46`, says routine unified online testing will not be arranged unless results are disputed. Prepare team-run evidence and retain the reproducible source and logs for any later verification.

The most recently verified conference notice says **30 October 24:00** without an explicit timezone. The team's internal target is 30 October 12:00 Asia/Shanghai. The extension survey is a consultation, not an approved date change. A seven-day extension is the team's recommendation; 6 November is conditional on an official seven-day change from 30 October.

## Normative measurement requirements

| Requirement | Application to the selected implementation |
| --- | --- |
| Exactly five trials, including hardware warmup; average all five | Retain the first trial and all round records; record the printed field and unit used in the report |
| Construct, solve and release solver components every trial | Numerical factorization, AMG/preconditioner setup and associated solve preparation remain counted; do not reuse a once-built numerical setup |
| CPU-to-GPU transfer is excluded | Measure the actual accepted transfer boundary; do not subtract host probes from an old overall mean to manufacture a new score |
| Coordinate-preserving storage conversion/sorting may be excluded | Row/column permutations and numerical reordering remain counted; callback names do not establish the boundary |
| Official example correctness and memory interfaces are required | Preserve official interface outputs, actual precision and memory semantics. The existing float128 original-system checks are valid archived evidence; rank RSS sums and sampled device use are separately labelled supporting metrics |
| Complete device work inside its counted interval | Establish the solver/library completion semantics or required synchronization at the actual chosen boundary |

The old public CPU driver prints a seconds measurement with an `ms` label, while the GPU sample converts to milliseconds. The team's prototype uses seconds. Since the team supplies its own report and evidence, identify the actual field, implementation and unit, and report seconds as the template results-table heading and note request (recorded in the source JSON); do not wait for an unspecified central scoring parser. Keep the official detection interfaces even when correcting a label or adapting the driver.

## Evidence already available

CPU candidate `SC26_CPU_candidate_6b7f675.tar.gz` retains 118 manifested entries. The scq build 9275741 and four full CPU runs 9275742–9275745 have portable raw records, source/cache/binary receipts, successful accounting and replayed results. GPU candidate `SC26_T2_HIP_preparation_20261023.tar.gz` retains 89 manifested entries. Job 966565 supplies a new build, full T2-low run and three small cases, all replayed, with five full-run rounds averaging 3.902198 s and Q-residual 5.896126e-7. See the [reproduction summary](REPRODUCE_SCQ_2026-10-25.md).

These records establish their own experimental implementation and configuration. They do not establish that a final video exists or that a changed measurement/entry is covered. The original small-case answer vectors were intentionally excluded from the handoff; on-node known-solution receipts remain available, while local elementwise comparison is unavailable. Binary files are linked through original hash receipts rather than rehashed locally.

LX2 authentication and queue recovery are a dated teammate terminal transcription supplied by the captain in the [environment appendix](LX2_ENVIRONMENT_APPENDIX_2026-10-24.md). No LX2 native build or compute job has been submitted; CA and aarch64 dependencies remain unresolved. LX2 stays an environment appendix this delivery round.

## Remaining checks that affect the final choice

| Item | Closure evidence |
| --- | --- |
| Final source/runtime/resources | Record the selected source and dependencies, actual MPI implementation and launch, permitted platform assignment and resource quantities. Existing experiments use OpenMPI 4.1.8; the upstream README mentions MPICH. Compare the applicable instructions with the actual recorded team-run environment and clarify a conflict only where it affects acceptance |
| HIP entry and official metrics | The working implementation is HIP through `MPI_iterative_solver`. The separate T2 GPU adapter remains a template with unimplemented callbacks. Determine whether the existing entry satisfies the applicable rules; implement that adapter only if it is actually required. Check the official memory-interface fields for the selected HIP path |
| Final timer and device completion | Check each counted lifecycle against the established rules above. Existing approximately 3.9 s prototype values include their original migration/setup/solve/diagnostic/cleanup scope. Use a newly measured compliant field when changing boundaries, with affected known-case/full-data qualification |
| Genuine selected-artifact reproduction | CPU reproduction and the existing GPU experimental artifact are already evidenced. If final source/entry/runtime/resources change, validate and reproduce the affected selection; retain the approved CPU path and still-applicable checks |
| Videos and report/package agreement | Associate each selected problem/platform with the final source/configuration, a complete submission-to-success video, official outputs, report entry and running instructions; verify large-video downloads |
| Final selection and email submission | Captain confirms the main-result/platform table and exact versioned package. Retain sent email, timestamp, package identity and any organizer receipt or reply. No unannounced receipt format or extra permission letter is presumed |

When rules or an applicable organizer reply already resolve an item, record that evidence and close it. The email entrance, package layout, five-trial definition and component lifecycle are established requirements. Team members are already consulting the test group; keep any remaining query focused on the actual HIP entry/resource/metrics ambiguity and attach its reply to the applicable configuration.

CPU remains the delivery mainline with passing T2-low, T4–T7 and ten RHS each for T8/T9/T10; T1, T3 and T2-high remain numerical limitations. GPU T2 is a conditional candidate pending the final alignment and captain's choice. The current work order prepares the final materials under the original deadline while any extension request is unresolved.
