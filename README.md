# IAEA_wgsbac-docker

Docker image for the WGSBAC pipeline for Salmonella and Brucella in the context of IAEA-GenPat joint project.

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

The list of analyses run for *Brucella* and *Salmonella* species and the tools used are available on the official WGSBAC software's GitLab page: <https://gitlab.com/FLI_Bioinfo/WGSBAC#modules>

## Requirements

- `wgsbac_env_20250210.yml` (configuration file of the main environment);
- `envs.zip` (archive of configuration files for `wgsbac.pl`'s tools);
- Docker and its relevant dependencies:

	> In GNU-Linux (Ubuntu):
	>	```
	>	docker.io
	>	docker-compose
	>	docker-buildx
	>	```

- `git` (optional, if cloning this repo)

Dependencies for `wgsbac.pl` (<https://gitlab.com/FLI_Bioinfo/WGSBAC#install-wgsbac>) are managed inside the container and dealt with through the `wgsbac_env_20250210.yml` and `envs.zip` files, during build. 

## Installation

1. Clone repository:

```bash
git clone https://github.com/genpat-it/iaea_wgsbac-docker.git
```

2. Build Docker:

```bash
cd iaea_wgsbac-docker/
ls 
```

## How to run

## Acknowledgement

## Final Notes
    Per la build il Docker necessita del file di configurazione wgsbac_env_20250210.yml, in modo da creare l'ambiente Conda nel container;
    Per preparare gli ambienti Conda dei singoli tools, il Docker necessita dei rispettivi files di configurazione (contenuti nell'archivio envs.zip);
    Alla build il Docker effettuerà il git clone della pipeline WGSBAC dal GitLab ufficiale e il download e update dei seguenti databases:
        bakta_db_light_250210
        amrfinderplus-db
        Platon
        SPI (spis_ibiz_database)
    I databases di kraken2 e confindr sono necessari per l'esecuzione della pipeline ma non sono cucinati nel Docker: vanno mappati con -v;
    Lo script R custom "table2itol.R" è spento perchè causava errori e non è di interesse;
    Le analisi funzionanti e testate sono solo quelle di interesse per il progetto o per Genpat, e solo per gli organismi Salmonella e Brucella.

I comandi passati al Docker vengono eseguiti nell'environment Conda creato (wgsbac).
