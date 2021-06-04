FROM python:3.8

ARG SPLEETER_VERSION=2.2.2
ENV MODEL_PATH /model

RUN mkdir -p /model

# ffmpeg
RUN apt-get -y install wget tar
RUN cd /usr/local/bin && mkdir ffmpeg && cd ffmpeg && \
    wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz && \
    tar xvf ffmpeg-release-amd64-static.tar.xz && mv ffmpeg-4.4-amd64-static/ffmpeg . && mv ffmpeg-4.4-amd64-static/ffprobe . && \
    ln -s /usr/local/bin/ffmpeg/ffmpeg /usr/bin/ffmpeg && ln -s /usr/local/bin/ffmpeg/ffprobe /usr/bin/ffprobe

# libsndfile
RUN apt update
RUN apt-get -y install libsndfile1

# spleeter
RUN pip install musdb museval
RUN pip install spleeter==${SPLEETER_VERSION}

# boto3
RUN pip install boto3

# logic & entry
WORKDIR '/app'
COPY app.py ./
CMD ["python", "app.py"]
