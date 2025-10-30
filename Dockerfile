# Base image: official miniconda3 image version 24.9.2, from continuumio
FROM continuumio/miniconda3:24.9.2-0

# Set working directory for COPY and RUN instructions
WORKDIR /context

# Make sure commands are executed as root
USER root

# Copy exported yml file of conda environment (copy requirements/dependencies)
COPY wgsbac_env_20250210.yml /context/wgsbac_env_20250210.yml
# Copy pre-produced and modified environment yaml files for tools
COPY envs.zip /context/envs.zip
# Copy Platon db tarball
COPY db.tar.gz /context/db.tar.gz

# Set the shell to /bin/bash
SHELL ["/bin/bash", "-c"]

# Layer 1
## Create the Conda environment using the exported conda yml and set up automatic boot into new env
RUN echo "alias ll='ls -alF'" >> ~/.bashrc && \
	python3 -m pip install regex && \
	conda config --system --set auto_activate_base false && \
	sed -i '/^[[:space:]]*conda[[:space:]]\+activate[[:space:]]\+base/s/^/#/' /root/.bashrc || true && \
	conda clean --all --yes && \
	conda config --prepend channels defaults && \
	conda config --prepend channels bioconda && \
	conda config --prepend channels conda-forge && \
#	conda config --set channel_priority strict && \
	conda env create -f=/context/wgsbac_env_20250210.yml -n wgsbac && \
	conda clean --all --yes

# Layer 2
## Git clone WGSBAC pipeline and add directories to $PATH
RUN git clone https://gitlab.com/FLI_Bioinfo/WGSBAC.git && \
	cd /context/WGSBAC/ && git checkout _non_automatic_update && cd - && \
	chmod -R +x /context/WGSBAC/*

# Layer 3
## Download databases + fix meta_to_itol.R script error
RUN conda run --no-capture-output -n wgsbac bakta_db download --output /context/bakta_db_light_250210 --type light && \
	chmod -R 774 /context/bakta_db_light_250210/db-light/amrfinderplus-db && \
	conda run --no-capture-output -n wgsbac amrfinder_update --force_update --database /context/bakta_db_light_250210/db-light/amrfinderplus-db && \
	tar -xvf db.tar.gz && mv db WGSBAC/data/Platon && rm db.tar.gz && \
	git clone https://gitlab.com/FLI_Bioinfo_pub/spis_ibiz_database WGSBAC/data/SPI && \
	chmod -R 774 /context/WGSBAC/data/Platon && chmod -R 774 /context/WGSBAC/data/SPI && \
	sed -i '65s/^/#/; 69,71s/^/#/; 191,192s/^/#/' /context/WGSBAC/snakefiles/master.Snakefile && \
	sed -i '18,20s/^/#/; 26,27s/$itol,//; 37s/$itol,//; 105,107s/^/#/; 126s/$itol,//; 171s/^/#/; 191,192s/^/#/; 233,235s/^/#/; 241s/^/#/' /context/WGSBAC/scripts/perl5lib/WGSBAC/Snakefile.pm

# Layer 4
## Replace buggy yaml environment files with modified ones
RUN apt-get update && apt-get install -y --no-install-recommends less zip fontconfig r-base && \
	shopt -s extglob && shopt -s nullglob && \
	unzip /context/envs.zip && \
	yes | mv -f /context/envs/*.yaml /context/WGSBAC/envs/. && \
	rm /context/envs.zip && \
	rm -r /context/envs && \
	rm -rf /var/lib/apt/lists/*

# Layer 5
## Switch into WGSBAC to scan for environment yaml files needed in the Snakefile and pre-create them all
WORKDIR /context/WGSBAC
RUN set -euo pipefail && \
	: > build_envs.Snakefile && : > build_envs.rules && \
	echo 'rule all:' >> build_envs.Snakefile && \
	echo '    input:' >> build_envs.Snakefile && \
	mkdir -p .bootstrap && \
	# Collect env files once, safely (handles spaces/newlines) and dedupe
	mapfile -d '' ys < <(find envs -type f \( -name '*.yml' -o -name '*.yaml' \) -print0 | sort -zu) && \
	count=${#ys[@]} && idx=0 && \
	for y in "${ys[@]}"; do \
	  base="$(basename "${y%.*}")"; \
	  safe_base="$(printf '%s' "$base" | tr -c 'A-Za-z0-9' '_')"; \
	  suffix="$(printf '%s' "$y" | sha1sum | cut -c1-8)"; \
	  marker=".bootstrap/${safe_base}_${suffix}.ok"; \
	  # Append to rule all input (comma on all but last)
	  idx=$((idx+1)); \
	  sep=$([ "$idx" -lt "$count" ] && echo ',' || echo ''); \
	  printf '        "%s"%s\n' "$marker" "$sep" >> build_envs.Snakefile; \
	  # Prepare the per-env rule (written later)
	  printf 'rule bootstrap_%s_%s:\n' "$safe_base" "$suffix" >> build_envs.rules; \
	  printf '    output:\n        "%s"\n' "$marker" >> build_envs.rules; \
	  printf '    conda:\n        "%s"\n' "$y" >> build_envs.rules; \
	  printf '    shell:\n        "mkdir -p .bootstrap && echo ok > %s"\n\n' "$marker" >> build_envs.rules; \
	done && \
	# Append all rules after the input list so the file is valid Python
	cat build_envs.rules >> build_envs.Snakefile && rm -f build_envs.rules && \
	echo "Generated build_envs.Snakefile:" && sed -n '1,200p' build_envs.Snakefile && \
	# Create all environments (hashed) without running any rule commands
	conda run --no-capture-output -n wgsbac snakemake \
	  -s build_envs.Snakefile \
	  --cores 8 \
	  --use-conda \
	  --conda-prefix /context/WGSBAC/conda \
	  --conda-create-envs-only

ENV PATH="/opt/conda/envs/wgsbac/bin:/context/WGSBAC:$PATH"

# Change working directory for CMD and ENTRYPOINT instructions
WORKDIR /wd

# Set ENTRYPOINT to execute command line commands in wgsbac conda environment
ENTRYPOINT ["/opt/conda/bin/conda", "run", "--no-capture-output", "-n", "wgsbac"]


# Set CMD for default execution of Bash shell at container boot
CMD ["/bin/bash"]