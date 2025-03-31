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

# Set the shell to /bin/bash
SHELL ["/bin/bash", "-c"]

# Layer 1
## Create the Conda environment using the exported conda yml and set up automatic boot into new env
RUN echo "alias ll='ls -alF'" >> ~/.bashrc && \
	shopt -s extglob && shopt -s nullglob && \
	conda init && conda clean --all --yes && \
	conda config --add channels conda-forge && \
	conda config --add channels bioconda && \
	conda config --add channels defaults && \
	source /root/.bashrc && \
	conda env create -f=/context/wgsbac_env_20250210.yml -n wgsbac && \
	conda clean --all --yes && \
	echo "conda activate wgsbac" >> ~/.bashrc

# Layer 2
## Git clone WGSBAC pipeline and add directories to $PATH
RUN git clone https://gitlab.com/FLI_Bioinfo/WGSBAC.git && \
	cd /context/WGSBAC/ && git checkout _non_automatic_update && cd - && \
	chmod +x /context/WGSBAC/*

# Layer 3
## Download databases + fix meta_to_itol.R script error
RUN conda run --no-capture-output -n wgsbac bakta_db download --output /context/bakta_db_light_250210 --type light && \
	chmod 774 /context/bakta_db_light_250210/db-light/amrfinderplus-db && \
	conda run --no-capture-output -n wgsbac amrfinder_update --force_update --database /context/bakta_db_light_250210/db-light/amrfinderplus-db && \
	cd WGSBAC/data/ && wget https://zenodo.org/record/4066768/files/db.tar.gz && \
	tar -xvf db.tar.gz && mv db Platon && mv db.tar.gz Platon/. && \
	git clone https://gitlab.com/FLI_Bioinfo_pub/spis_ibiz_database && mv spis_ibiz_database SPI && cd - && \
	chmod 774 /context/WGSBAC/data/Platon && chmod 774 /context/WGSBAC/data/SPI && \
	sed -i '65s/^/#/; 69,71s/^/#/; 191,192s/^/#/' /context/WGSBAC/snakefiles/master.Snakefile && \
	sed -i '18,20s/^/#/; 26,27s/$itol,//; 37s/$itol,//; 105,107s/^/#/; 126s/$itol,//; 171s/^/#/; 191,192s/^/#/; 233,235s/^/#/' /context/WGSBAC/scripts/perl5lib/WGSBAC/Snakefile.pm

# Layer 4
## Replace buggy yaml environment files with modified ones
RUN apt-get update && apt-get install less -y && \
	apt-get install zip -y && \
	unzip /context/envs.zip && \
	yes | mv -f /context/envs/*.yaml /context/WGSBAC/envs/. && \
	rm /context/envs.zip && \
	rm -r /context/envs && \
	yes | apt-get install fontconfig

# Update PATH
ENV PATH="/opt/conda/envs/wgsbac/bin:/context/WGSBAC:$PATH"

# Change working directory for CMD and ENTRYPOINT instructions
WORKDIR /wd

# Set ENTRYPOINT to execute command line commands in wgsbac conda environment
ENTRYPOINT ["/opt/conda/bin/conda", "run", "--no-capture-output", "-n", "wgsbac"]

# Set CMD for default execution of Bash shell at container boot
CMD ["/bin/bash"]