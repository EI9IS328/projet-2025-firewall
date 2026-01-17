EXECUTABLE_PATH="../build/bin/semproxy"
PROBLEM_SIZE="50 60 70 80 90 100 110 120 130 140 150"
ENABLE_SNAPSHOTS=true
SNAPSHOT_FREQUENCY="50"
MAX_TIME=1.2
RECEIVERS_FILES="1"
COMPARE_WITH_SLICES="true"
FOLDER="/tmp/$(date '+%Y-%m-%d-%H:%M:%S')"
current_dir=$(pwd)
CSV_FILE="$current_dir/benchmarks_results.csv"

echo "problem_size,execution_time_seconds" > "$CSV_FILE"

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
for pb_size in $PROBLEM_SIZE; do
    echo "creating folder for size ${pb_size}"
    mkdir -p "${FOLDER}_output_size${pb_size}"
done
mkdir -p "${FOLDER}"

echo "Running benchmarks..."
for pb_size in $PROBLEM_SIZE; do
    echo "Problem size: ${pb_size}, Snapshot Frequency: ${SNAPSHOT_FREQUENCY}"

    "$EXECUTABLE_PATH" --ex ${pb_size} --ey ${pb_size} --ez ${pb_size} --timemax ${MAX_TIME} --snapshot true --save-interval $SNAPSHOT_FREQUENCY --sismos true --sismos-folder "${FOLDER}_output_size${pb_size}" --snap-folder "${FOLDER}_output_size${pb_size}" > "${FOLDER}/output_snapshots_${pb_size}_${SNAPSHOT_FREQUENCY}"

done

for pb_size in $PROBLEM_SIZE; do

    start_time=$(date +%s.%N)
    echo "Formatting results..."
    python3 formatter.py "${FOLDER}_output_size${pb_size}"

    cd "${FOLDER}_output_size${pb_size}"

    echo "Generating plots..."

    for snapshot in *.snapshot; do
        Rscript "$current_dir/../pressure_map.R" $snapshot

    done


    for sismos in *.sismos; do
        Rscript "$current_dir"/../sismos_plot.R $sismos
    done

    Rscript "$current_dir/../version_cmp.R" output

    echo "ffconcat version 1.0" > concat.txt 
    for image in *.png; do
        echo "file ${image}" >> concat.txt
    done
    ffmpeg -f concat -safe 0 -r 1 -i concat.txt animation.mp4
    
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    echo "${pb_size},${duration}" >> "$CSV_FILE"
    echo "Finished size ${pb_size} in ${duration} seconds."

    cd "$current_dir/.."
done

Rscript "$current_dir/../plot_performance.R" "$CSV_FILE"
