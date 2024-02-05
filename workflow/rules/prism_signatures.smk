import glob

## TODO: This rule can be split in 2
checkpoint prism_annotate_models:
    input:
        response_curves=datasets.loc["prism_response_curves", "directory"],
        cell_lines_annotation=rules.annotate_cell_lines.output.cell_lines_annotation,
        count_matrix=rules.get_rnaseq_counts.output.raw_gene_counts,
    output:
        auc_models_candidates=directory(f"{results}/prism/auc_models_candidates"),
        compounds_lines_profiled=f"{results}/prism/compounds_lines_profiled.csv",
    threads: get_resource("ctrp_annotate_models", "threads"),
    resources:
        mem_mb=get_resource("ctrp_annotate_models", "mem_mb"),
        runtime=get_resource("ctrp_annotate_models", "runtime"),
    conda:
        "../envs/common_file_manipulation.yaml"
    script:
        "../scripts/prism_generate_annotation.R"


rule prism_compounds_diffexpr:
    input:
        raw_gene_counts=rules.get_rnaseq_counts.output.raw_gene_counts,
        compound_to_test=f"{results}/prism/auc_models_candidates/{{broad_id}}.csv",
    output:
        ebayes=f"{results}/prism/ebayes/{{broad_id}}_eBayes.rds",
    log:
        f"{LOGDIR}/prism_compounds_diffexpr/{{broad_id}}.log",
    threads: get_resource("gdsc_compounds_diffexp", "threads"),
    resources:
        mem_mb=get_resource("gdsc_compounds_diffexp", "mem_mb"),
        runtime=get_resource("gdsc_compounds_diffexp", "runtime"),
    conda:
        "../envs/prism_limma.yaml"
    script:
        "../scripts/prism_generate_ebayes_model.R"


##TODO: These two rules could benefit from rule inheritance
rule prism_geneset_from_ebayes_classic:
    input:
        fitted_bayes=rules.prism_compounds_diffexpr.output.ebayes,
        treatment_info=datasets.loc["prism_treatment_info", "directory"],
    output:
        bidirectional_geneset=directory(
            f"{results}/prism/genesets/classic/{{broad_id}}"
        ),
    log:
        f"{LOGDIR}/prism_geneset_from_ebayes/{{broad_id}}_classic.log",
    params:
        signature_type="classic",
    threads: get_resource("ctrp_generate_geneset", "threads"),
    resources:
        mem_mb=get_resource("ctrp_generate_geneset", "mem_mb"),
        runtime=get_resource("ctrp_generate_geneset", "runtime"),
    conda:
        "../envs/generate_genesets.yaml"
    script:
        "../scripts/prism_signature_from_ebayes.R"


rule prism_geneset_from_ebayes_fold:
    input:
        fitted_bayes=rules.prism_compounds_diffexpr.output.ebayes,
        treatment_info=datasets.loc["prism_treatment_info", "directory"],
    output:
        bidirectional_geneset=directory(f"{results}/prism/genesets/fold/{{broad_id}}"),
    log:
        f"{LOGDIR}/prism_geneset_from_ebayes/{{broad_id}}_fold.log",
    params:
        signature_type="fold",
    threads: get_resource("ctrp_generate_geneset", "threads"),
    resources:
        mem_mb=get_resource("ctrp_generate_geneset", "mem_mb"),
        runtime=get_resource("ctrp_generate_geneset", "runtime"),
    conda:
        "../envs/generate_genesets.yaml"
    script:
        "../scripts/prism_signature_from_ebayes.R"
