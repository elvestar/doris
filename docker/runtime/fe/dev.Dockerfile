#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# choose a base image
FROM openjdk:8u342-jdk

# set environment variables
ENV JAVA_HOME="/usr/local/openjdk-8/" \
	PATH="/opt/apache-doris/fe/bin:${PATH}"

ADD docker/runtime/sources.list /etc/apt/

RUN apt-get update && \
	apt-get install -y default-mysql-client vim less && \
	apt-get clean && \
	mkdir -p /opt/apache-doris/fe && \
	cd /opt/apache-doris/fe && mkdir bin conf lib log doris-meta webroot

ADD bin/stop_fe.sh bin/dev/start_fe.sh /opt/apache-doris/fe/bin/
ADD conf/fe.conf conf/ldap.conf conf/*.xml /opt/apache-doris/fe/conf/
ADD docs/build/help-resource.zip /opt/apache-doris/fe/lib/
ADD webroot/static/* /opt/apache-doris/fe/webroot/
ADD fe/fe-core/target/lib/* fe/fe-core/target/doris-fe.jar /opt/apache-doris/fe/lib/

ADD docker/runtime/fe/resource/init_fe.sh /opt/apache-doris/fe/bin
ADD docker/runtime/fe/resource/init_db.sh /opt/apache-doris/fe/bin
RUN chmod 755 /opt/apache-doris/fe/bin/init_fe.sh

ENTRYPOINT ["/opt/apache-doris/fe/bin/init_fe.sh"]
