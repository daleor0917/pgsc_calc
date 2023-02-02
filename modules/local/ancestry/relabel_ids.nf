process RELABEL_IDS {
    // labels are defined in conf/modules.config
    label 'process_low'
    label 'pgscatalog_utils' // controls conda, docker, + singularity options

    conda (params.enable_conda ? "${task.ext.conda}" : null)

    container "${ workflow.containerEngine == 'singularity' &&
        !task.ext.singularity_pull_docker_container ?
        "${task.ext.singularity}${task.ext.singularity_version}" :
        "${task.ext.docker}${task.ext.docker_version}" }"

    input:
    tuple val(meta), path(matched), path(target)

    output:
    tuple val(meta), path("*.var")
    path "versions.yml", emit: versions

    script:
    """
    relabel_ids.py --maps <(zcat $matched) \
        --col_from ID_REF \
        --col_to ID_TARGET \
        --target_file $target \
        --target_col ID \
        --out ${meta.id}_${target.getExtension()}

    # todo: compress output

    cat <<-END_VERSIONS > versions.yml
    ${task.process.tokenize(':').last()}:
        pgscatalog_utils: \$(echo \$(python -c 'import pgscatalog_utils; print(pgscatalog_utils.__version__)'))
    END_VERSIONS
    """
}
