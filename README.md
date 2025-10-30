# IAEA_wgsbac-docker

Docker image for the WGSBAC pipeline for *Salmonella* and *Brucella* in the context of IAEA-GenPat joint project.

## Index

- [Overview](#overview)
- [About the Project](#about-the-project)
- [Disclaimer](#disclaimer)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Technical Notes](#important-technical-notes-dont-skip)
- [How to run](#how-to-run)
- [Acknowledgements](#acknowledgements)
- [Final Notes](#final-notes)

## Overview

This repository hosts the Dockerfile, developed by GenPat's bioinformatics team, and necessary dependencies (`yml` and `envs.zip`) to build the Docker for the WGSBAC pipeline (<https://gitlab.com/FLI_Bioinfo/WGSBAC>) by Jörg Linde (@joerg.linde) and Mostafa Abdel-Glil (@Mostafa.Abdel-Glil).

- Version: 2.0.0
- Author: GenPat
- Contact: genpat@izs.it

## About the Project

In the context of the 2024-2025 IAEA-GenPat joint project, the GenPat platform ensured interoperability with the Galaxy platform, by adapting and transfering bioinformatics workflows. This repository hosts the development results of the migration and adaptation of the bacterial workflows (for *Brucella* and *Salmonella*), from the contact of the Friedrich-Loeffler-Institut (Jörg Linde: Joerg.Linde@fli.de).

The developed dockerized version of the original software (`wgsbac.pl`) was used for deployment of the analyses for the 2 organisms of interest on the GenPat platform.

- GenPat platform: <https://genpat.izs.it>
- Galaxy platform: <https://usegalaxy.org>

## Disclaimer

The code in this repo has been developed uniquely for the needs of the GenPat platform, and published here to share it with the open source community and the `wgsbac` authors, and in accordance with the original authors' [MIT license](./LICENSE).

Only commands and tools of interest were tested, and some adaptations were added to allow integration of the pipeline into the GenPat platform, for IAEA users. 

As such, the Dockerfile's code in this repository is provided "as is", without warranty of any kind, express or implied, including but not limited to fitness for a particular purpose. 

## Features

The dockerized WGSBAC pipeline runs a suite of tools that can be subdivided into:

- Reads Quality Check (QC) and trimming
- Sequence reconstruction
- Assembly QC and contamination check
- Genome annotation
- Typing

The list of analyses run for *Brucella* and *Salmonella* species and the tools used are available on the official WGSBAC software's GitLab page: <https://gitlab.com/FLI_Bioinfo/WGSBAC#modules>. The list of analyses available in this dockerized version are listed in the tables below.

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
| Anti-Micorbial Resistance (AMR) detection | AMRFinderPlus |
| MLVA (Multiple-Locus Variable number tandem repeat Analysis) | `MLVA_finder.py` |

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
| Anti-Micorbial Resistance (AMR) detection | AMRFinderPlus |
| virulence genes identification | SPI |
| Salmonella serotype prediction | `seqSero` |
| Salmonella serovar prediction | `sistr` |

## Requirements

- `wgsbac_env_20250210.yml` (configuration file of the main environment);
- `envs.zip` (archive of configuration files for `wgsbac.pl`'s tools);
- Docker and its relevant dependencies;
- access to `kraken2` and `confindr` databases (they need to be provided as directories on the host system);
- Platon's database (`db.tar.gz` from this repo, or `db.tar.gz` from Zenodo, or replacing copy of DB with `wget` of DB in Dockerfile);
- \>40.3GB of disk space available;
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
db.tar.gz   envs.zip  README.md
Dockerfile  LICENSE   wgsbac_env_20250210.yml
```

- **Build Docker:**

```bash
# docker build command
docker build -t wgsbac:2.0 .
```

> **NOTE: the docker has steps to create necessary environments, clone some necessary databases and the wgsbac repository in the container's context. This will take some time to execute and also requires ~40GB of disk space for the final image ([read the Technical Notes section below](#important-technical-notes-dont-skip)).**

### Important Technical Notes (don't skip!)

1. The building process will create a **VERY LARGE** Docker image (~40GB). This is due to:
   - pre-created environments for each tool in the image, needed to solve dependency conflicts;
   - internal needs of containerization, re-usage/share of environments and overhead reduction (~20-30min of saved time per run);
   - the nature of the original code and wrapper.
2. Since the image is large and some steps include slow downloads (DBs for Bakta, AMRfinder and Platon), expect a long build time (especially for environment pre-creation).
3. Conda envs required by `wgsbac` are pre-created to grant reproducibility and to avoid experiencing overhead for subsequent Docker container runs. If you don't care about this or you need to reduce the image size, just comment the full `RUN` instruction of layer 5 before building. **This will skip creation of envs at build time and will save ~25GB of disk space**.
4. Download of Platon DB was known to timeout during the build. **We provide the "pre-downloded" Platon `db.tar.gz` (from October 2025) directly in the context**, to avoid potential build errors.
   - If a newer version comes out and you wish to use it, just replace `db.tar.gz` in the build context with the new one (you can get it from <https://github.com/oschwengers/platon?tab=readme-ov-file#database>).
   - If you don't want to download Platon's `db.tar.gz` separately and still wish to try download during build time, you can comment out **line 13 of Dockerfile** (`COPY envs.zip /context/envs.zip`) and replace **line 43 of Dockerfile** with:
     ```bash
	 wget https://zenodo.org/record/4066768/files/db.tar.gz && tar -xvf db.tar.gz && mv db Platon && rm db.tar.gz && \
     ```

## How to run

After building, you can run the container with:

```bash
# For non-interactive docker run
docker run --rm -v $(pwd):/wd wgsbac:2.0
## with paths to external databases (if not in working directory)
docker run --rm -v /path/to/confindr_db:/mnt/confindr -v /path/to/kraken_db:/mnt/kraken -v $(pwd):/wd wgsbac:2.0
## with defined user permissions:
docker run --rm -u 0:0 -v /path/to/confindr_db:/mnt/confindr -v /path/to/kraken_db:/mnt/kraken -v $(pwd):/wd wgsbac:2.0

# For interactive docker run
docker run --rm -it -v /path/to/confindr_db:/mnt/confindr -v /path/to/kraken_db:/mnt/kraken -v $(pwd):/wd wgsbac:2.0
## with defined user permissions:
docker run --rm -it -u 0:0 -v /path/to/confindr_db:/mnt/confindr -v /path/to/kraken_db:/mnt/kraken -v $(pwd):/wd wgsbac:2.0
```

To run the whole pipeline, provide the desired `wgsbac` command after the `docker run` call. Please follow [instructions on WGSABAC's official GitLab](https://gitlab.com/FLI_Bioinfo/WGSBAC#running-wgsbac) to build the desired command for the species of interest. Below you'll find examples of full analysis for the 2 supported species:

- for *Brucella*:

```bash
docker run --rm -u 0:0 -v /path/to/confindr_db:/mnt/confindr -v /path/to/kraken_db:/mnt/kraken -v $(pwd):/wd wgsbac:2.0 wgsbac.pl --table metadata_brucella.tsv --results test_brucella --kraken minikraken_8GB_20200312 --mlst brucella --mlva Brucella --virulence --conf confindr --snippy --plasmid --cpus 100 --run
```

- for *Salmonella*:

```bash
docker run --rm -u 0:0 -v /path/to/confindr_db:/mnt/confindr -v /path/to/kraken_db:/mnt/kraken -v $(pwd):/wd wgsbac:2.0 wgsbac.pl --table metadata_salmonella.tsv --results test_salmonella --kraken minikraken_8GB_20200312 --mlst senterica --seqsero --sistr --amr --amrorganism Salmonella --virulence --spi --conf confindr --snippy --plasmid --cpus 100 --run
```

> **NOTE 1:** `kraken2` and `confindr` databases **are not** cooked inside the container: ensure you have access to them (especially `confinder`'s full version) because they are needed to run the most basic analysis possible with `wgsbac.pl`.

> **NOTE 2:** remember to map necessary directories with Docker's `-v` option: if external databases (`confindr` and `kraken2`) are not in the working directory, ensure the container can read their directories and that correct paths are provided.

> **NOTE 2:** all commands passed to the container in non-interactive mode will be executed by default in the `wgsbac` environment. For execution of the pipeline in Docker's interactive mode (`-it`), you need to activate the env manually: 
>
> ```bash
> docker run --rm -it -u 0:0 -v /path/to/confindr_db:/mnt/confindr -v /path/to/kraken_db:/mnt/kraken -v $(pwd):/wd wgsbac:2.0
> conda activate wgsbac
> ```

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
- Only analysis relevant for this project (*i.e.* for *Salmonella* and *Brucella*) will work at 100%, since those are the only ones that have been set up and tested.

## Acknowledgements

This is not an official Docker release of the WGSBAC pipeline.

GenPat's bioinformatics group has no control nor rights over the WGSBAC sofware, except for the permissions granted by its authors through the provided license. The Docker for such pre-existing software is provided with WGSBAC's original license.

The group sincerely thanks the author Jörg Linde for their kind support during development of this piece of software and all developers of used tools for their contribution to the open-source community.
