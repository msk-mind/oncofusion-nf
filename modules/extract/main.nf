params.dremio.port = 32010
params.dremio.scheme = 'grpc+tcp'

process GET_SLIDES {
    label "localTask"

    secret 'DREMIO_PASSWORD'
    secret 'DREMIO_USERNAME'

    output:
    path "samples.csv"

    """
    #!/usr/bin/env python
    import os
    from luna.common.connectors import DremioDataframeConnector

    username = os.environ['DREMIO_USERNAME']
    password = os.environ['DREMIO_PASSWORD']

    dremioDfConnector = DremioDataframeConnector(
        "$params.dremio.scheme",
        "$params.dremio.hostname",
        $params.dremio.port,
        username,
        password
        )
    df = dremioDfConnector.get_table("$params.dremio.space", "$params.dremio.table")
    with open("samples.csv", 'w') as f:
        f.write('slide_id,path\\n')
        for image_id in df.image_id:
            f.write(f'{image_id},s3://hobbit/{image_id}.svs\\n')
    """
}

