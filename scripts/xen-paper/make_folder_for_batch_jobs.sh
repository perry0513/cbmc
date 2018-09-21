
home=$(pwd)

cp xen/xen/xen-syms.binary binaries_for_batch/
cp xen/xen/arch/x86/harness.o binaries_for_batch/
cp xen/xen/common/multicallstub.o binaries_for_batch/
cp xen/stub_syscall.o binaries_for_batch/

cp cbmc/src/cbmc/cbmc binaries_for_batch/
cp cbmc/src/goto-instrument/goto-instrument binaries_for_batch/
cp cbmc/src/goto-cc/goto-cc binaries_for_batch

sed -i -e "s/my_trace_name/$JOBNAME/g" binaries_for_batch/batch_script.sh
sed -i -e "s/bucket_name/$BUCKETNAME/g" binaries_for_batch/batch_script.sh

tar -cvzf batch.tar.gz binaries_for_batch

aws s3 cp batch.tar.gz $BUCKETNAME/batch.tar.gz



