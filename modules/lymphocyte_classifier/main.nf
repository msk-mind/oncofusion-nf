import groovy.json.JsonBuilder

params.use_gpu = true

params.annotation_name = "lymphocyte_classifier"
params.annotation_fill_colors = [
    Other: "rgba(0,255,0,100)",
    Lymphocyte: "rgba(255,0,0,100)"
]
params.annotation_line_colors = [
    Other: "rgb(0,255,0)",
    Lymphocyte: "rgb(255,0,0)"
]

params.use_singularity = true
params.stardist_image = '/gpfs/mskmind_ess/limr/repos/workflows2/qupath-stardist_0.4.3a.sif'
params.stardist_script =  "/scripts/stardist_nuclei_and_lymphocytes.groovy"

process LUNA_STARDIST_CELL_DETECTION {
    publishDir "$params.outdir/$slide_id/stardist_cell/"
    label "${params.use_gpu? 'gpuTask' : 'cpuTask'}"
    label "bigTask"
    label "parallelTask"

    input:
    tuple val(slide_id), path(slide)

    output:
    tuple val(slide_id), path("cell_detections.geojson")

    script:
    def gpu = params.use_gpu ? "--use_gpu" : ""
    def contr = params.use_singularity ? "--use_singularity" : ""

    """
    run_stardist_cell_detection cell-lymphocyte \
        --slide_urlpath $slide \
        --output_urlpath . \
        --num_cores ${task.cpus} \
        --max_heap_size ${task.memory.bytes} \
        --image ${params.stardist_image} \
        --use_singularity \
        --use_gpu
        $contr \
        $gpu
    """
}

process STARDIST_CELL_DETECTION {
    publishDir "$params.outdir/$slide_id/stardist_cell/"
    label "qupathTask"
    label "${params.use_gpu? 'gpuTask' : 'cpuTask'}"
    label "bigTask"
    label "parallelTask"
     
    memory 36.GB

    input:
    tuple val(slide_id), path(slide)

    output:
    tuple val(slide_id), path("cell_detections.geojson"), emit: geojson
    tuple val(slide_id), path("cell_detections.tsv"), emit: tsv

    script:
    def cmd = params.use_gpu ? "QuPath-gpu" : "QuPath-cpu"
    """
    export _JAVA_OPTIONS="-XX:ActiveProcessorCount=${task.cpus} -Xmx${task.memory.bytes}"
    $cmd script --image $slide ${params.stardist_script}
    """

}


process DSA_STARDIST_POLYGON {
    label "smallTask"

    input:
    tuple val(slide_id), path(cell_detections)

    output:
    tuple val(slide_id), path("${params.annotation_name}_${slide_id}.json")

    script:
    def line_colors = "--line_colors '${new JsonBuilder(params.annotation_line_colors).toPrettyString()}'"
    def fill_colors = "--fill_colors '${new JsonBuilder(params.annotation_fill_colors).toPrettyString()}'"

    """
    dsa stardist-polygon \
        --input_urlpath $cell_detections \
        --output_urlpath . \
        --annotation_name $params.annotation_name \
        --image_filename ${slide_id}.svs \
        $line_colors \
        $fill_colors
    """
}

