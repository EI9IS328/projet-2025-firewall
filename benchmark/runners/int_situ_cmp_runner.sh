EXECUTABLE_PATH="../build/bin/semproxy"
PROBLEM_SIZE="50 60 70 80 90 100 110 120"
ENABLE_SNAPSHOTS=true
SNAPSHOT_FREQUENCY="50"
MAX_TIME=2.0
RECEIVERS_FILES="1"
COMPARE_WITH_SLICES="true"
FOLDER=$(date '+%Y-%m-%d-%H:%M:%S')

current_dir=$(pwd)
if [[ $current_dir == *runners ]]; then
  echo "Compiling project"
else
    echo "cd to runners directory to run the benchmark"
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
    echo "Problem size: ${pb_size}, Snapshot Frequency: ${SNAPSHOT_FREQUENCY}, Compare with slices: ${COMPARE_WITH_SLICES}"
    "$EXECUTABLE_PATH" --ex ${pb_size} --ey ${pb_size} --ez ${pb_size} --timemax ${MAX_TIME} --snapshot true --save-interval 50 --sismos true --sismos-folder "${FOLDER}" --snap-folder "${FOLDER}" --slices > "${FOLDER}/output_snapshots_${pb_size}_slice_50"
    "$EXECUTABLE_PATH" --ex ${pb_size} --ey ${pb_size} --ez ${pb_size} --timemax ${MAX_TIME} --snapshot true --save-interval 200 --sismos true --sismos-folder "${FOLDER}" --snap-folder "${FOLDER}" > "${FOLDER}/output_snapshots_${pb_size}_snap_200"
    "$EXECUTABLE_PATH" --ex ${pb_size} --ey ${pb_size} --ez ${pb_size} --timemax ${MAX_TIME} --in-situ --sismos > "${FOLDER}/output_snapshots_${pb_size}_in_situ"
    "$EXECUTABLE_PATH" --ex ${pb_size} --ey ${pb_size} --ez ${pb_size} --timemax ${MAX_TIME} > "${FOLDER}/output_snapshots_${pb_size}_ref"
done


echo "Formatting results..."
python3 formatter.py "${FOLDER}"

cd "$FOLDER"

Rscript ../version_cmp.R output