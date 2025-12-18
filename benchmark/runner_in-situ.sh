EXECUTABLE_PATH="../build/bin/semproxy"
PROBLEM_SIZE="30"
ENABLE_SNAPSHOTS=false
SNAPSHOT_FREQUENCY=50
MAX_TIME=2.0
RECEIVERS_FILES="1"
FOLDER=$(date '+%Y-%m-%d-%H:%M:%S')

current_dir=$(pwd)
if [[ $current_dir == *benchmark ]]; then
  echo "Compiling project"
else
    echo "cd to benchmark directory to run the benchmark"
    exit 1
fi

mkdir -p ../build
cd ../build
cmake ..
make
cd ../benchmark
mkdir -p "${FOLDER}"

echo "Running benchmarks..."
for pb_size in $PROBLEM_SIZE; do
    for recv_file in $RECEIVERS_FILES; do
        echo "Problem size: ${pb_size}, Receivers file: ${recv_file}"
        if [[ "$ENABLE_SNAPSHOTS" == false ]] ; then
            "$EXECUTABLE_PATH" --ex ${pb_size} --ey ${pb_size} --ez ${pb_size} --timemax ${MAX_TIME} --sismos true --sismos-folder "${FOLDER}" --snap-folder "${FOLDER}" --in-situ > "${FOLDER}/output_no_snapshots_${pb_size}"
        else
            "$EXECUTABLE_PATH" --ex ${pb_size} --ey ${pb_size} --ez ${pb_size} --timemax ${MAX_TIME} --snapshot true --save-interval $SNAPSHOT_FREQUENCY --sismos true --sismos-folder "${FOLDER}" --snap-folder "${FOLDER}" --in-situ > "${FOLDER}/output_snapshots_${pb_size}_${SNAPSHOT_FREQUENCY}"
        fi
    done
done

cd "$FOLDER"

echo "ffconcat version 1.0" > concat.txt 
for image in *.ppm; do
    echo "file ${image}" >> concat.txt
done
ffmpeg -f concat -safe 0 -r 1 -i concat.txt animation.mp4