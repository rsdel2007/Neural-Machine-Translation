#!/bin/bash
#SBATCH -N 1
#SBATCH -c 12
#SBATCH --mem-per-cpu=3G
#SBATCH -p gpu -C gpuk40 --gres=gpu:1
#SBATCH --time=10-00:30:00
#SBATCH --mail-type=ALL
#SBATCH --output=slurm-translate.out
#SBATCH --job-name="nmt-translate"

if [[ $# != 3 ]] ; then
    echo 'Error, command should be: <sbatch translate.sh src-lang-code tgt-lang-code path-of-inputTranscript>'
    exit 1
fi

src=$1
tgt=$2
input_file=$3
lang=${1}-${2}

export HOME=$(pwd)/../..
export DATA=$HOME/data
export DATA_PREP=$DATA/$lang
export MODELS=$HOME/models/$lang
export SCRIPT=$HOME/Neural-Machine-Translation/scripts

module load singularity/2.5.1
cd $HOME/singularity
singularity shell -w --nv rh_xenial_20180308.img

cd $SCRIPT
source $HOME/myenv/bin/activate
toggle=1

if [ $toggle -eq 0 ]
then
python $SCRIPT/parse.py $input_file
perl $SCRIPT/tokenizer.perl -l $src < tmp.txt > tmp.txt.tok
perl $SCRIPT/lowercase.perl < tmp.txt.tok > tmp.txt.tok.low
$HOME/Neural-Machine-Translation/subword-nmt/apply_bpe.py -c $HOME/Neural-Machine-Translation/subword-nmt/$lang/bpe.32000 < tmp.txt.tok.low > tmp.txt.tok.low.bpe
mv tmp.txt.tok.low.bpe tmp.txt
python $HOME/Neural-Machine-Translation/translate.py -data $DATA_PREP/processed_all-train.pt -load_from $MODELS/model_25_reinforce.pt -test_src $SCRIPT/tmp.txt
sed -r -i 's/(@@ )|(@@ ?$)//g' tmp.txt.pred
python $SCRIPT/output.py $input_file
rm $SCRIPT/tmp.txt*
fi

#### To translate a simple file not in the news transcript format:
if [ $toggle -eq 1 ]
then
	python $HOME/Neural-Machine-Translation/translate.py -data $DATA_PREP/processed_all-train.pt -load_from $MODELS/model_25_reinforce.pt -test_src $input_file
	input_file="$input_file.pred"
	sed -r -i 's/(@@ )|(@@ ?$)//g' $input_file
fi
