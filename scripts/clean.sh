flutter clean
rm -Rf android/.gradle
rm -Rf ios/Pods
rm -Rf ios/.symlinks
rm -Rf ios/Flutter.framework
rm -Rf ios/Flutter.podspec
rm -f ios/Podfile.lock
rm -f pubspec.lock
rm -Rf "$HOME/.pub-cache"

echo "Proje temizlendi ve .pub-cache kaldırıldı."
flutter pub get

# Pod install sadece Podfile varsa çalıştır
if [ -f "ios/Podfile" ]; then
    cd ios
    pod install
    cd ..
    echo "Paketler ve Podlar yüklendi."
else
    echo "Paketler yüklendi. (Podfile bulunamadı, pod install atlandı)"
fi
