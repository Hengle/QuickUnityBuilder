#!/bin/sh

#������õĲ���:
#Build_Target              Unity����ƽ̨ѡ��
#Build_Method            Unity�Ĺ�������
#Bundles_Version        Unity������AB�汾
#Unity_Channel           Unity��������ѡ��
#Development_Build 
#Git_Operate               ��֧����ѡ��    Clean ����ǰ��֧ Stash ���浱ǰ��֧
#Git_Branch                 Git��֧ѡ��

#Fir_Token                   �������й�ƽ̨Fir�˺�ѡ��
#Upload_Bundles        �Ƿ��ϴ���Դ��
#Upload_Fir                 �Ƿ��ϴ��������й�ƽ̨
#Upload_Bugly            �Ƿ��ϴ����ű�
#Write_Macro              ��Ҫд��ĺ�
#Publish_Mode            IOS����ģʽѡ��

echo "--> Get Jenkins Params"

#���ղ���
BUILD_TARGET=$Build_Target
BUILD_METHOD=$Build_Method
GIT_OPERATE=$Git_Operate
GIT_BRANCH=$Git_Branch
UNITY_CHANNEL=$Unity_Channel;
BUNDLES_VERSION=$Bundles_Version;
DEVELOPMENT_BUILD=$Development_Build;
FIR_TOKEN=$Fir_Token
UPLOAD_FIR=$Upload_Fir
UPLOAD_BUGLY=$Upload_Bugly
UPLOAD_BUNDLES=$Upload_Bundles

#�����ǿ��ж�
if [[ ! $BUILD_TARGET || ! $BUILD_METHOD || ! $GIT_OPERATE || ! $GIT_BRANCH || ! $UNITY_CHANNEL || ! $BUNDLES_VERSION || ! $DEVELOPMENT_BUILD ]]; then
  echo "--> Error : Jenkins������õĲ�������, ������һ��Ϊ��, ����"
    exit 1
fi

echo "--> Set Params"

#������Ŀ����
UNITY_PATH="/Applications/Unity/Unity.app/Contents/MacOS/Unity"
BUILD_TIME="`date +%Y%m%d_%H%M`"

if [[ $BUILD_TARGET = "Android" ]]; then
  REMOTE_BUILD_TARGET_NAME="ANDROID"
  PACK_NAME="Android Apk: ";
  PROJ_GIT_PATH="/Users/mac2144/Documents/ylclient_android/ylclient"
  PROJ_PATH="${PROJ_GIT_PATH}/YL"
  BUILD_FILE_NAME="Unity_Android_${UNITY_CHANNEL}_${BUILD_TIME}.apk"
  BUILD_PATH="${PROJ_GIT_PATH}/AutoBuilder/Android/"
  BUILD_LOG_PATH="${PROJ_GIT_PATH}/AutoBuilder/Android/build.log"
  if [[ $BUILD_METHOD = "BuildBundles" ]]; then
    UNITY3D_BUILD_METHOD="JenkinsBuilder.JenkinsBuildAndroidBundles"
  elif  [[ $BUILD_METHOD = "BuildPackage" ]]; then
    UNITY3D_BUILD_METHOD="JenkinsBuilder.JenkinsBuildAndroid"
  else
    UNITY3D_BUILD_METHOD="JenkinsBuilder.JenkinsOnekeyBuildAndroid"
  fi
elif  [[ $BUILD_TARGET = "iOS" ]]; then
  REMOTE_BUILD_TARGET_NAME="IOS"
  PACK_NAME="Xcode Project: ";
  PROJ_GIT_PATH="/Users/mac2144/Documents/ylclient_ios/ylclient"
  PROJ_PATH="${PROJ_GIT_PATH}/YL"
  BUILD_FILE_NAME="Unity_iPhone_${UNITY_CHANNEL}"
  BUILD_PATH="${PROJ_GIT_PATH}/AutoBuilder/IOS"
  BUILD_LOG_PATH="${PROJ_GIT_PATH}/AutoBuilder/IOS/build.log"
  if [[ $BUILD_METHOD = "BuildBundles" ]]; then
    UNITY3D_BUILD_METHOD="JenkinsBuilder.JenkinsBuildIOSBundles"
  elif  [[ $BUILD_METHOD = "BuildPackage" ]]; then
    UNITY3D_BUILD_METHOD="JenkinsBuilder.JenkinsBuildIOS"
  else
    UNITY3D_BUILD_METHOD="JenkinsBuilder.JenkinsOnekeyBuildIOS"
  fi
else 
  echo "Log Error : ����Ĵ��ƽ̨���� : ${BUILD_TARGET}"
    exit 1
fi

BUILD_TOOL_PATH="${PROJ_GIT_PATH}/AutoBuilder/PackTools"

echo "--> Set BUILD_TOOL_PATH : ${BUILD_TOOL_PATH}" 
echo "--> Set PROJ_GIT_PATH : ${PROJ_GIT_PATH}" 
echo "--> Set PROJ_PATH : ${PROJ_PATH}" 
echo "--> Set BUILD_FILE_NAME : ${BUILD_FILE_NAME}" 
echo "--> Set BUILD_PATH : ${BUILD_PATH}" 
echo "--> Set BUILD_LOG_PATH : ${BUILD_LOG_PATH}" 
echo "--> Set UNITY3D_BUILD_METHOD : ${UNITY3D_BUILD_METHOD}" 

echo "--> �л�Ŀ¼�� ${PROJ_GIT_PATH}"
cd ${PROJ_GIT_PATH}

if [[ $GIT_OPERATE = "Stash" ]]; then
  echo "--> ���浱ǰ��֧"
  git fetch
  git stash save "�Զ���� ���ػ��� _${BUILD_TIME}"
elif  [[ $GIT_OPERATE = "Clean" ]]; then
echo "--> ����ǰ��֧"
  git fetch
  git reset --hard
  git clean -df
  if [ $? -ne 0 ];then
    echo "--> Error : Clean ${PROJ_GIT_PATH}"
    exit 1
  fi
else 
  echo "--> Error : GIT_OPERATE Param : ${GIT_OPERATE}"
    exit 1
fi

echo "--> �л�Ŀ¼����֧ ${GIT_BRANCH}"
git checkout -B ${GIT_BRANCH} --track origin/${GIT_BRANCH}
git pull

if [ $? -ne 0 ];then
    echo "--> Error : Checkout ${GIT_BRANCH}"
    exit 1
fi

#�����־�ļ��Ѵ��� ɾ����־�ļ�
if [[ -f $BUILD_LOG_PATH ]]; then
  rm -f $BUILD_LOG_PATH
fi

#UNITY3D_REFRESH_METHOD="JenkinsBuilder.Refresh"
#echo ˢ��Unity����
#$UNITY_PATH -quit -batchmode -nographics -projectPath $PROJ_PATH -executeMethod ${UNITY3D_REFRESH_METHOD} 

echo "--> ִ��Unity�Ĵ������"
$UNITY_PATH -quit -batchmode -nographics -projectPath $PROJ_PATH -executeMethod ${UNITY3D_BUILD_METHOD}  Bundles_Version-$BUNDLES_VERSION Unity_Channel-$UNITY_CHANNEL Development_Build-$DEVELOPMENT_BUILD Build_Path-$BUILD_PATH Build_FileName-$BUILD_FILE_NAME -logFile $BUILD_LOG_PATH


if [[ $BUILD_METHOD = "BuildPackage" || $BUILD_METHOD = "BuildBundlesAndPackage" ]]; then
if  [[ $BUILD_TARGET = "Android" ]]; then
	if [ -f "$BUILD_PATH/$BUILD_FILE_NAME" ] ; then
      echo "--> ${PACK_NAME}${BUILD_FILE_NAME} ���ɳɹ� "
    else
      echo "--> ${PACK_NAME}${BUILD_FILE_NAME} ����ʧ��, Error building Player because scripts had compiler errors "
	  echo `cat ${BUILD_LOG_PATH}`
        exit 1
    fi
elif  [[ $BUILD_TARGET = "iOS" ]]; then
	if [ -d "$BUILD_PATH/$BUILD_FILE_NAME" ] ; then
      echo "--> ${PACK_NAME}${BUILD_FILE_NAME} ���ɳɹ� "
    else
      echo "--> ${PACK_NAME}${BUILD_FILE_NAME} ����ʧ��, Error building Player because scripts had compiler errors "
	  echo `cat ${BUILD_LOG_PATH}`
        exit 1
    fi
else 
  echo "--> Error : ����Ĵ��ƽ̨���� : ${BUILD_TARGET}"
    exit 1
fi
fi

#Xcode�������
if  [[ $BUILD_TARGET = "iOS" ]]; then
  if [[ $BUILD_METHOD = "BuildPackage" || $BUILD_METHOD = "BuildBundlesAndPackage" ]]; then
	
	#Xcode·����ز���
    CONFIGURATION=Release
    SCHEME="Unity-iPhone"
    IPA_OUTPUT_PATH="${BUILD_PATH}/IPA_Output"
    XCODE_PROJ_PATH="${BUILD_PATH}/${BUILD_FILE_NAME}/${SCHEME}.xcodeproj"
    ARCHIVE_PATH="${IPA_OUTPUT_PATH}/${BUILD_FILE_NAME}/${SCHEME}.xcarchive"
    EXPORT_PATH="${IPA_OUTPUT_PATH}/${BUILD_FILE_NAME}"

    if [ ! -d $IPA_OUTPUT_PATH ];then
      mkdir $IPA_OUTPUT_PATH
    fi

	#Xcode����������
	CODE_SIGN_IDENTITY="iPhone Distribution: Shanghai Blademaster Network Technology Co., Ltd."
    PROVISIONING_PROFILE_NAME="ylqt_inhouse"
    EXPORT_OPTION_PLIST=${BUILD_TOOL_PATH}/ExportOptions/exportOptionsPlist.plist
    BUNDLE_IDENTIFIER=com.baiyao.ylqt
	#(K8EN9Z764W)
	# ����ssh����mac���ն�,ǩ����ʱ�����ʾ��User interaction is not allowed.
    # ����Ҫ�ȶ�֤����� ֱ�����ն�ִ�п��Բ���Ҫ
    #UNLOCK=`security show-keychain-info ~/Library/Keychains/login.keychain 2>&1|grep no-timeout`
    #if [ -z "$UNLOCK" ]; then
        # -p �������������,���������ܲ�һ��,Ҫ�޸�
        #security unlock-keychain -p 123u123u ~/Library/Keychains/login.keychain
        # �޸�unlock-keychain����ʱ��,��ô���һ�δ��ʱ��
        #security set-keychain-settings -t 3600000 -l ~/Library/Keychains/login.keychain
    #fi
	
	echo "--> Delete Auto Manage Signing"
	python ${BUILD_TOOL_PATH}/ExportOptions/DeleteAutoManageSigning.py ${BUILD_PATH}/${BUILD_FILE_NAME}/

	echo '--> ����������'
	xcodebuild clean -project ${XCODE_PROJ_PATH} -scheme ${SCHEME} -configuration ${CONFIGURATION} \
	>>${BUILD_LOG_PATH}

	echo '--> �����������-->>>--���ڱ��빤��:'${CONFIGURATION}
	xcodebuild archive -project ${XCODE_PROJ_PATH} \
	-scheme ${SCHEME} -configuration ${CONFIGURATION} -archivePath ${ARCHIVE_PATH} \
	CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" PROVISIONING_PROFILE_SPECIFIER="${PROVISIONING_PROFILE_NAME}" \
	>>${BUILD_LOG_PATH}
	if [ -d "$ARCHIVE_PATH" ] ; then
      echo '--> ��Ŀ����ɹ�'
    else
      echo '--> ��Ŀ����ʧ��'
        exit 1
    fi

	echo '--> ��Ŀ�������-->>>--��ʼIPA���'
	xcodebuild -exportArchive -archivePath ${ARCHIVE_PATH} -configuration ${CONFIGURATION} \
	-exportPath ${EXPORT_PATH} -exportOptionsPlist "$EXPORT_OPTION_PLIST" \
	>>${BUILD_LOG_PATH}
	
	if [ -e "$EXPORT_PATH" ] ; then
      echo '--> ��Ŀ�����ɹ�'
	  open $EXPORT_PATH  # ������ipa�����ļ���  
    else
      echo '--> ��Ŀ����ʧ��'
        exit 1
    fi
  fi
fi

#��˾Fir�˺ŵ�Token  2c5a5ecc1df1a247ce2ce9616dcbb4f6
#����Fir�˺ŵ�Token  95c0c894b9ee035d1cc67761272822fb
#�����ϴ�����

if  [[ $FIR_TOKEN = "piaoyuzc@qq.com" ]]; then
  if [[ $BUILD_TARGET = "Android" ]]; then
    FIR_TOKEN_ID="2c5a5ecc1df1a247ce2ce9616dcbb4f6"
	FIR_SHORT_NAME="ylqtswa"
  else
    FIR_TOKEN_ID="2c5a5ecc1df1a247ce2ce9616dcbb4f6"
	FIR_SHORT_NAME="ylqtswi"
  fi
else
  if [[ $BUILD_TARGET = "Android" ]]; then
    FIR_TOKEN_ID="95c0c894b9ee035d1cc67761272822fb"
	FIR_SHORT_NAME="ylqta"
  else
    FIR_TOKEN_ID="95c0c894b9ee035d1cc67761272822fb"
	FIR_SHORT_NAME="ylqti"
  fi
fi

echo "--> Set FIR_TOKEN : ${FIR_TOKEN}" 
echo "--> Set FIR_TOKEN_ID : ${FIR_TOKEN_ID}" 
echo "--> Set FIR_SHORT_NAME : ${FIR_SHORT_NAME}" 

#Ӧ���ϴ�Fir�������й�
if  [[ $UPLOAD_FIR = "true" ]]; then
echo '--> ����Ӧ�õ� fir.imƽ̨'
  if [[ $BUILD_TARGET = "Android" ]]; then
    UPLOAD_APP_PATH=${BUILD_PATH}/${BUILD_FILE_NAME}
  else
	UPLOAD_APP_PATH=${IPA_OUTPUT_PATH}/${BUILD_FILE_NAME}/${SCHEME}.ipa
  fi

  echo "--> Set UPLOAD_APP_PATH : ${UPLOAD_APP_PATH}" 

    # ��Ҫ���ڱ��ذ�װ fir ���,��װfir�������: gem install fir-cli
    fir login -T ${FIR_TOKEN_ID}  # fir.im token
    fir publish  ${UPLOAD_APP_PATH} --short=${FIR_SHORT_NAME}

    if [ $? = 0 ];then
      echo "--> �ύfir.im�ɹ� "
    else
      echo "--> �ύfir.imʧ�� "
	  exit 1
    fi
fi

if  [[ $UPLOAD_BUGLY = "true" ]]; then
BUGLY_ID="3a46b040bc"
BUGLY_KEY="2501780d-1a32-48c4-80f7-457a1a76df04"
echo '--> �ϴ�Bugly���ű�'
  COMMAND_PATH="${BUILD_TOOL_PATH}/buglySymboliOS"
  SETTINGS_PATH="${BUILD_TOOL_PATH}/buglySymboliOS/settings.txt"
  DSYM_NAME="${ARCHIVE_PATH}/dSYMs/ylqt.app.dSYM"
  sh ${COMMAND_PATH}/buglySymboliOS.sh -i ${DSYM_NAME} -u true -d true -id ${BUGLY_ID} -key ${BUGLY_KEY}
    if [ $? = 0 ];then
      echo "--> �ϴ����ű�ɹ� "
    else
      echo "--> �ϴ����ű�ʧ�� "
    fi
fi

if  [[ $UPLOAD_BUNDLES = "true" ]]; then
echo "--> �ϴ� ${BUILD_TARGET} Bundles"

LOCAL_PATH=${PROJ_GIT_PATH}/AssetsBundle/${UNITY_CHANNEL}/${REMOTE_BUILD_TARGET_NAME}/Uploads/${REMOTE_BUILD_TARGET_NAME}
REMOTE_PATH=/${UNITY_CHANNEL}/

echo "--> Set LOCAL_PATH  : ${LOCAL_PATH}" 
echo "--> Set REMOTE_PATH : ${REMOTE_PATH}" 

if [ ! -d $LOCAL_PATH ];then
  echo "Log Error : ����û����Ҫ�ϴ�����ԴĿ¼ : ${LOCAL_PATH}"
    exit 1
fi

lftp -u hulinchao,hulinchao@123 -p 2122 192.168.10.181 <<EOF
set ftp:list-empty-ok yes
cd /
mkdir -p ${REMOTE_PATH}
cd ${REMOTE_PATH}
lcd ${LOCAL_PATH}
mirror -R ${LOCAL_PATH}
exit
EOF

if [ $? = 0 ];then
   echo "--> �ϴ�${BUILD_TARGET} Bundles�ɹ� "
   
   echo "--> ��ʼˢ��CDN" 

   python $BUILD_TOOL_PATH/Qcloud_CDN_API/QcloudCdnTools_V2.py RefreshCdnDir -u AKIDCCzXq6L0f5GG1XNrlcP3ShgPs52koNIx -p ZtxlIfnfHdjY7QTFl4A2e2B4g27wf8LI --dirs http://res.ylqt.2144gy.com/${UNITY_CHANNEL}/${REMOTE_BUILD_TARGET_NAME}/

   if [ $? = 0 ];then
     echo "--> CDNˢ�³ɹ� "
   else
     echo "--> CDNˢ��ʧ�� "
   fi

else
   echo "--> �ϴ�${BUILD_TARGET} Bundlesʧ�� "
fi

fi