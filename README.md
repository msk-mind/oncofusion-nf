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


