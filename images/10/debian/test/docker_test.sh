#!/usr/bin/sh

set -e

################################################################################
# Testing docker containers

echo "Waiting to ensure everything is fully ready for the tests..."
sleep 60

echo "Checking content of sites directory..."
if [ ! -f "./sites/apps.txt" ] || [ ! -f "./sites/.docker-app-init" ] || [ ! -f "./sites/currentsite.txt" ] || [ ! -f "./sites/.docker-site-init" ] || [ ! -f "./sites/.docker-init" ]; then
    echo 'Apps and site are not initalized?!'
    ls -al "./sites"
    exit 1
fi

echo "Checking main containers are reachable..."
if ! sudo ping -c 10 -q erpnext_db ; then
    echo 'Database container is not responding!'
    echo 'Check the following logs for details:'
    tail -n 100 logs/*.log
    exit 2
fi

if ! sudo ping -c 10 -q erpnext_app ; then
    echo 'App container is not responding!'
    echo 'Check the following logs for details:'
    tail -n 100 logs/*.log
    exit 4
fi

if ! sudo ping -c 10 -q erpnext_web ; then
    echo 'Web container is not responding!'
    echo 'Check the following logs for details:'
    tail -n 100 logs/*.log
    exit 8
fi

echo "Checking bench environment..."
bench doctor

echo "Checking apps installed..."
bench list-apps
BENCH_LIST_APPS=$(bench list-apps)

for app in frappe erpnext; do
    if ! echo "$BENCH_LIST_APPS" | grep "$app"; then
        echo "$app is not installed!"
        exit 16
    fi
done


################################################################################
# Success
echo 'Docker tests successful'


################################################################################
# Automated Unit tests
# https://docs.docker.com/docker-hub/builds/automated-testing/
# https://frappe.io/docs/user/en/testing
################################################################################

# TODO Enable tests again
#FRAPPE_APP_TO_TEST=erpnext

################################################################################
# TODO Frappe Unit tests
# https://frappe.io/docs/user/en/guides/automated-testing/unit-testing

FRAPPE_APP_UNIT_TEST_REPORT="$(pwd)/sites/.${FRAPPE_APP_TO_TEST}_unit_tests.xml"
FRAPPE_APP_UNIT_TEST_PROFILE="$(pwd)/sites/.${FRAPPE_APP_TO_TEST}_unit_tests.prof"

#bench run-tests --help

if [ -n "${FRAPPE_APP_TO_TEST}" ]; then

    echo "Preparing Frappe application '${FRAPPE_APP_TO_TEST}' tests..."

    bench set-config allow_tests true -g

    bench doctor
    bench enable-scheduler
    bench doctor

    echo "Executing Unit Tests of '${FRAPPE_APP_TO_TEST}' app..."
    if [ "${TEST_VERSION}" = "10" ]; then
        bench run-tests \
            --app "${FRAPPE_APP_TO_TEST}" \
            --junit-xml-output "${FRAPPE_APP_UNIT_TEST_REPORT}" \
            --profile > "${FRAPPE_APP_UNIT_TEST_PROFILE}"
    else
        bench run-tests \
            --app "${FRAPPE_APP_TO_TEST}" \
            --coverage \
            --junit-xml-output "${FRAPPE_APP_UNIT_TEST_REPORT}" \
            --profile > "${FRAPPE_APP_UNIT_TEST_PROFILE}"
    fi

fi

## Check result of tests
if [ -f "${FRAPPE_APP_UNIT_TEST_REPORT}" ]; then
    echo "Checking Frappe application '${FRAPPE_APP_TO_TEST}' unit tests report..."

    if grep -E '(errors|failures)="[1-9][0-9]*"' "${FRAPPE_APP_UNIT_TEST_REPORT}"; then
        echo "Unit Tests of '${FRAPPE_APP_TO_TEST}' app failed! See report for details:"
        #cat "${FRAPPE_APP_UNIT_TEST_REPORT}"
        # FIXME Fix the tests in error
        #exit 1
    else
        echo "Unit Tests of '${FRAPPE_APP_TO_TEST}' app successful! See report for details:"
        #cat "${FRAPPE_APP_UNIT_TEST_REPORT}"
    fi
fi

if [ -f ./sites/.coverage ]; then
    echo "Sending Unit Tests coverage of '${FRAPPE_APP_TO_TEST}' app to Coveralls..."
    set +e
    cp ./sites/.coverage ./.coverage

    echo "Unit Tests coverage report of '${FRAPPE_APP_TO_TEST}' app:"
    coverage report -m

    #echo "Sending Unit Tests coverage of '${FRAPPE_APP_TO_TEST}' app to Coveralls..."
    #coveralls -b "$(pwd)/apps/${FRAPPE_APP_TO_TEST}" -d "$(pwd)/sites/.coverage"

    # TODO When frappe supports coverage report in XML format
    # https://github.com/frappe/frappe/issues/9696
    #echo "Sending Unit Tests coverage of '${FRAPPE_APP_TO_TEST}' app to Codacy..."
    #wget -qO - https://coverage.codacy.com/get.sh | sh -s report -l Python -r "$(pwd)/sites/coverage.xml"

    rm ./.coverage
    set -e
fi

if [ -f "${FRAPPE_APP_UNIT_TEST_PROFILE}" ]; then
    echo "Checking Frappe application '${FRAPPE_APP_TO_TEST}' unit tests profile..."

    # XXX Are there any online services that could receive and display profiles?
    #cat "${FRAPPE_APP_UNIT_TEST_PROFILE}"
fi


################################################################################
# TODO QUnit (JS) Unit tests
# https://frappe.io/docs/user/en/guides/automated-testing/qunit-testing

bench run-ui-tests --help

#echo "Executing UI Tests of '${FRAPPE_APP_TO_TEST}' app..."
#if [ "${TEST_VERSION}" = "10" ] || [ "${TEST_VERSION}" = "11" ]; then
#    bench run-ui-tests --app ${FRAPPE_APP_TO_TEST}
#else
#    bench run-ui-tests ${FRAPPE_APP_TO_TEST}
#fi

## TODO Check result of UI tests



################################################################################
# TODO Generate docs

#bench build-docs --help

#echo "Generating docs for '${FRAPPE_APP_TO_TEST}' app..."
#if [ "${TEST_VERSION}" = "10" ] || [ "${TEST_VERSION}" = "11" ]; then
#    set +e
#    bench build-docs \
#        --target ${FRAPPE_APP_TO_TEST} \
#        --docs-version ${FRAPPE_APP_TO_TEST} \
#        ${FRAPPE_APP_TO_TEST}
#    set -e
#else
#    echo "Building docs is not available for this version of Frappe (${TEST_VERSION})"
#fi

## TODO Check docs generated properly


################################################################################
# Success
echo "Frappe app '${FRAPPE_APP_TO_TEST}' tests finished"
echo 'Check the CI reports and logs for details.'
exit 0
