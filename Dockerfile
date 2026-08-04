ARG IMAGE=docker.iscinternal.com/docker-intersystems/intersystems/iris-community:2026.3.0AI.126.0
FROM $IMAGE 

WORKDIR /home/irisowner/dev

ARG NAMESPACE="IRISAPP"

## Embedded Python environment
ENV IRISUSERNAME "_SYSTEM"
ENV IRISPASSWORD "SYS"
ENV IRISNAMESPACE $NAMESPACE
ENV PYTHON_PATH=/usr/irissys/bin/
ENV PATH "/usr/irissys/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/irisowner/bin"

COPY ./merge.cpf ./merge.cpf

ENV PYTHONPATH="/usr/irissys/lib/python"
ENV PATH "/usr/irissys/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/irisowner/bin"
WORKDIR /home/irisowner/dev


RUN --mount=type=bind,src=.,dst=. \
    iris start IRIS && \
    iris merge IRIS merge.cpf && \
	iris session IRIS < iris.script && \
    iris stop IRIS quietly