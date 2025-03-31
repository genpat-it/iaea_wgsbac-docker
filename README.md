# IAEA_wgsbac-docker

Docker image for the WGSBAC pipeline for *Salmonella* and *Brucella* in the context of IAEA-GenPat joint project.

## Index

- [Overview](#overview)
- [About the Project](#about-the-project)
- [Disclaimer](#disclaimer)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [How to run](#how-to-run)
- [Acknowledgement](#acknowledgement)
- [Final Notes](#final-notes)

## Overview

This repository hosts the Dockerfile, developed by GenPat's bioinformatics team, and necessary dependencies (`yml` and `envs.zip`) to build the Docker for the WGSBAC pipeline (<https://gitlab.com/FLI_Bioinfo/WGSBAC>) by Jörg Linde (@joerg.linde) and Mostafa Abdel-Glil (@Mostafa.Abdel-Glil).

- Version: 1.0.0
- Author: GenPat
- Contact: genpat@izs.it

## About the Project

In the context of the 2024-2025 IAEA-GenPat joint project, the GenPat platform ensured interoperability with the Galaxy platform, by adapting and transfering bioinformatics workflows. This repository hosts the development results of the migration and adaptation of the bacterial workflows (for *Brucella* and *Salmonella*), from the contact of the Friedrich-Loeffler-Institut (Jörg Linde: Joerg.Linde@fli.de).

The developed dockerized version of the original software (`wgsbac.pl`) was used for deployment of the analyses for the 2 organisms of interest on the GenPat platform.

- GenPat platform: <https://genpat.izs.it>
- Galaxy platform: <https://usegalaxy.org>

## Disclaimer

The code in this repo has been developed uniquely for the needs of the GenPat platform, and published here to share it with the open source community and the authors, and in accordance with the original authors' [MIT license](./LICENSE).

Only commands and tools of interest were tested, and some adaptations were added to allow integration of the pipeline into the GenPat platform, for IAEA users. 

As such, the Dockerfile's code in this repository is provided "as is", without warranty of any kind, express or implied, including but not limited to fitness for a particular purpose. 


## Features

The dockerized WGSBAC pipeline runs a suite of tools that can be subdivided into:

- Reads Quality Check (QC) and trimming
- Sequence reconstruction
- Assembly QC and contamination check
- Genome annotation
- Typing

The list of analyses run for *Brucella* and *Salmonella* species and the tools used are available on the official WGSBAC software's GitLab page: <https://gitlab.com/FLI_Bioinfo/WGSBAC#modules>. The list of analises available in this dockerized version are listed in the tables below.

- For execution on *Brucella* samples:

| Analysis | Tool/DB |
| --- | --- |
| contamination check | `confindr` |
| coverage calculation | custom script |
| trimming and QC | `fastp` |
| raw reads quality check | `fastqc` |
| contamination check | `kraken2` |
| Multi Lucus Sequence Typing | `mlst` |
| QC | `multiQC`, `fastQC` |
| plasmid identification | `plasmidfinder`/`platon` |
| assembly QC | Quast |
| de novo assembly | Shovill |
| variant calling | Snippy |
| species identification | Sourmash |

- For execution on *Salmonella* samples:

| Analysis | Tool/DB |
| --- | --- |
| contamination check | `confindr` |
| coverage calculation | custom script |
| trimming and QC | `fastp` |
| raw reads quality check | `fastqc` |
| contamination check | `kraken2` |
| Multi Lucus Sequence Typing | `mlst` |
| QC | `multiQC`, `fastQC` |
| plasmid identification | `plasmidfinder`/`platon` |
| assembly QC | Quast |
| de novo assembly | Shovill |
| variant calling | Snippy |
| species identification | Sourmash |
| virulence genes identification | SPI |
| Salmonella serotype prediction | `seqSero` |
| Salmonella serovar prediction | `sistr` |

## Requirements

- `wgsbac_env_20250210.yml` (configuration file of the main environment);
- `envs.zip` (archive of configuration files for `wgsbac.pl`'s tools);
- Docker and its relevant dependencies;
- access to `kraken2` and `confindr` databases (they need to be provided as directories on the host system);
- `git` (optional, if cloning this repo).

Dependencies for `wgsbac.pl` (<https://gitlab.com/FLI_Bioinfo/WGSBAC#install-wgsbac>) are managed inside the container and dealt with through the `wgsbac_env_20250210.yml` and `envs.zip` files, during build. 

## Installation

- **Clone repository:**

```bash
# clone repo
git clone https://github.com/genpat-it/iaea_wgsbac-docker.git

# move into repository directory
cd iaea_wgsbac-docker/
## check contents
ls
Dockerfile  envs.zip  LICENSE  README.md  wgsbac_env_20250210.yml
```

- **Build Docker:**

```bash
# docker build command
docker build -t wgsbac:1.0 .
```

> **NOTE: the docker has steps to clone some necessary databases and the wgsbac repository in the container's context. This will take some time to execute and also requires ~11GB of disk space for the final image.**

## How to run

After building, you can run the container with:

```bash
docker run --rm -it -v $(pwd):/wd wgsbac:1.0
```

To run the whole pipeline, provide the desired `wgsbac` command after the `docker run` call. Please follow [instructions on WGSABAC's official GitLab](https://gitlab.com/FLI_Bioinfo/WGSBAC#running-wgsbac) to build the desired command for the species of interest. Below you'll find examples of full analysis for the 2 supported species:

- for *Brucella*:

```bash
docker run --rm -it -v $(pwd):/wd wgsbac:1.0 wgsbac.pl --table metadata_brucella.tsv --results test_brucella --kraken minikraken_8GB_20200312 --mlst brucella --virulence --conf confindr --snippy --plasmid --cpus 100 --run
```

- for *Salmonella*:

```bash
docker run --rm -it -v $(pwd):/wd wgsbac:1.0 wgsbac.pl --table metadata_salmonella.tsv --results test_salmonella --kraken minikraken_8GB_20200312 --mlst senterica --seqsero --sistr --amr --amrorganism Salmonella --virulence --spi --conf confindr --snippy --plasmid --cpus 100 --run
```

> **NOTE 1:** `kraken2` and `confindr` databases **are not** cooked inside the container: ensure you have access to them (especially `confinder`'s full version) because they are needed to run the most basic analysis possible with `wgsbac.pl`.

> **NOTE 2:** remember to map necessary directories with Docker's `-v` option: if external databases (`confindr` and `kraken2`) are not in the working directory, ensure the container can read their directories and that correct paths are provided.

## Final Notes

- The following 2 files are necessary because of how the original WGSBAC software needs to be installed (https://gitlab.com/FLI_Bioinfo/WGSBAC#install-wgsbac) and because of how it runs different tools:
	- `wgsbac_env_20250210.yml` is a Conda configuration file, needed to automatically create the main `wgsbac` Conda environment in the Docker;
	- `envs.zip` is an archive containing Conda configuration files for each tool used by `wgsbac.pl`.
- During build, the Docker will git clone the WGSBAC pipeline from the official GitLab page and it will update the following databases, cooked in the container:
	- `bakta_db_light_250210`
	- `amrfinderplus-db`
	- `Platon`
	- SPI (`spis_ibiz_database`)
- `kraken2` and `confindr` databases are necessary for the pipeline execution, but are not cooked in the Docker container, so they need to be mapped with the `-v` flag;
- The custom Rscript `table2itol.R` is disabled through commands run in the Dockerfile. If you wish to turn it on again, just delete or comment lines 46 and 47 of the Dockerfile;
- Only analysis relevant for this project (*i.e.* for *Salmonella* and *Brucella*) will work, since those are the only ones that have been set up and tested:
- All commands passed to the container will be executed in the created Conda environment (`wgsbac`).

## Acknowledgements

This is not an official Docker release of the WGSBAC pipeline.

GenPat's bioinformatics group has no control nor rights over the WGSBAC sofware, except for the permissions granted by its authors through the provided license. The Docker for such pre-existing software is provided with WGSBAC's original license.

The group sincerely thanks the author Jörg Linde for their kind support during development of this piece of software.
