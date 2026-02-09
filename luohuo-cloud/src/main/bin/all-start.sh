#!/bin/bash

/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-gateway.sh
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-oauth.sh
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-base.sh
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-system.sh
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-ai.sh
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-im.sh
/bin/bash /var/jenkins_home/workspace/luohuo-cloud/src/main/bin/restart-luohuo-ws.sh