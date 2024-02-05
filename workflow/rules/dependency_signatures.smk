checkpoint dependencies_annotate_crispr_data:
    input:
        crispr_gene_dependency_chronos=datasets.loc[
            "crispr_gene_dependency_chronos", "directory"
        ],
        sample_info=rules.annotate_cell_lines.output.cell_lines_annotation,
        expression_matrix=rules.get_rnaseq_counts.output.raw_gene_counts,
    output:
        model_candidates=directory(f"{results}/dependencies/model_candidates"),
    threads: get_resource("annotate_cell_lines", "threads"),
    resources:
        mem_mb=get_resource("annotate_cell_lines", "mem_mb"),
        runtime=get_resource("annotate_cell_lines", "runtime"),
    conda:
        "../envs/common_file_manipulation.yaml"
    script:
        "../scripts/dependencies_annotate_dependencies.R"


rule dependencies_generate_ebayes:
    input:
        raw_gene_counts=rules.get_rnaseq_counts.output.raw_gene_counts,
        dependency_to_test=f"{results}/dependencies/model_candidates/{{gene}}.csv",
    output:
        ebayes=f"{results}/dependencies/ebayes/{{gene}}_eBayes.rds",
    log:
        f"{LOGDIR}/dependencies_ebayes/{{gene}}.log",
    threads: get_resource("default", "threads"),
    resources:
        mem_mb=get_resource("default", "mem_mb"),
        runtime=get_resource("default", "runtime"),
    conda:
        "../envs/prism_limma.yaml"
    script:
        "../scripts/dependencies_generate_ebayes_model.R"


rule dependencies_geneset_from_ebayes:
    input:
        fitted_bayes=rules.dependencies_generate_ebayes.output.ebayes,
    output:
        bidirectional_geneset=directory(f"{results}/dependencies/genesets/{{gene}}"),
    log:
        f"{LOGDIR}/dependencies_geneset/{{gene}}.log",
    threads: get_resource("ctrp_generate_geneset", "threads"),
    resources:
        mem_mb=get_resource("ctrp_generate_geneset", "mem_mb"),
        runtime=get_resource("ctrp_generate_geneset", "runtime"),
    conda:
        "../envs/generate_genesets.yaml"
    script:
        "../scripts/dependency_signature_from_ebayes.R"
