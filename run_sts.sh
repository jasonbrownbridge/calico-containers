#!/bin/bash

set -x
set -e
date
pwd
git status

nosetests calico_containers/tests/st

# Run the STs. Need to run from the /code directory since the tests expect
# to be run from the root of the codebase.
docker run --privileged -v `pwd`/calico_containers:/code/calico_containers \
 -v `pwd`/dist:/code/dist \
 --name host1 -tid jpetazzo/dind
docker exec -t host1 bash -c \
 'while ! docker ps; do sleep 1; done && \
 docker load --input /code/calico_containers/calico-node.tar && \
 docker load --input /code/calico_containers/busybox.tar && \
 docker load --input /code/calico_containers/nsenter.tar'

docker exec -t host1 bash -c 'cd /code && sudo ./calico_containers/tests/st/add_container.sh'
docker exec -t host1 bash -c 'cd /code && sudo ./calico_containers/tests/st/add_ip.sh'
docker exec -t host1 bash -c 'cd /code && sudo ./calico_containers/tests/st/arg_parsing.sh'
docker exec -t host1 bash -c 'cd /code && sudo ./calico_containers/tests/st/profile_commands.sh'
docker exec -t host1 bash -c 'cd /code && sudo ./calico_containers/tests/st/no_powerstrip.sh'

docker exec -t host1 bash -c 'docker rm -f $(docker ps -qa) ; \
                              docker rmi $(docker images -qa)' || true
docker rm -f host1 || true

echo "All tests have passed."