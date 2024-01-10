import groovy.json.JsonBuilder

params.torch_model_repo_or_dir = "msk-mind/luna-ml"
params.model_name = "TissueTileNetTransformer"
params.batch_size = 2000
params.tile_size = 128
params.tile_magnification = 20
params.detect_tissue_thumbnail_magnification = 2
params.detect_tissue_filter_query = "otsu_score >= 0.15 and purple_score > 0.05"
params.annotation_name = "tissue_tile_net_label"
params.annotation_fill_colors = [
    Tumor: "rgb(255,0,0)",
    Stroma: "rgb(0,255,0)",
    Fat: "rgb(0,0,255)",
    Necrosis: "rgb(255,0,255)"
]
params.annotation_line_colors = [
    Tumor: "rgba(255,0,0,100)",
    Stroma: "rgba(0,255,0,100)",
    Fat: "rgba(0,0,255,100)",
    Necrosis: "rgba(255,0,255,100)"
]
params.use_gpu = true

process DETECT_TISSUE {
    publishDir "$params.outdir/$slide_id/detect_tissue/"
    label "parallelTask"
    label "bigTask"

    input:
    tuple val(slide_id), path(slide)
    
    output:
    tuple val(slide_id), path(slide), path("${slide_id}.tiles.parquet")

    script:
    def filter_query = params.detect_tissue_filter_query ? "--filter_query '$params.detect_tissue_filter_query'" : ""
    def thumbnail_mag = params.detect_tissue_thumbnail_magnification ? "--thumbnail_magnification $params.detect_tissue_thumbnail_magnification": ""
    def tile_mag = params.tile_magnification ? "--tile_magnification $params.tile_magnification": ""
    def dask_options = "{ 'n_workers': $task.cpus, 'threads_per_worker': 1 }"
    
    """
    detect_tissue \
        --slide_urlpath $slide \
        --tile_size $params.tile_size \
        --output_urlpath . \
        --batch_size $params.batch_size \
        --dask_options "$dask_options" \
        $filter_query \
        $thumbnail_mag \
        $tile_mag
    """
}

process SAVE_TILES {
    publishDir "$params.outdir/$slide_id/save_tiles/"
    label "parallelTask"
    label "bigTask"

    input:
    tuple val(slide_id), path(slide, stageAs: 'in/*'), path(tiles, stageAs: 'in/*')

    output:
    tuple val(slide_id), path("${slide_id}.tiles.parquet"), path("${slide_id}.tiles.h5")

    script:
    def dask_options = "{ 'n_workers': $task.cpus, 'threads_per_worker': 1 }"
    
    """
    save_tiles \
        --slide_urlpath $slide \
        --tiles_urlpath $tiles \
        --output_urlpath . \
        --batch_size $params.batch_size \
        --dask_options "$dask_options"
    """
}

process INFER_TILE_LABELS {
    publishDir "$params.outdir/$slide_id/infer_tiles/"
    label "${params.use_gpu? 'gpuTask' : 'cpuTask'}"
    label "parallelTask"
    label "bigTask"

    input:
    tuple val(slide_id), path(tiles, stageAs: 'in/*'), path(h5, stageAs: 'in/*')

    output:
    tuple val(slide_id), path("${slide_id}.tiles.parquet")

    script:
    def gpu = params.use_gpu ? "--use_gpu" : ""
    def dask_options = "{ 'n_workers': $task.cpus, 'threads_per_worker': 1 }"

    """
    infer_tiles \
        --tile_store_urlpath $h5 \
        --tiles_urlpath $tiles \
        --insecure \
        --output_urlpath . \
        --dask_options "$dask_options" \
        --torch_model_repo_or_dir $params.torch_model_repo_or_dir \
        --model_name $params.model_name \
        --batch_size  $params.batch_size \
        $gpu

    """

}


process DSA_HEATMAP {
    publishDir "$params.outdir/$slide_id/dsa_heatmap/"
    label "smallTask"

    input:
    tuple val(slide_id), path(tiles)

    output:
    tuple val(slide_id), path("Classification_${params.annotation_name}_${slide_id}.json")

    script:
    def line_colors = "--line_colors '${new JsonBuilder(params.annotation_line_colors).toPrettyString()}'"
    def fill_colors = "--fill_colors '${new JsonBuilder(params.annotation_fill_colors).toPrettyString()}'"

    """
    dsa heatmap \
        --column Classification \
        --input_urlpath $tiles \
        --output_urlpath . \
        --annotation_name $params.annotation_name \
        --tile_size $params.tile_size \
        --image_filename ${slide_id}.svs \
        $line_colors \
        $fill_colors
    """
}

        

