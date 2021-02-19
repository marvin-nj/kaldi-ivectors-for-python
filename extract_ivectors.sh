#!/bin/bash
# Copyright     2013  Daniel Povey
#               2014  David Snyder
# Apache 2.0.

# Modified by Copyright 2017 Nicanor Garcia-Ospina
# Apache 2.0.

# This script extracts iVectors for a set of utterances, given
# features and a trained iVector extractor.

# Begin configuration section.
nj=4
num_gselect=20 # Gaussian-selection using diagonal model: number of Gaussians to select
min_post=0.025 # Minimum posterior to use (posteriors below this are pruned out)
posterior_scale=1.0 # This scale helps to control for successve features being highly
                    # correlated.  E.g. try 0.1 or 0.3.
# End configuration section.

echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then 
.  ./path.sh
fi
. utils/parse_options.sh ||exit  1;


if [ $# != 3 ]; then
  echo "Usage: $0 <extractor-dir> <features> <ivector-dir>"
  echo " e.g.: $0 exp/extractor_2048_male data/train_male.scp exp/ivectors_male"
  echo "main options (for others, see top of script file)"
  echo "  --config <config-file>                           # config containing options"
  echo "  --num-iters <#iters|10>                          # Number of iterations of E-M"
  echo "  --nj <n|10>                                      # Number of jobs (also see num-processes and num-threads)"
  echo "  --num-threads <n|8>                              # Number of threads for each process"
  echo "  --num-gselect <n|20>                             # Number of Gaussians to select using"
  echo "                                                   # diagonal model."
  echo "  --min-post <min-post|0.025>                      # Pruning threshold for posteriors"
  exit 1;
fi

srcdir=$1
features=$2
dir=$3

if [ -f $dir/ivector.scp ]; then
   rm  -r  $dir/*
	
fi

for f in $srcdir/final.ie $srcdir/final.ubm ${features} ; do
  [ ! -f $f ] && echo "No such file $f" && exit 1;
done

# Set various variables.
mkdir -p $dir/log

delta_opts=`cat $srcdir/delta_opts 2>/dev/null`

## Set up features.
feats="ark:copy-matrix scp:${features} ark:- |"

  echo "$0: extracting iVectors"
  dubm="fgmm-global-to-gmm $srcdir/final.ubm -|"

gmm-gselect --n=$num_gselect "$dubm" "$feats" ark:- | \
fgmm-global-gselect-to-post --min-post=$min_post $srcdir/final.ubm "$feats" \
 ark:- ark:- | scale-post ark:- $posterior_scale ark:- | \
  ivector-extract --verbose=2 $srcdir/final.ie "$feats" ark:- \
  ark,scp:$dir/ivector.ark,$dir/ivector.scp || exit 1;

  echo "ivector save  OK"
