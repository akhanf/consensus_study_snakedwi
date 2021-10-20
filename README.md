# dwipreproc_snakedwi
workflow for processing ISMRM Diffusion Study - Best Practices in Image Preprocessing data

Snakemake workflow to run dwi preprocessing.

Uses snakemake & snakedwi, see docs here:

https://snakemake.readthedocs.io

https://snakedwi.readthedocs.io

This workflow converts the data to bids and runs snakedwi, then prepares data for uploading the submission

Put the raw data in `../sourcedata` (can be configured with `config.yml`)

You will need to update the `--profile` option in the snakedwi command (or remove it if you are not using an execution profile).
