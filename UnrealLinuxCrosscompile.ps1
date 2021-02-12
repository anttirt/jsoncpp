$linuxRoot = 'D:\UE\Toolchains\v17_clang-10.0.1-centos7\x86_64-unknown-linux-gnu'
$architectureTriple ='x86_64-unknown-linux-gnu'
$engineSource = 'D:/UE/Engine/source-4.26/Engine/Source'

$jsoncpp_files = @(
    "src/lib_json/json_reader.cpp";
    "src/lib_json/json_value.cpp";
    "src/lib_json/json_writer.cpp";
)

# these flags were adapted from the file
# Intermediate\Build\Linux\...\*.cpp.o.rsp
# after a linux cross-compile via UAT
#

$CXXFLAGS = @(
    "-pthread";
    "-DHAVE_PTHREAD=1";
    "-DGSDK_LINUX";
    "-Iinclude";
    "-Isrc/lib_json";
    "-c";
    "-nostdinc++";
    "-I${engineSource}/ThirdParty/Linux/LibCxx/include/";
    "-I${engineSource}/ThirdParty/Linux/LibCxx/include/c++/v1";
    "-Wall";
    "-Werror";
    "-Wsequence-point";
    "-Wdelete-non-virtual-dtor";
    "-fno-math-errno";
    "-fno-rtti";
    "-mssse3";
    "-fvisibility-ms-compat";
    "-fvisibility-inlines-hidden";
    "-fdiagnostics-format=msvc";
    "-fdiagnostics-absolute-paths";
    "-Wno-unused-private-field";
    "-Wno-tautological-compare";
    "-Wno-undefined-bool-conversion";
    "-Wno-unused-local-typedef";
    "-Wno-inconsistent-missing-override";
    "-Wno-undefined-var-template";
    "-Wno-unused-lambda-capture";
    "-Wno-unused-variable";
    "-Wno-unused-function";
    "-Wno-unused-value";
    "-Wno-switch";
    "-Wno-unknown-pragmas";
    "-Wno-invalid-offsetof";
    "-Wno-gnu-string-literal-operator-template";
#    "-Wshadow";
    "-Wundef";
    "-gdwarf-4";
    "-ggnu-pubnames";
    "-O2";
    "-ffunction-sections";
    "-fdata-sections";
    "-fexceptions";
    "-DPLATFORM_EXCEPTIONS_DISABLED=0";
    "-D_LINUX64";
    "-target"; "x86_64-unknown-linux-gnu";
    "--sysroot=$linuxRoot";
    "-x"; "c++";
    "-std=c++14";
)

rm -re -fo -ea 0 obj/ | out-null
rm -re -fo -ea 0 lib/ | out-null

get-job | remove-job

$pwd=$(get-location).path

$block = {
    Param([string] $src)
    cd $using:pwd
    $obj = $src.Replace('src/', 'obj/').Replace('.cpp', '.o')
    $objPath = split-path $obj
    md $objPath -ea 0 | out-null
    echo "$using:linuxRoot/bin/clang++.exe $($using:CXXFLAGS -join " ") -c $src -o $obj"
    &     $using:linuxRoot/bin/clang++.exe @using:CXXFLAGS              -c $src -o $obj
}

$maxthreads = 12

foreach ($src in $jsoncpp_files) {
    while ($(get-job -state running).count -ge $maxthreads) {
        start-sleep -milliseconds 3
    }
    start-job -scriptblock $block -argumentlist $src | out-null
}

while ($(get-job -state running).count -gt 0) {
    start-sleep 1
}

foreach ($job in get-job) {
    receive-job -id ($job.id)
}

get-job | remove-job

md lib -ea 0 | out-null

$jsoncpp_objs = @($jsoncpp_files | %{ $_.Replace('.cpp', '.o').Replace('src/', 'obj/') })

echo "$linuxRoot/bin/llvm-ar rc lib/libjsoncpp.a $($jsoncpp_objs -join " ")"
&     $linuxRoot/bin/llvm-ar rc lib/libjsoncpp.a @jsoncpp_objs


