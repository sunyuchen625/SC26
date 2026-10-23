#!/bin/bash
#SBATCH --job-name=sc26_t2_exact
#SBATCH --partition=hx1hdnormal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --gres=dcu:Hygon:1
#SBATCH --mem=58G
#SBATCH --time=00:45:00
#SBATCH --output=sc26_t2_exact-%j.out
#SBATCH --error=sc26_t2_exact-%j.err
set -e
if [[ -z ${SLURM_JOB_ID:-} || -z ${SLURMD_NODENAME:-} || $(hostname -s) != "$SLURMD_NODENAME" ]]; then
    printf 'Submit with sbatch; execution requires the allocated compute node.\n' >&2
    exit 2
fi
export LC_ALL=C
module load compiler/gcc/12.2.0 compiler/cmake/3.24.1 compiler/dtk/25.04.2
module load mpi/openmpi/4.1.8/gcc-12.2.0/shca
set -uo pipefail
mpi_prefix=/public/software/mpi/openmpi/openmpi-4.1.8
dtk_root=/public/software/compiler/dtk-25.04.2
export OMPI_MCA_mca_base_component_path="$mpi_prefix/lib/openmpi:/public/software/mpi/pmix/4.2.9/lib/pmix"
export OMPI_MCA_ess_singleton_isolated=1
export OMP_NUM_THREADS=1
work="$HOME/sc26-hip-20261007"
run="$work/exact-$SLURM_JOB_ID"
data=/public/share/ac3k88uz8y/SolverChallenge26-TenProblems/solverchallenge26_02
mkdir -p "$run"
cp "$0" "$run/submitted.sbatch"
printf 'EXPERIMENT=exact_CSR_preallocation JOB=%s NODE=%s\n' "$SLURM_JOB_ID" "$(hostname -s)"
scontrol show job "$SLURM_JOB_ID"
module list
hy-smi
rocminfo | grep -E 'Name:|Size:'
printf '%s  %s\n' \
 '9708c99de61699a0c9d7452503ab07c97284ed3287b57185a816947d8de58ee0' "$work/SC26_T2_HIP_source_20261009.tar.gz" \
 'e3887d90f71190657cd3315b8b4e896bbf238ad38b0178f0b2b05ad8535deb36' "$work/install-892588/lib/libHYPRE.a" \
 'ea9373832008d1b0928d46053de923b872b1fed73f9b0f31aef43d8f6aec24d1' "$data/solverchallenge26_02_A.dat" \
 '3dc7f3a0e52b088e21ab1b540b37583db2828eca8385ed2a963e34789615a46e' "$data/solverchallenge26_02_b.dat" | sha256sum -c -
grep -E 'HYPRE_USING_(HIP|GPU|UNIFIED_MEMORY)' "$work/install-892588/include/HYPRE_config.h"
run_full() {
    local source_dir=$1 output=$2 status=0
    unset SC26_RTOL SC26_PROJECT_CONSTANT
    mkdir -p "$output"
    cd "$output"
    /usr/bin/time -v -o process.time "$source_dir/build/bin/MPI_iterative_solver" \
      "$data/solverchallenge26_02_A.dat" "$data/solverchallenge26_02_b.dat" 0 0 \
      >solver.log 2>solver.err || status=$?
    printf '%s\n' "$status" >process.exit
    test "$status" -eq 0
    test ! -s solver.err
    test "$(grep -c '^T2_HIP_POLICY memory_device=1 execution_device=1$' solver.log)" -eq 5
    test "$(grep -c '^T2_PHASE_SECONDS ' solver.log)" -eq 5
    test "$(grep -c '^T2_PREP_CALL_SECONDS ' solver.log)" -eq 5
    test "$(grep -c '^T2_RHS_PROJECTION ' solver.log)" -eq 5
    test "$(grep -c '^T2_GMRES .* rtol=1.0e-07$' solver.log)" -eq 5
    python3 "$source_dir/tests/check_result.py" solver.log 1e-6
    python3 - <<'ROUND_CHECK'
import re,math
from pathlib import Path
log=Path('solver.log').read_text()
rows=re.findall(r'^CHECK round (\d+) time : (\S+) s$',log,re.M)
assert [int(i)for i,_ in rows]==[1,2,3,4,5]
assert all(math.isfinite(float(t))and float(t)>0 for _,t in rows)
print('OUTER_ROUND_RECORDS_PASS')
ROUND_CHECK
    awk -v limit="$((SLURM_MEM_PER_NODE * 1024))" '/Maximum resident set size/ {if ($NF > limit) exit 1}' process.time
    printf 'FULL_PASS=%s\n' "$output"
    grep -E '^CHECK round |^CHECK end|^T2_PREP_CALL_SECONDS |^T2_PHASE_SECONDS |^T2_GMRES |Q-Check' solver.log
}
for variant in baseline exact; do
    candidate="$run/$variant/source"
    mkdir -p "$candidate"
    cd "$candidate"
    tar -xzf "$work/SC26_T2_HIP_source_20261009.tar.gz"
    sha256sum -c source-sha256.txt
    python3 - "$variant" <<'PATCH_SOURCE'
from pathlib import Path
import hashlib,json,sys
variant=sys.argv[1]
base=b'/* SolverChallenge26 problem 02 solver implementation. */\n#include "solver.h"\n#include <math.h>\n#include <stdio.h>\n#include <stdlib.h>\n\n#ifdef DIRECT_SOLVER\nvoid preprocess(struct MySolver* solver, const struct SC26_SolverInput* input)\n{\n    /* add the code */\n}\n\nvoid direct_solver(struct MySolver* solver, const struct SC26_SolverInput* input)\n{\n    /* add the code */\n}\n\nvoid solve(struct MySolver* solver, const struct SC26_SolverInput* input)\n{\n    /* add the code */\n}\n\nvoid preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)\n{\n    /* add the code */\n}\n\nvoid direct_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)\n{\n    /* add the code */\n}\n\nvoid solve_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)\n{\n    /* add the code */\n}\n#endif\n\n#ifdef ITERATIVE_SOLVER\n#ifdef MPI_USE\n#define HYPRE_CALL(call) do { \\\n    HYPRE_Int code = (call); \\\n    if (code) { \\\n        fprintf(stderr, "%s failed: HYPRE error %d\\n", #call, (int)code); \\\n        MPI_Abort(input->comm, code); \\\n    } \\\n} while (0)\n\nvoid analyse(struct MySolver* solver, const struct SC26_SolverInput* input)\n{\n    double started = MPI_Wtime();\n    HYPRE_CALL(HYPRE_Initialize());\n#ifdef HYPRE_USING_HIP\n    HYPRE_CALL(HYPRE_SetMemoryLocation(HYPRE_MEMORY_HOST));\n    HYPRE_CALL(HYPRE_DeviceInitialize());\n    HYPRE_CALL(HYPRE_PrintDeviceInfo());\n    HYPRE_CALL(HYPRE_MemoryPrintUsage(input->comm, 1, "T2_HIP_ANALYSE", -1));\n#endif\n    solver->tolerance = 1e-7;\n    const char *setting = getenv("SC26_RTOL");\n    if (setting) {\n        char *end;\n        solver->tolerance = strtod(setting, &end);\n        if (*end || !(solver->tolerance > 0 && solver->tolerance < 1)) {\n            fprintf(stderr, "SC26_RTOL must be a number between 0 and 1\\n");\n            MPI_Abort(input->comm, 1);\n        }\n    }\n    solver->rows = malloc((size_t)input->local_n * sizeof(*solver->rows));\n    solver->row_sizes = malloc((size_t)input->local_n * sizeof(*solver->row_sizes));\n    if (input->local_n && (!solver->rows || !solver->row_sizes))\n        MPI_Abort(input->comm, 1);\n    for (int i = 0; i < input->local_n; ++i) {\n        solver->rows[i] = input->row_begin + i;\n        solver->row_sizes[i] = input->row_ptr[i + 1] - input->row_ptr[i];\n    }\n    HYPRE_BigInt lower = input->row_begin;\n    HYPRE_BigInt upper = lower + input->local_n - 1;\n    HYPRE_CALL(HYPRE_IJMatrixCreate(input->comm, lower, upper, lower, upper, &solver->matrix));\n    HYPRE_CALL(HYPRE_IJMatrixSetObjectType(solver->matrix, HYPRE_PARCSR));\n    HYPRE_CALL(HYPRE_IJMatrixSetRowSizes(solver->matrix, solver->row_sizes));\n    solver->analyse_seconds = MPI_Wtime() - started;\n}\n\nvoid preprocess(struct MySolver* solver, const struct SC26_SolverInput* input)\n{\n    double started = MPI_Wtime();\n    HYPRE_BigInt lower = input->row_begin;\n    HYPRE_BigInt upper = lower + input->local_n - 1;\n    HYPRE_CALL(HYPRE_IJMatrixInitialize(solver->matrix));\n    HYPRE_CALL(HYPRE_IJMatrixSetValues(solver->matrix, input->local_n,\n        solver->row_sizes, solver->rows, input->col_idx, input->val));\n    HYPRE_CALL(HYPRE_IJMatrixAssemble(solver->matrix));\n    HYPRE_CALL(HYPRE_IJVectorCreate(input->comm, lower, upper, &solver->rhs));\n    HYPRE_CALL(HYPRE_IJVectorSetObjectType(solver->rhs, HYPRE_PARCSR));\n    HYPRE_CALL(HYPRE_IJVectorInitialize(solver->rhs));\n    const char *project_constant = getenv("SC26_PROJECT_CONSTANT");\n    double *projected_rhs = NULL;\n    if (!project_constant || atoi(project_constant)) {\n        long double local_sum = 0, global_sum;\n        for (int i = 0; i < input->local_n; ++i) local_sum += (long double)input->b[i];\n        MPI_Allreduce(&local_sum, &global_sum, 1, MPI_LONG_DOUBLE, MPI_SUM, input->comm);\n        long double mean = global_sum / input->global_n;\n        projected_rhs = malloc((size_t)input->local_n * sizeof(*projected_rhs));\n        if (input->local_n && !projected_rhs) MPI_Abort(input->comm, 1);\n        for (int i = 0; i < input->local_n; ++i)\n            projected_rhs[i] = (double)((long double)input->b[i] - mean);\n        if (input->row_begin == 0)\n            printf("T2_RHS_PROJECTION mean=%.18Le\\n", mean);\n    }\n    HYPRE_CALL(HYPRE_IJVectorSetValues(solver->rhs, input->local_n, solver->rows,\n        projected_rhs ? projected_rhs : input->b));\n    free(projected_rhs);\n    HYPRE_CALL(HYPRE_IJVectorAssemble(solver->rhs));\n    HYPRE_CALL(HYPRE_IJVectorCreate(input->comm, lower, upper, &solver->solution));\n    HYPRE_CALL(HYPRE_IJVectorSetObjectType(solver->solution, HYPRE_PARCSR));\n    HYPRE_CALL(HYPRE_IJVectorInitialize(solver->solution));\n    HYPRE_CALL(HYPRE_IJVectorSetValues(solver->solution, input->local_n, solver->rows, input->x));\n    HYPRE_CALL(HYPRE_IJVectorAssemble(solver->solution));\n\n#ifdef HYPRE_USING_HIP\n    double assembly_finished = MPI_Wtime();\n    HYPRE_CALL(HYPRE_IJMatrixMigrate(solver->matrix, HYPRE_MEMORY_DEVICE));\n    HYPRE_CALL(HYPRE_IJVectorMigrate(solver->rhs, HYPRE_MEMORY_DEVICE));\n    HYPRE_CALL(HYPRE_IJVectorMigrate(solver->solution, HYPRE_MEMORY_DEVICE));\n    HYPRE_CALL(HYPRE_SetMemoryLocation(HYPRE_MEMORY_DEVICE));\n    HYPRE_CALL(HYPRE_SetExecutionPolicy(HYPRE_EXEC_DEVICE));\n    double migration_finished = MPI_Wtime();\n    HYPRE_MemoryLocation location;\n    HYPRE_ExecutionPolicy policy;\n    HYPRE_CALL(HYPRE_GetMemoryLocation(&location));\n    HYPRE_CALL(HYPRE_GetExecutionPolicy(&policy));\n    printf("T2_HIP_POLICY memory_device=%d execution_device=%d\\n",\n           location == HYPRE_MEMORY_DEVICE, policy == HYPRE_EXEC_DEVICE);\n#endif\n    HYPRE_CALL(HYPRE_IJMatrixGetObject(solver->matrix, (void **)&solver->par_matrix));\n    HYPRE_CALL(HYPRE_IJVectorGetObject(solver->rhs, (void **)&solver->par_rhs));\n    HYPRE_CALL(HYPRE_IJVectorGetObject(solver->solution, (void **)&solver->par_solution));\n\n    HYPRE_CALL(HYPRE_BoomerAMGCreate(&solver->amg));\n#ifdef HYPRE_USING_HIP\n    HYPRE_CALL(HYPRE_BoomerAMGSetCoarsenType(solver->amg, 8));\n    HYPRE_CALL(HYPRE_BoomerAMGSetRAP2(solver->amg, 1));\n    HYPRE_CALL(HYPRE_BoomerAMGSetKeepTranspose(solver->amg, 1));\n    HYPRE_CALL(HYPRE_BoomerAMGSetRelaxType(solver->amg, 18));\n#else\n    HYPRE_CALL(HYPRE_BoomerAMGSetCoarsenType(solver->amg, 10));\n    HYPRE_CALL(HYPRE_BoomerAMGSetRelaxType(solver->amg, 6));\n#endif\n#ifdef HYPRE_USING_HIP\n    HYPRE_CALL(HYPRE_BoomerAMGSetInterpType(solver->amg, 18));\n#else\n    HYPRE_CALL(HYPRE_BoomerAMGSetInterpType(solver->amg, 6));\n#endif\n    HYPRE_CALL(HYPRE_BoomerAMGSetPMaxElmts(solver->amg, 4));\n    HYPRE_CALL(HYPRE_BoomerAMGSetStrongThreshold(solver->amg, 0.25));\n    /* Pressure has a constant nullspace; keep the coarse solve iterative. */\n    HYPRE_CALL(HYPRE_BoomerAMGSetCycleRelaxType(solver->amg, 6, 3));\n    HYPRE_CALL(HYPRE_BoomerAMGSetNumSweeps(solver->amg, 1));\n    HYPRE_CALL(HYPRE_BoomerAMGSetTol(solver->amg, 0));\n    HYPRE_CALL(HYPRE_BoomerAMGSetMaxIter(solver->amg, 1));\n    HYPRE_CALL(HYPRE_ParCSRGMRESCreate(input->comm, &solver->gmres));\n    HYPRE_CALL(HYPRE_ParCSRGMRESSetKDim(solver->gmres, 50));\n    HYPRE_CALL(HYPRE_ParCSRGMRESSetMaxIter(solver->gmres, 1000));\n    HYPRE_CALL(HYPRE_ParCSRGMRESSetTol(solver->gmres, solver->tolerance));\n    HYPRE_CALL(HYPRE_ParCSRGMRESSetAbsoluteTol(solver->gmres, 0));\n    HYPRE_CALL(HYPRE_ParCSRGMRESSetLogging(solver->gmres, 1));\n    HYPRE_CALL(HYPRE_ParCSRGMRESSetPrintLevel(solver->gmres, 2));\n    HYPRE_CALL(HYPRE_ParCSRGMRESSetPrecond(solver->gmres,\n        HYPRE_BoomerAMGSolve, HYPRE_BoomerAMGSetup, solver->amg));\n    HYPRE_CALL(HYPRE_ParCSRGMRESSetup(solver->gmres,\n        solver->par_matrix, solver->par_rhs, solver->par_solution));\n#ifdef HYPRE_USING_HIP\n    HYPRE_CALL(HYPRE_MemoryPrintUsage(input->comm, 1, "T2_HIP_SETUP", -1));\n    printf("T2_PREP_CALL_SECONDS assembly=%.9f migration_policy=%.9f gmres_amg_setup=%.9f\\n",\n           assembly_finished - started, migration_finished - assembly_finished,\n           MPI_Wtime() - migration_finished);\n#endif\n    solver->preprocess_seconds = MPI_Wtime() - started;\n}\n\nvoid iterative_solver(struct MySolver* solver, const struct SC26_SolverInput* input)\n{\n    double started = MPI_Wtime();\n    HYPRE_CALL(HYPRE_ParCSRGMRESSolve(solver->gmres,\n        solver->par_matrix, solver->par_rhs, solver->par_solution));\n#ifdef HYPRE_USING_HIP\n    HYPRE_CALL(HYPRE_MemoryPrintUsage(input->comm, 1, "T2_HIP_SOLVE", -1));\n    HYPRE_CALL(HYPRE_IJVectorMigrate(solver->solution, HYPRE_MEMORY_HOST));\n#endif\n    HYPRE_CALL(HYPRE_IJVectorGetValues(solver->solution, input->local_n, solver->rows, input->x));\n    HYPRE_Int iterations;\n    HYPRE_Real residual;\n    HYPRE_CALL(HYPRE_ParCSRGMRESGetNumIterations(solver->gmres, &iterations));\n    HYPRE_CALL(HYPRE_ParCSRGMRESGetFinalRelativeResidualNorm(solver->gmres, &residual));\n    if (!isfinite(residual) || residual > solver->tolerance) {\n        fprintf(stderr, "T2 GMRES did not converge: residual=%.12e tolerance=%.12e\\n",\n                residual, solver->tolerance);\n        MPI_Abort(input->comm, 1);\n    }\n    HYPRE_CALL(HYPRE_ParCSRGMRESDestroy(solver->gmres));\n    HYPRE_CALL(HYPRE_BoomerAMGDestroy(solver->amg));\n    HYPRE_CALL(HYPRE_IJMatrixDestroy(solver->matrix));\n    HYPRE_CALL(HYPRE_IJVectorDestroy(solver->rhs));\n    HYPRE_CALL(HYPRE_IJVectorDestroy(solver->solution));\n    free(solver->rows);\n    free(solver->row_sizes);\n    HYPRE_CALL(HYPRE_Finalize());\n    double times[3] = {solver->analyse_seconds, solver->preprocess_seconds, MPI_Wtime() - started};\n    double maximum[3];\n    MPI_Reduce(times, maximum, 3, MPI_DOUBLE, MPI_MAX, 0, input->comm);\n    int rank;\n    MPI_Comm_rank(input->comm, &rank);\n    if (rank == 0) {\n        printf("T2_GMRES iterations=%d relative_residual=%.12e rtol=%.1e\\n",\n               (int)iterations, residual, solver->tolerance);\n        printf("T2_PHASE_SECONDS analyse=%.6f preprocess=%.6f solve_cleanup=%.6f\\n",\n               maximum[0], maximum[1], maximum[2]);\n        fflush(stdout);\n    }\n}\n#else\nvoid analyse(struct MySolver* solver, const struct SC26_SolverInput* input)\n{\n    (void)solver; (void)input;\n    fprintf(stderr, "T2 HYPRE baseline requires the MPI_iterative_solver target\\n");\n    exit(EXIT_FAILURE);\n}\nvoid preprocess(struct MySolver* solver, const struct SC26_SolverInput* input)\n{\n    (void)solver; (void)input;\n}\nvoid iterative_solver(struct MySolver* solver, const struct SC26_SolverInput* input)\n{\n    (void)solver; (void)input;\n}\n#endif\n\nvoid analyse_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)\n{\n    (void)solver; (void)input;\n    fprintf(stderr, "T2 HYPRE baseline supports real systems only\\n");\n    exit(EXIT_FAILURE);\n}\n\nvoid preprocess_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)\n{\n    /* add the code */\n}\n\nvoid iterative_solver_complex(struct MySolver_complex* solver, const struct SC26_SolverInput* input)\n{\n    /* add the code */\n}\n#endif\n'
driver=b'/*\r\n * This is the reference MPI iterative method solver code of SolverChallenge26\r\n */\r\n\r\n// system file\r\n#include <math.h>\r\n#include <stdio.h>\r\n#include <stdlib.h>\r\n#include <string.h>\r\n#include <sys/resource.h>\r\n#include <sys/time.h>\r\n\r\n#include "mpi.h"\n\n#include "solverchallenge26/diagnostics.h"\n#include "solverchallenge26/mpi_system_loader.h"\n#include "solverchallenge26/solver_api.h"\n\r\nint main(int argc, char** argv)\n{\r\n\r\n    int     m, n, nnzA, isSymmetricA;\r\n    int*    row_ptr = NULL;         // the csr row pointer array of matrix A\r\n    int*    col_idx = NULL;         // the csr column index array of matrix A\r\n    double* val     = NULL;         // the csr value array of matrix A (real number)\r\n    double* val_im  = NULL;         // the csr value array of matrix A (imaginary number)\r\n    double *x = NULL, *x_im = NULL; // solution vector x, (x: real number, x_im: imaginary number)\n    double *b = NULL, *b_im = NULL; // right-hand side vector b, (b: real number, b_im: imaginary number)\n    double  tt, time;\n    int local_n, row_begin;\n    struct MPI_LocalSystem local_system;\n    int *gather_counts = NULL, *gather_displs = NULL;\n    double *x_global = NULL, *x_global_im = NULL;\n\r\n    char* filename_matrix;       // the filename of matrix A\r\n    char* filename_b;            // the filename of right-hand side vector b\r\n    int   read_matrix_base = 1;  // 0-base or 1-base, default 1-base\r\n    int   test_frequency   = 5; // run code frequency\n    int   sys_type         = 0;  // type of algebraic systems, 0: real, 1: complex; default 0\r\n\r\n    int myrank, size;\r\n    MPI_Init(&argc, &argv);\r\n    MPI_Comm_rank(MPI_COMM_WORLD, &myrank);\r\n    MPI_Comm_size(MPI_COMM_WORLD, &size);\r\n\r\n    /* ========================================== */\r\n    // Step 0: Read command line argument\r\n    /* ========================================== */\r\n    if (argc < 3 || argc > 5) {\n        if (myrank == 0) print_help();\n        MPI_Finalize();\n        return -1;\n    }\n    filename_matrix = argv[1];\n    filename_b = argv[2];\n    if (argc >= 4) {\n        filename_matrix  = argv[1];\n        filename_b       = argv[2];\n        read_matrix_base = atoi(argv[3]);\r\n\r\n        if (!((read_matrix_base == 0) || (read_matrix_base == 1))) {\r\n            if (myrank == 0) {\r\n                fprintf(stdout, "read_base error input %d\\n", read_matrix_base);\r\n                print_help();\r\n            }\r\n            MPI_Finalize();\r\n            return -1;\r\n        }\r\n    }\n    if (argc == 5) {\n        sys_type = atoi(argv[4]);\n        if (sys_type > 1 || sys_type < 0) {\n            if (myrank == 0) {\r\n                fprintf(stdout, "sys_type error input %d\\n", sys_type);\r\n                print_help();\r\n            }\r\n            MPI_Finalize();\r\n            return -1;\r\n        }\r\n    }\n\r\n    //! If the user does not specify parameter sys_type,\r\n    //! it will automatically determine whether it is a real system or a complex system\r\n    if (argc < 5) {\n        if (detect_sys_type_from_matrix(filename_matrix, &sys_type) != 0) {\r\n            if (myrank == 0) fprintf(stdout, "Failed to detect system type from %s\\n", filename_matrix);\r\n            MPI_Finalize();\r\n            return -1;\r\n        }\r\n    }\r\n\r\n    if (myrank == 0)\r\n        fprintf(stdout, "matrix name :      %s\\nvectorb name :     %s\\nread function :    %s\\nsys_type :         %d\\n",\n                filename_matrix, filename_b, file_is_petsc_matrix(filename_matrix) ? "PETSc binary (0-base)" : (read_matrix_base ? "MTX base-1" : "MTX base-0"),\n                sys_type);\n\r\n    /* ========================================== */\n    // Step 1: Load matrix and rhs (PETSc binary by default)\n    /* ========================================== */\n    if (mpi_load_local_linear_system(filename_matrix, filename_b, read_matrix_base, sys_type,\n                                     MPI_COMM_WORLD, &local_system) != 0) {\n        MPI_Finalize();\n        return -1;\n    }\n    m = local_system.global_rows;\n    n = local_system.global_cols;\n    nnzA = local_system.global_nnz;\n    row_begin = local_system.row_begin;\n    local_n = local_system.row_end - local_system.row_begin;\n    row_ptr = local_system.row_ptr;\n    col_idx = local_system.col_idx;\n    val = local_system.val;\n    val_im = local_system.val_im;\n    b = local_system.b;\n    b_im = local_system.b_im;\n    x = local_n ? (double*)calloc((size_t)local_n, sizeof(double)) : NULL;\n    int allocation_status = local_n && !x ? -1 : 0;\n    if (sys_type) {\n        x_im = local_n ? (double*)calloc((size_t)local_n, sizeof(double)) : NULL;\n        if (local_n && !x_im) allocation_status = -1;\n    }\n    int global_allocation_status = 0;\n    MPI_Allreduce(&allocation_status, &global_allocation_status, 1, MPI_INT, MPI_MIN, MPI_COMM_WORLD);\n    if (global_allocation_status) {\n        free(x);\n        free(x_im);\n        mpi_local_system_free(&local_system);\n        MPI_Finalize();\n        return -1;\n    }\n\n    struct SC26_SolverInput solver_input = {\n        .global_n = n,\n        .local_n = local_n,\n        .row_begin = row_begin,\n        .row_ptr = row_ptr,\n        .col_idx = col_idx,\n        .val = val,\n        .val_im = val_im,\n        .x = x,\n        .x_im = x_im,\n        .b = b,\n        .b_im = b_im,\n        .comm = MPI_COMM_WORLD\n    };\n\r\n    /* ========================================== */\r\n    // Step 2: Solve the linear system\r\n    /* ========================================== */\r\n    double round_seconds[test_frequency], round_maximum[test_frequency];\n    MPI_Barrier(MPI_COMM_WORLD);\n    tt = MPI_Wtime();\n    if (sys_type == 0) {\n        struct MySolver mysolver;\n        for (int i = 0; i < test_frequency; i++) {\n            double round_started = MPI_Wtime();\n            if (local_n) memset(x, 0, sizeof(*x) * (size_t)local_n);\n            analyse(&mysolver, &solver_input);\n            preprocess(&mysolver, &solver_input);\n            iterative_solver(&mysolver, &solver_input);\n            MPI_Barrier(MPI_COMM_WORLD);\n            round_seconds[i] = MPI_Wtime() - round_started;\n        }\n    } else {\n        struct MySolver_complex mysolver;\n        for (int i = 0; i < test_frequency; i++) {\n            double round_started = MPI_Wtime();\n            if (local_n) {\n                memset(x, 0, sizeof(*x) * (size_t)local_n);\n                memset(x_im, 0, sizeof(*x_im) * (size_t)local_n);\n            }\n            analyse_complex(&mysolver, &solver_input);\n            preprocess_complex(&mysolver, &solver_input);\n            iterative_solver_complex(&mysolver, &solver_input);\n            MPI_Barrier(MPI_COMM_WORLD);\n            round_seconds[i] = MPI_Wtime() - round_started;\n        }\n    }\n    {\n        double local_time = (MPI_Wtime() - tt) / (double)test_frequency;\n        MPI_Reduce(&local_time, &time, 1, MPI_DOUBLE, MPI_MAX, 0,\n                   MPI_COMM_WORLD);\n    }\n    MPI_Reduce(round_seconds, round_maximum, test_frequency, MPI_DOUBLE,\n               MPI_MAX, 0, MPI_COMM_WORLD);\n    if (myrank == 0)\n        for (int i = 0; i < test_frequency; ++i)\n            printf("CHECK round %d time : %.9f s\\n", i + 1, round_maximum[i]);\n\r\n    /* ========================================== */\r\n    // Step 3: Check time, memory and correctness\n    /* ========================================== */\r\n    // check the memory\r\n    mem_usage();\n\n    gather_counts = (int*)malloc((size_t)size * sizeof(*gather_counts));\n    gather_displs = (int*)malloc((size_t)size * sizeof(*gather_displs));\n    int gather_array_status = (!gather_counts || !gather_displs) ? -1 : 0;\n    int global_gather_array_status = 0;\n    MPI_Allreduce(&gather_array_status, &global_gather_array_status, 1, MPI_INT, MPI_MIN, MPI_COMM_WORLD);\n    if (global_gather_array_status) {\n        if (myrank == 0) fprintf(stdout, "MPI solution gather allocation failed.\\n");\n        free(gather_counts);\n        free(gather_displs);\n        free(x);\n        free(x_im);\n        mpi_local_system_free(&local_system);\n        MPI_Finalize();\n        return -1;\n    }\n    mpi_row_counts(n, size, gather_counts, gather_displs);\n    int gather_status = 0;\n    if (myrank == 0) {\n        x_global = (double*)malloc(sizeof(double) * (size_t)n);\n        if (sys_type) x_global_im = (double*)malloc(sizeof(double) * (size_t)n);\n        if (!x_global || (sys_type && !x_global_im)) gather_status = -1;\n    }\n    MPI_Bcast(&gather_status, 1, MPI_INT, 0, MPI_COMM_WORLD);\n    if (gather_status) {\n        free(x_global);\n        free(x_global_im);\n        free(x);\n        free(x_im);\n        mpi_local_system_free(&local_system);\n        free(gather_counts);\n        free(gather_displs);\n        MPI_Finalize();\n        return -1;\n    }\n    MPI_Gatherv(x, local_n, MPI_DOUBLE, x_global, gather_counts, gather_displs,\n                MPI_DOUBLE, 0, MPI_COMM_WORLD);\n    if (sys_type)\n        MPI_Gatherv(x_im, local_n, MPI_DOUBLE, x_global_im, gather_counts, gather_displs,\n                    MPI_DOUBLE, 0, MPI_COMM_WORLD);\n    free(x);\n    free(x_im);\n    x = NULL;\n    x_im = NULL;\n    mpi_local_system_free(&local_system);\n    row_ptr = NULL;\n    col_idx = NULL;\n    val = NULL;\n    val_im = NULL;\n    b = NULL;\n    b_im = NULL;\n    free(gather_counts);\n    free(gather_displs);\n\n    /* Re-read the complete system only on rank 0 for the final residual check. */\n    int reload_status = 0;\n    if (myrank == 0) {\n        reload_status = load_linear_system(filename_matrix, filename_b, read_matrix_base, sys_type,\n                                           &m, &n, &nnzA, &isSymmetricA, &row_ptr, &col_idx,\n                                           &val, &val_im, &b, &b_im);\n        if (reload_status == 0 && m != n) reload_status = -1;\n    }\n    MPI_Bcast(&reload_status, 1, MPI_INT, 0, MPI_COMM_WORLD);\n\n    if (myrank == 0) {\n\r\n        fprintf(stdout, "------------------------------------------\\n");\r\n\r\n        // check the memory\r\n        // mem_usage();\r\n\r\n        // check time\r\n        fprintf(stdout, "CHECK end to end time :         %12.6lf s\\n", time);\n\r\n        // store x to a file\n        char* answer_x = "answer_x.rhs";\n        if (sys_type == 0) // real rhs\n            store_x(n, x_global, answer_x);\n        else // complex rhs\n            store_x_complex(n, x_global, x_global_im, answer_x);\n\n        // check the correctness\n        if (reload_status != 0) {\n            fprintf(stdout, "Final full-system reload failed; residual check skipped.\\n");\n        } else if (sys_type == 0) // real system\n        {\n            // 1) using double precision\n            check_correctness(n, row_ptr, col_idx, val, x_global, b);\n            // 2) using long double precision\n            check_correctness_ld_d2ld(n, row_ptr, col_idx, val, x_global, b);\n#ifndef SC26_DISABLE_FLOAT128\n            // 3) using float128 precision\n            check_correctness_q_d2q(n, row_ptr, col_idx, val, x_global, b);\n#endif\n\n        } else { // complex system\n            // 1) using double precision\n            check_correctness_complex(n, row_ptr, col_idx, val, val_im, x_global, x_global_im, b, b_im);\n            // 2) using long double precision\n            check_correctness_complex_ld_d2ld(n, row_ptr, col_idx, val, val_im, x_global, x_global_im, b, b_im);\n#ifndef SC26_DISABLE_FLOAT128\n            // 3) using float128 precision\n            check_correctness_complex_q_d2q(n, row_ptr, col_idx, val, val_im, x_global, x_global_im, b, b_im);\n#endif\n\n        }\n        free(val_im);\n        free(b_im);\n        free(x_global);\n        free(x_global_im);\n        free(row_ptr);\n        free(col_idx);\n        free(val);\n        free(b);\n    }\n\r\n    MPI_Finalize();\r\n    return 0;\r\n}\r\n'
source=base
if variant=='exact':
 before=b'    HYPRE_CALL(HYPRE_IJMatrixSetRowSizes(solver->matrix, solver->row_sizes));'
 assert base.count(before)==1
 source=base.replace(before,b'#ifdef HYPRE_USING_HIP\n    HYPRE_Int *diag_sizes = malloc((size_t)input->local_n * sizeof(*diag_sizes));\n    HYPRE_Int *offdiag_sizes = malloc((size_t)input->local_n * sizeof(*offdiag_sizes));\n    if (input->local_n && (!diag_sizes || !offdiag_sizes)) MPI_Abort(input->comm, 1);\n    for (int i = 0; i < input->local_n; ++i) {\n        HYPRE_Int diagonal = 0;\n        for (int j = input->row_ptr[i]; j < input->row_ptr[i + 1]; ++j)\n            diagonal += input->col_idx[j] >= lower && input->col_idx[j] <= upper;\n        diag_sizes[i] = diagonal;\n        offdiag_sizes[i] = solver->row_sizes[i] - diagonal;\n    }\n    HYPRE_CALL(HYPRE_IJMatrixSetDiagOffdSizes(solver->matrix, diag_sizes, offdiag_sizes));\n    free(diag_sizes);\n    free(offdiag_sizes);\n#else\n    HYPRE_CALL(HYPRE_IJMatrixSetRowSizes(solver->matrix, solver->row_sizes));\n#endif')
expected=json.loads('{"baseline":{"solver_sha256":"c41653a15933fbda399aa305a6010a991fd2d7548edf27987ba35a20783639de","driver_sha256":"34f19d4985ded7685eeca2f1f07e6dfec0af91c9039dba668be75a6dedf2a6d0","manifest_sha256":"2360c24e1557b8cd4869ba708631a2faaab40026792a7c7df73e09c11bb02465"},"exact":{"solver_sha256":"ea585ebaf584fa059946ba40371378a03b5404629f841e66c286eb1a8f2856f4","driver_sha256":"34f19d4985ded7685eeca2f1f07e6dfec0af91c9039dba668be75a6dedf2a6d0","manifest_sha256":"edcbf44abeee448a736cc01bfe16ac58a052a74e44a132a2d67a2f35e0080d6b"}}')[variant]
assert hashlib.sha256(source).hexdigest()==expected['solver_sha256']
assert hashlib.sha256(driver).hexdigest()==expected['driver_sha256']
Path('src/problems/problem02/solver.c').write_bytes(source)
Path('src/apps/MPI_iterative_solver.c').write_bytes(driver)
lines=[]
for line in Path('source-sha256.txt').read_text().splitlines():
 _,name=line.split('  ',1);lines.append(hashlib.sha256(Path(name).read_bytes()).hexdigest()+'  '+name)
manifest=('\n'.join(lines)+'\n').encode()
assert hashlib.sha256(manifest).hexdigest()==expected['manifest_sha256']
Path('source-sha256.txt').write_bytes(manifest)
Path('parent-commit.txt').write_text('d09163c18ce629d65d55c0e6316b9755b7e2975d\n')
print('SOURCE_VARIANT='+variant)

PATCH_SOURCE
    sha256sum -c source-sha256.txt
    sha256sum source-sha256.txt src/problems/problem02/solver.c src/apps/MPI_iterative_solver.c
cmake -S src -B build -DCMAKE_BUILD_TYPE=Release \
 -DSC26_PROBLEM=02 -DSC26_T2_HIP=ON -DSC26_BUILD_MPI=ON \
 -DSC26_BUILD_MPI_GPU=OFF -DSC26_ENABLE_FLOAT128=ON \
 -DCMAKE_C_COMPILER="$mpi_prefix/bin/mpicc" \
 -DCMAKE_CXX_COMPILER="$dtk_root/llvm/bin/clang++" \
 -DCMAKE_HIP_COMPILER="$dtk_root/llvm/bin/clang++" \
 -DCMAKE_HIP_COMPILER_ROCM_ROOT="$dtk_root/hip" \
 -DCMAKE_HIP_ARCHITECTURES=gfx936 \
 -DCMAKE_HIP_FLAGS="--gpu-max-threads-per-block=1024" \
 -DCMAKE_EXE_LINKER_FLAGS="-L$dtk_root/llvm/lib/clang/17.0.0/lib/linux" \
 -DHYPRE_DIR="$work/install-892588/lib/cmake/HYPRE" \
 -DROCM_PATH="$dtk_root/hip" -Dhip_DIR="$dtk_root/hip/lib/cmake/hip" \
 -Drocblas_DIR="$dtk_root/lib/cmake/rocblas" \
 -Drocsparse_DIR="$dtk_root/lib/cmake/rocsparse" \
 -Drocrand_DIR="$dtk_root/lib/cmake/rocrand" >configure.log 2>&1 \
 || { status=$?; tail -n 35 configure.log >&2; exit "$status"; }
cmake --build build --parallel "$SLURM_CPUS_PER_TASK" --target MPI_iterative_solver >build.log 2>&1 \
 || { status=$?; tail -n 35 build.log >&2; exit "$status"; }
sha256sum build/CMakeCache.txt build/bin/MPI_iterative_solver
ldd build/bin/MPI_iterative_solver

    sha256sum build/bin/MPI_iterative_solver build/CMakeCache.txt
    python3 tests/make_small_systems.py
    source_dir="$candidate"
    for sample in poisson nonsymmetric neumann; do
        export SC26_RTOL=1e-11 SC26_PROJECT_CONSTANT=0
        args=(solver.log 1e-10 answer_x.rhs "$source_dir/tests/small_systems/${sample}_x.txt")
        if [[ "$sample" == neumann ]]; then export SC26_PROJECT_CONSTANT=1; args+=(constant-nullspace); fi
        mkdir -p "$run/$variant/small/$sample"
        cd "$run/$variant/small/$sample"
        status=0
        /usr/bin/time -v -o process.time "$source_dir/build/bin/MPI_iterative_solver" \
          "$source_dir/tests/small_systems/${sample}_A.dat" "$source_dir/tests/small_systems/${sample}_b.dat" 0 0 >solver.log 2>solver.err || status=$?
        printf '%s\n' "$status" >process.exit
        test "$status" -eq 0
        test ! -s solver.err
        test "$(grep -c '^T2_HIP_POLICY memory_device=1 execution_device=1$' solver.log)" -eq 5
        test "$(grep -c '^T2_PREP_CALL_SECONDS ' solver.log)" -eq 5
        test "$(grep -c '^CHECK round ' solver.log)" -eq 5
        python3 "$source_dir/tests/check_result.py" "${args[@]}"
    done
    run_full "$source_dir" "$run/$variant/full/screen"
done
python3 - "$run" <<'CHOOSE_WINNER'
from pathlib import Path
import json,re,sys
root=Path(sys.argv[1]);means={}
for variant in ('baseline','exact'):
 log=(root/variant/'full/screen/solver.log').read_text()
 means[variant]=float(re.search(r'CHECK end to end time\s*:\s*(\S+) s',log)[1])
winner=min(means,key=means.get)
(root/'winner.txt').write_text(winner+'\n')
(root/'screening-means.json').write_text(json.dumps({'means':means,'fastest_screened_variant':winner},indent=2)+'\n')
print('FASTEST_SCREENED_VARIANT='+winner)
CHOOSE_WINNER
run_full "$run/baseline/source" "$run/baseline/full/repeat"
winner=$(cat "$run/winner.txt")
run_full "$run/$winner/source" "$run/$winner/full/repeat-1"
run_full "$run/$winner/source" "$run/$winner/full/repeat-2"
printf 'SC26_EXACT_PREALLOCATION_COMPLETE\n'
