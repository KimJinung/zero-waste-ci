pipeline {
    agent {
        docker {
            image 'zero-waste-ci/ubuntu20-linux:latest'
            args '--user builder -v /srv/yocto/downloads:/home/builder/downloads'
        }
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    environment {
        POKY_REPO   = 'https://git.yoctoproject.org/poky'
        POKY_BRANCH = 'scarthgap'
        BUILD_DIR   = "${WORKSPACE}/build"
        MACHINE     = 'qemux86-64'
        TARGET      = 'core-image-minimal'
    }

    stages {
        stage('Fetch Poky') {
            steps {
                sh '''#!/bin/bash --login
                    git clone --depth=1 --branch ${POKY_BRANCH} ${POKY_REPO} poky
                '''
            }
        }

        stage('Configure') {
            steps {
                // oe-init-build-env creates BUILD_DIR and generates default conf files.
                // All conf edits must happen in the same shell context after sourcing.
                sh '''#!/bin/bash --login
                    source poky/oe-init-build-env ${BUILD_DIR}

                    echo "MACHINE = \\"${MACHINE}\\"" >> conf/local.conf

                    # Use persistent download cache mounted from the host
                    echo "DL_DIR = \\"/home/builder/downloads\\"" >> conf/local.conf

                    # Parallelize build based on available CPU cores
                    echo "BB_NUMBER_THREADS = \\"$(nproc)\\"" >> conf/local.conf
                    echo "PARALLEL_MAKE     = \\"-j$(nproc)\\"" >> conf/local.conf
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''#!/bin/bash --login
                    source poky/oe-init-build-env ${BUILD_DIR}
                    bitbake ${TARGET}
                '''
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts(
                    artifacts: 'build/tmp/deploy/images/**/*.wic*',
                    fingerprint: true,
                    allowEmptyArchive: false
                )
            }
        }
    }

    post {
        success {
            echo "Build succeeded: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        failure {
            // Clean workspace only on failure to remove corrupted build state.
            // On success, the workspace is preserved for incremental Yocto builds.
            echo "Build failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
            cleanWs()
        }
    }
}
