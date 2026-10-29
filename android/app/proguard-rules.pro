# The Room 2.2.5 consumer rule only keeps the database class. R8 full mode
# also needs its no-argument constructor, which Room invokes by reflection.
# WorkManager (a Mobile Ads dependency) creates this database before Flutter starts.
# Upstream fix: https://android.googlesource.com/platform/frameworks/support/+/e4765e38e27a3f4d86188b996df97a52403dff46
-keep class * extends androidx.room.RoomDatabase { void <init>(); }
