# Builder image
FROM alpine:3.9 as build
MAINTAINER Measurement Lab Support <support@measurementlab.net>

RUN apk add --update build-base gcc cmake libressl-dev curl-dev git
# TODO: Use an actual release tag. This commit is currently the latest one
# on the release/v0.27.0 branch, including the fix to make libndt build with
# musl-libc. It needs to be updated when v0.27.0 is released.
RUN git clone https://github.com/measurement-kit/libndt.git
WORKDIR /libndt
RUN git checkout 41e93c6a64684603e76ef686197877c749ae9c98

RUN cmake .
RUN cmake --build . -j $(nproc)
RUN ctest -a --output-on-failure .

# Murakami image
FROM python:3-alpine3.9
RUN apk add git
RUN pip install 'poetry==0.12.17'

WORKDIR /murakami
COPY poetry.lock pyproject.toml /murakami/

# Set up poetry to not create a virtualenv, since the docker container is
# isolated already, and install the required dependencies.
RUN poetry config settings.virtualenvs.create false \
    && poetry install --no-dev --no-interaction

# Copy Murakami and previously built test clients into the container.
COPY . /murakami/
COPY --from=build /libndt/libndt-client /murakami/bin/

CMD python -m murakami
