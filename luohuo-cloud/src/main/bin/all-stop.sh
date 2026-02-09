#!/bin/bash

/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-gateway.sh stop
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-oauth.sh stop
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-base.sh stop
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-system.sh stop
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-ai.sh stop
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-im.sh stop
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-ws.sh stop