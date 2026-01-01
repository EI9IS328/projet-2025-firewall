EXECUTABLE_PATH="../build/bin/semproxy"
PROBLEM_SIZE="20"
ENABLE_SNAPSHOTS=true
SNAPSHOT_FREQUENCY=50
MAX_TIME=0.2
RECEIVERS_FILES="1"
FOLDER="/tmp/$(date '+%Y-%m-%d-%H:%M:%S')"

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
        "$EXECUTABLE_PATH" --ex ${pb_size} --timemax ${MAX_TIME} --snapshot true --save-interval $SNAPSHOT_FREQUENCY --slices --sismos true --sismos-folder "${FOLDER}" --snap-folder "${FOLDER}" > "${FOLDER}/output_snapshots_${pb_size}_${SNAPSHOT_FREQUENCY}"
    done
done

echo "Formatting results..."
python3 formatter.py "${FOLDER}"

cd "$FOLDER"

echo "Generating plots..."
for file_xy in snapshot_xy_*.snapshot; do
    
    suffix="${file_xy#snapshot_xy_}"
    id="${suffix%.snapshot}"
    
    snapshot_xy="snapshot_xy_${id}.snapshot"
    snapshot_xz="snapshot_xz_${id}.snapshot"
    snapshot_yz="snapshot_yz_${id}.snapshot"

    if [[ -f "$snapshot_xz" && -f "$snapshot_yz" ]]; then
        echo "Processing ID: $id | Files: $snapshot_xy, $snapshot_xz, $snapshot_yz"
        Rscript "$current_dir/pressure_map_slice.R" "$snapshot_xy" "$snapshot_xz" "$snapshot_yz"
    else
        echo "Warning: Missing matching files for ID $id"
    fi
done

echo "ffconcat version 1.0" > concat.txt 
for image in *.png; do
    echo "file ${image}" >> concat.txt
done
ffmpeg -f concat -safe 0 -r 1 -i concat.txt animation.mp4