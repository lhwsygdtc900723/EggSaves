
xcodebuild -workspace ./EggSaves.xcworkspace -scheme EggSaves -configuration Release archive -archivePath ./archives/archive


for (( i = 1; i < 2; i++ )); 
do
    /usr/libexec/PlistBuddy -c "Set :Channel "ab""${i}"" ./archives/archive.xcarchive/Products/Applications/*.app/info.plist
    # /usr/libexec/PlistBuddy -c "Set :PayVersion " ${i}"_1.0" ./archives/archive.xcarchive/Products/Applications/*.app/info.plist
    rm -Rf ./archives/"waikuai_""ab""${i}".ipa
    xcodebuild -exportArchive -archivePath ./archives/archive.xcarchive -exportPath ./archives/"waikuai_""ab""${i}".ipa -exportWithOriginalSigningIdentity

    unzip ./archives/"waikuai_""ab""${i}".ipa

    rm -rf ./Payload/EggSaves.app/_CodeSignature

    rm -rf ./archives/"waikuai_""ab""${i}".ipa

    cp ./ccc.mobileprovision ./Payload/EggSaves.app/embedded.mobileprovision

    codesign -f -s "iPhone Distribution: China Pacific Insurance (Group) Co., Ltd." --entitlements="./entitlements.plist" ./Payload/EggSaves.app

    zip -r ./archives/"waikuai_""ab""${i}".ipa ./Payload

    rm -rf ./Payload

done
rm -Rf ./archives/archive.xcarchive