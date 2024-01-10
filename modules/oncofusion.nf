params.outdir = 'results'

include { DETECT_TISSUE; SAVE_TILES; INFER_TILE_LABELS; DSA_HEATMAP } from './infer_tiles'
include { STARDIST_CELL_DETECTION; DSA_STARDIST_POLYGON } from './lymphocyte_classifier'
include { DSA_UPLOAD } from './dsa'

params.cellular_features = "nucleus"
params.property_type = "all"
params.statistical_descriptors = "all"

process EXTRACT_TILE_SHAPE_FEATURES {
    label "bigTask"

    publishDir "$params.outdir/$slide_id/extract_tile_shape_features/"

    input:
    tuple val(slide_id), path(slide), path(tiles), path(object_geojson)

    output:
    path "shape_features.parquet"

    script:
    """
    extract_tile_shape_features \
        --slide_urlpath $slide \
        --tiles_urlpath $tiles \
        --object_urlpath $object_geojson \
        --output_urlpath . \
        --property_type $params.property_type \
        --cellular_features $params.cellular_features \
        --statistical_descriptors $params.statistical_descriptors 
    """

}

workflow ONCOFUSION {
    take:
        ch_slides

    main:
        ch_tiles = ch_slides | DETECT_TISSUE | SAVE_TILES | INFER_TILE_LABELS
        ch_cell_objects = ch_slides | STARDIST_CELL_DETECTION

        ch_tiles | DSA_HEATMAP
        ch_cell_objects.geojson | DSA_STARDIST_POLYGON

         ch_slides.join(ch_tiles).join(ch_cell_objects.geojson) | EXTRACT_TILE_SHAPE_FEATURES

    emit:
        EXTRACT_TILE_SHAPE_FEATURES.out
        
}
