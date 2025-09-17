process beast_gpu {

    container 'community.wave.seqera.io/library/beagle-lib_beast:71d8ea6f44154912'
    publishDir "${params.outdir}/", mode: 'copy' // Publish final report to local directory specified in params.config

    label "gpu"
    // Targetting g5.2xlarge (8 CPU, 32 GB, 1 A10G) and g5.12xlarge (64 CPU, 192 GB, 4 A10G)
    accelerator 1 // further configuration should be overloaded using withLabel:gpu
    cpus 8
    memory 32.GB

    input:
        path (input_xml)
        
    output:
        path("*.txt")
        path("*.chkpt")
        
    script:
    // we can't set maxForks dynamically, but we can detect it might be wrong!
    if (task.executor != "local" && task.maxForks == 1) {
        log.warn "Non-local workflow execution detected but GPU tasks are currently configured to run in serial, perhaps you should be using '-profile discrete_gpus' to parallelise GPU tasks for better performance?"
    }
    """
    beast -beagle_GPU -beagle_SSE -threads ${task.cpus} ${input_xml}
    """
}

process beast_cpu {

    container 'community.wave.seqera.io/library/beagle-lib_beast:71d8ea6f44154912'
    publishDir "${params.outdir}/", mode: 'copy' // Publish final report to local directory specified in params.config

    cpus 8
    memory 32.GB

    input:
        path (input_xml)
        
    output:
        path("*.txt")
        path("*.chkpt")
        
    script:
    """
    beast -threads ${task.cpus} ${input_xml}
    """
}

workflow  {

    input_file = file(params.input, type: "file", checkIfExists:true)
    Channel
        .fromPath(input_file)
        .set { input_ch }

    if (params.use_gpu) {
        beast_gpu(input_ch)
    } else {
        beast_cpu(input_ch)         
    }
}
