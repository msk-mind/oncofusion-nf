params.endpoint_url = "https://tlvimskmindvm1/dsa/api/v1"
params.collection_name = "wac"


process DSA_UPLOAD {
    secret 'DSA_USERNAME'
    secret 'DSA_PASSWORD'

    input:
    tuple val(slide_id), path(dsa_json)

    script:
    """
    dsa_upload \
        --dsa_endpoint_url $params.endpoint_url \
        --annotation_file_urlpath $dsa_json \
        --collection_name $params.collection_name \
        --image_filename ${slide_id}.svs
    """
}
