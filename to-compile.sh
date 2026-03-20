#!/usr/bin/env bash
# =============================================================================
# NULL MESH — LaTeX Compilation Script
# =============================================================================
# Compiles nullmesh/main.tex (or main-ITA.tex with --ITA flag) into a PDF
# using pdflatex (three passes to ensure correct TOC, cross-references and
# hyperlinks), then copies the resulting PDF to the repository root.
# A full compilation log is saved to compile.log.
#
# Usage:  ./to-compile.sh          → NULL_MESH.pdf     (English)
#         ./to-compile.sh --ITA    → NULL_MESH-ITA.pdf  (Italian)
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$REPO_ROOT/nullmesh"

# ---------------------------------------------------------------------------
# Language variant: default (English) or --ITA (Italian)
# Usage:  ./to-compile.sh          → compiles main.tex   → NULL_MESH.pdf
#         ./to-compile.sh --ITA    → compiles main-ITA.tex → NULL_MESH-ITA.pdf
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--ITA" ]]; then
    MAIN_TEX="main-ITA.tex"
    JOB_NAME="NULL_MESH-ITA"
    VARIANT="ITA"
else
    MAIN_TEX="main.tex"
    JOB_NAME="NULL_MESH"
    VARIANT="EN"
fi

LOG_FILE="$REPO_ROOT/compile.log"

# Ensure the nullmesh project directory exists
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "ERROR: Project directory not found: $PROJECT_DIR" >&2
    exit 1
fi

if [[ ! -f "$PROJECT_DIR/$MAIN_TEX" ]]; then
    echo "ERROR: Main TeX file not found: $PROJECT_DIR/$MAIN_TEX" >&2
    exit 1
fi

# Wipe previous log and start fresh
> "$LOG_FILE"

log() {
    echo "$*" | tee -a "$LOG_FILE"
}

separator() {
    log "============================================================================="
}

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
separator
log "NULL MESH — Compilation Log [$VARIANT]"
log "Date   : $(date '+%Y-%m-%d %H:%M:%S')"
log "Variant: $VARIANT"
log "Engine : $(pdflatex --version 2>&1 | head -1)"
log "Source : $PROJECT_DIR/$MAIN_TEX"
separator
log ""

# ---------------------------------------------------------------------------
# Helper: run one pdflatex pass and append its output to the log
# ---------------------------------------------------------------------------
run_pass() {
    local pass_number="$1"
    log ""
    log "--- Pass $pass_number / 3 ---"
    log ""

    # Run pdflatex from inside the project directory so that all \input{}
    # relative paths resolve correctly. The -output-directory flag keeps all
    # auxiliary files (aux, toc, out …) and the final PDF inside the project
    # folder; we copy the PDF to the repo root afterwards.
    pdflatex \
        -interaction=nonstopmode \
        -halt-on-error \
        -file-line-error \
        -jobname="$JOB_NAME" \
        -output-directory="$PROJECT_DIR" \
        "$MAIN_TEX" \
        2>&1 | tee -a "$LOG_FILE" || {
            log ""
            separator
            log "COMPILATION FAILED on pass $pass_number."
            log "Review the lines above (or $LOG_FILE) for details."
            separator
            exit 1
        }
}

# ---------------------------------------------------------------------------
# Three pdflatex passes
#   Pass 1 — first build; generates .aux, .toc, .out
#   Pass 2 — resolves forward references and TOC entries
#   Pass 3 — stabilises page numbers and hyperref bookmarks
# ---------------------------------------------------------------------------
cd "$PROJECT_DIR"

run_pass 1
run_pass 2
run_pass 3

# ---------------------------------------------------------------------------
# Copy the final PDF to the repository root
# ---------------------------------------------------------------------------
PDF_SRC="$PROJECT_DIR/$JOB_NAME.pdf"

if [[ -f "$PDF_SRC" ]]; then
    cp "$PDF_SRC" "$REPO_ROOT/$JOB_NAME.pdf"
    log ""
    separator
    log "SUCCESS — PDF written to: $REPO_ROOT/$JOB_NAME.pdf"
    separator
else
    log ""
    separator
    log "ERROR: Expected PDF not found at $PDF_SRC"
    separator
    exit 1
fi

# ---------------------------------------------------------------------------
# Summary of warnings and errors extracted from the log
# ---------------------------------------------------------------------------
log ""
log "--- Warning / Error Summary ---"
log ""

# Count warnings/errors from the last pass only (avoid triple-counting across 3 passes)
LAST_PASS_START=$(grep -n "^--- Pass 3 / 3 ---" "$LOG_FILE" | tail -1 | cut -d: -f1)
if [[ -n "$LAST_PASS_START" ]]; then
    WARNING_COUNT=$(tail -n +"$LAST_PASS_START" "$LOG_FILE" | grep -cE "^(LaTeX Warning|LaTeX Font Warning|Package .* Warning|Overfull|Underfull)" || true)
    ERROR_COUNT=$(tail -n +"$LAST_PASS_START" "$LOG_FILE" | grep -cE "^!|^.*:[0-9]+: " || true)
else
    WARNING_COUNT=$(grep -cE "^(LaTeX Warning|LaTeX Font Warning|Package .* Warning|Overfull|Underfull)" "$LOG_FILE" || true)
    ERROR_COUNT=$(grep -cE "^!|^.*:[0-9]+: " "$LOG_FILE" || true)
fi

log "Errors   : $ERROR_COUNT"
log "Warnings : $WARNING_COUNT"
log ""
log "Full log saved to: $LOG_FILE"
separator
