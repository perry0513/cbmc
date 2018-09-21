date
echo "Args: $@"
mkdir tmp_dir
aws s3 cp s3://xen-paper-bucket/batch.tar.gz tmpdir/batch.tar.gz
cd tmpdir
tar -xvf batch.tar.gz
cd binaries_for_batch
export PATH=$PATH:$(pwd)
./batch_script.sh $1 $2 $3 $4 $5 $6 $7
echo "bye bye!!"
