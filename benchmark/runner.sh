EXECUTABLE_PATH="../build/bin/semproxy"
PROBLEM_SIZE="20"
ENABLE_SNAPSHOTS=false
SNAPSHOT_FREQUENCY=20
MAX_TIME=0.2
RECEIVERS_FILES="1"

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

echo "Running benchmarks..."
for pb_size in $PROBLEM_SIZE; do
    for recv_file in $RECEIVERS_FILES; do
        echo "Problem size: ${pb_size}, Receivers file: ${recv_file}"
        if [[ "$ENABLE_SNAPSHOTS" == false ]] ; then
            "$EXECUTABLE_PATH" --ex ${pb_size} --timemax ${MAX_TIME} > "./output_no_snapshots_${pb_size}"
        else
            "$EXECUTABLE_PATH" --ex ${pb_size} --timemax ${MAX_TIME} --snapshot > "./output_snapshots_${pb_size}_${SNAPSHOT_FREQUENCY}"
        fi
    done

done