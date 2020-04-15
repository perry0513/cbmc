#!/usr/bin/env bash

#!/bin/bash

#NAME="final_run"
set -e 

BUCKETNAME="s3://xen-paper-bucket"
XSA_num=$1
depth=$2
unwinding=$3
preserve_direct_paths=$4
full_slice=$5
FP_removal=$6
minimise_trace=0
NAME=$7
if [ -z "$XSA_num" ]; then
    error "No XSA number given"
fi

if [ -z "${depth}" ]; then
    depth=0
fi

if [ -z "${unwinding}" ]; then
    unwinding=1
fi

if [ -z "${preserve_direct_paths}" ]; then
    preserve_direct_paths=0
fi

if [ -z "${full_slice}" ]; then
    full_slice=0
fi

if [ -z "$NAME" ]; then
  NAME="final_run"
fi  


SLICE_options="--aggressive-slice --aggressive-slice-call-depth ${depth} "

CBMC_options=" --stop-on-fail --object-bits 16 --trace --trace-show-function-calls --trace-show-code --trace-hex --no-sat-preprocessor --unwind ${unwinding} "

if [ ${preserve_direct_paths} -ne 0 ]; then
 SLICE_options="$SLICE_options --aggressive-slice-preserve-all-direct-paths "
fi

BASE=xsa$XSA_num
DIR=xsa$XSA_num-${depth}${unwinding}${preserve_direct_paths}
mkdir "$DIR"
cp xen-syms.binary "$DIR"
#cp xen-syms-norbert.binary "$DIR"
cp -- *.o "$DIR"
cd "$DIR" || exit


echo "Start analysis: $(date +%s)" |& tee "$BASE.sliced.trace"


case "$1" in

200) echo "XSA 200"
    goto-cc xen-syms.binary harness.o  -o "$BASE.tmp.binary"
    goto-cc --function main "$BASE.tmp.binary" -o "$BASE.binary"
    PROPERTY="x86_emulate.assertion.1"
    ;;

212) echo "XSA 212"
    goto-cc --function do_memory_op xen-syms.binary -o "$BASE.binary"
    PROPERTY="memory_exchange.assertion.1"
    ;;

213) echo "XSA 213"
	goto-cc xen-syms.binary multicallstub.o -o "$BASE.tmp.binary"
    goto-cc --function do_multicall_stub "$BASE.tmp.binary" -o "$BASE.binary"
    PROPERTY="mod_l4_entry.assertion.1"
    ;;

227) echo "XSA 227"
    goto-cc --function my_granttable_init xen-syms.binary -o "$BASE.binary"
    PROPERTY="create_grant_pte_mapping.assertion.1"
    ;;

238) echo "XSA 238"
    goto-cc xen-syms.binary stub_syscall.o -o "$BASE.tmp.binary"
    goto-cc --function start_function "$BASE.tmp.binary" -o "$BASE.binary"
    PROPERTY="hvm_unmap_io_range_from_ioreq_server.assertion.1"
    ;;

238b) echo "XSA 238"
    goto-cc xen-syms.binary stub_syscall.o -o "$BASE.tmp.binary"
    goto-cc --function start_function "$BASE.tmp.binary" -o "$BASE.binary"
    PROPERTY="hvm_map_io_range_to_ioreq_server.assertion.1"
    ;;

 *) error "XSA number not found"
    exit 1
    ;;

esac

case "$FP_removal" in
0) echo "default FP removal " |& tee -a "$BASE.sliced.log"
	goto-instrument --remove-function-pointers "$BASE.binary" tmp.binary
	mv tmp.binary "$BASE.binary"
	;;
1) echo "moderate FP removal " |& tee -a "$BASE.sliced.log"
	goto-instrument --moderate-function-pointer-removal "$BASE.binary" tmp.binary
	mv tmp.binary "$BASE.binary"
	;;
2) echo "extreme FP removal " |& tee -a "$BASE.sliced.log"
	goto-instrument --extreme-function-pointer-removal "$BASE.binary" tmp.binary
	mv tmp.binary "$BASE.binary"
	;;

*) echo "default FP removal " |& tee -a "$BASE.sliced.log"
	goto-instrument --remove-function-pointers "$BASE.binary" tmp.binary
	mv tmp.binary "$BASE.binary"
	;;
esac

echo "Slicing: $SLICE_options"
( time goto-instrument --timestamp monotonic $SLICE_options --property $PROPERTY $BASE.binary $BASE.sliced.binary ) |& tee  "$BASE.sliced.log"

if [ ${full_slice} -ne 0 ]; then
echo "Running full slicer" |& tee -a "$BASE.sliced.log"
( time goto-instrument --timestamp monotonic --full-slice --property $PROPERTY $BASE.sliced.binary $BASE.sliced2.binary ) |& tee -a "$BASE.sliced.log"
cp "$BASE.sliced2.binary" "$BASE.sliced.binary"
fi


echo "Done slicing $(date +%s)" |& tee -a "$BASE.sliced.trace"

goto-instrument --count-eloc "$BASE.sliced.binary" |tee -a "$BASE.sliced.trace"
goto-instrument --count-eloc "$BASE.binary" |tee -a "$BASE.sliced.trace"

echo "Havoc undefined function bodies"
goto-instrument --generate-function-body '.*' --generate-function-body-options 'havoc,params:.*' $BASE.sliced.binary $BASE.havoc.binary
goto-instrument --count-eloc "$BASE.havoc.binary" |tee -a "$BASE.sliced.trace"
cp $BASE.havoc.binary $BASE.sliced.binary

aws s3 cp "$BASE.sliced.trace" "$BUCKETNAME/$NAME$BASE.depth${depth}-unwind${unwinding}-dp${preserve_direct_paths}-fs${full_slice}-fp$FP_removal.trace"

echo "Running analysis: $CBMC_options"
( time cbmc --timestamp monotonic $CBMC_options --property $PROPERTY $BASE.sliced.binary ) |& tee -a "$BASE.sliced.trace"
CBMC_STATUS=${PIPESTATUS[0]}

if [ $minimise_trace -gt 0 ]; then

aws s3 cp "$BASE.sliced.log" "$BUCKETNAME/$NAME$BASE.depth${depth}-unwind${unwinding}-dp${preserve_direct_paths}-fs${full_slice}-fp$FP_removal.log"
aws s3 cp "$BASE.sliced.trace" "$BUCKETNAME/$NAME$BASE.depth${depth}-unwind${unwinding}-dp${preserve_direct_paths}-fs${full_slice}-fp$FP_removal.trace"

if [ "$CBMC_STATUS" -eq 10 ]; then

TRACELEN=$(grep -o "^State [0-9]* file" "$BASE.sliced.trace" | sort -V | tail -n 1 | awk '{print $2}')
echo "initial trace len: $TRACELEN" |tee -a "$BASE.sliced.log"
echo "try to reduce trace ..." |tee -a "$BASE.sliced.log"

MAX=$TRACELEN
ACTUAL_TRACE_LEN=$TRACELEN
MIN=1
MIDDLE=$MIN

while [ "$MAX" -gt "$MIN" ]; do
		# check for minimum
		echo "find trace for $MIDDLE ($MIN < $MIDDLE < $MAX)? ..." |tee -a "$BASE.sliced.log"

		( ulimit -t 180; time cbmc --timestamp monotonic $CBMC_options --property $PROPERTY --depth $MIDDLE $BASE.sliced.binary ) > "$TRACE.short" 2>&1
		MS=$?
		echo "  exited with $MS, last lines of output: $(tail -n 15 "$TRACE.short")"
		# check whether we found a shorter trace
		if [ "$MS" -eq 0 ]; then
			# no trace, increase middle again!
			echo "  failed, set min to $MIDDLE"
			MIN=$MIDDLE
		elif [ "$MS" -eq 10 ]; then
			# found trace
			MAX=$((MIDDLE-1))
			echo "  succeeds, set best to $MIDDLE"
			TMP_TRACELEN=$(grep -o "^State [0-9]* file" "$BASE.sliced.trace" | sort -V | tail -n 1 | awk '{print $2}')
			if [ "$TMP_TRACELEN" -lt "$ACTUAL_TRACE_LEN" ]; then
			  echo "actual trace len $TMP_TRACELEN, this is new best trace"
		          cp "$TRACE.short" "$BASE.sliced.trace"
		          ACTUAL_TRACE_LEN=TMP_TRACELEN
		        fi
		else
			echo "  failed with status $MS, abort minimization"
			break
		fi
		# update minimum
		MIDDLE=$(((MAX+1-MIN)/2))
		MIDDLE=$((MIN + MIDDLE))
done
NEWTRACELEN=$(grep -o "^State [0-9]* file" "$BASE.sliced.trace" | sort -V | tail -n 1 | awk '{print $2}')
echo "shortest trace steps: $NEWTRACELEN stored here: $(ls "$BASE.sliced.trace")"	|tee -a "$BASE.sliced.log"

else
echo "No trace found, CBMC status: $CBMC_STATUS " |tee -a "$BASE.sliced.log"
fi

fi

echo "goto-instrument options: $SLICE_options"  |tee -a "$BASE.sliced.trace"
echo "cbmc options: $CBMC_options" |tee -a "$BASE.sliced.trace"

echo "End time $(date +%s)" |& tee -a "$BASE.sliced.trace" 

aws s3 cp "$BASE.sliced.log" "$BUCKETNAME/$NAME$BASE.depth${depth}-unwind${unwinding}-dp${preserve_direct_paths}-fs${full_slice}-fp${FP_removal}.log"
aws s3 cp "$BASE.sliced.trace" "$BUCKETNAME/$NAME$BASE.depth${depth}-unwind${unwinding}-dp${preserve_direct_paths}-fs${full_slice}-fp${FP_removal}.trace"

