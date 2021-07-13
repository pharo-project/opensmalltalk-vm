def isWindows(){
  //If NODE_LABELS environment variable is null, we assume we are on master unix machine
  if (env.NODE_LABELS == null) {
    return false
  }
    return env.NODE_LABELS.toLowerCase().contains('windows')
}

def shell(params){
    if(isWindows()) bat(params) 
    else sh(params)
}

def isMainBranch(){
	return env.BRANCH_NAME == 'headless'
}

def runInCygwin(command){
	def c = """#!c:\\tools\\cygwin\\bin\\bash --login
    cd `cygpath \"$WORKSPACE\"`
    set -ex
    ${command}
    """
    
    echo("Executing: ${c}")
    withEnv(["PHARO_CI_TESTING_ENVIRONMENT=true"]) {    
      return sh(c)
    }
}

def buildGTKBundle(){
	node("unix"){
		cleanWs()
		stage("build-GTK-bundle"){

			def commitHash = checkout(scm).GIT_COMMIT

			unstash name: "packages-Windows-x86_64-CoInterpreter"
			def shortGitHash = commitHash.substring(0,8)
			def gtkBundleName = "PharoVM-8.1.0-GTK-${shortGitHash}-win64-bin.zip"

			dir("build"){
				shell "wget http://files.pharo.org/vm/pharo-spur64/win/third-party/Gtk3.zip"
				shell "unzip Gtk3.zip -d ./bundleGTK"
				shell "unzip -n build/packages/PharoVM-*-Windows-x86_64-bin.zip -d ./bundleGTK"

				dir("bundleGTK"){
					shell "zip -r -9 ../${gtkBundleName} *"
				}
			
				stash includes: "${gtkBundleName}", name: "packages-Windows-x86_64-gtkBundle"
				archiveArtifacts artifacts: "${gtkBundleName}"
				
				if(!isPullRequest() && isMainBranch()){
					sshagent (credentials: ['b5248b59-a193-4457-8459-e28e9eb29ed7']) {
						sh "scp -o StrictHostKeyChecking=no \
						${gtkBundleName} \
						pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/win/${gtkBundleName}"

						sh "scp -o StrictHostKeyChecking=no \
						${gtkBundleName} \
						pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/win/latest-win64-GTK.zip"
					}
				}
			}
		}
	}
}
def recordCygwinVersions(buildDirectory){
    runInCygwin "cd ${buildDirectory} &&  cygcheck -c -d > cygwinVersions.txt"
	archiveArtifacts artifacts: "${buildDirectory}/cygwinVersions.txt"
}

def runBuild(platformName, configuration, headless = true){
	cleanWs()
	
	def platform = headless ? platformName : "${platformName}-stockReplacement"
	def buildDirectory = headless ? "build" :"build-stockReplacement"
	def additionalParameters = headless ? "" : "-DALWAYS_INTERACTIVE=1"

  stage("Checkout-${platform}"){
    dir('repository') {
        checkout scm
    }
  }

	stage("Build-${platform}-${configuration}"){
    if(isWindows()){
      runInCygwin "mkdir ${buildDirectory}"
      recordCygwinVersions(buildDirectory)
      runInCygwin "cd ${buildDirectory} && cmake -DFLAVOUR=${configuration} ${additionalParameters} -DPHARO_DEPENDENCIES_PREFER_DOWNLOAD_BINARIES=TRUE ../repository -DICEBERG_DEFAULT_REMOTE=httpsUrl"
      runInCygwin "cd ${buildDirectory} && VERBOSE=1 make install"
      runInCygwin "cd ${buildDirectory} && VERBOSE=1 make package"
    }else{
      cmakeBuild generator: "Unix Makefiles", cmakeArgs: "-DFLAVOUR=${configuration} ${additionalParameters} -DPHARO_DEPENDENCIES_PREFER_DOWNLOAD_BINARIES=TRUE -DICEBERG_DEFAULT_REMOTE=httpsUrl", sourceDir: "repository", buildDir: "${buildDirectory}", installation: "InSearchPath"
      dir("${buildDirectory}"){
        shell "VERBOSE=1 make install"
        shell "VERBOSE=1 make package"
      }
    }
	
		stash excludes: '_CPack_Packages', includes: "${buildDirectory}/build/packages/*", name: "packages-${platform}-${configuration}"
		archiveArtifacts artifacts: "${buildDirectory}/build/packages/*", excludes: '_CPack_Packages'
	}
}

def runUnitTests(platform){
  cleanWs()

  stage("VM Unit Tests"){
    dir('repository') {
      checkout scm
    }

    cmakeBuild generator: "Unix Makefiles", cmakeArgs: "-DPHARO_DEPENDENCIES_PREFER_DOWNLOAD_BINARIES=TRUE", sourceDir: "repository", buildDir: "runTests", installation: "InSearchPath"
    dir("runTests"){
      shell "VERBOSE=1 make vmmaker"
      dir("build/vmmaker"){
        shell "wget https://files.pharo.org/vm/pharo-spur64/Darwin-x86_64/third-party/libllvm-full.zip"
        shell "unzip libllvm-full.zip -d ./vm/Contents/MacOS/Plugins"
        shell "wget https://files.pharo.org/vm/pharo-spur64/Darwin-x86_64/third-party/libunicorn.zip"
        shell "unzip libunicorn.zip  -d ./vm/Contents/MacOS/Plugins"

        timeout(20){
          shell "PHARO_CI_TESTING_ENVIRONMENT=true  ./vm/Contents/MacOS/Pharo --headless --logLevel=4 ./image/VMMaker.image test --junit-xml-output 'VMMakerTests'"
         } 
        // Stop if tests fail
        // Archive xml reports either case
        try {
          junit allowEmptyResults: true, testResults: "*.xml"
        } catch (ex) {
          if (currentBuild.result == 'UNSTABLE'){
            currentBuild.result = 'FAILURE'
          }
          archiveArtifacts artifacts: '*.xml'
        }
        
      }
    }
  }
}

def runTests(platform, configuration, packages, withWorker){
  cleanWs()

  def stageName = withWorker ? "Tests-${platform}-${configuration}-worker" : "Tests-${platform}-${configuration}"
  def hasWorker = withWorker ? "--worker" : ""

	stage(stageName){
		unstash name: "packages-${platform}-${configuration}"
		shell "mkdir runTests"
		dir("runTests"){
			try{
				shell "wget -O - get.pharo.org/64/90 | bash "
				shell "echo 90 > pharo.version"
          
				if(isWindows()){
					runInCygwin "cd runTests && unzip ../build/build/packages/PharoVM-*-${platform}-bin.zip -d ."
					runInCygwin "PHARO_CI_TESTING_ENVIRONMENT=true cd runTests && ./PharoConsole.exe  --logLevel=4 ${hasWorker} Pharo.image test --junit-xml-output --stage-name=${stageName} '${packages}'"
					} else {
						shell "unzip ../build/build/packages/PharoVM-*-${platform}-bin.zip -d ."

						if(platform == 'Darwin-x86_64' || platform == 'Darwin-arm64'){
							shell "PHARO_CI_TESTING_ENVIRONMENT=true ./Pharo.app/Contents/MacOS/Pharo --logLevel=4 ${hasWorker} Pharo.image test --junit-xml-output --stage-name=${stageName} '${packages}'"
						}

						if(platform == 'Linux-x86_64'){
							shell "PHARO_CI_TESTING_ENVIRONMENT=true ./pharo --logLevel=4 ${hasWorker} Pharo.image test --junit-xml-output --stage-name=${stageName} '${packages}'" 
						}
				}
				junit allowEmptyResults: true, testResults: "*.xml"
			} finally{
				if(fileExists('PharoDebug.log')){
					shell "mv PharoDebug.log PharoDebug-${stageName}.log"
					 archiveArtifacts allowEmptyArchive: true, artifacts: "PharoDebug-${stageName}.log", fingerprint: true
				}
				if(fileExists('crash.dmp')){
					shell "mv crash.dmp crash-${stageName}.dmp"
					archiveArtifacts allowEmptyArchive: true, artifacts: "crash-${stageName}.dmp", fingerprint: true
				}
				if(fileExists('progress.log')){
					shell "mv progress.log progress-${stageName}.log"
					shell "cat progress-${stageName}.log"
					archiveArtifacts allowEmptyArchive: true, artifacts: "progress-${stageName}.log", fingerprint: true
				}
			}
		}
		archiveArtifacts artifacts: 'runTests/*.xml', excludes: '_CPack_Packages'
	}
}

def upload(platform, configuration, archiveName) {

	cleanWs()

	unstash name: "packages-${platform}-${configuration}"

	def expandedBinaryFileName = sh(returnStdout: true, script: "ls build/build/packages/PharoVM-*-${archiveName}-bin.zip").trim()
	def expandedCSourceFileName = sh(returnStdout: true, script: "ls build/build/packages/PharoVM-*-${archiveName}-c-src.zip").trim()
	def expandedHeadersFileName = sh(returnStdout: true, script: "ls build/build/packages/PharoVM-*-${archiveName}-include.zip").trim()
	def expandedLibFileName = sh(returnStdout: true, script: "ls build/build/packages/PharoVM-*-${archiveName}-lib.zip").trim()


	sshagent (credentials: ['b5248b59-a193-4457-8459-e28e9eb29ed7']) {
		sh "scp -o StrictHostKeyChecking=no \
		${expandedBinaryFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${platform}"
		sh "scp -o StrictHostKeyChecking=no \
		${expandedBinaryFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${platform}/latest.zip"

		sh "scp -o StrictHostKeyChecking=no \
		${expandedHeadersFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${platform}/include"
		sh "scp -o StrictHostKeyChecking=no \
		${expandedHeadersFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${platform}/include/latest.zip"

		sh "scp -o StrictHostKeyChecking=no \
		${expandedCSourceFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${platform}/source"
		sh "scp -o StrictHostKeyChecking=no \
		${expandedCSourceFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${platform}/source/latest.zip"

		sh "scp -o StrictHostKeyChecking=no \
		${expandedLibFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${platform}/lib"
		sh "scp -o StrictHostKeyChecking=no \
		${expandedLibFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64-headless/${platform}/lib/latest.zip"
	}
}

def uploadStockReplacement(platform, configuration, archiveName) {

	cleanWs()

	unstash name: "packages-${archiveName}-${configuration}"

	def expandedBinaryFileName = sh(returnStdout: true, script: "ls build-stockReplacement/build/packages/PharoVM-*-${archiveName}-bin.zip").trim()

	sshagent (credentials: ['b5248b59-a193-4457-8459-e28e9eb29ed7']) {
		sh "scp -o StrictHostKeyChecking=no \
		${expandedBinaryFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64/${platform}"
		sh "scp -o StrictHostKeyChecking=no \
		${expandedBinaryFileName} \
		pharoorgde@ssh.cluster023.hosting.ovh.net:/home/pharoorgde/files/vm/pharo-spur64/${platform}/latestReplacement.zip"
	}
}


def isPullRequest() {
  return env.CHANGE_ID != null
}

def uploadPackages(platformNames){
	node('unix'){
		stage('Upload'){
			if (isPullRequest()) {
				//Only upload files if not in a PR (i.e., CHANGE_ID not empty)
				echo "[DO NO UPLOAD] In PR " + (env.CHANGE_ID?.trim())
				return;
			}

			if(!isMainBranch()){
				echo "[DO NO UPLOAD] In branch different that 'headless': ${env.BRANCH_NAME}";
				return;
			}

			for (platformName in platformNames) {
				upload(platformName, "CoInterpreter", platformName)
				uploadStockReplacement(platformName, "CoInterpreter", "${platformName}-stockReplacement")
			}
		}
	}
}

try{
	properties([disableConcurrentBuilds()])

	def platforms = ['Linux-x86_64', 'Darwin-x86_64', 'Windows-x86_64', 'Darwin-arm64']
	def builders = [:]
	def tests = [:]

  node('Darwin-x86_64'){
    runUnitTests('Darwin-x86_64')
  }

  for (platf in platforms) {
        // Need to bind the label variable before the closure - can't do 'for (label in labels)'
        def platform = platf
		
		builders[platform] = {
			node(platform){
				timeout(30){
					runBuild(platform, "CoInterpreter")
				}
				timeout(30){
					// Only build the Stock replacement version in the main branch
					if(isMainBranch()){
						runBuild(platform, "CoInterpreter", false)
					}
				}
			}
		}
		
		tests[platform] = {
			node(platform){
				timeout(45){
					runTests(platform, "CoInterpreter", ".*", false)
				}
				timeout(45){
					runTests(platform, "CoInterpreter", ".*", true)
				}				
			}
		}
	}

	parallel builders
	
	uploadPackages(platforms)

	buildGTKBundle()

	parallel tests

} catch (e) {
  throw e
}
