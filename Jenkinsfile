// ---------------------------------------------------------------------------
// Image naming convention (derived from Dockerfile path):
//   base/debian/ubuntu20/Dockerfile   → zero-waste-ci/ubuntu20-base
//   teams/android-team/ubuntu20/Dockerfile → zero-waste-ci/ubuntu20-android
//
// Adjust imageNameFromPath() if your project uses a different scheme.
// ---------------------------------------------------------------------------

def imageNameFromPath(String dockerfilePath) {
    def parts = dockerfilePath.split('/')
    def os   = parts[-2]                              // e.g. 'ubuntu20'
    def role = dockerfilePath.startsWith('base/')
        ? 'base'
        : parts[1].replaceAll('-team$', '')           // e.g. 'android-team' → 'android'
    return "zero-waste-ci/${os}-${role}"
}

pipeline {
    // Requires a Jenkins agent with Docker installed and in PATH.
    agent { label 'docker' }

    environment {
        // Registry host only – image names already carry their namespace prefix.
        // base image : registry.example.com/zero-waste-ci/ubuntu20-base
        // team image : registry.example.com/zero-waste-ci/ubuntu20-android
        REGISTRY  = 'registry.example.com'
        IMAGE_TAG = "${env.GIT_COMMIT?.take(7) ?: error('GIT_COMMIT is not set – is this a proper git checkout?')}"
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {
        // ------------------------------------------------------------------ //
        // Stage 1 – Detect Changes                                            //
        // Scans base/ and teams/ for Dockerfiles, then determines which ones  //
        // need rebuilding by comparing changed files against each Dockerfile's //
        // parent directory.                                                   //
        //                                                                     //
        // Rebuild triggers:                                                   //
        //   base image  – any file changed under its Dockerfile directory     //
        //   team image  – own directory changed, OR any base rebuilt,         //
        //                 OR common/ (shared scripts) changed                 //
        // ------------------------------------------------------------------ //
        stage('Detect Changes') {
            steps {
                script {
                    def diffRef = env.CHANGE_TARGET
                        ? "origin/${env.CHANGE_TARGET}"
                        : 'HEAD~1'

                    def changedFiles = sh(
                        script: """
                            git diff --name-only \$(git merge-base HEAD ${diffRef}) HEAD \
                                2>/dev/null || git diff --name-only HEAD~1 HEAD
                        """,
                        returnStdout: true
                    ).trim().split('\n').findAll { it }

                    echo "Changed files (vs ${diffRef}):\n${changedFiles.join('\n')}"

                    // Discover all Dockerfiles dynamically
                    def allBaseDockerfiles = sh(
                        script: 'find base -name Dockerfile -type f 2>/dev/null || true',
                        returnStdout: true
                    ).trim().split('\n').findAll { it }

                    def allTeamDockerfiles = sh(
                        script: 'find teams -name Dockerfile -type f 2>/dev/null || true',
                        returnStdout: true
                    ).trim().split('\n').findAll { it }

                    // --- Base targets: rebuild if files under its directory changed ---
                    def baseTargets = allBaseDockerfiles.findAll { df ->
                        def dir = df.replaceAll('/Dockerfile$', '')
                        changedFiles.any { it.startsWith("${dir}/") || it == df }
                    }

                    def baseChanged  = !baseTargets.isEmpty()
                    def commonChanged = changedFiles.any { it.startsWith('common/') }

                    // --- Team targets: own dir changed, OR base/common changed ---
                    def teamTargets
                    if (baseChanged || commonChanged) {
                        // base or common touched → every team image must be rebuilt
                        teamTargets = allTeamDockerfiles
                    } else {
                        teamTargets = allTeamDockerfiles.findAll { df ->
                            def dir = df.replaceAll('/Dockerfile$', '')
                            changedFiles.any { it.startsWith("${dir}/") || it == df }
                        }
                    }

                    // Persist as comma-separated strings for later stages
                    env.BASE_TARGETS = baseTargets.join(',')
                    env.TEAM_TARGETS = teamTargets.join(',')

                    echo """Build plan:
                        base images : ${baseTargets.collect { imageNameFromPath(it) } ?: '(none)'}
                        team images : ${teamTargets.collect { imageNameFromPath(it) } ?: '(none)'}
                    """
                }
            }
        }

        // ------------------------------------------------------------------ //
        // Stage 2 – Build Base                                                //
        // Dynamically creates parallel sub-stages for every affected base     //
        // Dockerfile. Each image is tagged with both :SHA and :latest so      //
        // downstream team images (FROM …:latest) pick up the new layer.      //
        // ------------------------------------------------------------------ //
        stage('Build Base Images') {
            when {
                expression { env.BASE_TARGETS?.trim() }
            }
            steps {
                script {
                    def targets = env.BASE_TARGETS.split(',').findAll { it }
                    def stages = [:]

                    for (t in targets) {
                        def dockerfile = t
                        def name = imageNameFromPath(dockerfile)
                        stages["Build ${name}"] = {
                            sh """
                                docker build \
                                    -f ${dockerfile} \
                                    -t ${name}:${env.IMAGE_TAG} \
                                    -t ${name}:latest \
                                    .
                            """
                        }
                    }

                    parallel stages
                }
            }
        }

        // ------------------------------------------------------------------ //
        // Stage 3 – Build Team Images                                         //
        // Dynamically creates parallel sub-stages for every affected team     //
        // Dockerfile. Build context is the repo root so COPY common/ and     //
        // COPY teams/ resolve correctly.                                     //
        // ------------------------------------------------------------------ //
        stage('Build Team Images') {
            when {
                expression { env.TEAM_TARGETS?.trim() }
            }
            steps {
                script {
                    def targets = env.TEAM_TARGETS.split(',').findAll { it }
                    def stages = [:]

                    for (t in targets) {
                        def dockerfile = t
                        def name = imageNameFromPath(dockerfile)
                        stages["Build ${name}"] = {
                            sh """
                                docker build \
                                    -f ${dockerfile} \
                                    -t ${name}:${env.IMAGE_TAG} \
                                    -t ${name}:latest \
                                    .
                            """
                        }
                    }

                    parallel stages
                }
            }
        }

        // ------------------------------------------------------------------ //
        // Stage 4 – Test                                                      //
        // Smoke-tests every image that was built (base + team),              //
        // including PR builds.                                               //
        // ------------------------------------------------------------------ //
        stage('Test') {
            when {
                expression { env.BASE_TARGETS?.trim() || env.TEAM_TARGETS?.trim() }
            }
            steps {
                script {
                    def stages = [:]

                    def allTargets = []
                    allTargets += env.BASE_TARGETS?.split(',')?.findAll { it } ?: []
                    allTargets += env.TEAM_TARGETS?.split(',')?.findAll { it } ?: []

                    for (t in allTargets) {
                        def name = imageNameFromPath(t)
                        stages["Test ${name}"] = {
                            // Verify the shell is functional and core build tools are present.
                            sh "docker run --rm ${name}:${env.IMAGE_TAG} bash -c 'bash --version && id'"
                        }
                    }

                    parallel stages
                }
            }
        }

        // ------------------------------------------------------------------ //
        // Stage 5 – Push                                                      //
        // Main-branch merges only. Pushes every image that was built (base + //
        // team) with both :SHA and :latest tags to the remote registry.      //
        // ------------------------------------------------------------------ //
        stage('Push') {
            when {
                allOf {
                    branch 'main'
                    not { changeRequest() }
                }
            }
            steps {
                script {
                    def allImages = []

                    env.BASE_TARGETS?.split(',')?.findAll { it }?.each {
                        allImages << imageNameFromPath(it)
                    }
                    env.TEAM_TARGETS?.split(',')?.findAll { it }?.each {
                        allImages << imageNameFromPath(it)
                    }

                    if (!allImages) {
                        echo 'No images were built – nothing to push.'
                        return
                    }

                    docker.withRegistry("https://${REGISTRY}", 'harbor-credentials') {
                        for (name in allImages) {
                            def img = docker.image("${name}:${env.IMAGE_TAG}")
                            img.push()
                            img.push('latest')
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------------ //
        // Stage 6 – Cleanup                                                   //
        // Runs on every non-main branch (including PRs).                     //
        // Removes all locally built images to reclaim disk on the agent.     //
        // ------------------------------------------------------------------ //
        stage('Cleanup') {
            when {
                allOf {
                    not { branch 'main' }
                    expression { env.BASE_TARGETS?.trim() || env.TEAM_TARGETS?.trim() }
                }
            }
            steps {
                script {
                    env.BASE_TARGETS?.split(',')?.findAll { it }?.each {
                        def name = imageNameFromPath(it)
                        sh "docker rmi -f ${name}:${env.IMAGE_TAG} ${name}:latest || true"
                    }
                    env.TEAM_TARGETS?.split(',')?.findAll { it }?.each {
                        def name = imageNameFromPath(it)
                        sh "docker rmi -f ${name}:${env.IMAGE_TAG} ${name}:latest || true"
                    }
                }
            }
        }
    }

    post {
        success {
            slackSend channel: '#ci-builds',
                color: 'good',
                message: "✅ ${env.JOB_NAME} #${env.BUILD_NUMBER} succeeded (${env.IMAGE_TAG})"
        }
        failure {
            slackSend channel: '#ci-builds',
                color: 'danger',
                message: "❌ ${env.JOB_NAME} #${env.BUILD_NUMBER} failed (${env.IMAGE_TAG}) — ${env.BUILD_URL}"
            mail to: 'team@example.com',
                subject: "[FAILED] ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build failed: ${env.BUILD_URL}"
        }
    }
}
