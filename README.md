# Oncofusion-NF pipeline

A pipeline for pathology slide analysis: tiles, detects tissue, infers tile labels, lymphocyte cell detection, and feature extraction.

## Requirements

* Unix-like operating system
* Java 11

## Quickstart

1. Install docker

2. Install nextflow:
    ```
    curl -s https://get.nextflow.io | bash
    ```

3. Launch the pipeline execution using docker
    ```
    ./nextflow run msk-mind/oncofusion-nf -profile standard,docker --samples_csv samples.csv
    ```
    `samples.csv` is a csv file where the first column is the slide ID and the second is the path to the slide.

4. When the execution completes, results will be in the `results` directory


## Azure Batch Support

1. Create an Azure storage account and batch account.

2. Modify the nextflow configuration files as necessary (see <https://www.nextflow.io/docs/edge/azure.html>)

3. Set the necessary secrets using `nextflow secrets set`. At a minimum set `AZURE_BATCH_KEY` and `AZURE_STORAGE_KEY`.

4. Launch nextflow:
    ```
    nextflow -Dcom.amazonaws.sdk.disableCertChecking=true run main.nf -bucket-dir {azure_bucket_dir} -profile docker,cloud
    ```
    where `{azure_bucket_dir}` is an azure path like `az://test/nftest`.

5. When the execution completes, results will be in the `results` directory
