@REM ----------------------------------------------------------------------------
@REM Licensed to the Apache Software Foundation (ASF) under one
@REM or more contributor license agreements.  See the NOTICE file
@REM distributed with this work for additional information
@REM regarding copyright ownership.  The ASF licenses this file
@REM to you under the Apache License, Version 2.0 (the
@REM "License"); you may not use this file except in compliance
@REM with the License.  You may obtain a copy of the License at
@REM
@REM    http://www.apache.org/licenses/LICENSE-2.0
@REM
@REM Unless required by applicable law or agreed to in writing,
@REM software distributed under the License is distributed on an
@REM "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
@REM KIND, either express or implied.  See the License for the
@REM specific language governing permissions and limitations
@REM under the License.
@REM ----------------------------------------------------------------------------

@REM ----------------------------------------------------------------------------
@REM Apache Maven Wrapper startup batch script, version 3.2.0
@REM ----------------------------------------------------------------------------

@IF "%__MVNW_ARG0_NAME__%"=="" (SET __MVNW_ARG0_NAME__=%~nx0)
@SET __MVNW_CMD__=
@SET __MVNW_ERROR__=
@SET __MVNW_SAVE_ERRORLEVEL__=
@SET __MVNW_SAVE_CD__=%CD%
@SETLOCAL

@SET __MVNW_WRAPPER_JAR__="%~dp0.mvn\wrapper\maven-wrapper.jar"
@SET __MVNW_WRAPPER_PROPERTIES__="%~dp0.mvn\wrapper\maven-wrapper.properties"

@FOR /F "usebackq tokens=1,2 delims==" %%a IN (%__MVNW_WRAPPER_PROPERTIES__%) DO @(
  IF "%%a"=="distributionUrl" SET __MVNW_DISTRIBUTION_URL__=%%b
  IF "%%a"=="projectDir" SET __MVNW_CUSTOM_USER_HOME__=%%b
)

@SET JAVA_HOME_PARENT="%JAVA_HOME%"
@IF NOT DEFINED JAVA_HOME SET JAVA_HOME=C:\Program Files\Java\jdk-21

@IF NOT EXIST %__MVNW_WRAPPER_JAR__% (
  ECHO Wrapper JAR not found. Trying to download it from: %__MVNW_DISTRIBUTION_URL__%
)

@"%JAVA_HOME%\bin\java.exe" -cp %__MVNW_WRAPPER_JAR__% org.apache.maven.wrapper.MavenWrapperMain %*
@SET MVNW_EXITCODE=%ERRORLEVEL%
@CD /D "%__MVNW_SAVE_CD__%"
@EXIT /B %MVNW_EXITCODE%
