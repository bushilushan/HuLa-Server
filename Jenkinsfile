#!groovy
pipeline {
    agent any

    tools {
        maven 'maven'
    }

    environment {
        // ====== luohuo-cloud 使用的变量 ======
        JAR_NAME = "${SERVER_NAME}-server"

        // 推送时需要忽略的项目前缀
        removePrefix = "${SERVER_NAME}/${JAR_NAME}/target/"

        // 需要推送到服务器端的文件(jar)
        sourceFiles = "${SERVER_NAME}/${JAR_NAME}/target/${JAR_NAME}.jar"
    }

    stages {

        stage('编译 luohuo-util 模块') {
            steps {
                echo "maven 本地编译 luohuo-util 模块"
                dir('luohuo-util') {
                    sh "pwd"
                    sh '''
                        mvn clean ${MAVEN_COMMAND} \
                        -T8 \
                        -Dmaven.compile.fork=true \
                        -Dmaven.test.skip=true
                    '''
                }
            }
        }

        stage('luohuo-cloud 替换环境参数') {
            steps {
                dir('luohuo-cloud') {
                    script {
                        // 工作空间（相对于 luohuo-cloud）
                        WORKSPACE_HOME = "src/main"

                        // 服务端执行的脚本
                        EXEC_COMMAND = "bash -x -s < ${WORKSPACE_HOME}/bin/run.sh ${JAR_NAME} ${SERVER_NAME} ${PROFILES} ${ACTION}"

                        echo "您选择了如下参数："
                        echo "拉取分支：${branch}"
                        echo "打包命令：${MAVEN_COMMAND}"
                        echo "运行环境参数：${PROFILES}"
                        echo "启动动作：${ACTION}"
                    }
                }
            }
        }

        stage('编译 luohuo-cloud 模块') {
            steps {
                dir('luohuo-cloud') {
                    script {
                        if ("${MAVEN_COMMAND}" != "none") {
                            sh '''
                                mvn clean ${MAVEN_COMMAND} \
                                -T2 \
                                -Dmaven.compile.fork=true \
                                -Dmaven.test.skip=true \
                                -P ${PROFILES}
                            '''
                        } else {
                            echo "无需编译项目（适用于代码没有改动的场景）"
                        }
                    }
                }
            }
        }
    }
}
