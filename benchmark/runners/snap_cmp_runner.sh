EXECUTABLE_PATH="../build/bin/semproxy"
PROBLEM_SIZE="50 60 70 80 90 100 110 120 130 140 150"
ENABLE_SNAPSHOTS=true
SNAPSHOT_FREQUENCY="50 100 150 200"
MAX_TIME=0.2
RECEIVERS_FILES="1"
FOLDER=$(date '+%Y-%m-%d-%H:%M:%S')

current_dir=$(pwd)
if [[ $current_dir == *benchmark ]]; then
  echo "Compiling project"
else
    echo "cd to benchmark directory to run the benchmark"
    exit 1
fi

mkdir -p ../../build
cd ../../build
cmake ..
make
cd ../benchmark
mkdir -p "${FOLDER}"

echo "Running benchmarks..."
for pb_size in $PROBLEM_SIZE; do
    echo "Problem size: ${pb_size}, Snapshot Frequency: ${snap_freq}"
    "$EXECUTABLE_PATH" --ex ${pb_size} --ey ${pb_size} --ez ${pb_size} --timemax ${MAX_TIME} --snapshot true --save-interval $snap_freq --sismos true --sismos-folder "${FOLDER}" --snap-folder "${FOLDER}" > "${FOLDER}/output_snapshots_${pb_size}_${SNAPSHOT_FREQUENCY}"
    "$EXECUTABLE_PATH" --ex ${pb_size} --ey ${pb_size} --ez ${pb_size} --timemax ${MAX_TIME} > "${FOLDER}/output_snapshots_${pb_size}_no_snap"
done


echo "Formatting results..."
python3 formatter.py "${FOLDER}"

cd "$FOLDER"

Rscript ../version_cmp.R output