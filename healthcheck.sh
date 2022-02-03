#! /bin/bash
NAMESPACE="onap"
BRANCH=`git --git-dir=/opt/oom/.git status | head -n 1 | sed 's/On branch //'`
CLUSTER=`hostname | cut -d "-" -f1,2`
echo $BRANCH
## RUN ONAP HEALTHCHECK

echo "Running ete-k8s healthcheck for $NAMESPACE $BRANCH"
TEST_RESULTS=`cat /dockerdata-nfs/onap/integration/xtesting-healthcheck/core/core/xunit.xml | head -n 2 | tail -n 1`

TEST_NAME=`cat /dockerdata-nfs/onap/integration/xtesting-healthcheck/core/core/xunit.xml | head -n 2 | tail -n 1 | cut -d " " -f2 | cut -d "\"" -f2`
TEST_NUMBER=`cat /dockerdata-nfs/onap/integration/xtesting-healthcheck/core/core/xunit.xml | head -n 2 | tail -n 1 | cut -d " " -f3 | cut -d "\"" -f2`
TEST_ERRORS=`cat /dockerdata-nfs/onap/integration/xtesting-healthcheck/core/core/xunit.xml | head -n 2 | tail -n 1 | cut -d " " -f4 | cut -d "\"" -f2`
TEST_FAILURES=`cat /dockerdata-nfs/onap/integration/xtesting-healthcheck/core/core/xunit.xml | head -n 2 | tail -n 1 | cut -d " " -f5 | cut -d "\"" -f2`
TEST_TIME=`cat /dockerdata-nfs/onap/integration/xtesting-healthcheck/core/core/xunit.xml | head -n 2 | tail -n 1 | cut -d " " -f7 | cut -d "\"" -f2`

if [ "$TEST_ERRORS" -ne "0" ] || [ "$TEST_FAILURES" -ne "0" ]
then
        TEST_STATUS=:rotating_light::rotating_light:
else
        TEST_STATUS=:white_check_mark::white_check_mark:
fi


  MESSAGE=`cat << EOM
$TEST_STATUS
**$CLUSTER** branch **$BRANCH** 
**$TEST_NAME:**
Tests:$TEST_NUMBER, ERROR:$TEST_ERRORS, FAIL:$TEST_FAILURES, Time:$TEST_TIME s
EOM`


## GENERATE PAYLOAD WITH MESSGE
## POST MESSAGE TO MATTERMOST

echo "$MESSAGE"

PAYLOAD=`cat << EOM
payload={"text": "$MESSAGE"}
EOM`

echo "Sending notification to mattermost"
curl -i -X POST --data "$PAYLOAD" https://mattermost.tech.orange/hooks/8b575qmijpdw7q4fcahdjg6cuw > /dev/null 2>&1
